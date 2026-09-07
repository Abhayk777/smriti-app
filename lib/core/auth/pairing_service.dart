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

/// The network surface pairing needs.
///
/// Exists so the service can be unit-tested without a live backend. The real
/// implementation is [SupabasePairingGateway]; nothing outside `lib/core/auth/`
/// and `lib/core/sync/` may talk to Supabase (AGENTS.md non-negotiable #1).
abstract class PairingGateway {
  Future<PairingResponse> invoke(String function, Map<String, dynamic> body);

  Future<void> setSession(String refreshToken);
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
