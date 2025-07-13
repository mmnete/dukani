// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Swahili (`sw`).
class AppLocalizationsSw extends AppLocalizations {
  AppLocalizationsSw([String locale = 'sw']) : super(locale);

  @override
  String welcomeMessage(String managerName) {
    return 'Karibu, $managerName';
  }

  @override
  String get dashboardOverview => 'Muhtasari wa Biashara';

  @override
  String get quickStockOverview => 'Muhtasari wa Bidhaa Zako';

  @override
  String get stockIn => 'Bidhaa Zilizoingia';

  @override
  String get stockOut => 'Mauzo';

  @override
  String get missedSales => 'Mauzo Yaliyokosekana';

  @override
  String get weeklyStockMovementAnalytics => 'Uchambuzi wa Harakati za Bidhaa';

  @override
  String get quickActions => 'Kazi za Haraka';

  @override
  String get recordSales => 'Rekodi Mauzo';

  @override
  String get recordStockIn => 'Ingiza Bidhaa';

  @override
  String get viewInventory => 'Angalia Bidhaa';

  @override
  String get salesReport => 'Ripoti ya Mauzo';

  @override
  String get manageProducts => 'Bidhaa Zako';

  @override
  String get manageWorkers => 'Wafanyakazi';

  @override
  String get managerMenu => 'Menyu ya Meneja';

  @override
  String get profileSettings => 'Mipangilio ya Wasifu';

  @override
  String get logout => 'Toka';

  @override
  String navigatingTo(String screenName) {
    return 'Inakwenda kwenye $screenName...';
  }

  @override
  String get notImplementedYet => '(Bado haijatekelezwa)';

  @override
  String get monday => 'Jtatu';

  @override
  String get tuesday => 'Jnnne';

  @override
  String get wednesday => 'Jtano';

  @override
  String get thursday => 'Alhms';

  @override
  String get friday => 'Ijumaa';

  @override
  String get saturday => 'Jmosi';

  @override
  String get sunday => 'Jpili';

  @override
  String get inviteWorker => 'Alika Mfanyakazi';

  @override
  String get enterPhoneNumber => 'Weka namba ya simu';

  @override
  String get selectFromContacts => 'Chagua kutoka kwa Anwani';

  @override
  String get sendInvite => 'Tuma Mwaliko';

  @override
  String get contactPermissionDenied =>
      'Ruhusa ya anwani imekataliwa. Tafadhali iwashe kwenye mipangilio ili kuchagua anwani.';

  @override
  String get noPhoneNumberSelected => 'Hakuna namba ya simu iliyochaguliwa.';

  @override
  String inviteSentSuccessfully(String phoneNumber) {
    return 'Mwaliko umetuma kwa $phoneNumber!';
  }

  @override
  String inviteFailed(String phoneNumber) {
    return 'Imeshindwa kutuma mwaliko kwa $phoneNumber.';
  }

  @override
  String get invalidPhoneNumber => 'Tafadhali weka namba ya simu halali.';

  @override
  String get phoneNumberAlreadyAdded => 'Namba hii ya simu tayari imeongezwa.';

  @override
  String get addPhoneNumber => 'Ongeza Namba ya Simu';

  @override
  String get selectedContacts => 'Anwani Zilizochaguliwa';

  @override
  String get registerYourShop => 'Sajili Duka Lako';

  @override
  String get shopName => 'Jina la Duka';

  @override
  String get shopAddress => 'Anwani ya Duka';

  @override
  String get completeShopRegistration => 'Kamilisha Usajili wa Duka';

  @override
  String get registerManager => 'Sajili Meneja';

  @override
  String get managerName => 'Jina la Meneja';

  @override
  String get managerPhone => 'Namba ya Simu ya Meneja';

  @override
  String get completeManagerRegistration => 'Kamilisha Usajili wa Meneja';

  @override
  String get workerManagementCenter => 'Usimamizi wa Wafanyakazi';

  @override
  String get searchWorkers => 'Tafuta Wafanyakazi';

  @override
  String get workerActivityLog => 'Shughuli za Mfanyakazi';

  @override
  String get noActivityRecorded =>
      'Hakuna shughuli iliyorekodiwa kwa mfanyakazi huyu.';

  @override
  String get noWorkersFound => 'Hakuna wafanyakazi kwenye mfumo wako.';

  @override
  String get workerRemoved => 'Mfanyakazi katolewa!';

  @override
  String get workerProfile => 'Taarifa';

  @override
  String get actionsToday => 'Kinachoendelea';

  @override
  String get lastActivity => 'Kazi ya hivi karibuni';
}
