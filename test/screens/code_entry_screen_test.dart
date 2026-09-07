import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/auth/pairing_service.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/ability_repo.dart';
import 'package:smriti/screens/pairing/code_entry_screen.dart';

import '../core/auth/pairing_service_test.dart' show FakePairingGateway;
import '../core/repo/_test_db.dart';

void main() {
  late SmritiDatabase db;

  setUp(() => db = newTestDb());
  tearDown(() async => db.close());

  Future<FakePairingGateway> pumpScreen(
    WidgetTester tester, {
    PairingResponse? response,
  }) async {
    final gateway = FakePairingGateway(response: response);
    await tester.pumpWidget(
      MaterialApp(
        home: CodeEntryScreen(
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

  Future<void> enterCode(WidgetTester tester, String code) async {
    for (var i = 0; i < code.length; i++) {
      await tester.enterText(find.byKey(Key('code_box_$i')), code[i]);
      await tester.pump();
    }
  }

  testWidgets('renders exactly 8 entry boxes', (tester) async {
    await pumpScreen(tester);

    expect(find.byType(TextField), findsNWidgets(8));
    for (var i = 0; i < 8; i++) {
      expect(find.byKey(Key('code_box_$i')), findsOneWidget);
    }
  });

  testWidgets('submit stays disabled until all 8 boxes are filled',
      (tester) async {
    await pumpScreen(tester);

    ElevatedButton submitButton() =>
        tester.widget<ElevatedButton>(find.byKey(const Key('pairing_submit')));

    expect(submitButton().onPressed, isNull);

    await enterCode(tester, 'ACDEFGH');
    expect(submitButton().onPressed, isNull, reason: 'only 7 characters');

    await tester.enterText(find.byKey(const Key('code_box_7')), 'J');
    await tester.pump();
    expect(submitButton().onPressed, isNotNull);
  });

  testWidgets('characters outside the alphabet cannot be typed at all',
      (tester) async {
    await pumpScreen(tester);

    // B, I, O, 0, 1, 8 are excluded per APP-BUILD-SPEC.md §7.
    for (final excluded in ['B', 'I', 'O', '0', '1', '8']) {
      await tester.enterText(find.byKey(const Key('code_box_0')), excluded);
      await tester.pump();
      final field =
          tester.widget<TextField>(find.byKey(const Key('code_box_0')));
      expect(field.controller!.text, isEmpty,
          reason: '$excluded must be filtered out');
    }

    // A permitted character goes in, lower case included.
    await tester.enterText(find.byKey(const Key('code_box_0')), 'a');
    await tester.pump();
    expect(
      tester.widget<TextField>(find.byKey(const Key('code_box_0')))
          .controller!
          .text,
      'A',
    );
  });

  testWidgets('a valid code redeems and pops with success', (tester) async {
    final gateway = await pumpScreen(
      tester,
      response: const PairingResponse(
        status: 200,
        data: {
          'refresh_token': 'refresh-token-abc123',
          'patient_id': 'p1',
          'device_user_id': 'd1',
          'lang_code': 'as',
          'elder_name': 'Aai',
          'age': 76,
          'education_years': 12,
        },
      ),
    );

    await enterCode(tester, 'ACDEFGHJ');
    await tester.tap(find.byKey(const Key('pairing_submit')));
    await tester.pumpAndSettle();

    expect(gateway.bodies.single, {'token': 'ACDEFGHJ'});
    expect(await db.appConfigsDao.getValue('patientId'), 'p1');
    expect(await db.appConfigsDao.getValue('langCode'), 'as');
  });

  testWidgets('a server rejection is shown and the screen stays put',
      (tester) async {
    await pumpScreen(
      tester,
      response: const PairingResponse(
        status: 400,
        data: {'error': 'token already redeemed'},
      ),
    );

    await enterCode(tester, 'ACDEFGHJ');
    await tester.tap(find.byKey(const Key('pairing_submit')));
    await tester.pumpAndSettle();

    expect(find.byKey(const Key('pairing_error')), findsOneWidget);
    expect(find.text('token already redeemed'), findsOneWidget);
    expect(find.byType(CodeEntryScreen), findsOneWidget);
    expect(await db.appConfigsDao.getValue('patientId'), isNull);
  });
}
