import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';
import 'user_session_provider.dart';
import 'api_provider.dart';
import '../models/models.dart';
import '../models/dummy_data.dart';

class DummyApiService implements ApiProvider {
  final _uuid = const Uuid();

  // Helper to find a shop by ID
  Shop? _findShopById(String shopId) {
    try {
      return dummyShops.firstWhere((shop) => shop.id == shopId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<Map<String, dynamic>> onboardShop({
    required String name,
    required String address,
    required String phoneNumber,
    required String managerFirebaseUid,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    // Check if a shop with this name already exists (simple check)
    if (dummyShops.any((shop) => shop.name.toLowerCase() == name.toLowerCase())) {
      return {'success': false, 'error': 'A shop with this name already exists.'};
    }

    final String newShopId = 'SHOP_${_uuid.v4().substring(0, 8).toUpperCase()}';

    // Create a new Manager object for the current Firebase user
    final newManager = Manager(
      id: 'MGR_${_uuid.v4().substring(0, 8).toUpperCase()}',
      name: 'Manager Name Placeholder', // This should ideally come from user input or Firebase profile
      phoneNumber: phoneNumber, // Using shop's phone as manager's for simplicity
      firebaseUid: managerFirebaseUid,
      shopId: newShopId,
    );

    final newShop = Shop(
      id: newShopId,
      name: name,
      address: address,
      phoneNumber: phoneNumber,
      managers: [newManager], // Add the current manager to the shop
      workers: [],
    );

    dummyShops.add(newShop); // Add the new shop to our dummy data
    print('🛍️ Dummy shop onboarded: ${newShop.name} (ID: ${newShop.id})');

    return {'success': true, 'shop_id': newShopId, 'manager_id': newManager.id};
  }

  @override
  Future<Map<String, dynamic>> onboardManager({
    required String shopId,
    required String managerName,
    required String managerPhone,
    required String managerFirebaseUid,
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    final shop = _findShopById(shopId);
    if (shop == null) {
      return {'success': false, 'error': 'Shop not found.'};
    }

    // Check if this manager (by Firebase UID) is already associated with this shop
    if (shop.managers.any((m) => m.firebaseUid == managerFirebaseUid)) {
      return {'success': false, 'error': 'This manager is already associated with this shop.'};
    }

    final newManager = Manager(
      id: 'MGR_${_uuid.v4().substring(0, 8).toUpperCase()}',
      name: managerName,
      phoneNumber: managerPhone,
      firebaseUid: managerFirebaseUid,
      shopId: shopId,
    );

    shop.managers.add(newManager);
    print('👤 Dummy manager onboarded: ${newManager.name} for shop ${shop.name}');

    return {'success': true, 'manager_id': newManager.id};
  }

  @override
  Future<Map<String, dynamic>> inviteWorker({
    required String shopId,
    required String name,
    required String phoneNumber,
    required String managerFirebaseUid, // Manager who is inviting
  }) async {
    await Future.delayed(const Duration(milliseconds: 500)); // Simulate network delay

    final shop = _findShopById(shopId);
    if (shop == null) {
      return {'success': false, 'error': 'Shop not found.'};
    }

    // Optional: Check if the inviting manager actually manages this shop
    if (!shop.managers.any((m) => m.firebaseUid == managerFirebaseUid)) {
      return {'success': false, 'error': 'Only a manager of this shop can invite workers.'};
    }

    // Check if worker with this phone number already exists in this shop
    if (shop.workers.any((w) => w.phoneNumber == phoneNumber)) {
      return {'success': false, 'error': 'A worker with this phone number already exists in this shop.'};
    }

    final newWorker = Worker(
      id: 'WRK_${_uuid.v4().substring(0, 8).toUpperCase()}',
      name: name,
      phoneNumber: phoneNumber,
      shopId: shopId,
      firebaseUid: null, // Firebase UID will be set when the worker registers/logs in
    );

    shop.workers.add(newWorker);
    print('👷 Dummy worker invited: ${newWorker.name} (${newWorker.phoneNumber}) for shop ${shop.name}');

    // In a real app, you'd generate a real invite code and send it via SMS/email
    return {
      'success': true,
      'invite_code': 'INVITE_${_uuid.v4().substring(0, 6).toUpperCase()}',
      'worker_id': newWorker.id,
    };
  }

  @override
  Future<Map<String, dynamic>> getShopDetails(String shopId) async {
    await Future.delayed(const Duration(milliseconds: 300));
    final shop = _findShopById(shopId);
    if (shop != null) {
      return {'success': true, 'shop': shop.toJson()};
    }
    return {'success': false, 'error': 'Shop not found.'};
  }

  @override
  Future<List<Shop>> getAllShops() async {
    await Future.delayed(const Duration(milliseconds: 200));
    return List.from(dummyShops); // Return a copy to prevent external modification
  }

  @override
  Future<bool> postStockEntry(Map<String, dynamic> data) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('📦 Dummy stock entry posted: $data');
    return true;
  }

  @override
  Future<bool> recordStockItem(Map<String, dynamic> item) async {
    await Future.delayed(const Duration(milliseconds: 300));
    print('📝 Dummy recordStockItem called: $item');
    return await postStockEntry(item);
  }
}