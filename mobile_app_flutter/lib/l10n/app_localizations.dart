import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/intl.dart' as intl;

import 'app_localizations_en.dart';
import 'app_localizations_sw.dart';

// ignore_for_file: type=lint

/// Callers can lookup localized strings with an instance of AppLocalizations
/// returned by `AppLocalizations.of(context)`.
///
/// Applications need to include `AppLocalizations.delegate()` in their app's
/// `localizationDelegates` list, and the locales they support in the app's
/// `supportedLocales` list. For example:
///
/// ```dart
/// import 'l10n/app_localizations.dart';
///
/// return MaterialApp(
///   localizationsDelegates: AppLocalizations.localizationsDelegates,
///   supportedLocales: AppLocalizations.supportedLocales,
///   home: MyApplicationHome(),
/// );
/// ```
///
/// ## Update pubspec.yaml
///
/// Please make sure to update your pubspec.yaml to include the following
/// packages:
///
/// ```yaml
/// dependencies:
///   # Internationalization support.
///   flutter_localizations:
///     sdk: flutter
///   intl: any # Use the pinned version from flutter_localizations
///
///   # Rest of dependencies
/// ```
///
/// ## iOS Applications
///
/// iOS applications define key application metadata, including supported
/// locales, in an Info.plist file that is built into the application bundle.
/// To configure the locales supported by your app, you’ll need to edit this
/// file.
///
/// First, open your project’s ios/Runner.xcworkspace Xcode workspace file.
/// Then, in the Project Navigator, open the Info.plist file under the Runner
/// project’s Runner folder.
///
/// Next, select the Information Property List item, select Add Item from the
/// Editor menu, then select Localizations from the pop-up menu.
///
/// Select and expand the newly-created Localizations item then, for each
/// locale your application supports, add a new item and select the locale
/// you wish to add from the pop-up menu in the Value field. This list should
/// be consistent with the languages listed in the AppLocalizations.supportedLocales
/// property.
abstract class AppLocalizations {
  AppLocalizations(String locale)
    : localeName = intl.Intl.canonicalizedLocale(locale.toString());

  final String localeName;

  static AppLocalizations? of(BuildContext context) {
    return Localizations.of<AppLocalizations>(context, AppLocalizations);
  }

  static const LocalizationsDelegate<AppLocalizations> delegate =
      _AppLocalizationsDelegate();

  /// A list of this localizations delegate along with the default localizations
  /// delegates.
  ///
  /// Returns a list of localizations delegates containing this delegate along with
  /// GlobalMaterialLocalizations.delegate, GlobalCupertinoLocalizations.delegate,
  /// and GlobalWidgetsLocalizations.delegate.
  ///
  /// Additional delegates can be added by appending to this list in
  /// MaterialApp. This list does not have to be used at all if a custom list
  /// of delegates is preferred or required.
  static const List<LocalizationsDelegate<dynamic>> localizationsDelegates =
      <LocalizationsDelegate<dynamic>>[
        delegate,
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ];

  /// A list of this localizations delegate's supported locales.
  static const List<Locale> supportedLocales = <Locale>[
    Locale('en'),
    Locale('sw'),
  ];

  /// No description provided for @welcomeMessage.
  ///
  /// In en, this message translates to:
  /// **'Welcome, {managerName}'**
  String welcomeMessage(String managerName);

  /// No description provided for @dashboardOverview.
  ///
  /// In en, this message translates to:
  /// **'Dashboard Overview'**
  String get dashboardOverview;

  /// No description provided for @quickStockOverview.
  ///
  /// In en, this message translates to:
  /// **'Quick Stock Overview'**
  String get quickStockOverview;

  /// No description provided for @stockIn.
  ///
  /// In en, this message translates to:
  /// **'Stock In'**
  String get stockIn;

  /// No description provided for @stockOut.
  ///
  /// In en, this message translates to:
  /// **'Sales'**
  String get stockOut;

  /// No description provided for @missedSales.
  ///
  /// In en, this message translates to:
  /// **'Missed Sales'**
  String get missedSales;

