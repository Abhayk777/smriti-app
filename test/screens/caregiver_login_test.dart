import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/auth/pairing_service.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/ability_repo.dart';
import 'package:smriti/screens/login_screen.dart';
import 'package:smriti/screens/pairing/pair_confirm_screen.dart';
import 'package:smriti/screens/pairing/patient_picker_screen.dart';

import '../core/auth/pairing_service_test.dart'
    show FakePairingGateway, patientRow, successBody;
import '../core/repo/_test_db.dart';

void main() {
  late SmritiDatabase db;

  setUp(() => db = newTestDb());
  tearDown(() async => db.close());

  Future<FakePairingGateway> pumpLogin(
    WidgetTester tester, {
    required List<Map<String, dynamic>> patientRows,
  }) async {
    final gateway = FakePairingGateway(
      response: PairingResponse(status: 200, data: successBody()),
      patientRows: patientRows,
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          pairingService: PairingService(
            configs: db.appConfigsDao,
            abilityRepo: AbilityRepo(db),
            gateway: gateway,
          ),
        ),
      ),
    );
    return gateway;
  }

  Future<void> signIn(WidgetTester tester) async {
    await tester.enterText(find.byType(TextField).first, 'c@example.com');
    await tester.enterText(find.byType(TextField).last, 'password');
    await tester.tap(find.byKey(const Key('sign_in_button')));
    await tester.pumpAndSettle();
  }

  testWidgets('one patient skips the picker and goes to confirmation',
      (tester) async {
    await pumpLogin(
      tester,
      patientRows: [patientRow(id: 'p1', displayName: 'Aai')],
    );

    await signIn(tester);

    expect(find.byType(PatientPickerScreen), findsNothing,
        reason: 'a single patient needs no picker');
    expect(find.byType(PairConfirmScreen), findsOneWidget);
    expect(find.byKey(const Key('confirm_patient_name')), findsOneWidget);
    expect(find.text('Aai'), findsOneWidget);
  });

  testWidgets('more than one patient shows the picker first', (tester) async {
    await pumpLogin(
      tester,
      patientRows: [
        patientRow(id: 'p1', displayName: 'Aai'),
        patientRow(id: 'p2', displayName: 'Deuta'),
        patientRow(id: 'p3', displayName: 'Mama'),
      ],
    );

    await signIn(tester);

    expect(find.byType(PatientPickerScreen), findsOneWidget);
    expect(find.text('Aai'), findsOneWidget);
    expect(find.text('Deuta'), findsOneWidget);
    expect(find.text('Mama'), findsOneWidget);
    expect(find.byType(PairConfirmScreen), findsNothing);

    // Choosing one moves on to confirmation for that patient.
    await tester.tap(find.byKey(const Key('patient_p2')));
    await tester.pumpAndSettle();

    expect(find.byType(PairConfirmScreen), findsOneWidget);
    expect(find.text('Deuta'), findsOneWidget);
  });

  testWidgets('confirming pairs the chosen patient and signs the caregiver out',
      (tester) async {
    final gateway = await pumpLogin(
      tester,
      patientRows: [
        patientRow(id: 'p1', displayName: 'Aai'),
        patientRow(id: 'p2', displayName: 'Deuta'),
      ],
    );

    await signIn(tester);
    await tester.tap(find.byKey(const Key('patient_p2')));
    await tester.pumpAndSettle();
    await tester.tap(find.byKey(const Key('confirm_pair_button')));
    await tester.pumpAndSettle();

    // The chosen patient, not merely the first one.
    expect(gateway.bodies.single, {'patient_id': 'p2'});
    expect(gateway.calls, [
      'signIn',
      'fetchPatients',
      'invoke:pair-device-authenticated',
      'signOut',
      'setSession',
    ]);

    expect(await db.appConfigsDao.getValue('patientId'), isNotNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('backing out of the picker signs the caregiver out',
      (tester) async {
    final gateway = await pumpLogin(
      tester,
      patientRows: [
        patientRow(id: 'p1', displayName: 'Aai'),
        patientRow(id: 'p2', displayName: 'Deuta'),
      ],
    );

    await signIn(tester);
    expect(find.byType(PatientPickerScreen), findsOneWidget);

    // Cancel out of the picker without choosing.
    Navigator.of(tester.element(find.byType(PatientPickerScreen))).pop();
    await tester.pumpAndSettle();

    expect(gateway.signOuts, 1,
        reason: 'the tablet must not keep caregiver credentials');
    expect(gateway.sessions, isEmpty);
    expect(await db.appConfigsDao.getValue('patientId'), isNull);
  });

  testWidgets('backing out of confirmation signs the caregiver out',
      (tester) async {
    final gateway = await pumpLogin(
      tester,
      patientRows: [patientRow(id: 'p1', displayName: 'Aai')],
    );

    await signIn(tester);
    expect(find.byType(PairConfirmScreen), findsOneWidget);

    await tester.tap(find.byIcon(Icons.arrow_back));
    await tester.pumpAndSettle();

    expect(gateway.signOuts, 1);
    expect(gateway.sessions, isEmpty);
    expect(await db.appConfigsDao.getValue('patientId'), isNull);
    expect(find.byType(LoginScreen), findsOneWidget);
  });

  testWidgets('a sign-in failure surfaces and pairs nothing', (tester) async {
    final gateway = FakePairingGateway(
      signInError: Exception('invalid login credentials'),
    );

    await tester.pumpWidget(
      MaterialApp(
        home: LoginScreen(
          pairingService: PairingService(
            configs: db.appConfigsDao,
            abilityRepo: AbilityRepo(db),
            gateway: gateway,
          ),
        ),
      ),
    );

    await signIn(tester);

    expect(find.byType(PatientPickerScreen), findsNothing);
    expect(find.byType(PairConfirmScreen), findsNothing);
    expect(find.byType(SnackBar), findsOneWidget);
    expect(await db.appConfigsDao.getValue('patientId'), isNull);
  });
}
