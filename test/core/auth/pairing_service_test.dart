import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/ability/estimator.dart';
import 'package:smriti/core/auth/pairing_service.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/ability_repo.dart';

import '../repo/_test_db.dart';

/// Records what the service tried to do, and answers with a canned response.
///
/// The live Edge Function is never called from tests; see the note in the task
/// report about manual verification with a real token.
class FakePairingGateway implements PairingGateway {
  FakePairingGateway({
    this.response,
    this.onInvoke,
    this.patientRows = const [],
    this.signInError,
    this.patientsError,
  });

  final PairingResponse? response;
  final PairingResponse Function(String function, Map<String, dynamic> body)?
      onInvoke;
  final List<Map<String, dynamic>> patientRows;
  final Object? signInError;
  final Object? patientsError;

  final List<String> invokedFunctions = [];
  final List<Map<String, dynamic>> bodies = [];
  final List<String> sessions = [];
  final List<String> signIns = [];
  int signOuts = 0;

  /// Every gateway call in order, so tests can assert that sign-out happens
  /// before the device session is established (AGENTS.md #8).
  final List<String> calls = [];

  int get invocations => invokedFunctions.length;

  @override
  Future<PairingResponse> invoke(
    String function,
    Map<String, dynamic> body,
  ) async {
    calls.add('invoke:$function');
    invokedFunctions.add(function);
    bodies.add(body);
    return onInvoke?.call(function, body) ??
        response ??
        const PairingResponse(status: 200, data: <String, dynamic>{});
  }

  @override
  Future<void> setSession(String refreshToken) async {
    calls.add('setSession');
    sessions.add(refreshToken);
  }

  @override
  Future<void> signInWithPassword(String email, String password) async {
    calls.add('signIn');
    if (signInError != null) throw signInError!;
    signIns.add(email);
  }

  @override
  Future<void> signOut() async {
    calls.add('signOut');
    signOuts++;
  }

  @override
  Future<List<Map<String, dynamic>>> fetchCaregiverPatients() async {
    calls.add('fetchPatients');
    if (patientsError != null) throw patientsError!;
    return patientRows;
  }
}

/// A `patient_members` row shaped like the real nested select returns.
Map<String, dynamic> patientRow({
  required String id,
  required String displayName,
  String langCode = 'as',
}) =>
    {
      'patient_id': id,
      'patients': {
        'id': id,
        'display_name': displayName,
        'lang_code': langCode,
      },
    };

/// A realistic successful response from `redeem-pairing-token`.
Map<String, dynamic> successBody({
  int age = 76,
  Object educationYears = 12,
}) =>
    {
      'refresh_token': 'refresh-token-abc123',
      'patient_id': '3f1c9b2e-5d47-4a1e-9c3a-77f0e2a4b118',
      'device_user_id': 'a20b7c64-9e31-4f8b-8d2a-1c5e6b9d0f43',
      'lang_code': 'as',
      'elder_name': 'Aai',
      'age': age,
      'education_years': educationYears,
    };

