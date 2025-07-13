import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:uuid/uuid.dart'; // For generating unique IDs

class UserSessionProvider with ChangeNotifier {
  String? _userId;
  String? _shopId;
  bool _isLoading = true; // To indicate if session data is being loaded

  String? get userId => _userId;
  String? get shopId => _shopId;
  bool get isLoading => _isLoading;

  UserSessionProvider() {
    _loadSessionData();
  }

  Future<void> _loadSessionData() async {
    _isLoading = true;
    notifyListeners(); // Notify listeners that loading has started

    final prefs = await SharedPreferences.getInstance();
    _userId = prefs.getString('userId');
    _shopId = prefs.getString('shopId');

    // If userId is null (first launch or data cleared), generate a new one
    if (_userId == null) {
      _userId = const Uuid().v4(); // Generate a unique ID
      await prefs.setString('userId', _userId!);
      print('Generated new userId: $_userId');
    } else {
      print('Loaded userId: $_userId');
    }

    if (_shopId == null) {
      // In a real app, shopId would be set after shop onboarding/creation.
      // For now, we'll set a default dummy one if not found.
      _shopId = 'SHOP_DEFAULT'; // A default shop ID for new users if not set
      await prefs.setString('shopId', _shopId!);
      print('Generated/Defaulted shopId: $_shopId');
    } else {
      print('Loaded shopId: $_shopId');
    }

    _isLoading = false;
    notifyListeners(); // Notify listeners that loading is complete
  }

  Future<void> setUserId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _userId = id;
    await prefs.setString('userId', id);
    notifyListeners();
    print('UserId set to: $id');
  }

  Future<void> setShopId(String id) async {
    final prefs = await SharedPreferences.getInstance();
    _shopId = id;
    await prefs.setString('shopId', id);
    notifyListeners();
    print('ShopId set to: $id');
  }

  Future<void> clearSession() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId');
    await prefs.remove('shopId');
    _userId = null;
    _shopId = null;
    notifyListeners();
    print('Session data cleared.');
  }
}