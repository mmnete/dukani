import 'package:permission_handler/permission_handler.dart';

class PermissionService {
  /// Requests contact permission and returns true if granted, false otherwise.
  static Future<bool> requestContactsPermission() async {
    final status = await Permission.contacts.request();
    return status.isGranted;
  }

  /// Checks if contact permission is granted.
  static Future<bool> checkContactsPermission() async {
    final status = await Permission.contacts.status;
    return status.isGranted;
  }
}