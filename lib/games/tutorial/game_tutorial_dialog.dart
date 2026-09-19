import 'package:flutter/material.dart';

import 'game_demo_stage.dart';

/// Localized "How to Play" header string across all 11 North-East regional languages.
String gameTutorialHowToPlayLabel(String code) {
  switch (code) {
    case 'as': return 'কেনে খেলিব শিকক';
    case 'bn': return 'কিভাবে খেলবেন দেখুন';
    case 'hi': return 'खेलने का तरीका देखें';
    case 'ne': return 'कसरी खेल्ने हेर्नुहोस्';
    case 'mni': return 'কেনে শানবগে য়েংবিউ';
    case 'kha': return 'Kumno ban ialehkai';
    case 'lus': return 'Khelh dan zir rawh';
    case 'grt': return 'Kalaniko mesokbo';
    case 'brx': return 'माबोरै गेलेनो नाय';
    case 'trp': return 'Bwkhwkhe kwlano nidi';
    case 'nag': return 'Kineke khelibo sabo';
    case 'en':
    default: return 'How to Play';
  }
}

/// Localized "Let's Play!" action button label.
String gameTutorialLetsPlayLabel(String code) {
  switch (code) {
    case 'as': return 'খেলা আৰম্ভ কৰক';
    case 'bn': return 'খেলা শুরু করুন';
    case 'hi': return 'खेल शुरू करें';
    case 'ne': return 'खेल सुरु गर्नुहोस्';
    case 'mni': return 'শানবা হৌসি';
    case 'kha': return 'Ialehkai noh';
    case 'lus': return 'Khel ṭan rawh';
    case 'grt': return 'Kalna a·bachengbo';
    case 'brx': return 'गेलेनो जागाय';
    case 'trp': return 'Kwlano cheng di';
    case 'nag': return 'Khel suru koribo';
    case 'en':
    default: return 'Let\'s Play!';
  }
}

/// Localized simple gameplay instruction for the tutorial stage.
String gameTutorialDescription(String id, String code, String fallback) {
  switch (id) {
    case 'faces_of_family':
      switch (code) {
        case 'as': return 'পৰিয়ালৰ সদস্যৰ লগত মিলা ফটোখনত টিপক';
        case 'bn': return 'পরিবারের সদস্যের সাথে মেলা ছবিতে স্পর্শ করুন';
        case 'hi': return 'परिवार के सदस्य से मेल खाती तस्वीर पर टैप करें';
        default: return 'Tap the photo that matches the family member';
      }
    case 'market_basket':
      switch (code) {
        case 'as': return 'বস্তুবোৰ মনত ৰাখক আৰু সঠিক বস্তু বাছি লওক';
        case 'bn': return 'জিনিসগুলো মনে রাখুন এবং সঠিক জিনিস বেছে নিন';
        case 'hi': return 'सामान याद रखें और दुकान से वही चुनें';
        default: return 'Remember the items and pick them from the shelf';
      }
    case 'sort_harvest':
      switch (code) {
        case 'as': return 'বস্তু চাই তলৰ সঠিক ডলাত টিপক';
        case 'bn': return 'জিনিস দেখে নিচের সঠিক ঝুড়িতে স্পর্শ করুন';
        case 'hi': return 'वस्तु देखकर नीचे सही टोकरी या मैट पर टैप करें';
        default: return 'Tap the basket or mat that matches the item';
      }
    case 'trace_path':
      switch (code) {
        case 'as': return 'ক্ৰম অনুসৰি শিলবোৰত এটাকৈ টিপক';
        case 'bn': return 'ক্রম অনুযায়ী পাথরগুলোতে একটি করে স্পর্শ করুন';
        case 'hi': return 'संख्या के क्रम में एक-एक पत्थर पर टैप करें';
          default: return 'Tap the stones in order of their numbers';
        }
      case 'my_day':
        switch (code) {
          case 'as': return 'দিনটোৰ কামবোৰ সময় অনুসৰি সজাওক';
          case 'bn': return 'দিনের কাজগুলো সময় অনুসারে সাজান';
          case 'hi': return 'दिन के कामों को सही क्रम में लगाएँ';
          default: return 'Arrange your daily routine in order of time';
        }
      case 'lamps_festival':
        switch (code) {
          case 'as': return 'চাকি জ্বলা মন কৰক আৰু সেই ক্ৰমতে টিপক';
          case 'bn': return 'প্রদীপ জ্বলা লক্ষ্য করুন এবং সেই ক্রমে স্পর্শ করুন';
          case 'hi': return 'दीये जलते देखें और उसी क्रम में टैप करें';
          default: return 'Watch the lamps light up, then tap them in order';
        }
      case 'name_harvest':
        switch (code) {
          case 'as': return 'এই ভাগৰ যিমান পাৰে সিমান শব্দ লিখক';
          case 'bn': return 'এই বিভাগের যতগুলো পারেন শব্দ লিখুন';
          case 'hi': return 'इस श्रेणी के जितने शब्द याद आएँ लिखें';
          default: return 'Name as many items as you can in this category';
        }
      case 'weaving_patterns':
        switch (code) {
          case 'as': return 'ওপৰৰ আৰ্হি চাই তলৰ মিলাটো বাছক';
          case 'bn': return 'উপরের নকশা দেখে নিচের মেলাটি বেছে নিন';
          case 'hi': return 'ऊपर का डिज़ाइन देखकर नीचे सही डिज़ाइन चुनें';
          default: return 'Find the pattern that matches the one above';
        }
      case 'sounds_home':
        switch (code) {
          case 'as': return 'চৰাইৰ মাত শুনিলে ঢোলত চাপৰ দিয়ক';
          case 'bn': return 'পাখির ডাক শুনলে ঢোলে টোকা দিন';
          case 'hi': return 'चिड़िया की आवाज़ सुनते ही ढोल पर टैप करें';
          default: return 'Tap the drum whenever you hear the bird';
        }
      default:
        return fallback;
    }
  }


/// The animated ghost-hand demonstration for one game: the real game plays
/// itself on easy items, with a hand tapping the right answers. Tapping it
/// starts the game.
class InteractiveGameDemoStage extends StatelessWidget {
  const InteractiveGameDemoStage({
    super.key,
    required this.gameId,
    required this.isCompact,
    this.onTapAnywhere,
  });

  final String gameId;
  final bool isCompact;
  final VoidCallback? onTapAnywhere;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: onTapAnywhere,
      child: GameDemoStage(gameId: gameId),
    );
  }
}
