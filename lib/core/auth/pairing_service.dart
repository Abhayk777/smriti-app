import 'package:supabase_flutter/supabase_flutter.dart';

import '../db/dao/app_configs_dao.dart';
import '../repo/ability_repo.dart';

/// Thrown when pairing cannot complete. Caregiver-facing: this is a setup
/// screen, so the message is shown. The elder never sees any of it
/// (AGENTS.md non-negotiable #9).
class PairingException implements Exception {
  const PairingException(this.message);

  final String message;

  @override
  String toString() => 'PairingException: $message';
}

/// Raw result of an Edge Function call, so [PairingService] can apply the
/// status handling APP-BUILD-SPEC.md §8 specifies without depending on
/// Supabase's concrete response type.
class PairingResponse {
  const PairingResponse({required this.status, this.data});

  final int status;
  final Object? data;
}

/// One patient a signed-in caregiver manages.
class CaregiverPatient {
  const CaregiverPatient({
    required this.id,
    required this.displayName,
    required this.langCode,
  });

  final String id;
  final String displayName;
  final String langCode;
}

/// The network surface pairing needs.
///
/// Exists so the service can be unit-tested without a live backend. The real
/// implementation is [SupabasePairingGateway]; nothing outside `lib/core/auth/`
/// and `lib/core/sync/` may talk to Supabase (AGENTS.md non-negotiable #1).
abstract class PairingGateway {
  Future<PairingResponse> invoke(String function, Map<String, dynamic> body);

  Future<void> setSession(String refreshToken);

  Future<void> signInWithPassword(String email, String password);

  Future<void> signOut();

  /// Raw `patient_members` rows for the signed-in caregiver.
  Future<List<Map<String, dynamic>>> fetchCaregiverPatients();
}

class SupabasePairingGateway implements PairingGateway {
  const SupabasePairingGateway();

  @override
  Future<PairingResponse> invoke(
    String function,
    Map<String, dynamic> body,
  ) async {
    final res =
        await Supabase.instance.client.functions.invoke(function, body: body);
    return PairingResponse(status: res.status, data: res.data);
  }

  @override
  Future<void> setSession(String refreshToken) =>
      Supabase.instance.client.auth.setSession(refreshToken);

  @override
  Future<void> signInWithPassword(String email, String password) async {
    await Supabase.instance.client.auth
        .signInWithPassword(email: email, password: password);
  }

  @override
  Future<void> signOut() => Supabase.instance.client.auth.signOut();

  /// Lists the caregiver's patients.
  ///
  /// A plain nested PostgREST select, not an RPC: RLS on `patient_members`
  /// already scopes rows to the authenticated caller, so a caregiver only ever
  /// sees their own. This is a caregiver-side read, so AGENTS.md non-negotiable
  /// #4 (no `.select()` on device writes) does not apply.
  @override
  Future<List<Map<String, dynamic>>> fetchCaregiverPatients() async {
    final rows = await Supabase.instance.client
        .from('patient_members')
        .select('patient_id, patients(id, display_name, lang_code)')
        .eq('role', 'caregiver');
    return (rows as List).cast<Map<String, dynamic>>();
  }
}

/// Pairs this tablet to a patient.
///
/// However pairing happens, the tablet ends in one state: signed in as a device
/// identity, with `patientId`/`langCode` in `AppConfigs`, holding no caregiver
/// credentials (APP-BUILD-SPEC.md §8).
class PairingService {
  PairingService({
    required this.configs,
    required this.abilityRepo,
    PairingGateway gateway = const SupabasePairingGateway(),
  }) : _gateway = gateway;

  final AppConfigsDao configs;
  final AbilityRepo abilityRepo;
  final PairingGateway _gateway;

  /// The pairing code alphabet, copied verbatim from APP-BUILD-SPEC.md §7.
  /// No B, I, O, 0, 1 or 8 - they are visually or verbally ambiguous.
  /// Do not retype this string (AGENTS.md non-negotiable #7).
  static const String codeAlphabet = 'ACDEFGHJKLMNPQRSTUVWXYZ2345679';

  static const int codeLength = 8;

  /// Normalises a typed or scanned code the way the Edge Function expects.
  static String normalize(String raw) =>
      raw.trim().toUpperCase().replaceAll('-', '');

  /// Whether [raw] is a well-formed 8-character typed code.
  ///
  /// Only applies to the code-entry path. A scanned QR payload is not required
  /// to be 8 characters, so [redeemToken] does not enforce this.
  static bool isValidCode(String raw) {
    final code = normalize(raw);
    if (code.length != codeLength) return false;
    return code.split('').every(codeAlphabet.contains);
  }

  /// Redeems a scanned QR payload or typed code against the live
  /// `redeem-pairing-token` Edge Function.
  ///
  /// Empty input is rejected locally, before any network call.
  Future<void> redeemToken(String token) async {
    final normalized = normalize(token);
    if (normalized.isEmpty) {
      throw const PairingException('invalid or expired code');
    }

    final res = await _gateway.invoke(
      'redeem-pairing-token',
      {'token': normalized},
    );

    if (res.status != 200) {
      throw PairingException(_errorOf(res.data) ?? 'invalid or expired code');
    }

    await _completePairing(_asMap(res.data));
  }