  /// No description provided for @weeklyStockMovementAnalytics.
  ///
  /// In en, this message translates to:
  /// **'Weekly Stock Movement Analytics'**
  String get weeklyStockMovementAnalytics;

  /// No description provided for @quickActions.
  ///
  /// In en, this message translates to:
  /// **'Quick Actions'**
  String get quickActions;

  /// No description provided for @recordSales.
  ///
  /// In en, this message translates to:
  /// **'Record Sales'**
  String get recordSales;

  /// No description provided for @recordStockIn.
  ///
  /// In en, this message translates to:
  /// **'Record Stock In'**
  String get recordStockIn;

  /// No description provided for @viewInventory.
  ///
  /// In en, this message translates to:
  /// **'View Inventory'**
  String get viewInventory;

  /// No description provided for @salesReport.
  ///
  /// In en, this message translates to:
  /// **'Sales Report'**
  String get salesReport;

  /// No description provided for @manageProducts.
  ///
  /// In en, this message translates to:
  /// **'Manage Products'**
  String get manageProducts;

  /// No description provided for @manageWorkers.
  ///
  /// In en, this message translates to:
  /// **'Manage Workers'**
  String get manageWorkers;

  /// No description provided for @managerMenu.
  ///
  /// In en, this message translates to:
  /// **'Manager Menu'**
  String get managerMenu;

  /// No description provided for @profileSettings.
  ///
  /// In en, this message translates to:
  /// **'Profile Settings'**
  String get profileSettings;

  /// No description provided for @logout.
  ///
  /// In en, this message translates to:
  /// **'Logout'**
  String get logout;

  /// No description provided for @navigatingTo.
  ///
  /// In en, this message translates to:
  /// **'Navigating to {screenName}...'**
  String navigatingTo(String screenName);

  /// No description provided for @notImplementedYet.
  ///
  /// In en, this message translates to:
  /// **'(Not implemented yet)'**
  String get notImplementedYet;

  /// No description provided for @monday.
  ///
  /// In en, this message translates to:
  /// **'Mon'**
  String get monday;

  /// No description provided for @tuesday.
  ///
  /// In en, this message translates to:
  /// **'Tue'**
  String get tuesday;

  /// No description provided for @wednesday.
  ///
  /// In en, this message translates to:
  /// **'Wed'**
  String get wednesday;

  /// No description provided for @thursday.
  ///
  /// In en, this message translates to:
  /// **'Thu'**
  String get thursday;

  /// No description provided for @friday.
  ///
  /// In en, this message translates to:
  /// **'Fri'**
  String get friday;

  /// No description provided for @saturday.
  ///
  /// In en, this message translates to:
  /// **'Sat'**
  String get saturday;

  /// No description provided for @sunday.
  ///
  /// In en, this message translates to:
  /// **'Sun'**
  String get sunday;

  /// No description provided for @inviteWorker.
  ///
  /// In en, this message translates to:
  /// **'Invite Worker'**
  String get inviteWorker;

  /// No description provided for @enterPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Enter phone number'**
  String get enterPhoneNumber;

  /// No description provided for @selectFromContacts.
  ///
  /// In en, this message translates to:
  /// **'Select from Contacts'**
  String get selectFromContacts;

  /// No description provided for @sendInvite.
  ///
  /// In en, this message translates to:
  /// **'Send Invite'**
  String get sendInvite;

  /// No description provided for @contactPermissionDenied.
  ///
  /// In en, this message translates to:
  /// **'Contact permission denied. Please enable it in settings to select contacts.'**
  String get contactPermissionDenied;

  /// No description provided for @noPhoneNumberSelected.
  ///
  /// In en, this message translates to:
  /// **'No phone number selected.'**
  String get noPhoneNumberSelected;

  /// No description provided for @inviteSentSuccessfully.
  ///
  /// In en, this message translates to:
  /// **'Invite sent successfully to {phoneNumber}!'**
  String inviteSentSuccessfully(String phoneNumber);

  /// No description provided for @inviteFailed.
  ///
  /// In en, this message translates to:
  /// **'Failed to send invite to {phoneNumber}.'**
  String inviteFailed(String phoneNumber);

