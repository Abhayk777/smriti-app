/// Core dictionary for all supported North-East India (NER) languages and link languages.
///
/// Supported languages (12 total):
/// - 'as': Assamese (অসমীয়া) - Assam
/// - 'bn': Bengali (বাংলা) - Barak Valley / Tripura
/// - 'brx': Bodo (बर') - Bodoland (Assam)
/// - 'grt': Garo (A·chik) - Meghalaya
/// - 'kha': Khasi (Ka Ktien Khasi) - Meghalaya
/// - 'lus': Mizo (Mizo ṭawng) - Mizoram
/// - 'mni': Manipuri / Meitei (মৈতৈলোন্) - Manipur
/// - 'nag': Nagamese (Nagamese) - Nagaland
/// - 'ne': Nepali (नेपाली) - Sikkim
/// - 'trp': Kokborok (ককবরক) - Tripura
/// - 'hi': Hindi (हिन्दी) - Regional Link / Arunachal
/// - 'en': English - Regional / Official
class LanguageMeta {
  const LanguageMeta({
    required this.code,
    required this.nativeName,
    required this.englishName,
    required this.region,
  });

  final String code;
  final String nativeName;
  final String englishName;
  final String region;
}

const List<LanguageMeta> kSupportedLanguages = [
  LanguageMeta(
    code: 'as',
    nativeName: 'অসমীয়া',
    englishName: 'Assamese',
    region: 'Assam',
  ),
  LanguageMeta(
    code: 'bn',
    nativeName: 'বাংলা',
    englishName: 'Bengali',
    region: 'Barak Valley / Tripura',
  ),
  LanguageMeta(
    code: 'brx',
    nativeName: "बर'",
    englishName: 'Bodo',
    region: 'Bodoland (Assam)',
  ),
  LanguageMeta(
    code: 'grt',
    nativeName: 'A·chik',
    englishName: 'Garo',
    region: 'Meghalaya',
  ),
  LanguageMeta(
    code: 'kha',
    nativeName: 'Khasi',
    englishName: 'Khasi',
    region: 'Meghalaya',
  ),
  LanguageMeta(
    code: 'lus',
    nativeName: 'Mizo',
    englishName: 'Mizo',
    region: 'Mizoram',
  ),
  LanguageMeta(
    code: 'mni',
    nativeName: 'মৈতৈলোন্',
    englishName: 'Manipuri',
    region: 'Manipur',
  ),
  LanguageMeta(
    code: 'nag',
    nativeName: 'Nagamese',
    englishName: 'Nagamese',
    region: 'Nagaland',
  ),
  LanguageMeta(
    code: 'ne',
    nativeName: 'नेपाली',
    englishName: 'Nepali',
    region: 'Sikkim',
  ),
  LanguageMeta(
    code: 'trp',
    nativeName: 'ককবরক',
    englishName: 'Kokborok',
    region: 'Tripura',
  ),
  LanguageMeta(
    code: 'hi',
    nativeName: 'हिन्दी',
    englishName: 'Hindi',
    region: 'Regional Link / Arunachal',
  ),
  LanguageMeta(
    code: 'en',
    nativeName: 'English',
    englishName: 'English',
    region: 'Official / Regional Link',
  ),
];

class AppStrings {
  const AppStrings._();

  static LanguageMeta metaFor(String code) {
    return kSupportedLanguages.firstWhere(
      (m) => m.code == code,
      orElse: () => kSupportedLanguages.firstWhere((m) => m.code == 'en'),
    );
  }

  // ── Greetings ─────────────────────────────────────────────────────────────

  static String greeting(String code, int hour) {
    if (hour < 12) return goodMorning(code);
    if (hour < 17) return goodAfternoon(code);
    return goodEvening(code);
  }

  static String goodMorning(String code) {
    switch (code) {
      case 'as': return 'শুভ ৰাতিপুৱা';
      case 'bn': return 'শুভ সকাল';
      case 'brx': return 'मोजां फुं';
      case 'grt': return 'Pringgipat namgipa';
      case 'kha': return 'Khublei step';
      case 'lus': return 'Chibai zing';
      case 'mni': return 'য়াইফবা অয়ুক';
      case 'nag': return 'Bhal phujor';
      case 'ne': return 'शुभ प्रभात';
      case 'trp': return 'Kaham salphung';
      case 'hi': return 'शुभ प्रभात';
      case 'en':
      default: return 'Good morning';
    }
  }

  static String goodAfternoon(String code) {
    switch (code) {
      case 'as': return 'শুভ দুপৰীয়া';
      case 'bn': return 'শুভ দুপুর';
      case 'brx': return 'मोजां सान';
      case 'grt': return 'Salbaro namgipa';
      case 'kha': return 'Khublei sngi';
      case 'lus': return 'Chibai chhun';
      case 'mni': return 'য়াইফবা নুমিৎথাক';
      case 'nag': return 'Bhal dupor';
      case 'ne': return 'शुभ दिउँसो';
      case 'trp': return 'Kaham salsali';
      case 'hi': return 'शुभ दोपहर';
      case 'en':
      default: return 'Good afternoon';
    }
  }

  static String goodEvening(String code) {
    switch (code) {
      case 'as': return 'শুভ গধূলি';
      case 'bn': return 'শুভ সন্ধ্যা';
      case 'brx': return 'मोजां बेलासे';
      case 'grt': return 'Attamo namgipa';
      case 'kha': return 'Khublei janmiet';
      case 'lus': return 'Chibai tlai';
      case 'mni': return 'য়াইফবা নুমিদাং';
      case 'nag': return 'Bhal bheli';
      case 'ne': return 'शुभ साँझ';
      case 'trp': return 'Kaham sanmari';
      case 'hi': return 'शुभ संध्या';
      case 'en':
      default: return 'Good evening';
    }
  }

  // ── Date formatting ────────────────────────────────────────────────────────

  static String dayOfWeek(String code, int weekday) {
    final days = _days[code] ?? _days['en']!;
    if (weekday >= 1 && weekday <= 7) return days[weekday];
    return '';
  }

  static String monthName(String code, int month) {
    final months = _months[code] ?? _months['en']!;
    if (month >= 1 && month <= 12) return months[month];
    return '';
  }

  static String formattedDate(String code, DateTime date) {
    final day = dayOfWeek(code, date.weekday);
    final month = monthName(code, date.month);
    return '$day, ${date.day} $month';
  }

