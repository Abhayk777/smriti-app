import 'package:flutter_test/flutter_test.dart';
import 'package:smriti/core/i18n/app_strings.dart';

void main() {
  group('AppStrings & kSupportedLanguages', () {
    test('contains exactly 12 supported NER and link languages', () {
      expect(kSupportedLanguages.length, equals(12));
      final codes = kSupportedLanguages.map((l) => l.code).toSet();
      expect(codes.length, equals(12));
      expect(
        codes,
        containsAll([
          'as',
          'bn',
          'brx',
          'grt',
          'kha',
          'lus',
          'mni',
          'nag',
          'ne',
          'trp',
          'hi',
          'en',
        ]),
      );
    });

    test('metaFor returns metadata for known and fallback languages', () {
      final asMeta = AppStrings.metaFor('as');
      expect(asMeta.nativeName, equals('অসমীয়া'));
      expect(asMeta.englishName, equals('Assamese'));

      final grtMeta = AppStrings.metaFor('grt');
      expect(grtMeta.nativeName, equals('A·chik'));
      expect(grtMeta.region, contains('Meghalaya'));

      final trpMeta = AppStrings.metaFor('trp');
      expect(trpMeta.nativeName, equals('ককবরক'));
      expect(trpMeta.region, contains('Tripura'));

      final neMeta = AppStrings.metaFor('ne');
      expect(neMeta.nativeName, equals('नेपाली'));
      expect(neMeta.region, contains('Sikkim'));

      final nagMeta = AppStrings.metaFor('nag');
      expect(nagMeta.nativeName, equals('Nagamese'));
      expect(nagMeta.region, contains('Nagaland'));

      // Unknown fallback to English
      final fallback = AppStrings.metaFor('unknown_code');
      expect(fallback.code, equals('en'));
    });

    test('all 12 languages have non-empty greetings and date strings', () {
      for (final meta in kSupportedLanguages) {
        final code = meta.code;

        expect(AppStrings.greeting(code, 9).isNotEmpty, isTrue);
        expect(AppStrings.greeting(code, 14).isNotEmpty, isTrue);
        expect(AppStrings.greeting(code, 19).isNotEmpty, isTrue);

        for (var day = 1; day <= 7; day++) {
          final dayName = AppStrings.dayOfWeek(code, day);
          expect(dayName.isNotEmpty, isTrue, reason: 'day $day in $code');
        }

        for (var month = 1; month <= 12; month++) {
          final monthName = AppStrings.monthName(code, month);
          expect(monthName.isNotEmpty, isTrue, reason: 'month $month in $code');
        }

        final formatted = AppStrings.formattedDate(code, DateTime(2026, 9, 18));
        expect(formatted.isNotEmpty, isTrue);
      }
    });

    test('all 12 languages have complete home and action strings', () {
      for (final meta in kSupportedLanguages) {
        final code = meta.code;

        expect(AppStrings.whatWouldYouLikeToDo(code).isNotEmpty, isTrue);
        expect(AppStrings.play(code).isNotEmpty, isTrue);
        expect(AppStrings.gamesForMind(code).isNotEmpty, isTrue);
        expect(AppStrings.myFamily(code).isNotEmpty, isTrue);
        expect(AppStrings.yourLovedOnes(code).isNotEmpty, isTrue);
        expect(AppStrings.myDay(code).isNotEmpty, isTrue);
        expect(AppStrings.yourDayAtGlance(code).isNotEmpty, isTrue);
        expect(AppStrings.medications(code).isNotEmpty, isTrue);
        expect(AppStrings.leaveVoiceMessage(code).isNotEmpty, isTrue);
        expect(AppStrings.message(code).isNotEmpty, isTrue);

        expect(AppStrings.timeToRestYourEyes(code).isNotEmpty, isTrue);
        expect(AppStrings.playedTodayMessage(code, 15).contains('15'), isTrue);
        expect(AppStrings.restNow(code).isNotEmpty, isTrue);
        expect(AppStrings.keepPlaying(code).isNotEmpty, isTrue);
        expect(AppStrings.timeForGoodRest(code).isNotEmpty, isTrue);
        expect(AppStrings.breakLockBody(code).isNotEmpty, isTrue);
        expect(AppStrings.takeARest(code).isNotEmpty, isTrue);
        expect(AppStrings.gamesAreResting(code).isNotEmpty, isTrue);
        expect(AppStrings.gamesRestingPrompt(code).isNotEmpty, isTrue);

        expect(AppStrings.games(code).isNotEmpty, isTrue);
        expect(AppStrings.playHistory(code).isNotEmpty, isTrue);
        expect(AppStrings.trySomethingNew(code).isNotEmpty, isTrue);
        expect(AppStrings.tryToday(code).isNotEmpty, isTrue);
        expect(AppStrings.maybeLater(code).isNotEmpty, isTrue);
        expect(AppStrings.backToGames(code).isNotEmpty, isTrue);
        expect(AppStrings.sessionComplete(code).isNotEmpty, isTrue);
        expect(AppStrings.chooseLanguage(code).isNotEmpty, isTrue);
      }
    });

    test('all 9 games have localized titles and descriptions for all 12 languages', () {
      const gameIds = [
        'market_basket',
        'faces_of_family',
        'sort_harvest',
        'trace_path',
        'my_day',
        'lamps_festival',
        'name_harvest',
        'weaving_patterns',
        'sounds_home',
      ];

      for (final gameId in gameIds) {
        for (final meta in kSupportedLanguages) {
          final code = meta.code;
          final title = AppStrings.gameTitle(code, gameId);
          final desc = AppStrings.gameDescription(code, gameId);

          expect(title.isNotEmpty, isTrue, reason: '$gameId title in $code');
          expect(desc.isNotEmpty, isTrue, reason: '$gameId desc in $code');
        }
      }
    });

    test('timeForMedication preserves English medicine name across all 12 languages', () {
      const testMed = 'Paracetamol 500mg';
      for (final meta in kSupportedLanguages) {
        final code = meta.code;
        final res = AppStrings.timeForMedication(code, testMed);
        expect(res.contains(testMed), isTrue, reason: 'Med name preserved in $code');
        expect(res.isNotEmpty, isTrue);
      }
      // Specific checks for key NER scripts
      expect(AppStrings.timeForMedication('as', 'Amlodipine'), contains('Amlodipine খোৱাৰ সময়'));
      expect(AppStrings.timeForMedication('bn', 'Amlodipine'), contains('Amlodipine খাওয়ার সময়'));
      expect(AppStrings.timeForMedication('hi', 'Amlodipine'), contains('Amlodipine लेने का समय'));
      expect(AppStrings.timeForMedication('en', 'Amlodipine'), equals('Time for Amlodipine'));
    });

    test('full-screen reminder alerts have complete translations for all 12 languages', () {
      for (final meta in kSupportedLanguages) {
        final code = meta.code;
        expect(AppStrings.timeForYourMedicine(code).isNotEmpty, isTrue);
        expect(AppStrings.doseLabel(code, '1 tablet').contains('1 tablet'), isTrue);
        expect(AppStrings.iHaveTakenIt(code).isNotEmpty, isTrue);
        expect(AppStrings.remindIn10Mins(code).isNotEmpty, isTrue);
        expect(AppStrings.hearVoiceAgain(code).isNotEmpty, isTrue);
        expect(AppStrings.listening(code).isNotEmpty, isTrue);
        expect(AppStrings.medicineRecordedWellDone(code).isNotEmpty, isTrue);
        expect(AppStrings.willRemindIn10Minutes(code).isNotEmpty, isTrue);
      }
    });

    test('medicine screen strings have complete translations and preserve med name', () {
      const medName = 'Donepezil';
      for (final meta in kSupportedLanguages) {
        final code = meta.code;
        expect(AppStrings.myMedicines(code).isNotEmpty, isTrue);
        expect(AppStrings.tapTakeOnceHad(code).isNotEmpty, isTrue);
        expect(AppStrings.noMedicinesScheduled(code).isNotEmpty, isTrue);
        expect(AppStrings.take(code).isNotEmpty, isTrue);
        expect(AppStrings.taken(code).isNotEmpty, isTrue);
        expect(AppStrings.hearInstruction(code).isNotEmpty, isTrue);

        final alreadyTaken = AppStrings.alreadyMarkedTaken(code, medName);
        expect(alreadyTaken.contains(medName), isTrue, reason: 'Med name preserved in $code');
      }
    });

    test('routine items map caregiver activities into selected NER language', () {
      for (final meta in kSupportedLanguages) {
        final code = meta.code;

        expect(AppStrings.routineEmptyTitle(code).isNotEmpty, isTrue);
        expect(AppStrings.routineEmptyMessage(code).isNotEmpty, isTrue);
        expect(AppStrings.comingUpNext(code).isNotEmpty, isTrue);
        expect(AppStrings.thatsAllForToday(code).isNotEmpty, isTrue);
        expect(AppStrings.doneCountSoFar(code, 2, 5).isNotEmpty, isTrue);
        expect(AppStrings.nowBadge(code).isNotEmpty, isTrue);

        for (final part in ['morning', 'afternoon', 'evening', 'night']) {
          expect(AppStrings.dayPartLabel(code, part).isNotEmpty, isTrue);
        }

        // Test common activities entered in English
        final walk = AppStrings.routineLabel(code, 'Morning Walk in Garden');
        final breakfast = AppStrings.routineLabel(code, 'Breakfast with family');
        final chai = AppStrings.routineLabel(code, 'Afternoon Chai / Tea');
        final puja = AppStrings.routineLabel(code, 'Evening Puja');
        final dinner = AppStrings.routineLabel(code, 'Dinner');
        final sleep = AppStrings.routineLabel(code, 'Sleep / Bedtime');

        expect(walk.isNotEmpty, isTrue);
        expect(breakfast.isNotEmpty, isTrue);
        expect(chai.isNotEmpty, isTrue);
        expect(puja.isNotEmpty, isTrue);
        expect(dinner.isNotEmpty, isTrue);
        expect(sleep.isNotEmpty, isTrue);

        if (code == 'as') {
          expect(walk, equals('খোজকাঢ়া'));
          expect(breakfast, equals('ৰাতিপুৱাৰ জলপান'));
          expect(chai, equals('চাহ খোৱাৰ সময়'));
          expect(puja, equals('প্ৰাৰ্থনা / পূজা'));
        } else if (code == 'bn') {
          expect(walk, equals('সকালের হাঁটা'));
          expect(breakfast, equals('সকালের প্রাতঃরাশ'));
          expect(chai, equals('চা পানের সময়'));
          expect(puja, equals('প্রার্থনা / পুজো'));
        }
      }

      // Unmatched custom caregiver activity passes through as-is
      expect(
        AppStrings.routineLabel('as', 'Dr. Sen consultation appointment'),
        equals('Dr. Sen consultation appointment'),
      );
    });

    test('voice memo strings are non-empty across all 12 languages', () {
      for (final meta in kSupportedLanguages) {
        final code = meta.code;
        expect(AppStrings.sendVoiceMessageToFamily(code).isNotEmpty, isTrue);
        expect(AppStrings.tapToRecord(code).isNotEmpty, isTrue);
        expect(AppStrings.recording(code).isNotEmpty, isTrue);
        expect(AppStrings.tapToStop(code).isNotEmpty, isTrue);
        expect(AppStrings.sendAVoiceMessage(code).isNotEmpty, isTrue);
        expect(AppStrings.yourVoiceMessages(code).isNotEmpty, isTrue);
        expect(AppStrings.noMessagesYet(code).isNotEmpty, isTrue);
        expect(AppStrings.todayAtTime(code, '5:30 PM').isNotEmpty, isTrue);
      }
    });

    test('family screen strings are non-empty across all 12 languages', () {
      for (final meta in kSupportedLanguages) {
        final code = meta.code;
        expect(AppStrings.thePeopleWhoLoveYou(code).isNotEmpty, isTrue);
        expect(AppStrings.familyWillAppearHere(code).isNotEmpty, isTrue);
        expect(AppStrings.photosShowUpPrompt(code).isNotEmpty, isTrue);
      }
    });

    test('all 8 cognitive games have translated titles and prompts across all 12 languages', () {
      const gameIds = [
        'market_basket',
        'faces_of_family',
        'lamps_festival',
        'sort_harvest',
        'name_harvest',
        'sounds_home',
        'trace_path',
        'weaving_patterns',
        'my_day',
      ];

      for (final meta in kSupportedLanguages) {
        final code = meta.code;

        for (final g in gameIds) {
          final title = AppStrings.gameTitle(code, g);
          expect(title.isNotEmpty, isTrue, reason: '$g title missing in $code');
        }

        // Market Basket
        expect(AppStrings.rememberTheseItems(code).isNotEmpty, isTrue);
        expect(AppStrings.getReady(code).isNotEmpty, isTrue);
        expect(AppStrings.pickItemsFromList(code).isNotEmpty, isTrue);
        expect(AppStrings.marketItemName(code, 'banana').isNotEmpty, isTrue);
        expect(AppStrings.marketItemName(code, 'tea').isNotEmpty, isTrue);

        // Faces of Family
        expect(AppStrings.whoIsThisPerson(code).isNotEmpty, isTrue);
        expect(AppStrings.canYouNameThisPerson(code).isNotEmpty, isTrue);
        expect(AppStrings.howIsPersonRelated(code).isNotEmpty, isTrue);
        expect(AppStrings.whenDidYouLastSeePerson(code).isNotEmpty, isTrue);
        expect(AppStrings.familyPhotosOnTheirWay(code).isNotEmpty, isTrue);
        expect(AppStrings.familyGameNeedMembers(code).isNotEmpty, isTrue);
        expect(AppStrings.backToGames(code).isNotEmpty, isTrue);

        // Lamps
        expect(AppStrings.watchLampsLightUp(code).isNotEmpty, isTrue);
        expect(AppStrings.tapLampsSameOrder(code).isNotEmpty, isTrue);
        expect(AppStrings.tapLampsReverseOrder(code).isNotEmpty, isTrue);
        expect(AppStrings.wellDone(code).isNotEmpty, isTrue);

        // Sort Harvest
        expect(AppStrings.placeItemWhereBelongs(code).isNotEmpty, isTrue);
        expect(AppStrings.harvestMatLabel(code, 'vegetable').isNotEmpty, isTrue);
        expect(AppStrings.harvestMatLabel(code, 'red').isNotEmpty, isTrue);

        // Name Harvest
        expect(AppStrings.nameAllCategoryPrompt(code, 'fruits').isNotEmpty, isTrue);
        expect(AppStrings.harvestCategory(code, 'vegetables').isNotEmpty, isTrue);
        expect(AppStrings.typeAnItem(code).isNotEmpty, isTrue);
        expect(AppStrings.itemsNamed(code, 4).isNotEmpty, isTrue);

        // Sounds of Home
        expect(AppStrings.listenForBird(code).isNotEmpty, isTrue);
        expect(AppStrings.soundsHomeIntro(code).isNotEmpty, isTrue);
        expect(AppStrings.hearTheBird(code).isNotEmpty, isTrue);
        expect(AppStrings.start(code).isNotEmpty, isTrue);
        expect(AppStrings.tapDrumWhenHearBird(code).isNotEmpty, isTrue);
        expect(AppStrings.drumTap(code).isNotEmpty, isTrue);
        expect(AppStrings.soundLabel(code, 'bird').isNotEmpty, isTrue);
        expect(AppStrings.soundLabel(code, 'rain').isNotEmpty, isTrue);

        // Trace Path
        expect(AppStrings.tracePathSequential(code).isNotEmpty, isTrue);
        expect(AppStrings.tracePathAlternating(code).isNotEmpty, isTrue);

        // Weaving
        expect(AppStrings.whichPatternMatches(code).isNotEmpty, isTrue);

        // My Day
        expect(AppStrings.putInOrderMorningToNight(code).isNotEmpty, isTrue);
        expect(AppStrings.done(code).isNotEmpty, isTrue);
        expect(AppStrings.orientationQuestion(code, 'season').isNotEmpty, isTrue);
        expect(AppStrings.orientationQuestion(code, 'day_of_week').isNotEmpty, isTrue);
        expect(AppStrings.displayOrientationOption(code, 'season', 'Winter').isNotEmpty, isTrue);
        expect(AppStrings.displayOrientationOption(code, 'day_of_week', 'Monday').isNotEmpty, isTrue);
      }
    });
  });
}
