import 'package:flutter/material.dart'; // Import for BuildContext
import 'package:provider/provider.dart'; // Import for Provider
import 'package:uuid/uuid.dart'; // For generating unique IDs
import 'api_provider.dart';
import 'user_session_provider.dart'; // Import your session provider

class DummyApiService implements ApiProvider {
  Map<String, dynamic> dummyShop = {};
  Map<String, dynamic> dummyManager = {};

  @override
  Future<Map<String, dynamic>> onboardShop({
    required String name,
    required String address,
    required BuildContext context, // Added BuildContext
  }) async {
    String managerName = '';
    String managerPhone = '';
    final sessionProvider = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );

    // Simulate shop ID generation
    final String newShopId =
        'SHOP_${const Uuid().v4().substring(0, 8).toUpperCase()}';
    // Simulate manager/user ID generation (if not already set)
    final String newUserId =
        sessionProvider.userId ??
        'USER_${const Uuid().v4().substring(0, 8).toUpperCase()}';

    dummyShop = {
      'name': name,
      'address': address,
      'manager': managerName,
      'phone': managerPhone,
      'shop_id': newShopId,
      'user_id': newUserId,
    };
    print('🛍️ Dummy shop saved: $dummyShop');

    // Update shared preferences via UserSessionProvider
    await sessionProvider.setUserId(newUserId);
    await sessionProvider.setShopId(newShopId);

    return {'success': true, 'shop_id': newShopId};
  }

  @override
  Future<Map<String, dynamic>> onboardManager({
    required String shopId,
    required String managerName,
    required String managerPhone,
    required BuildContext context, // Added BuildContext
  }) async {
    final sessionProvider = Provider.of<UserSessionProvider>(
      context,
      listen: false,
    );

    // Ensure userId is set, if not, generate one (fallback)
    final String currentUserId =
        sessionProvider.userId ??
        'USER_${const Uuid().v4().substring(0, 8).toUpperCase()}';
    if (sessionProvider.userId == null) {
      await sessionProvider.setUserId(currentUserId);
    }

    dummyManager = {
      'name': managerName,
      'phone': managerPhone,
      'shop_id': shopId,
      'user_id': currentUserId, // Associate with the current user ID
    };
    print('👤 Dummy manager saved: $dummyManager');

    // Ensure shopId is set in session if it's not already (e.g., if manager onboarding is separate from shop onboarding)
    if (sessionProvider.shopId == null || sessionProvider.shopId != shopId) {
      await sessionProvider.setShopId(shopId);
    }

    return {'success': true};
  }

  @override
  Future<bool> postStockEntry(Map<String, dynamic> data) async {
    print('📦 Dummy stock entry posted: $data');
    return true;
  }

  @override
  Future<bool> recordStockItem(Map<String, dynamic> item) async {
    print('📝 Dummy recordStockItem called: $item');
    return await postStockEntry(item);
  }

  @override
  Future<Map<String, dynamic>> inviteWorker({
    required String shopId, // Changed to String
    required String name,
    required String phone,
  }) async {
    print('👷 Dummy worker invited: $name ($phone) for shop $shopId');
    return {
      'success': true,
      'invite_code': 'ABC123',
      'worker_id': 'WORKER_${const Uuid().v4().substring(0, 8).toUpperCase()}',
    };
  }
}
