// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String welcomeMessage(String managerName) {
    return 'Welcome, $managerName';
  }

  @override
  String get dashboardOverview => 'Dashboard Overview';

  @override
  String get quickStockOverview => 'Quick Stock Overview';

  @override
  String get stockIn => 'Stock In';

  @override
  String get stockOut => 'Sales';

  @override
  String get missedSales => 'Missed Sales';

  @override
  String get weeklyStockMovementAnalytics => 'Weekly Stock Movement Analytics';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get recordSales => 'Record Sales';

  @override
  String get recordStockIn => 'Record Stock In';

  @override
  String get viewInventory => 'View Inventory';

  @override
  String get salesReport => 'Sales Report';

  @override
  String get manageProducts => 'Manage Products';

  @override
  String get manageWorkers => 'Manage Workers';

  @override
  String get managerMenu => 'Manager Menu';

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get logout => 'Logout';

  @override
  String navigatingTo(String screenName) {
    return 'Navigating to $screenName...';
  }

  @override
  String get notImplementedYet => '(Not implemented yet)';

  @override
  String get monday => 'Mon';

  @override
  String get tuesday => 'Tue';

  @override
  String get wednesday => 'Wed';

  @override
  String get thursday => 'Thu';

  @override
  String get friday => 'Fri';

  @override
  String get saturday => 'Sat';

  @override
  String get sunday => 'Sun';

  @override
  String get inviteWorker => 'Invite Worker';

  @override
  String get enterPhoneNumber => 'Enter phone number';

  @override
  String get selectFromContacts => 'Select from Contacts';

  @override
  String get sendInvite => 'Send Invite';

  @override
  String get contactPermissionDenied =>
      'Contact permission denied. Please enable it in settings to select contacts.';

  @override
  String get noPhoneNumberSelected => 'No phone number selected.';

  @override
  String inviteSentSuccessfully(String phoneNumber) {
    return 'Invite sent successfully to $phoneNumber!';
  }

  @override
  String inviteFailed(String phoneNumber) {
    return 'Failed to send invite to $phoneNumber.';
  }

  @override
  String get invalidPhoneNumber => 'Please enter a valid phone number.';

  @override
  String get phoneNumberAlreadyAdded => 'This phone number is already added.';

  @override
  String get addPhoneNumber => 'Add Phone Number';

  @override
  String get selectedContacts => 'Selected Contacts';

  @override
  String get registerYourShop => 'Register Your Shop';

  @override
  String get shopName => 'Shop Name';

  @override
  String get shopAddress => 'Shop Address';

  @override
  String get completeShopRegistration => 'Complete Shop Registration';

  @override
  String get registerManager => 'Register Manager';

  @override
  String get managerName => 'Manager Name';

  @override
  String get managerPhone => 'Manager Phone';

  @override
  String get completeManagerRegistration => 'Complete Manager Registration';

  @override
  String get workerManagementCenter => 'Worker Management Center';

  @override
  String get searchWorkers => 'Search Workers';

  @override
  String get workerActivityLog => 'Worker Activity Log';

  @override
  String get noActivityRecorded => 'No activity recorded for this worker.';

  @override
  String get noWorkersFound => 'You have no workers yet.';

  @override
  String get workerRemoved => 'Worker Removed!';

  @override
  String get workerProfile => 'Profile';

  @override
  String get actionsToday => 'Actions Today';

  @override
  String get lastActivity => 'Last Activity';
}