  static const Map<String, List<String>> _days = {
    'as': ['', 'সোমবাৰ', 'মঙলবাৰ', 'বুধবাৰ', 'বৃহস্পতিবাৰ', 'শুক্ৰবাৰ', 'শনিবাৰ', 'দেওবাৰ'],
    'bn': ['', 'সোমবার', 'মঙ্গলবার', 'বুধবার', 'বৃহস্পতিবার', 'শুক্রবার', 'শনিবার', 'রবিবার'],
    'brx': ['', 'सोमबार', 'मंगलबार', 'बुधबार', 'बृहस्पतिबार', 'शुक्रबार', 'शनिबार', 'रबिबार'],
    'grt': ['', 'Sombar', 'Mongolbar', 'Budbar', 'Bristibar', 'Sukrobar', 'Sonibar', 'Robibar'],
    'kha': ['', 'Ba-ar', 'Ba-lai', 'Ba-saw', 'Ba-san', 'Thohdieng', 'Sngi-U-Blei', 'Sngi-Phet'],
    'lus': ['', 'Thawhṭanni', 'Thawhlehni', 'Nilaini', 'Ningani', 'Zirtawpni', 'Inrinni', 'Pathianni'],
    'mni': ['', 'নিংথৌকাবা', 'লৈপাকপোকপা', 'য়ুমশৈকেইশা', 'শগোলশেন', 'ইরাই', 'থাংজা', 'নোংমাইজিং'],
    'nag': ['', 'Sombar', 'Mongolbar', 'Budhbar', 'Brihospotibar', 'Sukrobar', 'Sonibar', 'Deobar'],
    'ne': ['', 'सोमबार', 'मङ्गलबार', 'बुधबार', 'बिहीबार', 'शुक्रबार', 'शनिबार', 'आइतबार'],
    'trp': ['', 'Sombar', 'Monggolbar', 'Budbar', 'Brihaspatibar', 'Sukrobar', 'Sonibar', 'Robibar'],
    'hi': ['', 'सोमवार', 'मंगलवार', 'बुधवार', 'गुरुवार', 'शुक्रवार', 'शनिवार', 'रविवार'],
    'en': ['', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'],
  };

  static const Map<String, List<String>> _months = {
    'as': ['', 'জানুৱাৰী', 'ফেব্ৰুৱাৰী', 'মাৰ্চ', 'এপ্ৰিল', 'মে’', 'জুন', 'জুলাই', 'আগষ্ট', 'ছেপ্টেম্বৰ', 'অক্টোবৰ', 'নৱেম্বৰ', 'ডিচেম্বৰ'],
    'bn': ['', 'জানুয়ারি', 'ফেব্রুয়ারি', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগস্ট', 'সেপ্টেম্বর', 'অক্টোবর', 'নভেম্বর', 'ডিসেম্বর'],
    'brx': ['', 'जानुवारी', 'फेब्रुवारी', 'मार्स', 'एप्रिल', 'मे', 'जुन', 'जुलाइ', 'आगस्ट', 'सेप्तेम्बर', 'अक्तबर', 'नभेम्बर', 'दिसेम्बर'],
    'grt': ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'kha': ['', 'Kyllalyngkot', 'Rymphang', 'Lber', 'Iaiong', 'Jymmang', 'Jylliew', 'Naitung', 'Nailar', 'Nailur', 'Risaw', 'Naiwieng', 'Nohprah'],
    'lus': ['', 'Pawlkut', 'Ramtuk', 'Vau', 'Ṭawng', 'Zing', 'Nikir', 'Vang', 'Khuang', 'Mimkut', 'Kha', 'Thal', 'Pawltlak'],
    'mni': ['', 'জানুৱারী', 'ফেব্রুৱারী', 'মার্চ', 'এপ্রিল', 'মে', 'জুন', 'জুলাই', 'আগষ্ট', 'সেপ্টেম্বর', 'ওক্টোবর', 'নবেম্বর', 'ডিসেম্বর'],
    'nag': ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'ne': ['', 'जनवरी', 'फेब्रुअरी', 'मार्च', 'अप्रिल', 'मे', 'जुन', 'जुलाई', 'अगस्ट', 'सेप्टेम्बर', 'अक्टोबर', 'नोभेम्बर', 'डिसेम्बर'],
    'trp': ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
    'hi': ['', 'जनवरी', 'फ़रवरी', 'मार्च', 'अप्रैल', 'मई', 'जून', 'जुलाई', 'अगस्त', 'सितंबर', 'अक्टूबर', 'नवंबर', 'दिसंबर'],
    'en': ['', 'January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'],
  };

  // ── Home Screen Titles & Tiles ─────────────────────────────────────────────

  static String whatWouldYouLikeToDo(String code) {
    switch (code) {
      case 'as': return 'আপুনি কি কৰিব বিচাৰে?';
      case 'bn': return 'আপনি কি করতে চান?';
      case 'brx': return 'नोंथाङा मा खालामनो लुबैयो?';
      case 'grt': return 'Na·a maiko dakna skagen?';
      case 'kha': return 'Kiei kiba phi kwah ban leh?';
      case 'lus': return 'Eng nge tih i duh le?';
      case 'mni': return 'অদোমনা করি তৌবা পাম্বগে?';
      case 'nag': return 'Apuni ki koribole mon ase?';
      case 'ne': return 'तपाईं के गर्न चाहनुहुन्छ?';
      case 'trp': return 'Nwng tmo khlaino mwchwng?';
      case 'hi': return 'आप क्या करना चाहेंगे?';
      case 'en':
      default: return 'What would you like to do?';
    }
  }

  static String play(String code) {
    switch (code) {
      case 'as': return 'খেলক';
      case 'bn': return 'খেলুন';
      case 'brx': return 'गेले';
      case 'grt': return 'Kal·bo';
      case 'kha': return 'Lehkai';
      case 'lus': return 'Infiam';
      case 'mni': return 'শানবা';
      case 'nag': return 'Khelibi';
      case 'ne': return 'खेल्नुहोस्';
      case 'trp': return 'Gele di';
      case 'hi': return 'खेलें';
      case 'en':
      default: return 'Play';
    }
  }

  static String gamesForMind(String code) {
    switch (code) {
      case 'as': return 'মনৰ বাবে খেল';
      case 'bn': return 'মনের জন্য খেলা';
      case 'brx': return 'गोसोनि थाखाय गेलेनाय';
      case 'grt': return 'Chanchianina kal·ani';
      case 'kha': return 'Ki jingialehkai ba pynshait jingmut';
      case 'lus': return 'Rilru tana infiamna';
      case 'mni': return 'ৱাখলগী শান্নপোৎ';
      case 'nag': return 'Mon laga khel';
      case 'ne': return 'मनका लागि खेल';
      case 'trp': return 'Bwkha nani gelema';
      case 'hi': return 'मन के लिए खेल';
      case 'en':
      default: return 'Games for the mind';
    }
  }

  static String myFamily(String code) {
    switch (code) {
      case 'as': return 'মোৰ পৰিয়াল';
      case 'bn': return 'আমার পরিবার';
      case 'brx': return 'आंनि नखर';
      case 'grt': return 'Angni Nokdang';
      case 'kha': return 'Ka Iing Jong Nga';
      case 'lus': return 'Ka Chhungte';
      case 'mni': return 'ঐগী ইমুং';
      case 'nag': return 'Moi laga Poriyal';
      case 'ne': return 'मेरो परिवार';
      case 'trp': return 'Ani Nokhor';
      case 'hi': return 'मेरा परिवार';
      case 'en':
      default: return 'My Family';
    }
  }

  static String yourLovedOnes(String code) {
    switch (code) {
      case 'as': return 'আপোনাৰ আপোনজন';
      case 'bn': return 'আপনার প্রিয়জন';
      case 'brx': return 'नोंथांनि अनजालिफोर';
      case 'grt': return 'Nang·ni ka·saba manderang';
      case 'kha': return 'Ki baieit jong phi';
      case 'lus': return 'I mi duh takte';
      case 'mni': return 'অদোমগী নুংশিরবশিং';
      case 'nag': return 'Apuni laga manu khan';
      case 'ne': return 'तपाईंका प्रियजनहरू';
      case 'trp': return 'Nini hamjakmwrwk';
      case 'hi': return 'आपके अपने';
      case 'en':
      default: return 'Your loved ones';
    }
  }

  static String myDay(String code) {
    switch (code) {
      case 'as': return 'মোৰ দিনটো';
      case 'bn': return 'আমার দিন';
      case 'brx': return 'आंनि सान';
      case 'grt': return 'Angni Sal';
      case 'kha': return 'Ka Sngi Jong Nga';
      case 'lus': return 'Ka Ni';
      case 'mni': return 'ঐগী নুমিৎ';
      case 'nag': return 'Moi laga Din';
      case 'ne': return 'मेरो दिन';
      case 'trp': return 'Ani Sal';
      case 'hi': return 'मेरा दिन';
      case 'en':
      default: return 'My Day';
    }
  }

  static String yourDayAtGlance(String code) {
    switch (code) {
      case 'as': return 'আজিৰ কাৰ্যসূচী';
      case 'bn': return 'আজকের দিন এক নজরে';
      case 'brx': return 'साननि हाबाफारि';
      case 'grt': return 'Nang·ni salni kamrang';
      case 'kha': return 'Ki kam jong ka sngi';
      case 'lus': return 'I ni hman dan tlangpui';
      case 'mni': return 'নুমিৎসিগী থৌরম';
      case 'nag': return 'Aji laga kaam khan';
      case 'ne': return 'आजको दिनचर्या';
      case 'trp': return 'Nini salni samung';
      case 'hi': return 'आज की दिनचर्या';
      case 'en':
      default: return 'Your day at a glance';
    }
  }

  static String medications(String code) {
    switch (code) {
      case 'as': return 'ঔষধ';
      case 'bn': return 'ওষুধ';
      case 'brx': return 'मुलि';
      case 'grt': return 'Samrang';
      case 'kha': return 'Dawikhem';
      case 'lus': return 'Damdawi';
      case 'mni': return 'হিদাক';
      case 'nag': return 'Dawai khan';
      case 'ne': return 'औषधिहरू';
      case 'trp': return 'Bwswi';
      case 'hi': return 'दवाइयाँ';
      case 'en':
      default: return 'Medications';
    }
  }

  static String leaveVoiceMessage(String code) {
    switch (code) {
      case 'as': return 'কণ্ঠ বাৰ্তা পঠিয়াওক';
      case 'bn': return 'ভয়েস বার্তা পাঠান';
      case 'brx': return 'राव खौरां हर';
      case 'grt': return 'Khu·rangni gimin kobor watbo';
      case 'kha': return 'Phah khubor da ka sur';
      case 'lus': return 'Aw thuchah dah rawh';
      case 'mni': return 'খোন্থোক পাউজেল থাবা';
      case 'nag': return 'Awaz message pathabi';
      case 'ne': return 'आवाज सन्देश छोड्नुहोस्';
      case 'trp': return 'Kok thumwi hor di';
      case 'hi': return 'आवाज़ संदेश छोड़ें';
      case 'en':
      default: return 'Leave a Voice Message';
    }
  }

  static String message(String code) {
    switch (code) {
      case 'as': return 'বাৰ্তা';
      case 'bn': return 'বার্তা';
      case 'brx': return 'खौरां';
      case 'grt': return 'Kobor';
      case 'kha': return 'Khubor';
      case 'lus': return 'Thuchah';
      case 'mni': return 'পাউজেল';
      case 'nag': return 'Message';
      case 'ne': return 'सन्देश';
      case 'trp': return 'Kok';
      case 'hi': return 'संदेश';
      case 'en':
      default: return 'Message';
    }
  }

  // ── Rest Prompts & Dialogs ─────────────────────────────────────────────────

  static String timeToRestYourEyes(String code) {
    switch (code) {
      case 'as': return 'চকুক জিৰণি দিয়াৰ সময়?';
      case 'bn': return 'চোখকে বিশ্রাম দেওয়ার সময়?';
      case 'brx': return 'मेगनखौ बिथा होनायनि सम?';
      case 'grt': return 'Mikronko neng·taktokna salon ma?';
      case 'kha': return 'La dei ka por ban shongthait?';
      case 'lus': return 'Chawlh hahdam a hun em?';
      case 'mni': return 'মিৎপু পোন্থাবা মতম?';
      case 'nag': return 'Chokhuke aaram dibole homoy hoise?';
      case 'ne': return 'आँखालाई आराम दिने समय?';
      case 'trp': return 'Mwkholo nukhung rwno jora?';
      case 'hi': return 'आँखों को आराम देने का समय?';
      case 'en':
      default: return 'Time for a little rest';
    }
  }

  static String playedTodayMessage(String code, int minutes) {
    switch (code) {
      case 'as':
        return 'আপুনি আজি $minutes মিনিট খেলিলে। এতিয়া অলপ জিৰণি ল\'লে মন সতেজ থাকিব।';
      case 'bn':
        return 'আপনি আজ $minutes মিনিট খেলেছেন। একটু বিশ্রাম নিলে মন সতেজ থাকবে।';
      case 'brx':
        return 'नोंथाङा दिनै $minutes मिनिट गेलेबाय। एसेल\' बिथा लायोब्ला गोसोआ गोजोन जागोन।';
      case 'grt':
        return 'Na·a da·alo minute $minutes kal·manaha. Dikdiksa neng·takanio gisik bimchipkugen.';
      case 'kha':
        return 'Mynta ka sngi phi la lehkai $minutes minit. Ban shongthait khyndiat kan pynim biang ia ka jingmut.';
      case 'lus':
        return 'Vawiinah minute $minutes chhung i infiam tawh e. Chawlh rih khan rilru a tihahdam ang.';
      case 'mni':
        return 'অদোমনা ঙসি মিনিট $minutes শানখ্রে। পোন্থাবনা ৱাখলবু নৌনা থম্বীগনি।';
      case 'nag':
        return 'Apuni aji $minutes minute khelise. Olop aaram loile mon to bhal thakibo.';
      case 'ne':
        return 'तपाईंले आज $minutes मिनेट खेल्नुभयो। केही समय आराम गर्दा मन ताजा रहनेछ।';
      case 'trp':
        return 'Nwng tini $minutes minute gelerwkha. Khakchangwi nukhung rwo khe bwkha kotor tongnai.';
      case 'hi':
        return 'आपने आज $minutes मिनट खेला है। थोड़ा विश्राम लेने से मन ताज़ा रहेगा।';
      case 'en':
      default:
        return 'You have played for $minutes minutes today. Well done! How about a cup of tea or a short walk?';
    }
  }

  static String restNow(String code) {
    switch (code) {
      case 'as': return 'এতিয়া জিৰণি লওক';
      case 'bn': return 'এখন বিশ্রাম নিন';
      case 'brx': return 'दानो बिथा ला';
      case 'grt': return 'Da·o neng·takbo';
      case 'kha': return 'Shongthait noh';
      case 'lus': return 'Chawl tawh rawh';
      case 'mni': return 'হৌজিক পোন্থাবা';
      case 'nag': return 'Etiya aaram lobi';
      case 'ne': return 'अहिले आराम गर्नुहोस्';
      case 'trp': return 'Tabuk nukhung rw di';
      case 'hi': return 'अभी आराम करें';
      case 'en':
      default: return 'Rest now';
    }
  }

  static String keepPlaying(String code) {
    switch (code) {
      case 'as': return 'খেলি থাকক';
      case 'bn': return 'খেলতে থাকুন';
      case 'brx': return 'गेलेबाय था';
      case 'grt': return 'Kal·angkubo';
      case 'kha': return 'Ia lehkai beit';
      case 'lus': return 'Infiam zel rawh';
      case 'mni': return 'মখা তানা শানবা';
      case 'nag': return 'Kheli thakibi';
      case 'ne': return 'खेल्दै रहनुहोस्';
      case 'trp': return 'Gele tong di';
      case 'hi': return 'खेलते रहें';
      case 'en':
      default: return 'Keep playing';
    }
  }

  static String timeForGoodRest(String code) {
    switch (code) {
      case 'as': return 'ভালদৰে জিৰণি লোৱাৰ সময়';
      case 'bn': return 'ভালো করে বিশ্রাম নেওয়ার সময়';
      case 'brx': return 'मोजाङै बिथा लानायनि सम';
      case 'grt': return 'Knamtakgipa neng·takani sal';
      case 'kha': return 'Ka por ban shongthait bha';
      case 'lus': return 'Chawlh hahdam veng veng a hun';
      case 'mni': return 'ফনা পোন্থাবা মতম';
      case 'nag': return 'Bhal pora aaram lobi';
      case 'ne': return 'राम्रो आराम गर्ने समय';
      case 'trp': return 'Kaham nukhung rwno jora';
      case 'hi': return 'अच्छी तरह विश्राम का समय';
      case 'en':
      default: return 'Time for a good rest';
    }
  }

  static String breakLockBody(String code) {
    switch (code) {
      case 'as':
        return 'আজি আপুনি খুব ধুনীয়াকৈ খেলিলে! খেলসমূহে এতিয়া শান্তভাৱে জিৰণি লৈছে আৰু ৩ ঘণ্টা পিছত পুনৰ সাজু হ\'ব।';
      case 'bn':
        return 'আজ আপনি খুব সুন্দর খেলেছেন! খেলাগুলি এখন শান্তভাবে বিশ্রাম নিচ্ছে এবং ৩ ঘণ্টা পর আবার ফিরে আসবে।';
      case 'brx':
        return 'दिनै नोंथाङा जोबोद मोजां गेलेबाय! गेलेनायफोरा दानो गोजोनै बिथा लादों आरो ३ घन्टा उनाव फैगोन।';
      case 'grt':
        return 'Da·alo na·a nambee kal·aha! Kal·anirang da·o tom·tome neng·taka aro ghanta 3 ja·mano re·bakugen.';
      case 'kha':
        return 'Phi la lehkai bha bha mynta ka sngi! Ki jingialehkai ki shongthait noh bad kin wan biang hadien 3 kynta.';
      case 'lus':
        return 'Vawiinah nuam takin i infiam e! Infiamnate hi an chawl rih a, darkar 3 hnuah an lo kir leh ang.';
      case 'mni':
        return 'ঙসি অদোমনা য়াম্না ফনা শানখ্রে! শান্নপোৎশিং হৌজিক পোন্থারি অমসুং পুং ৩গী মতুংদা হন্না লাক্লগনি।';
      case 'nag':
        return 'Aji apuni bhal pora khelise! Khel khan etiya shanto pora aaram loi ase aru 3 ghonta bichete ahibo.';
      case 'ne':
        return 'आज तपाईंले धेरै राम्रो खेल्नुभयो! खेलहरू अहिले शान्त विश्राममा छन् र ३ घण्टापछि फेरि सुरु हुनेछन्।';
      case 'trp':
        return 'Tini nwng buma kaham gelerwkha! Gelema tabuk nukhung rwo tongo, ghanta 3 ulog phinai.';
      case 'hi':
        return 'आज आपने बहुत अच्छा खेला! खेल अभी शांत विश्राम पर हैं और 3 घंटे बाद फिर उपलब्ध होंगे।';
      case 'en':
      default:
        return 'You have had a wonderful playtime today! It is time to rest your eyes and mind. Games are taking a peaceful break and will be back in 3 hours.';
    }
  }

  static String takeARest(String code) {
    switch (code) {
      case 'as': return 'জিৰণি লওক';
      case 'bn': return 'বিশ্রাম নিন';
      case 'brx': return 'बिथा ला';
      case 'grt': return 'Neng·takbo';
      case 'kha': return 'Shongthait';
      case 'lus': return 'Chawl rawh';
      case 'mni': return 'পোন্থাবা';
      case 'nag': return 'Aaram lobi';
      case 'ne': return 'आराम गर्नुहोस्';
      case 'trp': return 'Nukhung rw di';
      case 'hi': return 'विश्राम लें';
      case 'en':
      default: return 'Take a rest';
    }
  }

  static String gamesAreResting(String code) {
    switch (code) {
      case 'as': return 'খেলসমূহ জিৰণি লৈছে';
      case 'bn': return 'খেলাগুলি বিশ্রাম নিচ্ছে';
      case 'brx': return 'गेलेनायफोरा बिथा लादों';
      case 'grt': return 'Kal·anirang neng·taka';
      case 'kha': return 'Ki jingialehkai ki shongthait';
      case 'lus': return 'Infiamnate an chawl rih e';
      case 'mni': return 'শান্নপোৎশিং পোন্থারি';
      case 'nag': return 'Khel khan aaram loi ase';
      case 'ne': return 'खेलहरू विश्राममा छन्';
      case 'trp': return 'Gelemarwk nukhung rwo';
      case 'hi': return 'खेल विश्राम पर हैं';
      case 'en':
      default: return 'Games are Resting';
    }
  }

  static String gamesRestingPrompt(String code) {
    switch (code) {
      case 'as':
        return 'খেলসমূহে এতিয়া শান্তভাৱে জিৰণি লৈছে। পৰিয়ালৰ ফটো চাব বিচাৰিব নে আজিৰ কাৰ্যসূচী চাব?';
      case 'bn':
        return 'খেলাগুলি এখন শান্তভাবে বিশ্রাম নিচ্ছে। পরিবারের ছবি দেখবেন নাকি আজকের রুটিন দেখবেন?';
      case 'brx':
        return 'गेलेनायफोरा दानो गोजोनै बिथा लादों। नखरनि फोटो नायनो लुबैयो ना दिनैनि हाबाफारि?';
      case 'grt':
        return 'Kal·anirang da·o tom·tome neng·taka. Nokdangni noksa ba da·alni kamrangko nina skama?';
      case 'kha':
        return 'Ki jingialehkai ki dang shongthait. Phi kwah ban peit ia ki dur iing lane ki kam jong ka sngi?';
      case 'lus':
        return 'Infiamnate an chawl rih e. I chhungte thlalak emaw vawiin i hna turte thlir i duh em?';
      case 'mni':
        return 'শান্নপোৎশিংনা হৌজিক পোন্থারি। ইমুংগী ফোতো য়েংবা পাম্বব্রা নত্রগা নুমিৎসিগী থৌরম?';
      case 'nag':
        return 'Khel khan etiya shanto pora aaram loi ase. Poriyal laga photo sabole mon ase naki aji laga kaam sabole?';
      case 'ne':
        return 'खेलहरू अहिले शान्त विश्राममा छन्। परिवारका फोटो हेर्न चाहनुहुन्छ कि आजको कार्यतालिका?';
      case 'trp':
        return 'Gelemarwk tabuk nukhung rwo tongo. Nokhorni photo naino nani salni samung naino?';
      case 'hi':
        return 'खेल अभी शांत विश्राम पर हैं। क्या आप परिवार के फ़ोटो देखना चाहेंगे या आज की दिनचर्या?';
      case 'en':
      default:
        return 'Games are taking a peaceful break right now. How about checking your family messages or your daily routine?';
    }
  }

  static String restingBannerText(String code, int remainingMinutes) {
    switch (code) {
      case 'as':
        return 'খেলসমূহ আৰু $remainingMinutes মিনিট জিৰণি লৈছে। অলপ জিৰণি লওক!';
      case 'bn':
        return 'খেলাগুলি আরও $remainingMinutes মিনিট বিশ্রাম নিচ্ছে। শান্তভাবে বিরতি নিন!';
      case 'brx':
        return 'गेलेनायफोरा आरोबाव $remainingMinutes मिनिट बिथा लादों। गोजोनै बिथा ला!';
      case 'grt':
        return 'Kal·anirang gipin minute $remainingMinutes-na neng·taka. Dikdiksa neng·takbo!';
      case 'kha':
        return 'Ki jingialehkai ki dang shongthait sa $remainingMinutes minit. Shongthait khyndiat!';
      case 'lus':
        return 'Infiamnate hi minute $remainingMinutes dang an chawl rih ang. Hahdam rawh le!';
      case 'mni':
        return 'শান্নপোৎশিংনা অমুকসু মিনিট $remainingMinutes পোন্থারি। পোন্থাবা লৌবীয়ু!';
      case 'nag':
        return 'Khel khan aru $remainingMinutes minute aaram loi ase. Shanto pora aaram lobi!';
      case 'ne':
        return 'खेलहरू अझै $remainingMinutes मिनेट विश्राममा छन्। शान्त विश्राम लिनुहोस्!';
      case 'trp':
        return 'Gelemarwk $remainingMinutes minute ulog nukhung rwo tongo. Khakchangwi nukhung rw di!';
      case 'hi':
        return 'खेल अगले $remainingMinutes मिनट के लिए विश्राम पर हैं। शांत विश्राम लें!';
      case 'en':
      default:
        return 'Games are resting for another $remainingMinutes minutes. Take a peaceful break!';
    }
  }

  static String varietyEnjoy(String code, String favGameTitle) {
    switch (code) {
      case 'as':
        return 'আপুনি $favGameTitle খেলি খুব ভাল পায়!';
      case 'bn':
        return 'আপনি $favGameTitle খেলতে খুব ভালোবাসেন!';
      case 'brx':
        return 'नोंथाङा $favGameTitle गेलेना जोबोद मोजां मोनो!';
      case 'grt':
        return 'Na·a $favGameTitle-ko namen kal·na namnika!';
      case 'kha':
        return 'Phi sngewtynad bha ban lehkai $favGameTitle!';
      case 'lus':
        return '$favGameTitle khelh hi nuam i ti hle mai!';
      case 'mni':
        return 'অদোমনা $favGameTitle শানবা য়াম্না নুংঙাইবা ফাওই!';
      case 'nag':
        return 'Apuni $favGameTitle kheli kene bhal pai!';
      case 'ne':
        return 'तपाईंलाई $favGameTitle खेल्न धेरै मन पर्छ!';
      case 'trp':
        return 'Nwng $favGameTitle geleno buma hamjakgo!';
      case 'hi':
        return 'आपको $favGameTitle खेलना बहुत पसंद है!';
      case 'en':
      default:
        return 'You really enjoy $favGameTitle!';
    }
  }

  static String varietyTry(String code, String sugGameTitle) {
    switch (code) {
      case 'as':
        return 'আজি $sugGameTitle খেলি চালে কেনে হয়? বেলেগ খেল খেলিলে মন সতেজ থাকে।';
      case 'bn':
        return 'আজ কি $sugGameTitle চেষ্টা করবেন? বিভিন্ন খেলা খেললে মন সতেজ থাকে।';
      case 'brx':
        return 'दिनै $sugGameTitle गेलेना नायनो नागिरो नामा? गुबुन गुबुन गेलेयोब्ला मेगन-गोसो मोजां जायो।';
      case 'grt':
        return 'Da·alo $sugGameTitle-ko kal·chengge ma? Dingtang dingtang kal·ani gisikko an·sengata.';
      case 'kha':
        return 'Kumno lada pyrshang ia ka $sugGameTitle mynta? Ka pynshait jingmut ban lehkai bun jait.';
      case 'lus':
        return 'Vawiinah $sugGameTitle hi ti chhin ta che? Infiamna danglam khelh hi rilru tan a ṭha e.';
      case 'mni':
        return 'ঙসি $sugGameTitle শানবা হোৎনবদা করি তৌই? তোঙানবা শান্নপোৎ শানবনা ৱাখলবু নৌহল্লি।';
      case 'nag':
        return 'Aji $sugGameTitle kheli sabi naki? Alag alag khel khele mon to bhal thakibo.';
      case 'ne':
        return 'आज $sugGameTitle प्रयास गर्दा कस्तो होला? विभिन्न खेलहरू खेल्नु दिमागका लागि राम्रो हुन्छ।';
      case 'trp':
        return 'Tini $sugGameTitle gele naide? Dingtang dingtang gele khe bwkha kaham tongo.';
      case 'hi':
        return 'आज $sugGameTitle आज़मा कर कैसा रहेगा? अलग-अलग खेल खेलना दिमाग के लिए अच्छा होता है।';
      case 'en':
      default:
        return 'How about trying $sugGameTitle today? It is good for the mind to play different games.';
    }
  }

  static String tryGame(String code, String sugGameTitle) {
    switch (code) {
      case 'as': return '$sugGameTitle খেলক';
      case 'bn': return '$sugGameTitle খেলুন';
      case 'brx': return '$sugGameTitle गेले';
      case 'grt': return '$sugGameTitle kal·bo';
      case 'kha': return 'Lehkai $sugGameTitle';
      case 'lus': return '$sugGameTitle khel rawh';
      case 'mni': return '$sugGameTitle শানবা';
      case 'nag': return '$sugGameTitle kheli sabi';
      case 'ne': return '$sugGameTitle खेल्नुहोस्';
      case 'trp': return '$sugGameTitle gele di';
      case 'hi': return '$sugGameTitle खेलें';
      case 'en':
      default: return 'Try $sugGameTitle';
    }
  }

  // ── Games Screen ───────────────────────────────────────────────────────────

  static String games(String code) {
    switch (code) {
      case 'as': return 'খেলসমূহ';
      case 'bn': return 'খেলাসমূহ';
      case 'brx': return 'गेलेनायफोर';
      case 'grt': return 'Kal·anirang';
      case 'kha': return 'Ki Jingialehkai';
      case 'lus': return 'Infiamnate';
      case 'mni': return 'শান্নপোৎশিং';
      case 'nag': return 'Khel khan';
      case 'ne': return 'खेलहरू';
      case 'trp': return 'Gelemarwk';
      case 'hi': return 'खेल';
      case 'en':
      default: return 'Games';
    }
  }

  static String playHistory(String code) {
    switch (code) {
      case 'as': return 'খেলৰ ইতিহাস';
      case 'bn': return 'খেলার ইতিহাস';
      case 'brx': return 'गेलेनायनि जारिमिन';
      case 'grt': return 'Kal·manani itihas';
      case 'kha': return 'Ka Jingialehkai mynshwa';
      case 'lus': return 'Infiamna Hriatrengte';
      case 'mni': return 'শান্নখিবগী ৱারী';
      case 'nag': return 'Khel laga Itihas';
      case 'ne': return 'खेलको इतिहास';
      case 'trp': return 'Gelemani Kothoma';
      case 'hi': return 'खेल इतिहास';
      case 'en':
      default: return 'Play History';
    }
  }

  static String trySomethingNew(String code) {
    switch (code) {
      case 'as': return 'আজি নতুন কিবা এটা খেলক!';
      case 'bn': return 'আজ নতুন কিছু চেষ্টা করুন!';
      case 'brx': return 'दिनै गोदान माबा गेले!';
      case 'grt': return 'Da·alo gital gita dakchinko!';
      case 'kha': return 'Pyrshang da kaba thymmai mynta!';
      case 'lus': return 'Vawiinah a thar ti chhin rawh!';
      case 'mni': return 'ঙসি অনৌবা অমতা হোৎনৌ!';
      case 'nag': return 'Aji notun ekta kheli sabi!';
      case 'ne': return 'आज केही नयाँ प्रयास गर्नुहोस्!';
      case 'trp': return 'Tini kwtal khe gele di!';
      case 'hi': return 'आज कुछ नया आज़माएँ!';
      case 'en':
      default: return 'Try something new today!';
    }
  }

  static String tryToday(String code) {
    switch (code) {
      case 'as': return 'আজি চেষ্টা কৰক';
      case 'bn': return 'আজ চেষ্টা করুন';
      case 'brx': return 'दिनै नाजा';
      case 'grt': return 'Da·al dakchengo';
      case 'kha': return 'Pyrshang mynta';
      case 'lus': return 'Vawiinah ti rawh';
      case 'mni': return 'ঙসি হোৎনৌ';
      case 'nag': return 'Aji kheli sabi';
      case 'ne': return 'आज प्रयास गर्नुहोस्';
      case 'trp': return 'Tini gele di';
      case 'hi': return 'आज आज़माएँ';
      case 'en':
      default: return 'Try today';
    }
  }

  static String maybeLater(String code) {
    switch (code) {
      case 'as': return 'পিছত কৰিম';
      case 'bn': return 'পরে করব';
      case 'brx': return 'उनाव खालामगोन';
      case 'grt': return 'Ja·manoba';
      case 'kha': return 'Hadien noh';
      case 'lus': return 'Nakinah le';
      case 'mni': return 'মতুংদা';
      case 'nag': return 'Bichete koribo';
      case 'ne': return 'पछि गरौँला';
      case 'trp': return 'Ulog khe';
      case 'hi': return 'बाद में';
      case 'en':
      default: return 'Maybe later';
    }
  }

  static String backToGames(String code) {
    switch (code) {
      case 'as': return 'খেললৈ উভতি যাওক';
      case 'bn': return 'খেলায় ফিরে যান';
      case 'brx': return 'गेलेनायाव फैफिन';
      case 'grt': return 'Kal·anina re·bapilbo';
      case 'kha': return 'Leh biang ia ki jingialehkai';
      case 'lus': return 'Infiamnaah kir leh rawh';
      case 'mni': return 'শান্নপোত্তা হন্না চৎপা';
      case 'nag': return 'Khelte wapas jabi';
      case 'ne': return 'खेलहरूमा फर्कनुहोस्';
      case 'trp': return 'Gelemao phin di';
      case 'hi': return 'खेलों पर वापस जाएँ';
      case 'en':
      default: return 'Back to Games';
    }
  }

  static String sessionComplete(String code) {
    switch (code) {
      case 'as': return 'খেল সমাপ্ত হ\'ল!';
      case 'bn': return 'খেলা সমাপ্ত!';
      case 'brx': return 'गेलेनाया जोबबाय!';
      case 'grt': return 'Matchotaha!';
      case 'kha': return 'La dep ka jingialehkai!';
      case 'lus': return 'I zo ta e!';
      case 'mni': return 'শান্নবা লোইশিল্লে!';
      case 'nag': return 'Khel khotom hoise!';
      case 'ne': return 'सत्र पूरा भयो!';
      case 'trp': return 'Paijakha!';
      case 'hi': return 'सत्र समाप्त!';
      case 'en':
      default: return 'Session Complete!';
    }
  }

  static String chooseLanguage(String code) {
    switch (code) {
      case 'as': return 'ভাষা বাছক';
      case 'bn': return 'ভাষা নির্বাচন করুন';
      case 'brx': return 'राव सायख';
      case 'grt': return 'Ku·sikko seokbo';
      case 'kha': return 'Jied ia ka Ktien';
      case 'lus': return 'Ṭawng thlang rawh';
      case 'mni': return 'লোন খনবগী';
      case 'nag': return 'Bhasha basibi';
      case 'ne': return 'भाषा छान्नुहोस्';
      case 'trp': return 'Kok baithang sai di';
      case 'hi': return 'भाषा चुनें';
      case 'en':
      default: return 'Choose Language';
    }
  }

  // ── Game Catalog Localized Titles & Descriptions ──────────────────────────

  static String gameTitle(String code, String gameId) {
    final titles = _gameTitles[gameId];
    if (titles != null && titles.containsKey(code)) {
      return titles[code]!;
    }
    return titles?['en'] ?? gameId;
  }

  static String gameDescription(String code, String gameId) {
    final desc = _gameDescriptions[gameId];
    if (desc != null && desc.containsKey(code)) {
      return desc[code]!;
    }
    return desc?['en'] ?? '';
  }

  static const Map<String, Map<String, String>> _gameTitles = {
    'market_basket': {
      'as': 'বজাৰৰ পাচি',
      'bn': 'বাজারের ঝুড়ি',
      'brx': 'बाजानि थुख्रि',
      'grt': 'Bajar Bazar',
      'kha': 'Ka Kho Iew',
      'lus': 'Bazar Bawm',
      'mni': 'কৈথেলগী থুম্বা',
      'nag': 'Bazar laga Tokri',
      'ne': 'बजारको टोकरी',
      'trp': 'Hatoini Tolai',
      'hi': 'बाज़ार की टोकरी',
      'en': 'Market Basket',
    },
    'faces_of_family': {
      'as': 'পৰিয়ালৰ মুখ',
      'bn': 'পরিবারের মুখ',
      'brx': 'नखरनि महर',
      'grt': 'Nokdangni Mikkang',
      'kha': 'Ki Khmat Iing',
      'lus': 'Chhungte Hmel',
      'mni': 'ইমুংগী মশক',
      'nag': 'Poriyal laga Mukh',
      'ne': 'परिवारका अनुहारहरू',
      'trp': 'Nokhorni Mwsang',
      'hi': 'परिवार के चेहरे',
      'en': 'Faces of My Family',
    },
    'sort_harvest': {
      'as': 'ফসল বাছনি',
      'bn': 'ফসল বাছাই',
      'brx': 'फसल सायखनाय',
      'grt': 'Biterangko Dingtangata',
      'kha': 'Jied ia ki Jingthung',
      'lus': 'Thlai Thliar',
      'mni': 'লোইরকপা খাইদোকপা',
      'nag': 'Fasol Chuna Khel',
      'ne': 'बाली छान्ने खेल',
      'trp': 'Mai-khang Swkma',
      'hi': 'फसल छँटाई',
      'en': 'Sort the Harvest',
    },
    'trace_path': {
      'as': 'বাট বিচাৰক',
      'bn': 'পথ অনুসন্ধান',
      'brx': 'लामा नागिर',
      'grt': 'Ramako Ja·rikbo',
      'kha': 'Bud ia ka Lynti',
      'lus': 'Kawng Chhui',
      'mni': 'লম্বী থিবা',
      'nag': 'Rasta Milabi',
      'ne': 'बाटो पछ्याउनुहोस्',
      'trp': 'Lama Riti',
      'hi': 'रास्ता खोजें',
      'en': 'Trace the Path',
    },
    'my_day': {
      'as': 'মোৰ দিনটো',
      'bn': 'আমার দিন',
      'brx': 'आंनि सान',
      'grt': 'Angni Sal',
      'kha': 'Ka Sngi Jong Nga',
      'lus': 'Ka Ni',
      'mni': 'ঐগী নুমিৎ',
      'nag': 'Moi laga Din',
      'ne': 'मेरो दिन',
      'trp': 'Ani Sal',
      'hi': 'मेरा दिन',
      'en': 'My Day',
    },
    'lamps_festival': {
      'as': 'চাকিৰ উৎসৱ',
      'bn': 'প্রদীপের উৎসব',
      'brx': 'साउस्रि फालिनाय',
      'grt': 'Wal·kuko Ritimani',
      'kha': 'Lehniam Sharak',
      'lus': 'Khawnvar Kut',
      'mni': 'থাউমৈগী চহাক',
      'nag': 'Chaki laga Utsob',
      'ne': 'दीपोत्सव',
      'trp': 'Bathini Phai',
      'hi': 'दीपों का त्योहार',
      'en': 'Lamps of the Festival',
    },
    'name_harvest': {
      'as': 'নামকৰণ',
      'bn': 'নাম পরিচয়',
      'brx': 'मुं सायखनाय',
      'grt': 'Mingani Bosturang',
      'kha': 'Ai Kyrteng',
      'lus': 'Hming Vuah',
      'mni': 'মিং খঙবা',
      'nag': 'Naam Chinibi',
      'ne': 'नाम पहिचान',
      'trp': 'Bostuni Mung',
      'hi': 'नाम पहचान',
      'en': 'Name the Harvest',
    },
    'weaving_patterns': {
      'as': 'তাঁতৰ শাল',
      'bn': 'তাঁতের নকশা',
      'brx': 'दासाय महर',
      'grt': 'Dokan Salani',
      'kha': 'Rukom Thain Jain',
      'lus': 'Tunkawng Ziah',
      'mni': 'শাফিগী মশক',
      'nag': 'Buna laga Pattern',
      'ne': 'बुनाईका ढाँचाहरू',
      'trp': 'Rignai Kiri',
      'hi': 'बुनाई के पैटर्न',
      'en': 'Weaving Patterns',
    },
    'sounds_home': {
      'as': 'ঘৰুৱা শব্দ',
      'bn': 'ঘরের শব্দ',
      'brx': "न'नि सोदोब",
      'grt': 'Nokni Gam·anirang',
      'kha': 'Ki Sur ha Iing',
      'lus': 'In Chhung Awte',
      'mni': 'য়ুমগী খোন্থা',
      'nag': 'Ghor laga Awaz',
      'ne': 'घरका आवाजहरू',
      'trp': 'Nokhoni Khwlwk',
      'hi': 'घर की आवाज़ें',
      'en': 'Sounds of Home',
    },
  };

  static const Map<String, Map<String, String>> _gameDescriptions = {
    'market_basket': {
      'as': 'বজাৰৰ পৰা সংগ্ৰহ কৰিবলগীয়া বস্তু মনত ৰাখক',
      'bn': 'বাজার থেকে আনা সামগ্রী মনে রাখুন',
      'brx': 'बाजारनिफ्राय लानो गोनां मुवाफोरखौ गोसोआव लाखि',
      'grt': 'Bajaroni ra·na nangani bosturangko gisik ra·bo',
      'kha': 'Kynmaw ia ki mar ban thied na iew',
      'lus': 'Bazar atanga lak turte vawng reng rawh',
      'mni': 'কৈথেলদগী লৌগদবা পোৎলমশিং নীংশিংবা',
      'nag': 'Bazar pora anibole thaka bostu khan yaad rakhibi',
      'ne': 'बजारबाट ल्याउनुपर्ने सामानहरू सम्झनुहोस्',
      'trp': 'Hatoini tubuma mwchangma bwkha khak di',
      'hi': 'बाज़ार से लाने वाली चीज़ें याद रखें',
      'en': 'Remember items to collect from the market',
    },
    'faces_of_family': {
      'as': 'আপোনাৰ আপোনজনক চিনাক্ত কৰক',
      'bn': 'আপনার প্রিয়জনদের চিনুন',
      'brx': 'नोंथांनि अनजालिफोरखौ सिनाय',
      'grt': 'Nang·ni ka·sagiparangko ma·sibo',
      'kha': 'Ithuh ia ki baieit jong phi',
      'lus': 'I mi duh takte hmel hre hrang rawh',
      'mni': 'অদোমগী নুংশিরবশিংবু মশক খঙবা',
      'nag': 'Nijor manu khan ke chinibi',
      'ne': 'आफ्ना प्रियजनहरूलाई चिन्नुहोस्',
      'trp': 'Nini hamjakmarwkno cheng di',
      'hi': 'अपने अपनों को पहचानें',
      'en': 'Recognise your loved ones',
    },
    'sort_harvest': {
      'as': 'শাক-পাচলি আৰু ফলমূল বাছক',
      'bn': 'সবজি ও ফসল আলাদা করুন',
      'brx': 'मैगं-थायगं सायख',
      'grt': 'Sam-jakrang aro biterangko dingtang dingtang sonbo',
      'kha': 'Pynbynta ia ki jhur bad ki jingthung',
      'lus': 'Thlaite dah hrang rawh',
      'mni': 'মহৈ-মরোং অমসুং হৌদোং খাইদোকপা',
      'nag': 'Sobji aru fosol khan alag koribi',
      'ne': 'तरकारी र फलफूलहरू छुट्याउनुहोस्',
      'trp': 'Bwsai-bwtwi chwngwi tongo',
      'hi': 'सब्जियों और उपज को छाँटें',
      'en': 'Sort vegetables and produce',
    },
    'trace_path': {
      'as': 'ধুনীয়াকৈ বাটটো সংযোগ কৰক',
      'bn': 'সহজে পথটি সংযুক্ত করুন',
      'brx': 'लामाखौ मोजाङै जोबोर खालाम',
      'grt': 'Ramako tik dake nangdimatbo',
      'kha': 'Pyniasoh ia ki lynti',
      'lus': 'Kawng dik chhui rawh',
      'mni': 'লম্বী অচুম্বা শম্নহনবা',
      'nag': 'Rasta to bhal pora juribi',
      'ne': 'बाटोलाई सहज रूपमा जोड्नुहोस्',
      'trp': 'Lama chwngwi pwtwk di',
      'hi': 'रास्ते को सुचारू रूप से जोड़ें',
      'en': 'Connect the path smoothly',
    },
    'my_day': {
      'as': 'আপোনাৰ দৈনন্দিন কাৰ্যক্ৰম অনুসৰণ কৰক',
      'bn': 'আপনার দৈনন্দিন রুটিন অনুসরণ করুন',
      'brx': 'नोंथांनि सानफ्रोमनि हाबाफारि नाय',
      'grt': 'Nang·ni salanti re·rurani bewalko ja·rikbo',
      'kha': 'Bud ia ki rukom leh jong ka sngi',
      'lus': 'I nitin hna thlir rawh',
      'mni': 'অদোমগী নোংমগী থৌরম নীংশিংবা',
      'nag': 'Apuni laga dinor kaam khan monat rakhibi',
      'ne': 'आफ्नो दैनिक दिनचर्या पछ्याउनुहोस्',
      'trp': 'Nini salbrumni samung budi',
      'hi': 'अपनी दिनचर्या का पालन करें',
      'en': 'Follow your daily routine',
    },
    'lamps_festival': {
      'as': 'জ্বলি থকা চাকিৰ ধৰণ মনত ৰাখক',
      'bn': 'উজ্জ্বল প্রদীপের ক্রম মনে রাখুন',
      'brx': 'ज्वलायनाय बाथि महरखौ गोसोआव लाखि',
      'grt': 'Changgipa cha·kiko gisik ra·bo',
      'kha': 'Kynmaw ia ki sharak kiba meh',
      'lus': 'Khawnvar eng chhui rawh',
      'mni': 'ঙাল্লিবা থাউমৈগী মশক নীংশিংবা',
      'nag': 'Joli thaka chaki laga pattern yaad rakhibi',
      'ne': 'बलेका दीपहरूको क्रम सम्झनुहोस्',
      'trp': 'Kwphang bathino bwkhak khak di',
      'hi': 'जलते दीपों का क्रम याद रखें',
      'en': 'Remember the glowing lamp pattern',
    },
    'name_harvest': {
      'as': 'বস্তু আৰু উপাদানসমূহ চিনাক্ত কৰক',
      'bn': 'বস্তু ও উপাদান চিহ্নিত করুন',
      'brx': 'मुवाफोरखौ सिनाय',
      'grt': 'Bosturang aro miksonganirangko ma·sibo',
      'kha': 'Ithuh ia ki mar ki mata',
      'lus': 'Thil hming hre rawh',
      'mni': 'পোৎলমশিংবু মিং খঙবা',
      'nag': 'Bostu aru fasol khan ke naam pora chinibi',
      'ne': 'वस्तुहरू र उपजहरू चिन्नुहोस्',
      'trp': 'Mung nukhung kwlai di',
      'hi': 'वस्तुओं और उपज को पहचानें',
      'en': 'Identify objects and produce',
    },
    'weaving_patterns': {
      'as': 'ধুনীয়া ফুল আৰু চানেকি মিলোৱাক',
      'bn': 'সুন্দর বুনন নকশা মেলাও',
      'brx': 'दासाय महरफोरखौ मिलाय',
      'grt': 'Nitogipa dokeni chinrangko apsanata',
      'kha': 'Pyniahap ia ki dur thain jain',
      'lus': 'Tunkawng ziah dik rem rawh',
      'mni': 'ফি শাবা নকশা তান্নহনবা',
      'nag': 'Dhuniya buna design khan milabi',
      'ne': 'सुन्दर बुनाईका ढाँचाहरू मिलाउनुहोस्',
      'trp': 'Kaham rignaini chwngma phan di',
      'hi': 'सुंदर बुनाई के पैटर्न मिलाएँ',
      'en': 'Match beautiful weaving motifs',
    },
    'sounds_home': {
      'as': 'পৰিচিত শব্দবোৰ শুনি চিনাক্ত কৰক',
      'bn': 'পরিচিত শব্দ শুনে চিনুন',
      'brx': 'मिथिगोनां सोदोबफोरखौ खोनासंना सिनाय',
      'grt': 'Gisik ra·atgipa knaanirangko ma·sibo',
      'kha': 'Sngap bad ithuh ia ki sur kiba ju iohsngew',
      'lus': 'In chhung aw hriat thante ngaithla rawh',
      'mni': 'খঙনরব খোন্থা তাদুনা খঙবা',
      'nag': 'Porithit awaz khan huni kene chinibi',
      'ne': 'परिचित आवाजहरू सुनेर पहिचान गर्नुहोस्',
      'trp': 'Si-jakmwrwk khwlwk khna di',
      'hi': 'परिचित आवाज़ें सुनकर पहचानें',
      'en': 'Listen and recognize familiar sounds',
    },
  };

  // ── Reminders & Notifications ──────────────────────────────────────────────

  /// Native notification banner and alert title. [medName] is preserved in English.
  static String timeForMedication(String code, String medName) {
    switch (code) {
      case 'as': return '$medName খোৱাৰ সময়';
      case 'bn': return '$medName খাওয়ার সময়';
      case 'brx': return '$medName लानो सम';
      case 'grt': return '$medName cha·ani salon';
      case 'kha': return 'Por ban dih $medName';
      case 'lus': return '$medName ei a hun';
      case 'mni': return '$medName চাবগী মতম';
      case 'nag': return '$medName khabole homoy hoise';
      case 'ne': return '$medName खाने समय';
      case 'trp': return '$medName chakhung rwno jora';
      case 'hi': return '$medName लेने का समय';
      case 'en':
      default: return 'Time for $medName';
    }
  }

  static String timeForYourMedicine(String code) {
    switch (code) {
      case 'as': return 'আপোনাৰ ঔষধ খোৱাৰ সময়';
      case 'bn': return 'আপনার ওষুধ খাওয়ার সময়';
      case 'brx': return 'नोंथांनि मुलि लानो सम';
      case 'grt': return 'Nang·ni sam cha·ani salon';
      case 'kha': return 'La dei ka por ban dih dawai';
      case 'lus': return 'Damdawi ei a hun ta';
      case 'mni': return 'অদোমগী হিদাক চাবগী মতম';
      case 'nag': return 'Apuni laga dawai khabole homoy hoise';
      case 'ne': return 'तपाईंको औषधि खाने समय';
      case 'trp': return 'Nini bwswi chakhung rwno jora';
      case 'hi': return 'आपकी दवाई का समय';
      case 'en':
      default: return 'Time for Your Medicine';
    }
  }

  static String doseLabel(String code, String dose) {
    switch (code) {
      case 'as': return 'মাত্ৰা: $dose';
      case 'bn': return 'মাত্রা: $dose';
      case 'brx': return 'मुलिनि परिमान: $dose';
      case 'grt': return 'Samni biding: $dose';
      case 'kha': return 'Ka jingthew: $dose';
      case 'lus': return 'A zat tur: $dose';
      case 'mni': return 'হিদাক্কী চাং: $dose';
      case 'nag': return 'Kiman khabo: $dose';
      case 'ne': return 'मात्रा: $dose';
      case 'trp': return 'Bwswini poriman: $dose';
      case 'hi': return 'मात्रा: $dose';
      case 'en':
      default: return 'Dose: $dose';
    }
  }

  static String iHaveTakenIt(String code) {
    switch (code) {
      case 'as': return 'মই ঔষধ খালোঁ';
      case 'bn': return 'আমি খেয়ে নিয়েছি';
      case 'brx': return 'आं लामारबाय';
      case 'grt': return 'Anga chamanchaha';
      case 'kha': return 'Nga la dih';
      case 'lus': return 'Ka ei tawh e';
      case 'mni': return 'ঐনা চাখ্রে';
      case 'nag': return 'Moi khai loishe';
      case 'ne': return 'मैले खाएँ';
      case 'trp': return 'Ang charwkha';
      case 'hi': return 'मैंने ले ली';
      case 'en':
      default: return 'I Have Taken It';
    }
  }

  static String remindIn10Mins(String code) {
    switch (code) {
      case 'as': return '১০ মিনিট পিছত জনাওক';
      case 'bn': return '১০ মিনিট পর জানান';
      case 'brx': return '१० मिनिट उनाव बाथ्रा फै';
      case 'grt': return 'Minute 10 ja·mano gisik ra·atbo';
      case 'kha': return 'Kynmaw biang hadien 10 minit';
      case 'lus': return 'Minute 10 hnuah min hriattir leh rawh';
      case 'mni': return 'মিনিট ১০গী মতুংদা নীংশিংবীযু';
      case 'nag': return '10 minute bichete yaad koribi';
      case 'ne': return '१० मिनेटपछि सम्झाउनुहोस्';
      case 'trp': return 'Minute 10 ulog kok phin di';
      case 'hi': return '10 मिनट बाद याद दिलाएँ';
      case 'en':
      default: return 'Remind in 10 Mins';
    }
  }

  static String hearVoiceAgain(String code) {
    switch (code) {
      case 'as': return 'কণ্ঠ পুনৰ শুনক';
      case 'bn': return 'কথা আবার শুনুন';
      case 'brx': return 'रावखौ फिन खोनासं';
      case 'grt': return 'Khu·rangko pil·ta kna·bo';
      case 'kha': return 'Sngap biang ia ka sur';
      case 'lus': return 'Aw ngaithla nawn rawh';
      case 'mni': return 'খোন্থা অমুক হন্না তারসি';
      case 'nag': return 'Awaz abar hunibi';
      case 'ne': return 'आवाज फेरि सुन्नुहोस्';
      case 'trp': return 'Khorangno ta phin di';
      case 'hi': return 'आवाज़ दोबारा सुनें';
      case 'en':
      default: return 'Hear Voice Again';
    }
  }

  static String listening(String code) {
    switch (code) {
      case 'as': return 'শুনি থকা হৈছে...';
      case 'bn': return 'শুনছি...';
      case 'brx': return 'खोनासंगासिनो...';
      case 'grt': return 'Kna·enga...';
      case 'kha': return 'Dang sngap...';
      case 'lus': return 'Ngaithla mek...';
      case 'mni': return 'তারি...';
      case 'nag': return 'Huni ase...';
      case 'ne': return 'सुन्दैछ...';
      case 'trp': return 'Khna tongo...';
      case 'hi': return 'सुन रहे हैं...';
      case 'en':
      default: return 'Listening...';
    }
  }

  static String medicineRecordedWellDone(String code) {
    switch (code) {
      case 'as': return 'ধন্যবাদ!';
      case 'bn': return 'ধন্যবাদ!';
      case 'brx': return 'मुलि लानाय जाबाय। गोजोन्थों!';
      case 'grt': return 'Mitela!';
      case 'kha': return 'Khublei!';
      case 'lus': return 'Ka lawm e!';
      case 'mni': return 'থাগৎচরি!';
      case 'nag': return 'Dhanyabad!';
      case 'ne': return 'धन्यवाद!';
      case 'trp': return 'Hambai!';
      case 'hi': return 'धन्यवाद!';
      case 'en':
      default: return 'Thank you!';
    }
  }

  static String willRemindIn10Minutes(String code) {
    switch (code) {
      case 'as': return 'আমি আপোনাক ১০ মিনিট পিছত পুনৰ সোঁৱৰাই দিম।';
      case 'bn': return 'আমরা আপনাকে ১০ মিনিট পর আবার মনে করিয়ে দেব।';
      case 'brx': return 'जों नोंथांखौ १० मिनिट उनाव फिन गोसोखां होनाय जागोन।';
      case 'grt': return 'Chinga minute 10 ja·mano gisik ra·atpilgen.';
      case 'kha': return 'Ngin pynkynmaw biang hadien 10 minit.';
      case 'lus': return 'Minute 10 hnuah kan rawn hriattir leh ang che.';
      case 'mni': return 'মিনিট ১০গী মতুংদা অমুক হন্না নীংশিংলগনি।';
      case 'nag': return 'Ami khan apunike 10 minute bichete abar monat korai dibo.';
      case 'ne': return 'हामी तपाईंलाई १० मिनेटपछि फेरि सम्झाउनेछौँ।';
      case 'trp': return 'Chwng nwngno minute 10 ulog kok phin nai.';
      case 'hi': return 'हम आपको 10 मिनट बाद फिर याद दिलाएँगे।';
      case 'en':
      default: return 'We will remind you in 10 minutes.';
    }
  }

  // ── Routine & Daily Schedule ───────────────────────────────────────────────

  static String myMedicines(String code) {
    switch (code) {
      case 'as': return 'মোৰ ঔষধসমূহ';
      case 'bn': return 'আমার ওষুধ';
      case 'brx': return 'आंनि मुलिफोर';
      case 'grt': return 'Angni Samrang';
      case 'kha': return 'Ki Dawai Jong Nga';
      case 'lus': return 'Ka Damdawite';
      case 'mni': return 'ঐগী হিদাকশিং';
      case 'nag': return 'Moi laga Dawai khan';
      case 'ne': return 'मेरो औषधिहरू';
      case 'trp': return 'Ani Bwswirwk';
      case 'hi': return 'मेरी दवाइयाँ';
      case 'en':
      default: return 'My Medicines';
    }
  }

  static String tapTakeOnceHad(String code) {
    switch (code) {
      case 'as': return 'ঔষধ খোৱাৰ পিছত \'খালোঁ\' টিপক';
      case 'bn': return 'ওষুধ খাওয়ার পর \'খেয়েছি\' চাপুন';
      case 'brx': return 'मुलि जानाय उनाव \'लाबाय\' थु';
      case 'grt': return 'Samko chamano ja·mano \'Cha·aha\' gita tike bo';
      case 'kha': return 'Kyntiew \'La dih\' haba la dep dih';
      case 'lus': return 'I ei zawhah \'Ka ei\' tih hmet rawh';
      case 'mni': return 'হিদাক চাবা মতুংদা \'চাখ্রে\' নম্বীয়ু';
      case 'nag': return 'Dawai khowa bichete \'Khai loishe\' te tap koribi';
      case 'ne': return 'औषधि खाएपछि \'खाएँ\' थिच्नुहोस्';
      case 'trp': return 'Bwswi chamani ulog \'Charwkha\' te di';
      case 'hi': return 'दवाई लेने के बाद \'ले ली\' पर टैप करें';
      case 'en':
      default: return 'Tap Take once you have had it';
    }
  }

  static String noMedicinesScheduled(String code) {
    switch (code) {
      case 'as': return 'কোনো ঔষধৰ সময় তালিকা নাই।';
      case 'bn': return 'কোনো ওষুধের সময়সূচী নেই।';
      case 'brx': return 'जेबो मुलिनि फारिलाइ गैया।';
      case 'grt': return 'Samko taria dongja.';
      case 'kha': return 'Ym don dawai ba la buh por.';
      case 'lus': return 'Damdawi ei tur a awm rih lo.';
      case 'mni': return 'হিদাক্কী থৌরম লৈত্ৰে।';
      case 'nag': return 'Kono dawai laga list nai.';
      case 'ne': return 'कुनै औषधि तालिकामा छैन।';
      case 'trp': return 'Khorokbo bwswini samung khorokliya.';
      case 'hi': return 'कोई दवाई निर्धारित नहीं है।';
      case 'en':
      default: return 'No medicines scheduled.';
    }
  }

  static String take(String code) {
    switch (code) {
      case 'as': return 'খাওক';
      case 'bn': return 'নিন';
      case 'brx': return 'ला';
      case 'grt': return 'Cha·bo';
      case 'kha': return 'Dih';
      case 'lus': return 'Ei rawh';
      case 'mni': return 'চাবিয়ু';
      case 'nag': return 'Lobi';
      case 'ne': return 'खानुहोस्';
      case 'trp': return 'Cha di';
      case 'hi': return 'लें';
      case 'en':
      default: return 'Take';
    }
  }

  static String taken(String code) {
    switch (code) {
      case 'as': return 'খালোঁ';
      case 'bn': return 'নিয়েছি';
      case 'brx': return 'लाबाय';
      case 'grt': return 'Cha·aha';
      case 'kha': return 'La dih';
      case 'lus': return 'Ei tawh';
      case 'mni': return 'চাখ্রে';
      case 'nag': return 'Khai loishe';
      case 'ne': return 'खाएँ';
      case 'trp': return 'Charwkha';
      case 'hi': return 'ले ली';
      case 'en':
      default: return 'Taken';
    }
  }

  static String hearInstruction(String code) {
    switch (code) {
      case 'as': return 'নিৰ্দেশনা শুনক';
      case 'bn': return 'নির্দেশনা শুনুন';
      case 'brx': return 'बिथोन खोनासं';
      case 'grt': return 'Ge·etaniko kna·bo';
      case 'kha': return 'Sngap ia ka jingbthah';
      case 'lus': return 'Kaihhruaina ngaithla rawh';
      case 'mni': return 'পাউতাক তারি';
      case 'nag': return 'Kotha hunibi';
      case 'ne': return 'निर्देशन सुन्नुहोस्';
      case 'trp': return 'Kok chongmalo khna di';
      case 'hi': return 'निर्देश सुनें';
      case 'en':
      default: return 'Hear Voice';
    }
  }

  static String alreadyMarkedTaken(String code, String medName) {
    switch (code) {
      case 'as': return '$medName আজি ইতিমধ্যে খোৱা বুলি চিহ্নিত কৰা হৈছে।';
      case 'bn': return '$medName আজ ইতিমধ্যে নেওয়া হয়েছে।';
      case 'brx': return '$medName दिनै लामारबाय होनना महर मोन्नाय जाबाय।';
      case 'grt': return '$medName da·al chamanchaha ine chin dakkaha.';
      case 'kha': return '$medName la dep dih lypa mynta ka sngi.';
      case 'lus': return '$medName chu vawiinah ei tawh angin a inziak e.';
      case 'mni': return '$medName ঙসি চাখ্রে হায়না পল্লে।';
      case 'nag': return '$medName aji khai loishe koi kene mark hoise.';
      case 'ne': return '$medName आज पहिले नै खाइसकिएको छ।';
      case 'trp': return '$medName tini charwkha hwnwi manjakha.';
      case 'hi': return '$medName आज पहले ही ली जा चुकी है।';
      case 'en':
      default: return '$medName is already marked as taken today.';
    }
  }

  static String routineEmptyTitle(String code) {
    switch (code) {
      case 'as': return 'আপোনাৰ কাৰ্যসূচী সোনকালে যোগ কৰা হ\'ব';
      case 'bn': return 'আপনার রুটিন শীঘ্রই যুক্ত করা হবে';
      case 'brx': return 'नोंथांनि हाबाफारिखौ थाबनो फोसावगोन';
      case 'grt': return 'Nang·ni bewalko ta·raken dingtangatgen';
      case 'kha': return 'Sa sa pynbeit shen ia ka rukom leh jong phi';
      case 'lus': return 'I nitin hna ruahmanna chu siam thuai a ni ang';
      case 'mni': return 'অদোমগী থৌরম থুনা হাপচিল্লগনি';
      case 'nag': return 'Apuni laga daily routine joldi ahibo';
      case 'ne': return 'तपाईंको तालिका चाँडै अद्यावधिक गरिनेछ';
      case 'trp': return 'Nini salni samung kubun thumwi rwnai';
      case 'hi': return 'आपकी दिनचर्या जल्द ही जोड़ी जाएगी';
      case 'en':
      default: return 'Your routine will be updated soon';
    }
  }

  static String routineEmptyMessage(String code) {
    switch (code) {
      case 'as': return 'পৰিয়ালে ইয়াত আপোনাৰ দৈনিক পৰিকল্পনা যোগ কৰিব।';
      case 'bn': return 'আপনার পরিবার এখানে আপনার দৈনন্দিন পরিকল্পনা যুক্ত করবে।';
      case 'brx': return 'नोंथांनि नखरा बेयाव सानफ्रोमनि हाबाफारिखौ बाहायगोन।';
      case 'grt': return 'Nokdangni manderang salanti kamko iano tarigen.';
      case 'kha': return 'Ki baha-iing kin pynbeit ia ki kam sngi jong phi hangne.';
      case 'lus': return 'I chhungten helai hmunah hian i ruahmanna an rawn dah ang.';
      case 'mni': return 'ইমুংগী মীশিংনা মফমসিদা নোংমগী থৌরম হাপ্লগনি।';
      case 'nag': return 'Poriyal laga manu khan aji laga plan eya te rakhidibo.';
      case 'ne': return 'तपाईंको परिवारले यहाँ तपाईंको दैनिक योजना थप्नुहुनेछ।';
      case 'trp': return 'Nokhorni borok tini salni porikolpona tei rwnai.';
      case 'hi': return 'आपका परिवार यहाँ आपकी दैनिक योजना जोड़ेगा।';
      case 'en':
      default: return 'Your family will add your daily plan here.';
    }
  }

  static String comingUpNext(String code) {
    switch (code) {
      case 'as': return 'পৰৱৰ্তী কাৰ্যসূচী';
      case 'bn': return 'পরবর্তী কাজ';
      case 'brx': return 'उननि हाबाफारि';
      case 'grt': return 'Ja·mano re·baenggipa';
      case 'kha': return 'Kaba bud';
      case 'lus': return 'A dawt leh tur';
      case 'mni': return 'মথংগী থৌরম';
      case 'nag': return 'Etiya ahibole thaka';
      case 'ne': return 'अर्को कार्यक्रम';
      case 'trp': return 'Ulog phainai';
      case 'hi': return 'अगला कार्यक्रम';
      case 'en':
      default: return 'Coming up next';
    }
  }

  static String thatsAllForToday(String code) {
    switch (code) {
      case 'as': return 'আজিৰ বাবে এইখিনিয়েই';
      case 'bn': return 'আজকের মত শেষ';
      case 'brx': return 'दिनैनि थाखाय एसेल\'';
      case 'grt': return 'Da·alona matchotaha';
      case 'kha': return 'La biang mynta ka sngi';
      case 'lus': return 'Vawiin atan chuan a tawk ta e';
      case 'mni': return 'ঙসিগীদি মসি খকনি';
      case 'nag': return 'Aji laga sob khotom hoise';
      case 'ne': return 'आजका लागि यति नै';
      case 'trp': return 'Tinino paijakha';
      case 'hi': return 'आज के लिए बस इतना ही';
      case 'en':
      default: return "That's all for today";
    }
  }

  static String doneCountSoFar(String code, int done, int total) {
    switch (code) {
      case 'as': return 'আজি মুঠ $total টাৰ ভিতৰত $done টা সম্পন্ন';
      case 'bn': return 'আজ মোট $total টির মধ্যে $done টি সম্পন্ন';
      case 'brx': return 'दिनै $total नि गेजेराव $done खालामबाय';
      case 'grt': return 'Da·alo $total-oni $done-ko matchotaha';
      case 'kha': return 'La dep $done na ki $total mynta ka sngi';
      case 'lus': return 'Vawiinah $total zinga $done tih zawh a ni ta';
      case 'mni': return 'ঙসি $total দগী $done লোইশিনখ্রে';
      case 'nag': return 'Aji $total laga majote $done ta hoise';
      case 'ne': return 'आज $total मध्ये $done वटा पूरा भयो';
      case 'trp': return 'Tini $total ni $done paijakha';
      case 'hi': return 'आज $total में से $done पूरे हुए';
      case 'en':
      default: return '$done of $total so far today';
    }
  }

  static String nowBadge(String code) {
    switch (code) {
      case 'as': return 'এতিয়া';
      case 'bn': return 'এখন';
      case 'brx': return 'दानो';
      case 'grt': return 'Da·o';
      case 'kha': return 'Mynta';
      case 'lus': return 'Tunah';
      case 'mni': return 'হৌজিক';
      case 'nag': return 'Etiya';
      case 'ne': return 'अहिले';
      case 'trp': return 'Tabuk';
      case 'hi': return 'अभी';
      case 'en':
      default: return 'Now';
    }
  }

  static String dayPartLabel(String code, String partKey) {
    final isMorning = partKey.toLowerCase().contains('morning');
    final isAfternoon = partKey.toLowerCase().contains('afternoon');
    final isEvening = partKey.toLowerCase().contains('evening');

    if (isMorning) {
      switch (code) {
        case 'as': return 'ৰাতিপুৱা';
        case 'bn': return 'সকাল';
        case 'brx': return 'फुं';
        case 'grt': return 'Pring';
        case 'kha': return 'Step';
        case 'lus': return 'Zing';
        case 'mni': return 'অয়ুক';
        case 'nag': return 'Phujor';
        case 'ne': return 'बिहान';
        case 'trp': return 'Salphung';
        case 'hi': return 'सुबह';
        case 'en': default: return 'Morning';
      }
    } else if (isAfternoon) {
      switch (code) {
        case 'as': return 'দুপৰীয়া';
        case 'bn': return 'দুপুর';
        case 'brx': return 'सान';
        case 'grt': return 'Salbaro';
        case 'kha': return 'Sngi';
        case 'lus': return 'Chhun';
        case 'mni': return 'নুমিৎথাক';
        case 'nag': return 'Dupor';
        case 'ne': return 'दिउँसो';
        case 'trp': return 'Salsali';
        case 'hi': return 'दोपहर';
        case 'en': default: return 'Afternoon';
      }
    } else if (isEvening) {
      switch (code) {
        case 'as': return 'গধূলি';
        case 'bn': return 'সন্ধ্যা';
        case 'brx': return 'बेलासे';
        case 'grt': return 'Attam';
        case 'kha': return 'Janmiet';
        case 'lus': return 'Tlai';
        case 'mni': return 'নুমিদাং';
        case 'nag': return 'Bheli';
        case 'ne': return 'साँझ';
        case 'trp': return 'Sanmari';
        case 'hi': return 'शाम';
        case 'en': default: return 'Evening';
      }
    } else {
      switch (code) {
        case 'as': return 'নিশা';
        case 'bn': return 'রাত';
        case 'brx': return 'हर';
        case 'grt': return 'Wal';
        case 'kha': return 'Miet';
        case 'lus': return 'Zan';
        case 'mni': return 'অহিং';
        case 'nag': return 'Raat';
        case 'ne': return 'रात';
        case 'trp': return 'Hor';
        case 'hi': return 'रात';
        case 'en': default: return 'Night';
      }
    }
  }

  /// Translates common web-app routine activities into the elder's selected language.
  /// If the label is unrecognized, returns [rawLabel] unmodified.
  static String routineLabel(String code, String rawLabel) {
    if (code == 'en') return rawLabel;
    final lower = rawLabel.trim().toLowerCase();

    // 1. Morning Walk / Stroll / Walk
    if (lower.contains('walk') || lower.contains('stroll')) {
      switch (code) {
        case 'as': return 'খোজকাঢ়া';
        case 'bn': return 'সকালের হাঁটা';
        case 'brx': return 'हाथािनाय';
        case 'grt': return 'Re·rama';
        case 'kha': return 'Ka jinglehkai step';
        case 'lus': return 'Zing len';
        case 'mni': return 'চৎথোক-চৎশিন';
        case 'nag': return 'Ghumibole jabi';
        case 'ne': return 'बिहानीको हिँडडुल';
        case 'trp': return 'Himma';
        case 'hi': return 'सुबह की सैर';
      }
    }

    // 2. Breakfast / Morning snack
    if (lower.contains('breakfast') || lower.contains('tiffin')) {
      switch (code) {
        case 'as': return 'ৰাতিপুৱাৰ জলপান';
        case 'bn': return 'সকালের প্রাতঃরাশ';
        case 'brx': return 'फुंनि ओंखाम';
        case 'grt': return 'Pringni cha·ani';
        case 'kha': return 'Jingbam step';
        case 'lus': return 'Tukṭhuan';
        case 'mni': return 'অয়ুক্কী চা-থক';
        case 'nag': return 'Phujor laga khana';
        case 'ne': return 'बिहानीको खाजा';
        case 'trp': return 'Salphungni chakhung';
        case 'hi': return 'सुबह का नाश्ता';
      }
    }

    // 3. Morning Tea / Chai
    if ((lower.contains('morning') && lower.contains('tea')) || (lower.contains('morning') && lower.contains('chai'))) {
      switch (code) {
        case 'as': return 'ৰাতিপুৱাৰ চাহ';
        case 'bn': return 'সকালের চা';
        case 'brx': return 'फुंनि साहा';
        case 'grt': return 'Pringni cha';
        case 'kha': return 'Sha step';
        case 'lus': return 'Zing thingpui';
        case 'mni': return 'অয়ুক্কী চা';
        case 'nag': return 'Phujor laga cha';
        case 'ne': return 'बिहानीको चिया';
        case 'trp': return 'Salphungni cha';
        case 'hi': return 'सुबह की चाय';
      }
    }

    // 4. Tea / Chai / Tea time
    if (lower.contains('tea') || lower.contains('chai')) {
      switch (code) {
        case 'as': return 'চাহ খোৱাৰ সময়';
        case 'bn': return 'চা পানের সময়';
        case 'brx': return 'साहा लोंनाय सम';
        case 'grt': return 'Cha ringani';
        case 'kha': return 'Ka por dih sha';
        case 'lus': return 'Thingpui in hun';
        case 'mni': return 'চা ঠকপগী মতম';
        case 'nag': return 'Cha khabole homoy';
        case 'ne': return 'चिया पिउने समय';
        case 'trp': return 'Cha nungmo jora';
        case 'hi': return 'चाय का समय';
      }
    }

    // 5. Bath / Shower / Wash
    if (lower.contains('bath') || lower.contains('shower') || lower.contains('wash')) {
      switch (code) {
        case 'as': return 'গা ধোৱা';
        case 'bn': return 'স্নান করা';
        case 'brx': return 'दुगैनाय';
        case 'grt': return 'Ausanani';
        case 'kha': return 'Sumbhor';
        case 'lus': return 'Inbual';
        case 'mni': return 'ইরুজবা';
        case 'nag': return 'Gaa dhuwabole';
        case 'ne': return 'नुहाउने समय';
        case 'trp': return 'Twi rungma';
        case 'hi': return 'स्नान / नहाना';
      }
    }

    // 6. Newspaper / Read / Reading
    if (lower.contains('newspaper') || lower.contains('paper') || lower.contains('read') || lower.contains('book')) {
      switch (code) {
        case 'as': return 'বাতৰিকাকত পঢ়া';
        case 'bn': return 'সংবাদপত্র পড়া';
        case 'brx': return 'रादाब बिलाइ फरायनाय';
        case 'grt': return 'Kobor leka poraiani';
        case 'kha': return 'Pule kot khubor';
        case 'lus': return 'Chanchinbu chhiar';
        case 'mni': return 'চেফোং পারবা';
        case 'nag': return 'News paper porhibole';
        case 'ne': return 'पत्रपत्रिका पढ्ने';
        case 'trp': return 'Khorang porima';
        case 'hi': return 'अख़बार पढ़ना';
      }
    }

    // 7. Puja / Prayer / Worship / Meditation
    if (lower.contains('puja') || lower.contains('prayer') || lower.contains('worship') || lower.contains('meditat') || lower.contains('church') || lower.contains('mandir')) {
      switch (code) {
        case 'as': return 'প্ৰাৰ্থনা / পূজা';
        case 'bn': return 'প্রার্থনা / পুজো';
        case 'brx': return 'आरज / फुजा';
        case 'grt': return 'Gitelna bi·ani';
        case 'kha': return 'Ka duwai';
        case 'lus': return 'Ṭawngṭai hun';
        case 'mni': return 'ঈশ্বর খুরুম্বা';
        case 'nag': return 'Prathana / Puja';
        case 'ne': return 'पूजा / प्रार्थना';
        case 'trp': return 'Borom rwma';
        case 'hi': return 'पूजा / प्रार्थना';
      }
    }

    // 8. Lunch / Midday Meal
    if (lower.contains('lunch') || (lower.contains('midday') && lower.contains('meal'))) {
      switch (code) {
        case 'as': return 'দুপৰীয়াৰ সাজ';
        case 'bn': return 'দুপুরের খাবার';
        case 'brx': return 'सान्नि ओंखाम';
        case 'grt': return 'Salni cha·ani';
        case 'kha': return 'Ja sngi';
        case 'lus': return 'Chhunchaw';
        case 'mni': return 'নুমিৎথাক্কী চাকুর';
        case 'nag': return 'Dupor laga khana';
        case 'ne': return 'दिउँसोको खाना';
        case 'trp': return 'Salsalini chakhung';
        case 'hi': return 'दोपहर का भोजन';
      }
    }

    // 9. Nap / Rest / Relax
    if (lower.contains('nap') || lower.contains('rest') || lower.contains('relax') || lower.contains('lie down')) {
      switch (code) {
        case 'as': return 'অলপ জিৰণি';
        case 'bn': return 'একটু বিশ্রাম';
        case 'brx': return 'एसेल\' बिथा';
        case 'grt': return 'Dikdiksa neng·takani';
        case 'kha': return 'Shongthait khyndiat';
        case 'lus': return 'Chawlh hahdam';
        case 'mni': return 'পোন্থাবা';
        case 'nag': return 'Olop aaram';
        case 'ne': return 'केही बेर आराम';
        case 'trp': return 'Nukhung rwma';
        case 'hi': return 'थोड़ा विश्राम';
      }
    }

    // 10. Plants / Garden / Gardening
    if (lower.contains('plant') || lower.contains('garden') || lower.contains('flower')) {
      switch (code) {
        case 'as': return 'গছত পানী দিয়া';
        case 'bn': return 'গাছে জল দেওয়া';
        case 'brx': return 'बिबार बारियाव दै होनाय';
        case 'grt': return 'Bibal bagano chi rudapani';
        case 'kha': return 'Ai um ia ki jingthung';
        case 'lus': return 'Pangpar tui pek';
        case 'mni': return 'উ-হীদগী ঈশিং থীবা';
        case 'nag': return 'Phul te pani dibole';
        case 'ne': return 'बिरुवामा पानी हाल्ने';
        case 'trp': return 'Bwsango twi rwna';
        case 'hi': return 'पौधों को पानी देना';
      }
    }

    // 11. Family Call / Phone Call / Call / Talk
    if (lower.contains('call') || lower.contains('phone') || lower.contains('talk')) {
      switch (code) {
        case 'as': return 'পৰিয়ালৰ সৈতে কথা পতা';
        case 'bn': return 'পরিবারের সাথে কথা বলা';
        case 'brx': return 'नखरजों रायज्लायनाय';
        case 'grt': return 'Nokdangni gimin agangrikbo';
        case 'kha': return 'Iakren bad ki baha-iing';
        case 'lus': return 'Chhungte biak';
        case 'mni': return 'ইমুংগী মীগা ৱারী শাবা';
        case 'nag': return 'Poriyal logote kotha kora';
        case 'ne': return 'परिवारसँग कुराकानी';
        case 'trp': return 'Nokhoni lok songbai kok salma';
        case 'hi': return 'परिवार से बात करना';
      }
    }

    // 12. Dinner / Supper / Night Meal
    if (lower.contains('dinner') || lower.contains('supper')) {
      switch (code) {
        case 'as': return 'নিশাৰ আহাৰ';
        case 'bn': return 'রাতের খাবার';
        case 'brx': return 'हरनि ओंखाम';
        case 'grt': return 'Walo cha·ani';
        case 'kha': return 'Ja miet';
        case 'lus': return 'Zanriah';
        case 'mni': return 'নুমিদাংগী চাকুর';
        case 'nag': return 'Raat laga khana';
        case 'ne': return 'रातिको खाना';
        case 'trp': return 'Hornani chakhung';
        case 'hi': return 'रात का भोजन';
      }
    }

    // 13. Sleep / Bedtime
    if (lower.contains('sleep') || lower.contains('bedtime') || lower.contains('bed')) {
      switch (code) {
        case 'as': return 'শুবলৈ যোৱা';
        case 'bn': return 'ঘুমাতে যাওয়া';
        case 'brx': return 'सिफिनो थांनाय';
        case 'grt': return 'Tusina re·ani';
        case 'kha': return 'Thiah noh';
        case 'lus': return 'Muthilh';
        case 'mni': return 'তুম্বা চৎপা';
        case 'nag': return 'Shutibole jabi';
        case 'ne': return 'सुत्न जाने';
        case 'trp': return 'Thuno tangma';
        case 'hi': return 'सोने का समय';
      }
    }

    // 14. Yoga / Exercise
    if (lower.contains('yoga') || lower.contains('exercise') || lower.contains('stretch')) {
      switch (code) {
        case 'as': return 'যোগাসন / ব্যায়াম';
        case 'bn': return 'যোগাসন / ব্যায়াম';
        case 'brx': return 'योग / बेयाम';
        case 'grt': return 'Be·en an·sengatani';
        case 'kha': return 'Jingpynheh bor';
        case 'lus': return 'Insawizawi';
        case 'mni': return 'ব্যায়াম তৌবা';
        case 'nag': return 'Bayam koribole';
        case 'ne': return 'योगाभ्यास / कसरत';
        case 'trp': return 'Khorok khunuma';
        case 'hi': return 'योग / व्यायाम';
      }
    }

    // Fallback: return original caregiver text as-is
    return rawLabel;
  }

  // ── Voice Memo Screen ──────────────────────────────────────────────────────

  static String sendVoiceMessageToFamily(String code) {
    switch (code) {
      case 'as': return 'পৰিয়াললৈ এটা কণ্ঠবাৰ্তা প্ৰেৰণ কৰক';
      case 'bn': return 'পরিবারকে একটি ভয়েস বার্তা পাঠান';
      case 'brx': return 'नखरनो खोन्दोब खौरां हर';
      case 'grt': return 'Nokdangna ku·rangni mesisko watbo';
      case 'kha': return 'Phah ka khubor ktien sha ka baha-iing';
      case 'lus': return 'Chhungte hnenah aw thawn rawh';
      case 'mni': return 'ইমুংদা খোঞ্জেলগী পাউজেল অমা থাবিয়ু';
      case 'nag': return 'Poriyal khan ke voice message ekta pathabi';
      case 'ne': return 'परिवारलाई भ्वाइस सन्देश पठाउनुहोस्';
      case 'trp': return 'Nokhorno khorangni kokthum thum di';
      case 'hi': return 'परिवार को एक वॉइस संदेश भेजें';
      case 'en':
      default: return 'Send a voice message to your family';
    }
  }

  static String tapToRecord(String code) {
    switch (code) {
      case 'as': return 'ৰেকৰ্ড কৰিবলৈ টিপক';
      case 'bn': return 'রেকর্ড করতে চাপুন';
      case 'brx': return 'रेकर्ड खालामनो थु';
      case 'grt': return 'Rekod dakanina tike bo';
      case 'kha': return 'Kyntiew ban ring sur';
      case 'lus': return 'Record turin hmet rawh';
      case 'mni': return 'রেকোর্দ তৌনবা নম্বীয়ু';
      case 'nag': return 'Record koribole tap koribi';
      case 'ne': return 'रेकर्ड गर्न थिच्नुहोस्';
      case 'trp': return 'Record khulaina te di';
      case 'hi': return 'रिकॉर्ड करने के लिए टैप करें';
      case 'en':
      default: return 'Tap to Record';
    }
  }

  static String recording(String code) {
    switch (code) {
      case 'as': return 'ৰেকৰ্ড হৈ আছে...';
      case 'bn': return 'রেকর্ড হচ্ছে...';
      case 'brx': return 'रेकर्ड जागासिनो...';
      case 'grt': return 'Rekod ong·enga...';
      case 'kha': return 'Dang ring sur...';
      case 'lus': return 'Record mek...';
      case 'mni': return 'রেকোর্দ তৌরি...';
      case 'nag': return 'Record hoi ase...';
      case 'ne': return 'रेकर्ड हुँदैछ...';
      case 'trp': return 'Record wngtongkho...';
      case 'hi': return 'रिकॉर्डिंग हो रही है...';
      case 'en':
      default: return 'Recording...';
    }
  }

  static String tapToStop(String code) {
    switch (code) {
      case 'as': return 'থামাবলৈ টিপক';
      case 'bn': return 'থামাতে চাপুন';
      case 'brx': return "थाद'होनो थु";
      case 'grt': return 'Dingtangataniko dontongbo';
      case 'kha': return 'Kyntiew ban sangeh';
      case 'lus': return 'Tawp turin hmet rawh';
      case 'mni': return 'লেপনবা নম্বীয়ু';
      case 'nag': return 'Rukhibole tap koribi';
      case 'ne': return 'रोक्न थिच्नुहोस्';
      case 'trp': return 'Thakna te di';
      case 'hi': return 'रोकने के लिए टैप करें';
      case 'en':
      default: return 'Tap to Stop';
    }
  }

  static String sendAVoiceMessage(String code) {
    switch (code) {
      case 'as': return 'কণ্ঠবাৰ্তা প্ৰেৰণ কৰক';
      case 'bn': return 'ভয়েস বার্তা পাঠান';
      case 'brx': return 'खोन्दोब खौरां हर';
      case 'grt': return 'Ku·rangni mesisko watbo';
      case 'kha': return 'Phah ka khubor ktien';
      case 'lus': return 'Aw thawn rawh';
      case 'mni': return 'খোঞ্জেলগী পাউজেল থাবিয়ু';
      case 'nag': return 'Voice message pathabi';
      case 'ne': return 'भ्वाइस सन्देश पठाउनुहोस्';
      case 'trp': return 'Khorangni kokthum thum di';
      case 'hi': return 'वॉइस संदेश भेजें';
      case 'en':
      default: return 'Send a voice message';
    }
  }

  static String yourVoiceMessages(String code) {
    switch (code) {
      case 'as': return 'আপোনাৰ কণ্ঠবাৰ্তাসমূহ';
      case 'bn': return 'আপনার ভয়েস বার্তাসমূহ';
      case 'brx': return 'नोंथांनि खोन्दोब खौरांफोर';
      case 'grt': return 'Nang·ni ku·rangni mesisrang';
      case 'kha': return 'Ki khubor ktien jong phi';
      case 'lus': return 'I aw thawnte';
      case 'mni': return 'অদোমগী খোঞ্জেলগী পাউজেলশিং';
      case 'nag': return 'Apuni laga voice message khan';
      case 'ne': return 'तपाईंका भ्वाइस सन्देशहरू';
      case 'trp': return 'Nini khorangni kokthumrog';
      case 'hi': return 'आपके वॉइस संदेश';
      case 'en':
      default: return 'Your Voice Messages';
    }
  }

  static String noMessagesYet(String code) {
    switch (code) {
      case 'as': return 'এতিয়ালৈকে কোনো বাৰ্তা প্ৰেৰণ কৰা হোৱা নাই।';
      case 'bn': return 'এখনো কোনো বার্তা পাঠানো হয়নি।';
      case 'brx': return 'दासिमबो जेबो खौरां हराखै।';
      case 'grt': return 'Da·alona mesisko watkujaha.';
      case 'kha': return 'Ym pat phah khubor eiei.';
      case 'lus': return 'Mesej la thawn a awm lo.';
      case 'mni': return 'হৌজিকফাওবা পাউজেল অমত্তা থাদ্রি।';
      case 'nag': return 'Etiya tak kono message potha nai.';
      case 'ne': return 'अहिलेसम्म कुनै सन्देश पठाइएको छैन।';
      case 'trp': return 'Tabuk sokari kokthum rwliya.';
      case 'hi': return 'अभी तक कोई संदेश नहीं भेजा गया है।';
      case 'en':
      default: return 'No messages sent yet.';
    }
  }

  static String todayAtTime(String code, String timeStr) {
    switch (code) {
      case 'as': return 'আজি $timeStr বজাত';
      case 'bn': return 'আজ $timeStr-এ';
      case 'brx': return 'दिनै $timeStr समाव';
      case 'grt': return 'Da·al $timeStr-o';
      case 'kha': return 'Mynta ha ka $timeStr';
      case 'lus': return 'Vawiinah $timeStr-ah';
      case 'mni': return 'ঙসি $timeStr দা';
      case 'nag': return 'Aji $timeStr te';
      case 'ne': return 'आज $timeStr मा';
      case 'trp': return 'Tini $timeStr o';
      case 'hi': return 'आज $timeStr पर';
      case 'en':
      default: return 'Today at $timeStr';
    }
  }

  // ── Family Screen ──────────────────────────────────────────────────────────

  static String thePeopleWhoLoveYou(String code) {
    switch (code) {
      case 'as': return 'আপোনাক মৰম কৰা মানুহবোৰ';
      case 'bn': return 'যারা আপনাকে ভালোবাসেন';
      case 'brx': return 'नोंथांखौ अनग्रा मानसिफोर';
      case 'grt': return 'Nang·ko ka·sagipa manderang';
      case 'kha': return 'Ki briew kiba ieit ia phi';
      case 'lus': return 'Nangmah hmangaihtu mite';
      case 'mni': return 'অদোমবু নুংশিবা মীওইশিং';
      case 'nag': return 'Apuni ke morom kora manu khan';
      case 'ne': return 'तपाईंलाई माया गर्ने मानिसहरू';
      case 'trp': return 'Nwngno hamjaknai borokrog';
      case 'hi': return 'वे लोग जो आपसे प्यार करते हैं';
      case 'en':
      default: return 'The people who love you';
    }
  }

  static String familyWillAppearHere(String code) {
    switch (code) {
      case 'as': return 'আপোনাৰ পৰিয়াল ইয়াত দেখা যাব';
      case 'bn': return 'আপনার পরিবার এখানে দেখা যাবে';
      case 'brx': return 'नोंथांनि नखरा बेयाव नुजागोन';
      case 'grt': return 'Nang·ni nokdang iano nikananggen';
      case 'kha': return 'Ki baha-iing jong phi kin paw hangne';
      case 'lus': return 'I chhungte helai hmunah hian an lo lang ang';
      case 'mni': return 'অদোমগী ইমুং মফমসিদা উবা ফংলগনি';
      case 'nag': return 'Apuni laga poriyal eya te ahibo';
      case 'ne': return 'तपाईंको परिवार यहाँ देखिनुहुनेछ';
      case 'trp': return 'Nini nokhor ophano phainai';
      case 'hi': return 'आपका परिवार यहाँ दिखाई देगा';
      case 'en':
      default: return 'Your family will appear here';
    }
  }

  static String photosShowUpPrompt(String code) {
    switch (code) {
      case 'as': return 'পৰিয়ালে ফটো যোগ কৰাৰ পিছত ইয়াত দেখা যাব।';
      case 'bn': return 'পরিবার ছবি যোগ করলে এখানে দেখা যাবে।';
      case 'brx': return 'नखरनिफ्राय फोटो बाहायब्ला बेयाव नुजागोन।';
      case 'grt': return 'Nokdang photorangko sonapaoniko iano nikgen.';
      case 'kha': return 'Ki dur kin paw haba ki baha-iing la thep ia ki.';
      case 'lus': return 'I chhungten thlalak an dah hunah helai hmunah hian a lo lang ang.';
      case 'mni': return 'ইমুংনা ফোতো হাপ্লবা মতুংদা মফমসিদা উবা ফংলগনি।';
      case 'nag': return 'Poriyal laga manu khan photo dhalile eya te dikhibo.';
      case 'ne': return 'परिवारले तस्बिर थपेपछि यहाँ देखा पर्नेछ।';
      case 'trp': return 'Nokhorni borok photo rwo ulog ophano twnai.';
      case 'hi': return 'परिवार द्वारा तस्वीरें जोड़ने पर यहाँ दिखाई देंगी।';
      case 'en':
      default: return 'Photos show up once your caregiver adds them.';
    }
  }

  // ── Game Screen Empty State & Prompts ──────────────────────────────────────

  static String familyPhotosOnTheirWay(String code) {
    switch (code) {
      case 'as': return 'আপোনাৰ পৰিয়ালৰ ফটোবোৰ সোনকালে আহি আছে';
      case 'bn': return 'আপনার পরিবারের ছবিগুলো শীঘ্রই আসছে';
      case 'brx': return 'नोंथांनि नखरनि फोटोफोरा फैगासिनो दं';
      case 'grt': return 'Nang·ni nokdangni photorang re·baenga';
      case 'kha': return 'Ki dur jong ki baha-iing jong phi ki dang wan';
      case 'lus': return 'I chhungte thlalak a lo thleng tep e';
      case 'mni': return 'অদোমগী ইমুংগী ফোতোশিং লাক্লি';
      case 'nag': return 'Apuni laga poriyal laga photo ahi ase';
      case 'ne': return 'तपाईंको परिवारका तस्बिरहरू आउँदैछन्';
      case 'trp': return 'Nini nokhorni photorog phaitongkho';
      case 'hi': return 'आपके परिवार की तस्वीरें जल्द आ रही हैं';
      case 'en':
      default: return 'Your family photos are on their way';
    }
  }

  static String familyGameNeedMembers(String code) {
    switch (code) {
      case 'as': return 'এই খেলখনত আপোনাৰ নিজৰ পৰিয়াল ব্যৱহাৰ কৰা হয়। পৰিয়ালে অন্ততঃ দুজন সদস্য যোগ কৰাৰ পিছত খেলখন সাজু হ\'ব।';
      case 'bn': return 'এই খেলায় আপনার নিজের পরিবারকে ব্যবহার করা হয়। পরিবার কমপক্ষে দুজন সদস্য যুক্ত করার পর খেলাটি প্রস্তুত হবে।';
      case 'brx': return 'बे गेलेनाया नोंथांनि नखरखौ बाहायो। नखरा खमसिनबाबो साब्रै मानसि बाहायनाय उनाव बे गेलेनाया जागोन।';
      case 'grt': return 'Ia kal·aniara nang·ni nokdangko jakkala. Nokdang ge·gni ba una baten manderangko sonapa matchotgen.';
      case 'kha': return 'Kane ka jinglehkai ka pyndonkam ia ki baha-iing jong phi. Kan kloi haba la don arngut ki dkhot.';
      case 'lus': return 'He infiamna hian i chhungte ngei a hmang a ni. Chhungkaw mi pahnih tal an telh hunah a khelh theih ang.';
      case 'mni': return 'শন্নাবা অসিদা অদোমগী ইমুং শীজিন্নৈ। ইমুংনা য়ামদ্রবদা মীওই অনি হাপ্লবা মতুংদা শান্নবা য়াৰগনি।';
      case 'nag': return 'Eya game te apuni laga poriyal use kore. Poriyal te kom se kom dui jon manu thakile ready hobo.';
      case 'ne': return 'यो खेलमा तपाईंको आफ्नै परिवार प्रयोग गरिन्छ। परिवारले कम्तिमा दुई सदस्य थपेपछि यो तयार हुनेछ।';
      case 'trp': return 'O kulumuni nini nokhorno rwo wngkhornai. Nokhorni khoroknwi borok kwlaio kulumung chengjaknai.';
      case 'hi': return 'यह खेल आपके अपने परिवार का उपयोग करता है। परिवार द्वारा कम से कम दो सदस्य जोड़ने पर यह तैयार होगा।';
      case 'en':
      default: return 'This game uses your own family. It will be ready once your caregiver adds at least two family members.';
    }
  }

  // ── Market Basket Game ─────────────────────────────────────────────────────

  static String rememberTheseItems(String code) {
    switch (code) {
      case 'as': return 'এই বস্তুবোৰ মনত ৰাখক:';
      case 'bn': return 'এই জিনিসগুলো মনে রাখুন:';
      case 'brx': return 'बे बेफोरखौ गोसोआव लाखि:';
      case 'grt': return 'Ia bosturangko gisik ra·bo:';
      case 'kha': return 'Kynmaw ia kine ki tiar:';
      case 'lus': return 'Heng thilte hi hre reng rawh:';
      case 'mni': return 'পোৎলমশিং অসি নীংশিংবিয়ু:';
      case 'nag': return 'Eya bhal ke mon te rakhibi:';
      case 'ne': return 'यी वस्तुहरू सम्झनुहोस्:';
      case 'trp': return 'O bosturogno gosomano thum di:';
      case 'hi': return 'इन चीज़ों को याद रखें:';
      case 'en':
      default: return 'Remember these items:';
    }
  }

  static String getReady(String code) {
    switch (code) {
      case 'as': return 'প্ৰস্তুত হওক...';
      case 'bn': return 'প্রস্তুত হন...';
      case 'brx': return 'थियारि जा...';
      case 'grt': return 'Taribo...';
      case 'kha': return 'Khreh noh...';
      case 'lus': return 'Inring rawh le...';
      case 'mni': return 'শেম-শাবিয়ু...';
      case 'nag': return 'Ready hobi...';
      case 'ne': return 'तयार हुनुहोस्...';
      case 'trp': return 'Tari wng di...';
      case 'hi': return 'तैयार हो जाइए...';
      case 'en':
      default: return 'Get ready...';
    }
  }

  static String pickItemsFromList(String code) {
    switch (code) {
      case 'as': return 'তালিকাৰ বস্তুবোৰ বাছক:';
      case 'bn': return 'তালিকার জিনিসগুলো বেছে নিন:';
      case 'brx': return "फारिलाइनिफ्राय बेफोरखौ सायख':";
      case 'grt': return 'Lis-oni bosturangko see ra·bo:';
      case 'kha': return 'Jied ia ki tiar na ka list:';
      case 'lus': return 'I list aṭang khan thilte chu thlang rawh:';
      case 'mni': return 'লিস্তত য়াওবা পোৎলমশিং খনবিয়ু:';
      case 'nag': return 'List te thaka bhal khan basibi:';
      case 'ne': return 'सूचीबाट वस्तुहरू छान्नुहोस्:';
      case 'trp': return 'List ni bosturogno khai di:';
      case 'hi': return 'सूची में से चीज़ों को चुनें:';
      case 'en':
      default: return 'Pick the items from your list:';
    }
  }

  static String marketItemName(String code, String rawId) {
    final id = rawId.toLowerCase().replaceFirst('item.', '').trim();
    if (code == 'en') {
      switch (id) {
        case 'rice': return 'Rice';
        case 'atta': return 'Atta';
        case 'poha': return 'Poha';
        case 'dal': return 'Dal';
        case 'chana': return 'Chana';
        case 'tomato': return 'Tomato';
        case 'potato': return 'Potato';
        case 'brinjal': return 'Brinjal';
        case 'banana': return 'Banana';
        case 'papaya': return 'Papaya';
        case 'milk': return 'Milk';
        case 'curd': return 'Curd';
        case 'tea': return 'Tea';
        case 'salt': return 'Salt';
        case 'mustardoil': return 'Mustard Oil';
        default: return id;
      }
    }

    switch (id) {
      case 'rice':
        switch (code) {
          case 'as': return 'চাউল';
          case 'bn': return 'চাল';
          case 'brx': return 'माइरं';
          case 'grt': return 'Mi';
          case 'kha': return 'Khaw';
          case 'lus': return 'Buh';
          case 'mni': return 'চেং';
          case 'nag': return 'Chawal';
          case 'ne': return 'चामल';
          case 'trp': return 'Mairung';
          case 'hi': return 'चावल';
        }
        break;
      case 'atta':
        switch (code) {
          case 'as': return 'আটা';
          case 'bn': return 'আটা';
          case 'brx': return 'आटा';
          case 'grt': return 'Moida';
          case 'kha': return 'Atta';
          case 'lus': return 'Chhangphut';
          case 'mni': return 'আতা';
          case 'nag': return 'Atta';
          case 'ne': return 'आँटा';
          case 'trp': return 'Atta';
          case 'hi': return 'आटा';
        }
        break;
      case 'poha':
        switch (code) {
          case 'as': return 'চিৰা';
          case 'bn': return 'চিঁড়ে';
          case 'brx': return 'सिरा';
          case 'grt': return 'Chira';
          case 'kha': return 'Kba-pud';
          case 'lus': return 'Buhchhun';
          case 'mni': return 'হৈৰুং';
          case 'nag': return 'Chira';
          case 'ne': return 'च्युरा';
          case 'trp': return 'Chira';
          case 'hi': return 'पोहा';
        }
        break;
      case 'dal':
        switch (code) {
          case 'as': return 'দাইল';
          case 'bn': return 'ডাল';
          case 'brx': return 'दालि';
          case 'grt': return 'Dal';
          case 'kha': return 'Dai';
          case 'lus': return 'Dal';
          case 'mni': return 'হৱাইজার';
          case 'nag': return 'Dal';
          case 'ne': return 'दाल';
          case 'trp': return 'Dal';
          case 'hi': return 'दाल';
        }
        break;
      case 'chana':
        switch (code) {
          case 'as': return 'বুট';
          case 'bn': return 'ছোলা';
          case 'brx': return 'साना';
          case 'grt': return 'Chana';
          case 'kha': return 'Chana';
          case 'lus': return 'Chana';
          case 'mni': return 'চনা';
          case 'nag': return 'Chana';
          case 'ne': return 'चना';
          case 'trp': return 'Chana';
          case 'hi': return 'चना';
        }
        break;
      case 'tomato':
        switch (code) {
          case 'as': return 'বিলাহী';
          case 'bn': return 'টমেটো';
          case 'brx': return 'बिलाथि';
          case 'grt': return 'Golmatha';
          case 'kha': return 'Sohsaw';
          case 'lus': return 'Tomato';
          case 'mni': return 'খামেন আসংবা';
          case 'nag': return 'Tomato';
          case 'ne': return 'गोलभेंडा';
          case 'trp': return 'Tomato';
          case 'hi': return 'टमाटर';
        }
        break;
      case 'potato':
        switch (code) {
          case 'as': return 'আলু';
          case 'bn': return 'আলু';
          case 'brx': return 'थाखौ';
          case 'grt': return 'Ta·a';
          case 'kha': return 'Phan';
          case 'lus': return 'Alu';
          case 'mni': return 'আলু';
          case 'nag': return 'Alu';
          case 'ne': return 'आलु';
          case 'trp': return 'Alu';
          case 'hi': return 'आलू';
        }
        break;
      case 'brinjal':
        switch (code) {
          case 'as': return 'বেঙেনা';
          case 'bn': return 'বেগুন';
          case 'brx': return 'बायगोन';
          case 'grt': return 'Bare';
          case 'kha': return 'Sohbaingon';
          case 'lus': return 'Bawkbawn';
          case 'mni': return 'পান্থৌবি';
          case 'nag': return 'Baigan';
          case 'ne': return 'भन्टा';
          case 'trp': return 'Banthai';
          case 'hi': return 'बैंगन';
        }
        break;
      case 'banana':
        switch (code) {
          case 'as': return 'কল';
          case 'bn': return 'কলা';
          case 'brx': return 'थालाइ';
          case 'grt': return 'Te·rik';
          case 'kha': return 'Kait';
          case 'lus': return 'Balhla';
          case 'mni': return 'লফোই';
          case 'nag': return 'Kela';
          case 'ne': return 'केरा';
          case 'trp': return 'Thailik';
          case 'hi': return 'केला';
        }
        break;
      case 'papaya':
        switch (code) {
          case 'as': return 'অমিতা';
          case 'bn': return 'পেঁপে';
          case 'brx': return 'मदि';
          case 'grt': return 'Modiphal';
          case 'kha': return 'Sohkyndur';
          case 'lus': return 'Thingfanghma';
          case 'mni': return 'অৱাথবী';
          case 'nag': return 'Mewa';
          case 'ne': return 'मेवा';
          case 'trp': return 'Khumpai';
          case 'hi': return 'पपीता';
        }
        break;
      case 'milk':
        switch (code) {
          case 'as': return 'গাখীৰ';
          case 'bn': return 'দুধ';
          case 'brx': return 'गाखिर';
          case 'grt': return 'Sokchi';
          case 'kha': return 'Dud';
          case 'lus': return 'Bawnghnute';
          case 'mni': return 'শঙ্গোম';
          case 'nag': return 'Dudh';
          case 'ne': return 'दूध';
          case 'trp': return 'Nokhwi';
          case 'hi': return 'दूध';
        }
        break;
      case 'curd':
        switch (code) {
          case 'as': return 'দৈ';
          case 'bn': return 'দই';
          case 'brx': return 'दै';
          case 'grt': return 'Dahi';
          case 'kha': return 'Dahi';
          case 'lus': return 'Bawnghnute khal';
          case 'mni': return 'দৈ';
          case 'nag': return 'Dahi';
          case 'ne': return 'दही';
          case 'trp': return 'Dahi';
          case 'hi': return 'दही';
        }
        break;
      case 'tea':
        switch (code) {
          case 'as': return 'চাহপাত';
          case 'bn': return 'চা পাতা';
          case 'brx': return 'साहा बिलाइ';
          case 'grt': return 'Cha bijak';
          case 'kha': return 'Slasha';
          case 'lus': return 'Thingpui hnah';
          case 'mni': return 'চা-নাফি';
          case 'nag': return 'Cha patti';
          case 'ne': return 'चियापत्ती';
          case 'trp': return 'Cha bilai';
          case 'hi': return 'चायपत्ती';
        }
        break;
      case 'salt':
        switch (code) {
          case 'as': return 'নিমখ';
          case 'bn': return 'নুন';
          case 'brx': return 'संख्रि';
          case 'grt': return 'Kari';
          case 'kha': return 'Mlluh';
          case 'lus': return 'Chi';
          case 'mni': return 'থুম';
          case 'nag': return 'Nimok';
          case 'ne': return 'नुन';
          case 'trp': return 'Khorok';
          case 'hi': return 'नमक';
        }
        break;
      case 'mustardoil':
        switch (code) {
          case 'as': return 'মিঠা তেল';
          case 'bn': return 'সর্ষের তেল';
          case 'brx': return 'बेसर तेल';
          case 'grt': return 'Beswal tel';
          case 'kha': return 'Umphniang tyrso';
          case 'lus': return 'Antel';
          case 'mni': return 'হঙ্গাম থাউ';
          case 'nag': return 'Tita tel';
          case 'ne': return 'तोरीको तेल';
          case 'trp': return 'Tel';
          case 'hi': return 'सरसों का तेल';
        }
        break;
    }

    return id;
  }

  // ── Faces of My Family Game ────────────────────────────────────────────────

  static String whoIsThisPerson(String code) {
    switch (code) {
      case 'as': return 'এই ব্যক্তিজন কোন?';
      case 'bn': return 'ইনি কে?';
      case 'brx': return 'बे मानसिया सोर?';
      case 'grt': return 'Ia mande sawa?';
      case 'kha': return 'Uei kane ka briew?';
      case 'lus': return 'He mi hi tunge?';
      case 'mni': return 'মীওই অসি কনানো?';
      case 'nag': return 'Eya manu kon ase?';
      case 'ne': return 'यो व्यक्ति को हुनुहुन्छ?';
      case 'trp': return 'O borok sabo?';
      case 'hi': return 'यह व्यक्ति कौन हैं?';
      case 'en':
      default: return 'Who is this person?';
    }
  }

  static String canYouNameThisPerson(String code) {
    switch (code) {
      case 'as': return 'আপুনি এওঁৰ নাম ক\'ব পাৰিবনে?';
      case 'bn': return 'আপনি কি এঁর নাম বলতে পারেন?';
      case 'brx': return 'नोंथाङा बिनि मुंखौ बुंनो हागोनना?';
      case 'grt': return 'Nang·a ia mandeni bimingko mingna amgenma?';
      case 'kha': return 'Phi lah ban ong ia ka kyrteng?';
      case 'lus': return 'He mi hming hi i sawi thei em?';
      case 'mni': return 'অদোম্না মীওই অসিগী মিং হায়বা ঙমগদরা?';
      case 'nag': return 'Apuni eya manu laga naam jani ase?';
      case 'ne': return 'के तपाईं उहाँको नाम भन्न सक्नुहुन्छ?';
      case 'trp': return 'Nwng bini mung sa mannai de?';
      case 'hi': return 'क्या आप इनका नाम बता सकते हैं?';
      case 'en':
      default: return 'Can you name this person?';
    }
  }

  static String howIsPersonRelated(String code) {
    switch (code) {
      case 'as': return 'আপোনাৰ সৈতে এওঁৰ সম্বন্ধ কি?';
      case 'bn': return 'আপনার সাথে এঁর সম্পর্ক কী?';
      case 'brx': return 'नोंथांनिजों बिनि सोमोन्दोआ मा?';
      case 'grt': return 'Nang·baksa ia mandeni ma·drang maia?';
      case 'kha': return 'Kumno kane ka briew ka iadei bad phi?';
      case 'lus': return 'He mi nen hian eng nge in inlaichinna?';
      case 'mni': return 'মীওই অসিবু অদোমগা করি মরী লৈনই?';
      case 'nag': return 'Apuni logote eya manu laga rista ki ase?';
      case 'ne': return 'उहाँ तपाईंसँग कसरी नाता पर्नुहुन्छ?';
      case 'trp': return 'Nini bai bini bwsang thum ma?';
      case 'hi': return 'इनका आपके साथ क्या रिश्ता है?';
      case 'en':
      default: return 'How is this person related to you?';
    }
  }

  static String whenDidYouLastSeePerson(String code) {
    switch (code) {
      case 'as': return 'আপুনি এওঁক শেষবাৰ কেতিয়া দেখিছিল?';
      case 'bn': return 'আপনি এঁর সাথে শেষ কবে দেখা করেছিলেন?';
      case 'brx': return 'नोंथाङा बिखौ जोबथारनाय माब्ला नुदोंमोन?';
      case 'grt': return 'Ia mandeko nang·a bon·kame basako nikachim?';
      case 'kha': return 'Mynno phi la iohi khadduh ia une?';
      case 'lus': return 'He mi hi engtikah nge i hmuh hnuhnun ber?';
      case 'mni': return 'অদোম্না মীওই অসি কন্দা অরোইবা ওইনা উখিবগে?';
      case 'nag': return 'Apuni eya manu ke sesh te ketiya lok paise?';
      case 'ne': return 'तपाईंले उहाँलाई पछिल्लो पटक कहिले देख्नुभएको थियो?';
      case 'trp': return 'Nwng bino sanmaro thum ma?';
      case 'hi': return 'आपने इन्हें आखिरी बार कब देखा था?';
      case 'en':
      default: return 'When did you last see this person?';
    }
  }

  // ── Lamps Festival Game ────────────────────────────────────────────────────

  static String watchLampsLightUp(String code) {
    switch (code) {
      case 'as': return 'চাকিবোৰ জ্বলি উঠা চাওক...';
      case 'bn': return 'প্রদীপগুলো জ্বলে ওঠা দেখুন...';
      case 'brx': return 'साखिफोरा जोंनायखौ नाय...';
      case 'grt': return 'Chakrang rokamako nibo...';
      case 'kha': return 'Peit ia ki sharak ba kin tyngshain...';
      case 'lus': return 'Khawnvartete a lo eng kual lai hi lo en rawh...';
      case 'mni': return 'থাওমৈনা চাকপা য়েংবিয়ু...';
      case 'nag': return 'Bati jolaise sa thakibi...';
      case 'ne': return 'बत्तीहरू बलेको हेर्नुहोस्...';
      case 'trp': return 'Batirwngno barmo nai di...';
      case 'hi': return 'दीयों को जलते हुए देखें...';
      case 'en':
      default: return 'Watch the lamps light up...';
    }
  }

  static String tapLampsReverseOrder(String code) {
    switch (code) {
      case 'as': return 'এতিয়া ওলোটা ক্ৰমত টিপক';
      case 'bn': return 'এখন বিপরীত ক্রমে চাপুন';
      case 'brx': return 'दानो उल्था फारियै थु';
      case 'grt': return 'Da·o ulta sulsul tike bo';
      case 'kha': return 'Kyntiew pynban da kaba khongpong';
      case 'lus': return 'A letling zawngin hmet leh rawh le';
      case 'mni': return 'হৌজিক ওনথোক্না নম্বিয়ু';
      case 'nag': return 'Etiya ulta hisap te tap koribi';
      case 'ne': return 'अब उल्टो क्रममा थिच्नुहोस्';
      case 'trp': return 'Tabuk ulta kwlai khai te di';
      case 'hi': return 'अब उल्टे क्रम में टैप करें';
      case 'en':
      default: return 'Now tap them in REVERSE order';
    }
  }

  static String tapLampsSameOrder(String code) {
    switch (code) {
      case 'as': return 'এতিয়া একে ক্ৰমত টিপক';
      case 'bn': return 'এখন একই ক্রমে চাপুন';
      case 'brx': return 'दानो एखे फारियै थु';
      case 'grt': return 'Da·o apsan sulsul tike bo';
      case 'kha': return 'Kyntiew kumjuh kumba la paw';
      case 'lus': return 'A hmaa a en dan indawt chiah khan hmet rawh';
      case 'mni': return 'হৌজিক চপ মান্নবা মতৌদা নম্বিয়ু';
      case 'nag': return 'Etiya eki hisap te tap koribi';
      case 'ne': return 'अब उस्तै क्रममा थिच्नुहोस्';
      case 'trp': return 'Tabuk khoroksa kwlai khai te di';
      case 'hi': return 'अब उसी क्रम में टैप करें';
      case 'en':
      default: return 'Now tap them in the same order';
    }
  }

  static String wellDone(String code) {
    switch (code) {
      case 'as': return 'খুব ভাল!';
      case 'bn': return 'খুব ভালো!';
      case 'brx': return 'मोजां जाबाय!';
      case 'grt': return 'Namgipa kam!';
      case 'kha': return 'Khublei shibun!';
      case 'lus': return 'I ti tha lutuk e!';
      case 'mni': return 'য়াম্না ফরে!';
      case 'nag': return 'Bhal hoise!';
      case 'ne': return 'धेरै राम्रो!';
      case 'trp': return 'Kaham wngkha!';
      case 'hi': return 'शाबाश!';
      case 'en':
      default: return 'Well done!';
    }
  }

  // ── Sort Harvest Game ──────────────────────────────────────────────────────

  static String placeItemWhereBelongs(String code) {
    switch (code) {
      case 'as': return 'এই বস্তুটো সঠিক ঠাইত থওক:';
      case 'bn': return 'এই জিনিসটি সঠিক জায়গায় রাখুন:';
      case 'brx': return 'बे बेसादखौ थिक जायगायाव दोन:';
      case 'grt': return 'Ia bostuko kragipa biapo donbo:';
      case 'kha': return 'Buh ia kane ka tiar ha kaba iadei:';
      case 'lus': return 'He thil hi a awmna tur hmunah dah rawh:';
      case 'mni': return 'পোৎলম অসি অচুম্বা মফমদা থম্বিয়ু:';
      case 'nag': return 'Eya bhal jaga te thobole lage:';
      case 'ne': return 'यो वस्तुलाई मिल्ने ठाउँमा राख्नुहोस्:';
      case 'trp': return 'O bostuno thik jaygao ton di:';
      case 'hi': return 'इस चीज़ को सही जगह पर रखें:';
      case 'en':
      default: return 'Place this item where it belongs:';
    }
  }

  // ── Name Harvest Game ──────────────────────────────────────────────────────

  static String nameAllCategoryPrompt(String code, String categoryLabel) {
    switch (code) {
      case 'as': return 'আপুনি মনত পৰা সকলো $categoryLabel ৰ নাম কওক:';
      case 'bn': return 'আপনার মনে পড়া সব $categoryLabel-এর নাম বলুন:';
      case 'brx': return 'नोंथांनि गोसोखांनाय गासै $categoryLabel नि मुंखौ बुं:';
      case 'grt': return 'Gisik ra·atgipa pilak $categoryLabel-ni bimingko aganbo:';
      case 'kha': return 'Kumno phi kynmaw ia ki kyrteng $categoryLabel:';
      case 'lus': return 'I hriat chhuah theih ang ang $categoryLabel te chu han sawi teh:';
      case 'mni': return 'অদোম্না নীংশিংবা ঙম্বা $categoryLabel পুম্নমকপু মমিং থোঙ্কু:';
      case 'nag': return 'Apuni mon te thaka sob $categoryLabel laga naam kobi:';
      case 'ne': return 'तपाईंले सम्झनुभएको सबै $categoryLabel को नाम भन्नुहोस्:';
      case 'trp': return 'Nini goso tongnai $categoryLabel ni mungno sa di:';
      case 'hi': return 'आपको याद आने वाले सभी $categoryLabel के नाम बताएं:';
      case 'en':
      default: return 'Name all the $categoryLabel you can think of:';
    }
  }

  static String tapToSpeak(String code) {
    switch (code) {
      case 'as': return 'কবলৈ টিপক';
      case 'bn': return 'বলতে চাপুন';
      case 'brx': return 'बुंनो थु';
      case 'grt': return 'Aganchinanina tike bo';
      case 'kha': return 'Kyntiew ban kren';
      case 'lus': return 'Sawi turin hmet rawh';
      case 'mni': return 'ঙাংনবা নম্বীয়ু';
      case 'nag': return 'Kotha kobole tap koribi';
      case 'ne': return 'बोल्न थिच्नुहोस्';
      case 'trp': return 'Sa na te di';
      case 'hi': return 'बोलने के लिए टैप करें';
      case 'en':
      default: return 'Tap to Speak';
    }
  }

  static String finish(String code) {
    switch (code) {
      case 'as': return 'সম্পূৰ্ণ';
      case 'bn': return 'শেষ';
      case 'brx': return 'जोबबाय';
      case 'grt': return 'Matchotaha';
      case 'kha': return 'La dep';
      case 'lus': return 'Zo ta';
      case 'mni': return 'লোইরে';
      case 'nag': return 'Khotom';
      case 'ne': return 'सकियो';
      case 'trp': return 'Paijakha';
      case 'hi': return 'पूरा हुआ';
      case 'en':
      default: return 'Finish';
    }
  }

  // ── Sounds of Home Game ────────────────────────────────────────────────────

  static String listenForBird(String code) {
    switch (code) {
      case 'as': return 'চৰাইটোৰ মাত শুনক';
      case 'bn': return 'পাখির ডাক শুনুন';
      case 'brx': return 'दाउनि रावखौ खोनासं';
      case 'grt': return 'Do·oni ku·rangko kna·timbo';
      case 'kha': return 'Sngap ia ka sim';
      case 'lus': return 'Sava aw ngaithla rawh';
      case 'mni': return 'উচেক্কী খোঞ্জেল তাবিয়ু';
      case 'nag': return 'Chorai laga aawaj hunibi';
      case 'ne': return 'चराको आवाज सुन्नुहोस्';
      case 'trp': return 'Tokni khorang khna di';
      case 'hi': return 'पक्षी की आवाज़ सुनें';
      case 'en':
      default: return 'Listen for the bird';
    }
  }

  static String soundsHomeIntro(String code) {
    switch (code) {
      case 'as': return 'আপুনি গাঁৱৰ শব্দ শুনিব। প্ৰতিবাৰ চৰাইৰ মাত শুনিলে ঢোলটোত টিপক।';
      case 'bn': return 'আপনি গ্রামের শব্দ শুনতে পাবেন। প্রতিবার পাখির ডাক শুনলে ঢোলে চাপুন।';
      case 'brx': return 'गामिनि रावफोरखौ खोनागोन। दाउनि राव खोनायब्लानो दामाव थु।';
      case 'grt': return 'Nang·a songchini ku·rangrangko knagen. Do·oni ku·rangko knagipa kario damako dokbo.';
      case 'kha': return 'Phin iohsngew ia ki sur na nongkyndong. Kyntiew ia ka nakra haba phi iohsngew ia ka sim.';
      case 'lus': return 'Khua aṭanga thawm ri hrang hrang i hria ang. Sava thlawk thawm i hriat apiangin khingah hian hmet rawh.';
      case 'mni': return 'অদোম্না খুঙ্গংগী খোঞ্জেল তাগনি। উচেক্কী খোঞ্জেল তারিবমখৈ পুং নম্বীয়ু।';
      case 'nag': return 'Apuni bosti laga aawaj hunibo. Chorai laga aawaj paile dhol te maribi.';
      case 'ne': return 'तपाईंले गाउँको आवाज सुन्नुहुनेछ। चराको आवाज सुन्दा हरेक पटक ढोलमा थिच्नुहोस्।';
      case 'trp': return 'Nwng nokhorni khorang khnanai. Tokni khorang khnabaio khamte te di.';
      case 'hi': return 'आप गाँव की आवाज़ें सुनेंगे। हर बार पक्षी की आवाज़ सुनने पर ढोल पर टैप करें।';
      case 'en':
      default: return 'You will hear sounds from the village. Tap the drum each time you hear the bird.';
    }
  }

  static String hearTheBird(String code) {
    switch (code) {
      case 'as': return 'চৰাইটোৰ মাত শুনক';
      case 'bn': return 'পাখির ডাক শুনুন';
      case 'brx': return 'दाउनि राव खोनासं';
      case 'grt': return 'Do·oni ku·rangko kna·bo';
      case 'kha': return 'Sngap ia ka sim';
      case 'lus': return 'Sava chu ngaithla rawh';
      case 'mni': return 'উচেক খোঞ্জেল তাবিয়ু';
      case 'nag': return 'Chorai ke hunibi';
      case 'ne': return 'चराको आवाज सुन्नुहोस्';
      case 'trp': return 'Tokno khna di';
      case 'hi': return 'पक्षी को सुनें';
      case 'en':
      default: return 'Hear the bird';
    }
  }

  static String start(String code) {
    switch (code) {
      case 'as': return 'আৰম্ভ কৰক';
      case 'bn': return 'শুরু করুন';
      case 'brx': return 'जागाय';
      case 'grt': return 'A·bachengbo';
      case 'kha': return 'Sdang';
      case 'lus': return 'Tan rawh le';
      case 'mni': return 'হৌবিয়ু';
      case 'nag': return 'Suru koribi';
      case 'ne': return 'सुरु गर्नुहोस्';
      case 'trp': return 'Cheng di';
      case 'hi': return 'शुरू करें';
      case 'en':
      default: return 'Start';
    }
  }

  static String tapDrumWhenHearBird(String code) {
    switch (code) {
      case 'as': return 'চৰাইৰ মাত শুনিলে ঢোলটোত টিপক';
      case 'bn': return 'পাখির ডাক শুনলে ঢোলে চাপুন';
      case 'brx': return 'दाउनि राव खोनाब्ला दामाव थु';
      case 'grt': return 'Do·oni ku·rangko kna·o damako dokbo';
      case 'kha': return 'Kyntiew ia ka nakra haba phi iohsngew ia ka sim';
      case 'lus': return 'Sava aw i hriat veleh khingah hian hmet rawh';
      case 'mni': return 'উচেক্কী খোঞ্জেল তারকপা মতমদা পুং নম্বীয়ু';
      case 'nag': return 'Chorai laga aawaj paile dhol te maribi';
      case 'ne': return 'चराको आवाज सुनेपछि ढोलमा थिच्नुहोस्';
      case 'trp': return 'Tokni khorang khnao khamno te di';
      case 'hi': return 'पक्षी की आवाज़ सुनने पर ढोल पर टैप करें';
      case 'en':
      default: return 'Tap the drum when you hear the bird';
    }
  }

  // ── Trace Path Game ────────────────────────────────────────────────────────

  static String tracePathSequential(String code) {
    switch (code) {
      case 'as': return 'ক্ৰম অনুসৰি শিলবোৰত টিপক: ১, ২, ৩...';
      case 'bn': return 'ক্রম অনুসারে পাথরে চাপুন: ১, ২, ৩...';
      case 'brx': return 'फारियै अन्थाइफोराव थु: १, २, ३...';
      case 'grt': return 'Rongchiterangko sulsul tike bo: 1, 2, 3...';
      case 'kha': return 'Kyntiew ia ki maw kat kum ka jingbuh: 1, 2, 3...';
      case 'lus': return 'Lungte hi indawtin hmet rawh: 1, 2, 3...';
      case 'mni': return 'নংসিলনা নুংদা নম্বিয়ু: ১, ২, ৩...';
      case 'nag': return 'Pathor khan ke line te tap koribi: 1, 2, 3...';
      case 'ne': return 'क्रमबद्ध रूपमा ढुङ्गाहरूमा थिच्नुहोस्: १, २, ३...';
      case 'trp': return 'Hathaino sulsul te di: 1, 2, 3...';
      case 'hi': return 'क्रम अनुसार पत्थरों पर टैप करें: 1, 2, 3...';
      case 'en':
      default: return 'Tap the stones in order: 1, 2, 3...';
    }
  }

  static String tracePathAlternating(String code) {
    switch (code) {
      case 'as': return 'সালসলনিকৈ টিপক: ১, ক, ২, খ...';
      case 'bn': return 'পর্যায়ক্রমে চাপুন: ১, ক, ২, খ...';
      case 'brx': return 'सोलाय-सोलौयै थु: १, A, २, B...';
      case 'grt': return 'Dingtang dingtang tike bo: 1, A, 2, B...';
      case 'kha': return 'Kyntiew mar kylliang: 1, A, 2, B...';
      case 'lus': return 'Inthlak kualin hmet rawh: 1, A, 2, B...';
      case 'mni': return 'অমগী মতুংদা অমা নম্বিয়ু: ১, A, ২, B...';
      case 'nag': return 'Alternating te tap koribi: 1, A, 2, B...';
      case 'ne': return 'पालैपालो थिच्नुहोस्: १, A, २, B...';
      case 'trp': return 'Khoroksa khoroksa te di: 1, A, 2, B...';
      case 'hi': return 'एक के बाद एक बदल कर टैप करें: 1, A, 2, B...';
      case 'en':
      default: return 'Tap alternating: 1, A, 2, B, 3, C...';
    }
  }

  // ── Weaving Patterns Game ──────────────────────────────────────────────────

  static String whichPatternMatches(String code) {
    switch (code) {
      case 'as': return 'কোনটো নক্সাৰ সৈতে মিলে?';
      case 'bn': return 'কোন নকশার সাথে মিল আছে?';
      case 'brx': return 'बबे महरा जोरा जायो?';
      case 'grt': return 'Badia gita nika melienga?';
      case 'kha': return 'Kano ka rukom kaba iahap?';
      case 'lus': return 'A eng zawk hi nge inmil le?';
      case 'mni': return 'করম্বা শক্তমগা চুনরে?';
      case 'nag': return 'Konto pattern mile ase?';
      case 'ne': return 'कुन ढाँचा मिल्छ?';
      case 'trp': return 'Bobi daag manjakha?';
      case 'hi': return 'कौन सा डिज़ाइन मिलता है?';
      case 'en':
      default: return 'Which pattern matches?';
    }
  }

  // ── My Day Game ────────────────────────────────────────────────────────────

  static String putInOrderMorningToNight(String code) {
    switch (code) {
      case 'as': return 'ৰাতিপুৱাৰ পৰা নিশাপৰ্যন্ত ক্ৰমত সজাওক:';
      case 'bn': return 'সকাল থেকে রাত পর্যন্ত ক্রমানুসারে সাজান:';
      case 'brx': return 'फुंनिफ्राय हरसिम फारियै साजाय:';
      case 'grt': return 'Pringoni walona sulsul matchotbo:';
      case 'kha': return 'Pynbeit na ka step sha ka miet:';
      case 'lus': return 'Zing aṭanga zan thlengin indawtin dah rawh:';
      case 'mni': return 'অয়ুক্তগী অহিংসুবা ফাওবদা মথং-মনাও শেমবিয়ু:';
      case 'nag': return 'Phujor para raat tak line te lagabi:';
      case 'ne': return 'बिहानदेखि रातिसम्मको क्रम मिलाउनुहोस्:';
      case 'trp': return 'Salphungni horni sulsul khai ton di:';
      case 'hi': return 'सुबह से रात तक क्रम में लगाएं:';
      case 'en':
      default: return 'Put these in order, from morning to night:';
    }
  }

  static String done(String code) {
    switch (code) {
      case 'as': return 'সম্পন্ন';
      case 'bn': return 'সম্পন্ন';
      case 'brx': return 'जाबाय';
      case 'grt': return 'Matchotaha';
      case 'kha': return 'La dep';
      case 'lus': return 'Zo ta';
      case 'mni': return 'লোইরে';
      case 'nag': return 'Hoise';
      case 'ne': return 'सकियो';
      case 'trp': return 'Paijakha';
      case 'hi': return 'हो गया';
      case 'en':
      default: return 'Done';
    }
  }

  static String typeAnItem(String code) {
    switch (code) {
      case 'as': return 'এটা বস্তুৰ নাম লিখক...';
      case 'bn': return 'একটি জিনিসের নাম লিখুন...';
      case 'brx': return 'मोनसे बेसादनि मुं लिर...';
      case 'grt': return 'Bostuni biming se·bo...';
      case 'kha': return 'Thoh ka kyrteng tiar...';
      case 'lus': return 'Thil hming ziak rawh...';
      case 'mni': return 'পোৎলম অমগী মমিং ইরু...';
      case 'nag': return 'Eman laga naam likhibi...';
      case 'ne': return 'एउटा वस्तुको नाम लेख्नुहोस्...';
      case 'trp': return 'Khoroksa bostuni mung soi di...';
      case 'hi': return 'एक चीज़ का नाम लिखें...';
      case 'en':
      default: return 'Type an item...';
    }
  }

  static String itemsNamed(String code, int count) {
    switch (code) {
      case 'as': return '$count টা বস্তুৰ নাম কোৱা হ\'ল';
      case 'bn': return '$count টি জিনিসের নাম বলা হয়েছে';
      case 'brx': return '$count मोन बेसादनि मुं बुंबाय';
      case 'grt': return 'Bostu $count-ko mingaha';
      case 'kha': return '$count tylli ki tiar la thoh';
      case 'lus': return 'Thil hming $count sawi a ni';
      case 'mni': return 'পোৎলম $count মমিং থোঙ্ক্রে';
      case 'nag': return '$count ta saman laga naam koise';
      case 'ne': return '$count वस्तुहरूको नाम भनियो';
      case 'trp': return '$count ta bostuni mung sajakkha';
      case 'hi': return '$count चीज़ों के नाम बताए गए';
      case 'en':
      default: return '$count items named';
    }
  }

  static String harvestCategory(String code, String category) {
    switch (category) {
      case 'vegetables':
        switch (code) {
          case 'as': return 'শাক-পাচলি';
          case 'bn': return 'শাকসবজি';
          case 'brx': return 'थासं-मेगं';
          case 'grt': return 'sam·bolrang';
          case 'kha': return 'ki jhur';
          case 'lus': return 'thlai';
          case 'mni': return 'হেন্দল-হৌদাবা';
          case 'nag': return 'sobji';
          case 'ne': return 'तरकारीहरू';
          case 'trp': return 'samung-chak';
          case 'hi': return 'सब्जियाँ';
          case 'en':
          default: return 'vegetables';
        }
      case 'fruits':
        switch (code) {
          case 'as': return 'ফল-মূল';
          case 'bn': return 'ফলমূল';
          case 'brx': return 'फिथाइ';
          case 'grt': return 'bite-bite';
          case 'kha': return 'ki soh';
          case 'lus': return 'thei';
          case 'mni': return 'হৈ-হৌ';
          case 'nag': return 'phol khan';
          case 'ne': return 'फलफूलहरू';
          case 'trp': return 'thailik-thai';
          case 'hi': return 'फल';
          case 'en':
          default: return 'fruits';
        }
      case 'animals':
        switch (code) {
          case 'as': return 'জীৱ-জন্তু';
          case 'bn': return 'পশুপাখি';
          case 'brx': return 'जुन्थाय';
          case 'grt': return 'matburang';
          case 'kha': return 'ki mrad';
          case 'lus': return 'ransa';
          case 'mni': return 'শান-থা';
          case 'nag': return 'janwar khan';
          case 'ne': return 'जनावरहरू';
          case 'trp': return 'mayung';
          case 'hi': return 'जानवर';
          case 'en':
          default: return 'animals';
        }
      case 'things_in_kitchen':
        switch (code) {
          case 'as': return 'ৰান্ধনিশালৰ বস্তু';
          case 'bn': return 'রান্নাঘরের জিনিস';
          case 'brx': return 'संखानि बेसाद';
          case 'grt': return 'song·chakani bosturang';
          case 'kha': return 'ki tiar shetja';
          case 'lus': return 'choka bungrua';
          case 'mni': return 'চাখুমগী পোৎলম';
          case 'nag': return 'kitchen laga saman';
          case 'ne': return 'भान्साका सामानहरू';
          case 'trp': return 'sungno toni bostu';
          case 'hi': return 'रसोई की चीजें';
          case 'en':
          default: return 'things in the kitchen';
        }
      case 'things_in_market':
        switch (code) {
          case 'as': return 'বজাৰৰ বস্তু';
          case 'bn': return 'বাজারের জিনিস';
          case 'brx': return 'हाटनि बेसाद';
          case 'grt': return 'bajarani bosturang';
          case 'kha': return 'ki tiar iew';
          case 'lus': return 'bazar bungrua';
          case 'mni': return 'কৈথেলগী পোৎলম';
          case 'nag': return 'bazar laga saman';
          case 'ne': return 'बजारका सामानहरू';
          case 'trp': return 'hati ni bostu';
          case 'hi': return 'बाज़ार की चीजें';
          case 'en':
          default: return 'things at the market';
        }
      case 'things_that_are_red':
        switch (code) {
          case 'as': return 'ৰঙা বস্তু';
          case 'bn': return 'লাল রঙের জিনিস';
          case 'brx': return 'गोजा बेसाद';
          case 'grt': return 'gitchak bosturang';
          case 'kha': return 'ki kiei kiei kiba saw';
          case 'lus': return 'thil sen';
          case 'mni': return 'অঙাংবা পোৎশক';
          case 'nag': return 'lal bostu khan';
          case 'ne': return 'राता चिजहरू';
          case 'trp': return 'kchak bostu';
          case 'hi': return 'लाल चीजें';
          case 'en':
          default: return 'things that are red';
        }
      case 'festival_foods':
        switch (code) {
          case 'as': return 'উৎসৱৰ খাদ্য';
          case 'bn': return 'উৎসবের খাবার';
          case 'brx': return 'फोराबनि जामुं';
          case 'grt': return 'maniani cha·anirang';
          case 'kha': return 'ki jingbam lehniam';
          case 'lus': return 'kut chaw';
          case 'mni': return 'কুহ্মৈগী চিঞ্জাক';
          case 'nag': return 'festival te khowa saman';
          case 'ne': return 'चाডपर्वका परिकारहरू';
          case 'trp': return 'bwisagu chaknai';
          case 'hi': return 'त्योहार के पकवान';
          case 'en':
          default: return 'festival foods';
        }
      case 'birds':
        switch (code) {
          case 'as': return 'চৰাই';
          case 'bn': return 'পাখি';
          case 'brx': return 'दाउ';
          case 'grt': return 'do·orang';
          case 'kha': return 'ki sim';
          case 'lus': return 'savate';
          case 'mni': return 'উচেকশিং';
          case 'nag': return 'chorai khan';
          case 'ne': return 'चराहरू';
          case 'trp': return 'tokrog';
          case 'hi': return 'पक्षी';
          case 'en':
          default: return 'birds';
        }
      default:
        return category;
    }
  }

  static String harvestMatLabel(String code, String mat) {
    switch (mat.toLowerCase()) {
      case 'vegetable':
      case 'vegetables':
        switch (code) {
          case 'as': return 'পাচলি';
          case 'bn': return 'সবজি';
          case 'brx': return 'मेगं';
          case 'grt': return 'sam·bol';
          case 'kha': return 'jhur';
          case 'lus': return 'thlai';
          case 'mni': return 'হেন্দল';
          case 'nag': return 'sobji';
          case 'ne': return 'तरकारी';
          case 'trp': return 'chak';
          case 'hi': return 'सब्जी';
          case 'en':
          default: return 'vegetable';
        }
      case 'fruit':
      case 'fruits':
        switch (code) {
          case 'as': return 'ফল';
          case 'bn': return 'ফল';
          case 'brx': return 'फिथाइ';
          case 'grt': return 'bite';
          case 'kha': return 'soh';
          case 'lus': return 'thei';
          case 'mni': return 'হৈ';
          case 'nag': return 'phol';
          case 'ne': return 'फलफूल';
          case 'trp': return 'thai';
          case 'hi': return 'फल';
          case 'en':
          default: return 'fruit';
        }
      case 'red':
        switch (code) {
          case 'as': return 'ৰঙা';
          case 'bn': return 'লাল';
          case 'brx': return 'गोजा';
          case 'grt': return 'gitchak';
          case 'kha': return 'saw';
          case 'lus': return 'sen';
          case 'mni': return 'অঙাংবা';
          case 'nag': return 'lal';
          case 'ne': return 'रातो';
          case 'trp': return 'kchak';
          case 'hi': return 'लाल';
          case 'en':
          default: return 'red';
        }
      case 'green':
        switch (code) {
          case 'as': return 'সেউজীয়া';
          case 'bn': return 'সবুজ';
          case 'brx': return 'गोथां';
          case 'grt': return 'tangsek';
          case 'kha': return 'jyrngam';
          case 'lus': return 'hring';
          case 'mni': return 'অশংবা';
          case 'nag': return 'sobuj';
          case 'ne': return 'हरियो';
          case 'trp': return 'ktang';
          case 'hi': return 'हरा';
          case 'en':
          default: return 'green';
        }
      case 'purple':
        switch (code) {
          case 'as': return 'বেঙুনীয়া';
          case 'bn': return 'বেগুনী';
          case 'brx': return 'जाम्बुलि';
          case 'grt': return 'begun';
          case 'kha': return 'sawbthuh';
          case 'lus': return 'sen duk';
          case 'mni': return 'হৈৰোম্পী';
          case 'nag': return 'baigania';
          case 'ne': return 'बैजनी';
          case 'trp': return 'kchak-som';
          case 'hi': return 'बैंगनी';
          case 'en':
          default: return 'purple';
        }
      case 'yellow':
        switch (code) {
          case 'as': return 'হালধীয়া';
          case 'bn': return 'হলুদ';
          case 'brx': return 'गोमो';
          case 'grt': return 'gimik';
          case 'kha': return 'stem';
          case 'lus': return 'eng';
          case 'mni': return 'নপীকপা';
          case 'nag': return 'holod';
          case 'ne': return 'पहेँलो';
          case 'trp': return 'bwsang';
          case 'hi': return 'पीला';
          case 'en':
          default: return 'yellow';
        }
      case 'small':
        switch (code) {
          case 'as': return 'সৰু';
          case 'bn': return 'ছোট';
          case 'brx': return 'फिसा';
          case 'grt': return 'chon·gipa';
          case 'kha': return 'ritrud';
          case 'lus': return 'te';
          case 'mni': return 'অপীম্বা';
          case 'nag': return 'choto';
          case 'ne': return 'सानो';
          case 'trp': return 'kotor ma';
          case 'hi': return 'छोटा';
          case 'en':
          default: return 'small';
        }
      case 'large':
        switch (code) {
          case 'as': return 'ডাঙৰ';
          case 'bn': return 'বড়';
          case 'brx': return 'गेदेर';
          case 'grt': return 'dal·gipa';
          case 'kha': return 'heh';
          case 'lus': return 'lian';
          case 'mni': return 'অচৌবা';
          case 'nag': return 'dangor';
          case 'ne': return 'ठूलो';
          case 'trp': return 'kwtwr';
          case 'hi': return 'बड़ा';
          case 'en':
          default: return 'large';
        }
      default:
        return mat.replaceAll('_', ' ');
    }
  }

  static String drumTap(String code) {
    switch (code) {
      case 'as': return 'টিপক';
      case 'bn': return 'চাপুন';
      case 'brx': return 'थु';
      case 'grt': return 'Tike bo';
      case 'kha': return 'Kyntiew';
      case 'lus': return 'Hmet rawh';
      case 'mni': return 'নম্বীয়ু';
      case 'nag': return 'Tap koribi';
      case 'ne': return 'थिच्नुहोस्';
      case 'trp': return 'Te di';
      case 'hi': return 'टैप करें';
      case 'en':
      default: return 'Tap';
    }
  }

  static String soundLabel(String code, String soundId) {
    switch (soundId) {
      case 'rain':
        switch (code) {
          case 'as': return 'বৰষুণ';
          case 'bn': return 'বৃষ্টি';
          case 'brx': return 'अखा';
          case 'grt': return 'Mikka';
          case 'kha': return 'Slap';
          case 'lus': return 'Ruah';
          case 'mni': return 'নোং';
          case 'nag': return 'Boroxun';
          case 'ne': return 'वर्षा';
          case 'trp': return 'Nokhabor';
          case 'hi': return 'बारिश';
          case 'en':
          default: return 'Rain';
        }
      case 'wind':
        switch (code) {
          case 'as': return 'বতাহ';
          case 'bn': return 'বাতাস';
          case 'brx': return 'बार';
          case 'grt': return 'Balwa';
          case 'kha': return 'Lyer';
          case 'lus': return 'Thli';
          case 'mni': return 'নুংশিৎ';
          case 'nag': return 'Hawa';
          case 'ne': return 'हावा';
          case 'trp': return 'Nokhor';
          case 'hi': return 'हवा';
          case 'en':
          default: return 'Wind';
        }
      case 'cow':
        switch (code) {
          case 'as': return 'গৰু';
          case 'bn': return 'গরু';
          case 'brx': return 'मोसौ';
          case 'grt': return 'Matchu';
          case 'kha': return 'Masi';
          case 'lus': return 'Bawng';
          case 'mni': return 'শন';
          case 'nag': return 'Goru';
          case 'ne': return 'गाई';
          case 'trp': return 'Mwsou';
          case 'hi': return 'गाय';
          case 'en':
          default: return 'Cow';
        }
      case 'dog':
        switch (code) {
          case 'as': return 'কুকুৰ';
          case 'bn': return 'কুকুর';
          case 'brx': return 'सैमा';
          case 'grt': return 'Achak';
          case 'kha': return 'Ksew';
          case 'lus': return 'Ui';
          case 'mni': return 'হুই';
          case 'nag': return 'Kukur';
          case 'ne': return 'कुकुर';
          case 'trp': return 'Kui';
          case 'hi': return 'कुत्ता';
          case 'en':
          default: return 'Dog';
        }
      case 'river':
        switch (code) {
          case 'as': return 'নৈ';
          case 'bn': return 'নদী';
          case 'brx': return 'दैसा';
          case 'grt': return 'Chibima';
          case 'kha': return 'Wah';
          case 'lus': return 'Lui';
          case 'mni': return 'তুৰেল';
          case 'nag': return 'Nodi';
          case 'ne': return 'नदी';
          case 'trp': return 'Twima';
          case 'hi': return 'नदी';
          case 'en':
          default: return 'River';
        }
      case 'thunder':
        switch (code) {
          case 'as': return 'মেঘৰ গৰ্জন';
          case 'bn': return 'বজ্রপাত';
          case 'brx': return 'अखाख्लाय';
          case 'grt': return 'Mikkabang·a';
          case 'kha': return 'Pyrthat';
          case 'lus': return 'Khawpui';
          case 'mni': return 'নোংথক';
          case 'nag': return 'Bijuli';
          case 'ne': return 'चट्याङ';
          case 'trp': return 'Nokhabor-khna';
          case 'hi': return 'बादल';
          case 'en':
          default: return 'Thunder';
        }
      case 'cricket':
        switch (code) {
          case 'as': return 'উঁহ';
          case 'bn': return 'ঝিঝি পোকা';
          case 'brx': return 'जिंजि';
          case 'grt': return 'Gong·grak';
          case 'kha': return 'Kynphad';
          case 'lus': return 'Chhimbuk';
          case 'mni': return 'পোং-অং';
          case 'nag': return 'Jhingur';
          case 'ne': return 'झ्याउँकिरी';
          case 'trp': return 'Chichiri';
          case 'hi': return 'झींगुर';
          case 'en':
          default: return 'Cricket';
        }
      case 'bell':
        switch (code) {
          case 'as': return 'ঘণ্টা';
          case 'bn': return 'ঘণ্টা';
          case 'brx': return 'घन्टा';
          case 'grt': return 'Ganta';
          case 'kha': return 'Ka baje';
          case 'lus': return 'Dar';
          case 'mni': return 'ঘণ্টা';
          case 'nag': return 'Ghanta';
          case 'ne': return 'घण्टी';
          case 'trp': return 'Ghanta';
          case 'hi': return 'घंटी';
          case 'en':
          default: return 'Bell';
        }
      case 'rooster':
        switch (code) {
          case 'as': return 'কুকুৰা';
          case 'bn': return 'মোরগ';
          case 'brx': return 'दाउज्ला';
          case 'grt': return 'Do·bipa';
          case 'kha': return 'Syiar ryngkuh';
          case 'lus': return 'Arpa';
          case 'mni': return 'য়েনবা';
          case 'nag': return 'Kukura';
          case 'ne': return 'भाले';
          case 'trp': return 'Tok-sa';
          case 'hi': return 'मुर्गा';
          case 'en':
          default: return 'Rooster';
        }
      case 'temple_bell':
        switch (code) {
          case 'as': return 'মন্দিৰৰ ঘণ্টা';
          case 'bn': return 'মন্দিরের ঘণ্টা';
          case 'brx': return 'थाननि घन्टा';
          case 'grt': return 'Giljani ganta';
          case 'kha': return 'Ka baje mane';
          case 'lus': return 'Biakin dar';
          case 'mni': return 'লাইশংগী ঘণ্টা';
          case 'nag': return 'Mandir laga ghanta';
          case 'ne': return 'मन्दिरको घण्टी';
          case 'trp': return 'Mandirni ghanta';
          case 'hi': return 'मंदिर की घंटी';
          case 'en':
          default: return 'Temple bell';
        }
      case 'bird':
        switch (code) {
          case 'as': return 'চৰাই';
          case 'bn': return 'পাখি';
          case 'brx': return 'दाउ';
          case 'grt': return 'Do·o';
          case 'kha': return 'Sim';
          case 'lus': return 'Sava';
          case 'mni': return 'উচেক';
          case 'nag': return 'Chorai';
          case 'ne': return 'चरा';
          case 'trp': return 'Tok';
          case 'hi': return 'पक्षी';
          case 'en':
          default: return 'Bird';
        }
      default:
        return soundId;
    }
  }

  static String orientationQuestion(String code, String questionId, {String? defaultText}) {
    switch (questionId) {
      case 'season':
        switch (code) {
          case 'as': return 'এতিয়া কি ঋতু চলিছে?';
          case 'bn': return 'এখন কোন ঋতু চলছে?';
          case 'brx': return 'दा बे समाव मा बोथोरा चलिदों?';
          case 'grt': return 'Da·alo bano bilsi gita oenga?';
          case 'kha': return 'Kano ka aiom kaba long mynta?';
          case 'lus': return 'Tunah eng sik nge ni?';
          case 'mni': return 'হৌজিক করম্বা ঋতুনি?';
          case 'nag': return 'Etiya ki ritu ase?';
          case 'ne': return 'अहिले कुन ऋतु हो?';
          case 'trp': return 'Tini bobi bisi phuh?';
          case 'hi': return 'अभी कौन सा मौसम है?';
          case 'en':
          default: return 'What season is it now?';
        }
      case 'day_of_week':
        switch (code) {
          case 'as': return 'আজি কি বাৰ?';
          case 'bn': return 'আজ কী বার?';
          case 'brx': return 'दिनै मा बार?';
          case 'grt': return 'Da·alo badia sal ong·a?';
          case 'kha': return 'Kano ka sngi kaba long mynta?';
          case 'lus': return 'Vawiin hi eng ni nge?';
          case 'mni': return 'ঙসি করম্বা নুমিৎনো?';
          case 'nag': return 'Aji ki bar ase?';
          case 'ne': return 'आज के बार हो?';
          case 'trp': return 'Tini bobi sal?';
          case 'hi': return 'आज कौन सा दिन है?';
          case 'en':
          default: return 'What day of the week is it?';
        }
      case 'after_lunch':
        switch (code) {
          case 'as': return 'দুপৰীয়া খোৱাৰ পিছত সাধাৰণতে কি কৰে?';
          case 'bn': return 'দুপুরের খাবারের পর সাধারণত আপনি কী করেন?';
          case 'brx': return 'सानजायनि जामुंनि उनाव नोंथाङा मा खालामो?';
          case 'grt': return 'Mijilsi cha·manba nang·a mai daka?';
          case 'kha': return 'Kaei kaba phi ju leh ynda la dep bam ja sngi?';
          case 'lus': return 'Chhuna chaw ei hnuah enge i tih ṭhin?';
          case 'mni': return 'নুংথিল চাবা লোইবা মতুংদা অদোম্না করী তৌই?';
          case 'nag': return 'Dupur khowa piche te apuni ki kore?';
          case 'ne': return 'दिउँसोको खानापछि तपाईं प्रायः के गर्नुहुन्छ?';
          case 'trp': return 'Salphung chamanba nwng tmo khai?';
          case 'hi': return 'दोपहर के खाने के बाद आप आमतौर पर क्या करते हैं?';
          case 'en':
          default: return 'What do you usually do after lunch?';
        }
      case 'before_dinner':
        switch (code) {
          case 'as': return 'ৰাতি খোৱাৰ আগত সাধাৰণতে কি কৰে?';
          case 'bn': return 'রাতের খাবারের আগে সাধারণত আপনি কী করেন?';
          case 'brx': return 'हरनि जामुंनि सिगां नोंथाङा मा खालामो?';
          case 'grt': return 'Miatam cha·china skang nang·a mai daka?';
          case 'kha': return 'Kaei kaba phi ju leh shuwa ban bam ja miet?';
          case 'lus': return 'Zana chaw ei hmain enge i tih ṭhin?';
          case 'mni': return 'অহিংশাং চাদ্রিঙৈদা অদোম্না করী তৌই?';
          case 'nag': return 'Raat khowa aage te apuni ki kore?';
          case 'ne': return 'रातिको खाना खानुअघि तपाईं प्रायः के गर्नुहुन्छ?';
          case 'trp': return 'Hor chana skang nwng tmo khai?';
          case 'hi': return 'रात के खाने से पहले आप आमतौर पर क्या करते हैं?';
          case 'en':
          default: return 'What do you usually do before dinner?';
        }
      case 'month':
        switch (code) {
          case 'as': return 'এতিয়া কি মাহ?';
          case 'bn': return 'এখন কোন মাস?';
          case 'brx': return 'दा मा दान?';
          case 'grt': return 'Da·alo bano jason ong·a?';
          case 'kha': return 'Kano ka bnai kaba long mynta?';
          case 'lus': return 'Tunah eng thla nge ni?';
          case 'mni': return 'হৌজিক করম্বা থাগী মতম্নো?';
          case 'nag': return 'Etiya ki maah ase?';
          case 'ne': return 'अहिले कुन महिना हो?';
          case 'trp': return 'Tini bobi tal?';
          case 'hi': return 'अभी कौन सा महीना है?';
          case 'en':
          default: return 'What month is it?';
        }
      case 'date':
        switch (code) {
          case 'as': return 'আজি কি তাৰিখ?';
          case 'bn': return 'আজ কত তারিখ?';
          case 'brx': return 'दिनै मा अक्ट\', तारीख?';
          case 'grt': return 'Da·al badia tariko ong·a?';
          case 'kha': return 'Kano ka tarik mynta?';
          case 'lus': return 'Vawiin hi ni engzat nge?';
          case 'mni': return 'ঙসিগী তারিখ করীনো?';
          case 'nag': return 'Aji ki tarik ase?';
          case 'ne': return 'आज कति गते / तारिख हो?';
          case 'trp': return 'Tini bobi tarik?';
          case 'hi': return 'आज क्या तारीख है?';
          case 'en':
          default: return 'What is today\'s date?';
        }
      default:
        return defaultText ?? questionId;
    }
  }

  static String seasonName(String code, String season) {
    switch (season.toLowerCase()) {
      case 'winter':
        switch (code) {
          case 'as': return 'শীতকাল';
          case 'bn': return 'শীতকাল';
          case 'brx': return 'गोजां बोथोर';
          case 'grt': return 'Sin·kari';
          case 'kha': return 'Tlang';
          case 'lus': return 'Thlasik';
          case 'mni': return 'নিংথমথা';
          case 'nag': return 'Thanda din';
          case 'ne': return 'हिउँद / जाडो';
          case 'trp': return 'Kchang bisi';
          case 'hi': return 'सर्दी';
          case 'en':
          default: return 'Winter';
        }
      case 'spring':
        switch (code) {
          case 'as': return 'বসন্তকাল';
          case 'bn': return 'বসন্তকাল';
          case 'brx': return 'बैसागु बोथोर';
          case 'grt': return 'Gitchak kari';
          case 'kha': return 'Pyrem';
          case 'lus': return 'Ṭhal';
          case 'mni': return 'য়েন্থা';
          case 'nag': return 'Bohag din';
          case 'ne': return 'वसन्त';
          case 'trp': return 'Bwisagu bisi';
          case 'hi': return 'बसंत';
          case 'en':
          default: return 'Spring';
        }
      case 'summer':
        switch (code) {
          case 'as': return 'গ্ৰীষ্মকাল';
          case 'bn': return 'গ্রীষ্মকাল';
          case 'brx': return 'दुंथाय बोथोर';
          case 'grt': return 'Ding·kari';
          case 'kha': return 'Lypun';
          case 'lus': return 'Nipui';
          case 'mni': return 'কালেনথা';
          case 'nag': return 'Garam din';
          case 'ne': return 'गर्मी';
          case 'trp': return 'Ksa bisi';
          case 'hi': return 'गर्मी';
          case 'en':
          default: return 'Summer';
        }
      case 'monsoon':
        switch (code) {
          case 'as': return 'বৰ্ষাকাল';
          case 'bn': return 'বর্ষাকাল';
          case 'brx': return 'अखा बोथोर';
          case 'grt': return 'Mikka kari';
          case 'kha': return 'Slap';
          case 'lus': return 'Fuasik';
          case 'mni': return 'নোংজুথা';
          case 'nag': return 'Boroxun din';
          case 'ne': return 'वर्षा';
          case 'trp': return 'Wathop bisi';
          case 'hi': return 'बरसात';
          case 'en':
          default: return 'Monsoon';
        }
      case 'autumn':
        switch (code) {
          case 'as': return 'শৰৎকাল';
          case 'bn': return 'শরৎকাল';
          case 'brx': return 'सोरद बोथोर';
          case 'grt': return 'Bilsi jok·a kari';
          case 'kha': return 'Synrai';
          case 'lus': return 'Favang';
          case 'mni': return 'মেরাথা';
          case 'nag': return 'Sarat din';
          case 'ne': return 'शरद';
          case 'trp': return 'Phunkha bisi';
          case 'hi': return 'शरद';
          case 'en':
          default: return 'Autumn';
        }
      default:
        return season;
    }
  }

  static String dayOfWeekName(String code, String day) {
    final enDays = _days['en']!;
    final index = enDays.indexWhere((d) => d.toLowerCase() == day.toLowerCase());
    if (index > 0) return dayOfWeek(code, index);
    return day;
  }

  static String monthNameByString(String code, String month) {
    final enMonths = _months['en']!;
    final index = enMonths.indexWhere((m) => m.toLowerCase() == month.toLowerCase());
    if (index > 0) return monthName(code, index);
    return month;
  }

  static String displayOrientationOption(String code, String questionId, String option) {
    switch (questionId) {
      case 'season':
        return seasonName(code, option);
      case 'day_of_week':
        return dayOfWeekName(code, option);
      case 'month':
        return monthNameByString(code, option);
      default:
        return option;
    }
  }
}
