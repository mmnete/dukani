// lib/services/auth/local_storage_service.dart

import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'i_auth_service.dart'; // Adjust import path

const String _userProfileKey = 'loggedInUserProfile';
const String _currentShopIdKey = 'currentShopId'; // Consider a separate key for clarity if not part of UserProfile

class LocalStorageService {
  // Make SharedPreferences an injected dependency
  final SharedPreferences _prefs;

  // Primary constructor: accepts a SharedPreferences instance
  LocalStorageService(this._prefs);

  // --- Instance Methods for User Profile Management ---

  Future<void> saveUserProfile(UserProfile profile) async {
    await _prefs.setString(_userProfileKey, jsonEncode(profile.toJson()));
  }

  Future<UserProfile?> getUserProfile() async {
    final String? profileString = _prefs.getString(_userProfileKey);
    if (profileString != null) {
      try {
        return UserProfile.fromJson(jsonDecode(profileString));
      } catch (e) {
        // In a real app, consider using a logger instead of print
        print('Error decoding user profile from local storage: $e');
        return null;
      }
    }
    return null;
  }

  Future<void> clearUserProfile() async {
    await _prefs.remove(_userProfileKey);
    // Also remove the current shop ID if it's stored separately
    await _prefs.remove(_currentShopIdKey);
  }

  // --- Instance Methods for Current Shop ID Management ---

  // Option 1 (Recommended): Store current shop ID as a separate preference
  // This is simpler and less prone to issues than modifying nested JSON.
  Future<void> saveCurrentShopId(String shopId) async {
    await _prefs.setString(_currentShopIdKey, shopId);
    // If you also want to update the user profile's currentShopId, you'd need to
    // get the profile, update it, and re-save it. But typically, this is
    // handled by the UserProfile object itself and saved as a whole.
  }

  Future<String?> getCurrentShopId() async {
    return _prefs.getString(_currentShopIdKey);
  }


  // --- Original logic if you insist on storing currentShopId *within* the UserProfile JSON
  //     (less ideal for isolated updates, but keeps original behavior)
  /*
  Future<void> saveCurrentShopId_Legacy(String shopId) async {
    final String? profileString = _prefs.getString(_userProfileKey);
    if (profileString != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(profileString);
        jsonMap['currentShopId'] = shopId;
        await _prefs.setString(_userProfileKey, jsonEncode(jsonMap));
      } catch (e) {
        print('Error updating current shop ID in local storage: $e');
      }
    }
  }

  Future<String?> getCurrentShopId_Legacy() async {
    final String? profileString = _prefs.getString(_userProfileKey);
    if (profileString != null) {
      try {
        final Map<String, dynamic> jsonMap = jsonDecode(profileString);
        return jsonMap['currentShopId'] as String?;
      } catch (e) {
        print('Error retrieving current shop ID from local storage: $e');
        return null;
      }
    }
    return null;
  }
  */
}