  /// Code-entry path. Validates against the exact alphabet before spending a
  /// network round trip on a code that cannot possibly be right.
  /// Async so a rejected code surfaces as a failed future, the same as a
  /// server-side rejection, rather than throwing at the call site.
  Future<void> redeemCode(String code) async {
    if (!isValidCode(code)) {
      throw const PairingException('invalid or expired code');
    }
    return redeemToken(code);
  }

  // CAREGIVER-LOGIN PATH
  //
  // Split into sign-in and pair steps because the patient picker sits between
  // them: the list can only be read while the caregiver session is alive, but
  // that session must be gone before the device session exists.

  /// Signs the caregiver in and returns the patients they manage.
  ///
  /// If anything goes wrong after sign-in, the caregiver is signed out before
  /// the error propagates — the tablet must never be left holding caregiver
  /// credentials (AGENTS.md non-negotiable #8).
  Future<List<CaregiverPatient>> signInCaregiver({
    required String email,
    required String password,
  }) async {
    final trimmedEmail = email.trim();
    if (trimmedEmail.isEmpty || password.isEmpty) {
      throw const PairingException('Enter an email address and password.');
    }

    await _gateway.signInWithPassword(trimmedEmail, password);

    try {
      final patients = _parsePatients(await _gateway.fetchCaregiverPatients());
      if (patients.isEmpty) {
        throw const PairingException(
          'This account does not manage any patients.',
        );
      }
      return patients;
    } catch (_) {
      await _gateway.signOut();
      rethrow;
    }
  }

  /// Abandons a caregiver login without pairing. Always signs out.
  Future<void> cancelCaregiverLogin() => _gateway.signOut();

  /// Completes pairing for [patientId] using the live caregiver session.
  ///
  /// The sign-out happens immediately after the Edge Function returns and
  /// before the device session is established, in that order, per AGENTS.md
  /// non-negotiable #8 — including when the call failed.
  Future<void> completeCaregiverPairing(String patientId) async {
    if (patientId.isEmpty) {
      throw const PairingException('No patient selected.');
    }

    PairingResponse res;
    try {
      res = await _gateway.invoke(
        'pair-device-authenticated',
        {'patient_id': patientId},
      );
    } catch (_) {
      await _gateway.signOut();
      rethrow;
    }

    // Mandatory, and before setSession below.
    await _gateway.signOut();

    if (res.status != 200) {
      throw PairingException(_errorOf(res.data) ?? 'could not pair this tablet');
    }

    await _completePairing(_asMap(res.data));
  }

  /// The single-call form given in APP-BUILD-SPEC.md §8, for a caregiver who
  /// already knows which patient to pair. The UI uses the split form above so
  /// it can show a picker.
  Future<void> pairViaCaregiverLogin(
    String email,
    String password,
    String patientId,
  ) async {
    await _gateway.signInWithPassword(email.trim(), password);
    await completeCaregiverPairing(patientId);
  }

  /// Flattens `patient_members` rows joined to `patients`.
  static List<CaregiverPatient> _parsePatients(
    List<Map<String, dynamic>> rows,
  ) {
    final patients = <CaregiverPatient>[];
    for (final row in rows) {
      // PostgREST returns the joined row as an object, or as a single-element
      // list depending on how the relationship is detected.
      final joined = row['patients'];
      final patient = joined is List
          ? (joined.isEmpty ? null : joined.first)
          : joined;
      if (patient is! Map) continue;

      final id = patient['id'] ?? row['patient_id'];
      if (id is! String || id.isEmpty) continue;

      patients.add(
        CaregiverPatient(
          id: id,
          displayName: patient['display_name'] as String? ?? 'Unnamed patient',
          langCode: patient['lang_code'] as String? ?? 'en',
        ),
      );
    }
    return patients;
  }

  /// Applies the device session and patient details returned by either path.
  Future<void> _completePairing(Map<String, dynamic> data) async {
    final refreshToken = data['refresh_token'];
    if (refreshToken is! String || refreshToken.isEmpty) {
      throw const PairingException('pairing response missing refresh_token');
    }

    await _gateway.setSession(refreshToken);

    final age = _requireInt(data, 'age');
    final educationYears = _requireInt(data, 'education_years');

    await configs.setAll({
      'patientId': _requireString(data, 'patient_id'),
      'deviceUserId': _requireString(data, 'device_user_id'),
      'langCode': _requireString(data, 'lang_code'),
      'elderName': _requireString(data, 'elder_name'),
      'age': age.toString(),
      'educationYears': educationYears.toString(),
      'deviceRefreshToken': refreshToken,
    });

    // Seeded from the real demographics, so the first session starts near the
    // elder's expected baseline instead of zero (APP-BUILD-SPEC.md §3).
    await abilityRepo.seedAll();
  }

  static Map<String, dynamic> _asMap(Object? data) {
    if (data is Map) return Map<String, dynamic>.from(data);
    throw const PairingException('unexpected pairing response');
  }

  static String? _errorOf(Object? data) {
    if (data is Map && data['error'] is String) return data['error'] as String;
    return null;
  }

  static String _requireString(Map<String, dynamic> data, String key) {
    final value = data[key];
    if (value is String && value.isNotEmpty) return value;
    throw PairingException('pairing response missing $key');
  }

  static int _requireInt(Map<String, dynamic> data, String key) {
    final value = data[key];
    final parsed = value is int ? value : int.tryParse('$value');
    if (parsed == null) throw PairingException('pairing response missing $key');
    return parsed;
  }
}