  /// No description provided for @invalidPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Please enter a valid phone number.'**
  String get invalidPhoneNumber;

  /// No description provided for @phoneNumberAlreadyAdded.
  ///
  /// In en, this message translates to:
  /// **'This phone number is already added.'**
  String get phoneNumberAlreadyAdded;

  /// No description provided for @addPhoneNumber.
  ///
  /// In en, this message translates to:
  /// **'Add Phone Number'**
  String get addPhoneNumber;

  /// No description provided for @selectedContacts.
  ///
  /// In en, this message translates to:
  /// **'Selected Contacts'**
  String get selectedContacts;

  /// No description provided for @registerYourShop.
  ///
  /// In en, this message translates to:
  /// **'Register Your Shop'**
  String get registerYourShop;

  /// No description provided for @shopName.
  ///
  /// In en, this message translates to:
  /// **'Shop Name'**
  String get shopName;

  /// No description provided for @shopAddress.
  ///
  /// In en, this message translates to:
  /// **'Shop Address'**
  String get shopAddress;

  /// No description provided for @completeShopRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Shop Registration'**
  String get completeShopRegistration;

  /// No description provided for @registerManager.
  ///
  /// In en, this message translates to:
  /// **'Register Manager'**
  String get registerManager;

  /// No description provided for @managerName.
  ///
  /// In en, this message translates to:
  /// **'Manager Name'**
  String get managerName;

  /// No description provided for @managerPhone.
  ///
  /// In en, this message translates to:
  /// **'Manager Phone'**
  String get managerPhone;

  /// No description provided for @completeManagerRegistration.
  ///
  /// In en, this message translates to:
  /// **'Complete Manager Registration'**
  String get completeManagerRegistration;

  /// No description provided for @workerManagementCenter.
  ///
  /// In en, this message translates to:
  /// **'Worker Management Center'**
  String get workerManagementCenter;

  /// No description provided for @searchWorkers.
  ///
  /// In en, this message translates to:
  /// **'Search Workers'**
  String get searchWorkers;

  /// No description provided for @workerActivityLog.
  ///
  /// In en, this message translates to:
  /// **'Worker Activity Log'**
  String get workerActivityLog;

  /// No description provided for @noActivityRecorded.
  ///
  /// In en, this message translates to:
  /// **'No activity recorded for this worker.'**
  String get noActivityRecorded;

  /// No description provided for @noWorkersFound.
  ///
  /// In en, this message translates to:
  /// **'You have no workers yet.'**
  String get noWorkersFound;

  /// No description provided for @workerRemoved.
  ///
  /// In en, this message translates to:
  /// **'Worker Removed!'**
  String get workerRemoved;

  /// No description provided for @workerProfile.
  ///
  /// In en, this message translates to:
  /// **'Profile'**
  String get workerProfile;

  /// No description provided for @actionsToday.
  ///
  /// In en, this message translates to:
  /// **'Actions Today'**
  String get actionsToday;

  /// No description provided for @lastActivity.
  ///
  /// In en, this message translates to:
  /// **'Last Activity'**
  String get lastActivity;
}

class _AppLocalizationsDelegate
    extends LocalizationsDelegate<AppLocalizations> {
  const _AppLocalizationsDelegate();

  @override
  Future<AppLocalizations> load(Locale locale) {
    return SynchronousFuture<AppLocalizations>(lookupAppLocalizations(locale));
  }

  @override
  bool isSupported(Locale locale) =>
      <String>['en', 'sw'].contains(locale.languageCode);

  @override
  bool shouldReload(_AppLocalizationsDelegate old) => false;
}

AppLocalizations lookupAppLocalizations(Locale locale) {
  // Lookup logic when only language code is specified.
  switch (locale.languageCode) {
    case 'en':
      return AppLocalizationsEn();
    case 'sw':
      return AppLocalizationsSw();
  }

  throw FlutterError(
    'AppLocalizations.delegate failed to load unsupported locale "$locale". This is likely '
    'an issue with the localizations generation tool. Please file an issue '
    'on GitHub with a reproducible sample app and the gen-l10n configuration '
    'that was used.',
  );
}
