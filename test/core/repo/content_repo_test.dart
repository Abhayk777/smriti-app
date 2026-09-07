import 'package:drift/drift.dart' show Value;
import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/db/database.dart';
import 'package:smriti/core/repo/content_repo.dart';

import '_test_db.dart';

void main() {
  late SmritiDatabase db;
  late ContentRepo repo;

  setUp(() {
    db = newTestDb();
    repo = ContentRepo(db);
  });

  tearDown(() async => db.close());

  test('round-trips people, medications and routine items', () async {
    await repo.replaceContent(
      people: [
        PeopleCompanion.insert(
          id: 'p1',
          name: 'Anjali',
          relationship: 'daughter',
          photoPath: '/docs/people/photos/p1.jpg',
          voicePath: const Value('/docs/people/voice/p1.m4a'),
          memoryPrompt: const Value('She visits on Sundays.'),
          sortOrder: 1,
        ),
        PeopleCompanion.insert(
          id: 'p2',
          name: 'Bikash',
          relationship: 'husband',
          photoPath: '/docs/people/photos/p2.jpg',
          isDeceased: const Value(true),
          sortOrder: 0,
        ),
      ],
      medications: [
        MedicationsCompanion.insert(
          id: 'm1',
          name: 'Donepezil',
          dose: '5 mg',
          pillPhotoPath: const Value('/docs/medications/photos/m1.jpg'),
          windowStartMin: 480,
          windowEndMin: 600,
          chosenTimeMin: 540,
          daysOfWeek: '1,2,3,4,5,6,7',
        ),
        MedicationsCompanion.insert(
          id: 'm2',
          name: 'Discontinued pill',
          dose: '1 tab',
          windowStartMin: 1200,
          windowEndMin: 1260,
          chosenTimeMin: 1230,
          daysOfWeek: '1,2,3,4,5,6,7',
          active: const Value(false),
        ),
      ],
      routineItems: [
        RoutineItemsCompanion.insert(
          id: 'r1',
          timeMin: 420,
          labelKey: 'routine.breakfast',
          iconAsset: 'assets/icons/breakfast.png',
        ),
      ],
      contentVersion: '7',
    );

    // People come back ordered by sortOrder, with every column intact.
    final people = await repo.getPeople();
    expect(people.map((p) => p.id), ['p2', 'p1']);

    final anjali = await repo.getPerson('p1');
    expect(anjali, isNotNull);
    expect(anjali!.name, 'Anjali');
    expect(anjali.relationship, 'daughter');
    expect(anjali.photoPath, '/docs/people/photos/p1.jpg');
    expect(anjali.voicePath, '/docs/people/voice/p1.m4a');
    expect(anjali.memoryPrompt, 'She visits on Sundays.');
    expect(anjali.isDeceased, isFalse);

    expect((await repo.getLivingPeople()).map((p) => p.id), ['p1']);

    // Medications default to active-only.
    expect((await repo.getMedications()).map((m) => m.id), ['m1']);
    expect((await repo.getMedications(activeOnly: false)).map((m) => m.id),
        ['m1', 'm2']);

    final med = await repo.getMedication('m1');
    expect(med!.dose, '5 mg');
    expect(med.windowStartMin, 480);
    expect(med.windowEndMin, 600);
    expect(med.chosenTimeMin, 540);
    expect(med.daysOfWeek, '1,2,3,4,5,6,7');
    expect(med.voicePath, isNull);

    final routine = await repo.getRoutineItems();
    expect(routine.single.labelKey, 'routine.breakfast');

    expect(await repo.getContentVersion(), '7');
  });

  test('replaceContent swaps atomically, leaving no stale rows', () async {
    await repo.replaceContent(
      people: [
        PeopleCompanion.insert(
          id: 'old',
          name: 'Old Person',
          relationship: 'friend',
          photoPath: '/docs/people/photos/old.jpg',
          sortOrder: 0,
        ),
      ],
      medications: const [],
      routineItems: const [],
      contentVersion: '1',
    );

    await repo.replaceContent(
      people: [
        PeopleCompanion.insert(
          id: 'new',
          name: 'New Person',
          relationship: 'son',
          photoPath: '/docs/people/photos/new.jpg',
          sortOrder: 0,
        ),
      ],
      medications: const [],
      routineItems: const [],
      contentVersion: '2',
    );

    expect((await repo.getPeople()).map((p) => p.id), ['new']);
    expect(await repo.getPerson('old'), isNull);
    expect(await repo.getContentVersion(), '2');
  });

  test('a failed swap rolls back and keeps the previous content', () async {
    await repo.replaceContent(
      people: [
        PeopleCompanion.insert(
          id: 'keep',
          name: 'Keep Me',
          relationship: 'daughter',
          photoPath: '/docs/people/photos/keep.jpg',
          sortOrder: 0,
        ),
      ],
      medications: const [],
      routineItems: const [],
      contentVersion: '1',
    );

    // Duplicate primary key inside the batch aborts the transaction.
    await expectLater(
      repo.replaceContent(
        people: [
          PeopleCompanion.insert(
            id: 'dupe',
            name: 'A',
            relationship: 'son',
            photoPath: '/a.jpg',
            sortOrder: 0,
          ),
          PeopleCompanion.insert(
            id: 'dupe',
            name: 'B',
            relationship: 'son',
            photoPath: '/b.jpg',
            sortOrder: 1,
          ),
        ],
        medications: const [],
        routineItems: const [],
        contentVersion: '2',
      ),
      throwsA(anything),
    );

    expect((await repo.getPeople()).map((p) => p.id), ['keep']);
    expect(await repo.getContentVersion(), '1');
  });
}