void main() {
  late SmritiDatabase db;
  late AbilityRepo abilityRepo;

  setUp(() {
    db = newTestDb();
    abilityRepo = AbilityRepo(db);
  });

  tearDown(() async => db.close());

  PairingService serviceWith(FakePairingGateway gateway) => PairingService(
        configs: db.appConfigsDao,
        abilityRepo: abilityRepo,
        gateway: gateway,
      );

  group('code validation', () {
    test('accepts exactly the spec alphabet, 8 characters', () {
      expect(PairingService.codeAlphabet, 'ACDEFGHJKLMNPQRSTUVWXYZ2345679');
      expect(PairingService.codeLength, 8);

      // Every ambiguous character is absent, per APP-BUILD-SPEC.md §7.
      for (final excluded in ['B', 'I', 'O', '0', '1', '8']) {
        expect(PairingService.codeAlphabet, isNot(contains(excluded)),
            reason: '$excluded must not be in the alphabet');
      }

      expect(PairingService.isValidCode('ACDEFGHJ'), isTrue);
      expect(PairingService.isValidCode('23456792'), isTrue);
      // Lower case and separators are normalised, not rejected.
      expect(PairingService.isValidCode('acdefghj'), isTrue);
      expect(PairingService.isValidCode('ACDE-FGHJ'), isTrue);
    });

    test('rejects excluded characters, wrong lengths and empties', () {
      expect(PairingService.isValidCode('BCDEFGHJ'), isFalse, reason: 'has B');
      expect(PairingService.isValidCode('ICDEFGHJ'), isFalse, reason: 'has I');
      expect(PairingService.isValidCode('OCDEFGHJ'), isFalse, reason: 'has O');
      expect(PairingService.isValidCode('0CDEFGHJ'), isFalse, reason: 'has 0');
      expect(PairingService.isValidCode('1CDEFGHJ'), isFalse, reason: 'has 1');
      expect(PairingService.isValidCode('8CDEFGHJ'), isFalse, reason: 'has 8');
      expect(PairingService.isValidCode('ACDEFGH'), isFalse, reason: '7 chars');
      expect(PairingService.isValidCode('ACDEFGHJK'), isFalse, reason: '9');
      expect(PairingService.isValidCode(''), isFalse);
      expect(PairingService.isValidCode('   '), isFalse);
      expect(PairingService.isValidCode('ACDE FGH'), isFalse);
    });
  });

  group('rejects bad input before any network call', () {
    test('empty and whitespace-only tokens never reach the gateway', () async {
      final gateway = FakePairingGateway();
      final service = serviceWith(gateway);

      for (final bad in ['', '   ', '-', '--']) {
        await expectLater(
          service.redeemToken(bad),
          throwsA(isA<PairingException>()),
        );
      }

      expect(gateway.invocations, 0);
      expect(gateway.sessions, isEmpty);
      expect(await db.appConfigsDao.getValue('patientId'), isNull);
    });

    test('malformed typed codes never reach the gateway', () async {
      final gateway = FakePairingGateway();
      final service = serviceWith(gateway);

      // Excluded characters, wrong length, and empty.
      for (final bad in ['BCDEFGHJ', 'OICDEFGH', 'ACDEFGH', 'ACDEFGHJK', '']) {
        await expectLater(
          service.redeemCode(bad),
          throwsA(isA<PairingException>()),
          reason: '$bad must be rejected locally',
        );
      }

      expect(gateway.invocations, 0,
          reason: 'no round trip is spent on a code that cannot be right');
      expect(await db.select(db.abilityStates).get(), isEmpty);
    });
  });

  group('successful pairing', () {
    test('populates AppConfigs and seeds every ability domain', () async {
      final gateway = FakePairingGateway(
        response: PairingResponse(status: 200, data: successBody()),
      );
      final service = serviceWith(gateway);

      await service.redeemCode('acde-fghj');

      // Called the right function, with the code normalised as §8 specifies.
      expect(gateway.invokedFunctions, ['redeem-pairing-token']);
      expect(gateway.bodies.single, {'token': 'ACDEFGHJ'});

      // Device session established from the returned refresh token.
      expect(gateway.sessions, ['refresh-token-abc123']);

      final configs = db.appConfigsDao;
      expect(await configs.getValue('patientId'),
          '3f1c9b2e-5d47-4a1e-9c3a-77f0e2a4b118');
      expect(await configs.getValue('deviceUserId'),
          'a20b7c64-9e31-4f8b-8d2a-1c5e6b9d0f43');
      expect(await configs.getValue('langCode'), 'as');
      expect(await configs.getValue('elderName'), 'Aai');
      expect(await configs.getValue('age'), '76');
      expect(await configs.getValue('educationYears'), '12');

      // Ability seeded from the real demographics, for all five domains.
      final expected = AbilityEstimator.seed(76, 12);
      final all = await abilityRepo.getAllRecords();
      expect(all.keys, hasLength(CognitiveDomain.values.length));
      for (final domain in CognitiveDomain.values) {
        expect(all[domain], isNotNull, reason: '$domain must be seeded');
        expect(all[domain]!.theta, closeTo(expected.theta, 1e-12));
        expect(all[domain]!.nTrials, 0);
      }
      // Education 12 with age 76 is above the neutral baseline.
      expect(expected.theta, isNot(closeTo(0.0, 1e-9)));
    });

    test('handles age and education arriving as strings', () async {
      final gateway = FakePairingGateway(
        response: PairingResponse(
          status: 200,
          data: successBody(age: 81, educationYears: '5'),
        ),
      );

      await serviceWith(gateway).redeemToken('ACDEFGHJ');

      expect(await db.appConfigsDao.getValue('age'), '81');
      expect(await db.appConfigsDao.getValue('educationYears'), '5');

      final expected = AbilityEstimator.seed(81, 5);
      final record = await abilityRepo.getRecord(CognitiveDomain.memory);
      expect(record!.theta, closeTo(expected.theta, 1e-12));
    });

    test('a QR payload longer than 8 characters is still redeemed', () async {
      final gateway = FakePairingGateway(
        response: PairingResponse(status: 200, data: successBody()),
      );

      // Scanned payloads are opaque and need not match the typed-code format.
      await serviceWith(gateway)
          .redeemToken('pairing-token-9f2c41ab7de84c0fa3');

      expect(gateway.bodies.single['token'], 'PAIRINGTOKEN9F2C41AB7DE84C0FA3');
      expect(await db.appConfigsDao.getValue('langCode'), 'as');
    });

    test('re-pairing does not wipe accumulated ability history', () async {
      await abilityRepo.saveRecord(
        CognitiveDomain.memory,
        const AbilityRecord(
          theta: 1.4,
          nTrials: 120,
          rtMeanLog: 7.6,
          rtVar: 0.18,
        ),
      );

      final gateway = FakePairingGateway(
        response: PairingResponse(status: 200, data: successBody()),
      );
      await serviceWith(gateway).redeemToken('ACDEFGHJ');

      final memory = await abilityRepo.getRecord(CognitiveDomain.memory);
      expect(memory!.nTrials, 120, reason: 'existing history is preserved');
      expect(memory.theta, closeTo(1.4, 1e-12));

      // Untouched domains are still seeded.
      expect(await abilityRepo.getRecord(CognitiveDomain.language), isNotNull);
    });
  });

  group('caregiver-login path', () {
    test('signs the caregiver out BEFORE establishing the device session',
        () async {
      final gateway = FakePairingGateway(
        response: PairingResponse(status: 200, data: successBody()),
        patientRows: [patientRow(id: 'p1', displayName: 'Aai')],
      );
      final service = serviceWith(gateway);

      await service.signInCaregiver(email: 'c@example.com', password: 'pw');
      await service.completeCaregiverPairing('p1');

      // The whole point of AGENTS.md non-negotiable #8, asserted as an order.
      expect(gateway.calls, [
        'signIn',
        'fetchPatients',
        'invoke:pair-device-authenticated',
        'signOut',
        'setSession',
      ]);
      expect(
        gateway.calls.indexOf('signOut'),
        lessThan(gateway.calls.indexOf('setSession')),
        reason: 'caregiver credentials must be gone before the device session',
      );

      expect(gateway.bodies.single, {'patient_id': 'p1'});
      expect(await db.appConfigsDao.getValue('patientId'),
          '3f1c9b2e-5d47-4a1e-9c3a-77f0e2a4b118');
      expect(await abilityRepo.getRecord(CognitiveDomain.memory), isNotNull);
    });

    test('parses the nested patient_members select', () async {
      final gateway = FakePairingGateway(
        patientRows: [
          patientRow(id: 'p1', displayName: 'Aai', langCode: 'as'),
          patientRow(id: 'p2', displayName: 'Deuta', langCode: 'bn'),
        ],
      );

      final patients = await serviceWith(gateway)
          .signInCaregiver(email: ' c@example.com ', password: 'pw');

      expect(patients.map((p) => p.id), ['p1', 'p2']);
      expect(patients.map((p) => p.displayName), ['Aai', 'Deuta']);
      expect(patients.map((p) => p.langCode), ['as', 'bn']);
      // Email is trimmed before it reaches the backend.
      expect(gateway.signIns, ['c@example.com']);
      // Still signed in: the picker needs the session alive.
      expect(gateway.signOuts, 0);
    });

    test('tolerates the join arriving as a single-element list', () async {
      final gateway = FakePairingGateway(
        patientRows: [
          {
            'patient_id': 'p1',
            'patients': [
              {'id': 'p1', 'display_name': 'Aai', 'lang_code': 'as'},
            ],
          },
        ],
      );

      final patients = await serviceWith(gateway)
          .signInCaregiver(email: 'c@example.com', password: 'pw');

      expect(patients.single.id, 'p1');
      expect(patients.single.displayName, 'Aai');
    });

    test('empty credentials never reach the network', () async {
      final gateway = FakePairingGateway();
      final service = serviceWith(gateway);

      await expectLater(
        service.signInCaregiver(email: '  ', password: 'pw'),
        throwsA(isA<PairingException>()),
      );
      await expectLater(
        service.signInCaregiver(email: 'c@example.com', password: ''),
        throwsA(isA<PairingException>()),
      );

      expect(gateway.calls, isEmpty);
    });

    test('a caregiver managing no patients is signed out again', () async {
      final gateway = FakePairingGateway(patientRows: const []);

      await expectLater(
        serviceWith(gateway)
            .signInCaregiver(email: 'c@example.com', password: 'pw'),
        throwsA(isA<PairingException>()),
      );

      expect(gateway.signOuts, 1,
          reason: 'no credentials may be left on the tablet');
      expect(gateway.calls, ['signIn', 'fetchPatients', 'signOut']);
    });

    test('a failed patient lookup signs the caregiver out', () async {
      final gateway = FakePairingGateway(
        patientsError: Exception('network down'),
      );

      await expectLater(
        serviceWith(gateway)
            .signInCaregiver(email: 'c@example.com', password: 'pw'),
        throwsA(isA<Exception>()),
      );

      expect(gateway.signOuts, 1);
    });

    test('cancelling after sign-in signs out', () async {
      final gateway = FakePairingGateway(
        patientRows: [patientRow(id: 'p1', displayName: 'Aai')],
      );
      final service = serviceWith(gateway);

      await service.signInCaregiver(email: 'c@example.com', password: 'pw');
      await service.cancelCaregiverLogin();

      expect(gateway.signOuts, 1);
      expect(gateway.sessions, isEmpty);
      expect(await db.appConfigsDao.getValue('patientId'), isNull);
    });

    test('a rejected pairing still signs out, and pairs nothing', () async {
      final gateway = FakePairingGateway(
        response: const PairingResponse(
          status: 403,
          data: {'error': 'not authorised for this patient'},
        ),
        patientRows: [patientRow(id: 'p1', displayName: 'Aai')],
      );
      final service = serviceWith(gateway);

      await service.signInCaregiver(email: 'c@example.com', password: 'pw');
      await expectLater(
        service.completeCaregiverPairing('p1'),
        throwsA(
          isA<PairingException>().having(
            (e) => e.message,
            'message',
            'not authorised for this patient',
          ),
        ),
      );

      expect(gateway.signOuts, 1, reason: 'sign-out happens even on failure');
      expect(gateway.sessions, isEmpty);
      expect(await db.appConfigsDao.getValue('patientId'), isNull);
    });

    test('a thrown Edge Function call still signs out', () async {
      final gateway = FakePairingGateway(
        onInvoke: (_, __) => throw Exception('connection reset'),
        patientRows: [patientRow(id: 'p1', displayName: 'Aai')],
      );
      final service = serviceWith(gateway);

      await service.signInCaregiver(email: 'c@example.com', password: 'pw');
      await expectLater(
        service.completeCaregiverPairing('p1'),
        throwsA(isA<Exception>()),
      );

      expect(gateway.signOuts, 1);
      expect(gateway.sessions, isEmpty);
    });

    test('pairing with no patient selected never calls the backend', () async {
      final gateway = FakePairingGateway();

      await expectLater(
        serviceWith(gateway).completeCaregiverPairing(''),
        throwsA(isA<PairingException>()),
      );

      expect(gateway.invocations, 0);
    });

    test('the single-call form from spec 8 keeps the same ordering', () async {
      final gateway = FakePairingGateway(
        response: PairingResponse(status: 200, data: successBody()),
      );

      await serviceWith(gateway)
          .pairViaCaregiverLogin('c@example.com', 'pw', 'p1');

      expect(gateway.calls, [
        'signIn',
        'invoke:pair-device-authenticated',
        'signOut',
        'setSession',
      ]);
      expect(await db.appConfigsDao.getValue('patientId'), isNotNull);
    });
  });

  group('failed pairing', () {
    test('surfaces the server error message and writes nothing', () async {
      final gateway = FakePairingGateway(
        response: const PairingResponse(
          status: 400,
          data: {'error': 'token already redeemed'},
        ),
      );

      await expectLater(
        serviceWith(gateway).redeemToken('ACDEFGHJ'),
        throwsA(
          isA<PairingException>().having(
            (e) => e.message,
            'message',
            'token already redeemed',
          ),
        ),
      );

      expect(gateway.sessions, isEmpty);
      expect(await db.appConfigsDao.getValue('patientId'), isNull);
      expect(await db.select(db.abilityStates).get(), isEmpty);
    });

    test('falls back to a generic message when the body has no error',
        () async {
      final gateway = FakePairingGateway(
        response: const PairingResponse(status: 401, data: null),
      );

      await expectLater(
        serviceWith(gateway).redeemToken('ACDEFGHJ'),
        throwsA(
          isA<PairingException>().having(
            (e) => e.message,
            'message',
            'invalid or expired code',
          ),
        ),
      );
    });

    test('a 200 with a malformed body pairs nothing', () async {
      final gateway = FakePairingGateway(
        response: const PairingResponse(
          status: 200,
          data: {'patient_id': 'p1'}, // no refresh_token
        ),
      );

      await expectLater(
        serviceWith(gateway).redeemToken('ACDEFGHJ'),
        throwsA(isA<PairingException>()),
      );

      expect(gateway.sessions, isEmpty);
      expect(await db.appConfigsDao.getValue('patientId'), isNull);
    });

    test('a missing demographic field aborts before AppConfigs is written',
        () async {
      final body = successBody()..remove('education_years');
      final gateway = FakePairingGateway(
        response: PairingResponse(status: 200, data: body),
      );

      await expectLater(
        serviceWith(gateway).redeemToken('ACDEFGHJ'),
        throwsA(isA<PairingException>()),
      );

      expect(await db.appConfigsDao.getValue('patientId'), isNull,
          reason: 'AppConfigs is written in one transaction, all or nothing');
    });
  });
}
