// lib/services/auth/fake_user_service.dart

import 'i_user_service.dart'; // Adjust import path
// To potentially update user profiles in fake DB
import 'fake_auth_service.dart';

// In-memory "database" for fake service
// Updated with new universal address details
final Map<String, ShopInfo> fakeShops = {
  "shop_A": ShopInfo(
    id: "shop_A",
    name: "Alice's Emporium",
    managerPhoneNumber: "1234567890",
    storeType: "General Store",
    businessRegistrationNumber: "13413132123",
    // Universal Address Components for US
    streetAddress: "123 Main St",
    streetAddress2: null, // No second line needed for this example
    city: "San Jose",
    region: "CA", // State
    postalCode: "95123",
    country: "United States",
    storePhoneNumber: "408-111-2222",
    storeEmail: "alice.emporium@example.com",
  ),
  "shop_B": ShopInfo(
    id: "shop_B",
    name: "Diana's Discounts",
    managerPhoneNumber: "5544332211",
    storeType: "Discount Retailer",
    businessRegistrationNumber: "324324",
    // Universal Address Components for Tanzania
    streetAddress: "Plot 45, Nyerere Rd",
    streetAddress2: "Ilala", // Can be used for sub-locality or block
    city: "Dar es Salaam",
    region: "Dar es Salaam", // Region
    postalCode: "11101", // Example Tanzanian postal code
    country: "Tanzania",
    storePhoneNumber: "255-755-123456",
    storeEmail: "dianas.discounts@example.co.tz",
  ),
  "shop_C": ShopInfo(
    id: "shop_C",
    name: "Global Goods",
    managerPhoneNumber: "1234567890", // Alice owns another shop
    storeType: "Import/Export",
    businessRegistrationNumber: "234234wer",
    streetAddress: "789 International Blvd",
    streetAddress2: "Unit 10",
    city: "Milpitas",
    region: "CA",
    postalCode: "95035",
    country: "United States",
    storePhoneNumber: "408-999-0000",
    storeEmail: "global.goods@example.com",
  ),
};

// Simulate invitations where a manager invited a worker to a shop
final Map<String, List<String>> fakeInvitationsDb = {
  "0987654321": ["shop_A"],
  "1122334455": ["shop_B"],
  "9988776655": ["shop_A"], // New worker invited
};

class FakeUserService implements IUserService {
  @override
  Future<String> createShop(
    String shopName,
    String managerPhoneNumber, {
    String? storeType,
    String? businessRegistrationNumber,
    String? streetAddress,
    String? streetAddress2,
    String? city,
    String? region,
    String? postalCode,
    required String country, // Country is now required here
    String? storePhoneNumber,
    String? storeEmail,
  }) async {
    print(
        '[FakeUserService] Creating shop "$shopName" for manager $managerPhoneNumber in $city, $country');
    final newShopId = 'shop_${DateTime.now().microsecondsSinceEpoch}';
    fakeShops[newShopId] = ShopInfo(
      id: newShopId,
      name: shopName,
      managerPhoneNumber: managerPhoneNumber,
      storeType: storeType,
      businessRegistrationNumber: businessRegistrationNumber,
      streetAddress: streetAddress,
      streetAddress2: streetAddress2,
      city: city,
      region: region,
      postalCode: postalCode,
      country: country, // Pass the required country
      storePhoneNumber: storePhoneNumber,
      storeEmail: storeEmail,
    );

    // Update manager's profile in the now public `fakeUsers` map
    final manager = fakeUsers[managerPhoneNumber];
    if (manager != null) {
      final updatedShopsOwned = (manager.shopsOwned ?? [])..add(newShopId);
      fakeUsers[managerPhoneNumber] = manager.copyWith(shopsOwned: updatedShopsOwned);
    }

    return Future.value(newShopId);
  }

  @override
  Future<bool> inviteWorkerToShop(
      String managerPhoneNumber, String shopId, String workerPhoneNumber) async {
    print(
        '[FakeUserService] Inviting worker $workerPhoneNumber to shop $shopId by manager $managerPhoneNumber');
    final shop = fakeShops[shopId];
    if (shop == null || shop.managerPhoneNumber != managerPhoneNumber) {
      return Future.value(false); // Manager doesn't own this shop or shop doesn't exist
    }

    // Add to the public `fakeInvites` map in fake_auth_service.dart
    fakeInvites.putIfAbsent(workerPhoneNumber, () => []).add(shopId);

    // Also update the in-memory invitations DB within FakeUserService if it's separate
    fakeInvitationsDb.putIfAbsent(workerPhoneNumber, () => []).add(shopId);

    return Future.value(true);
  }

  @override
  Future<List<ShopInfo>> getShopsOwnedByManager(String managerPhoneNumber) async {
    print('[FakeUserService] Getting shops owned by manager $managerPhoneNumber');
    return Future.value(
        fakeShops.values.where((shop) => shop.managerPhoneNumber == managerPhoneNumber).toList());
  }

  @override
  Future<List<ShopInfo>> getInvitedShopsForWorker(String workerPhoneNumber) async {
    print('[FakeUserService] Getting invited shops for worker $workerPhoneNumber');
    // Access the now public `fakeInvites` map from fake_auth_service.dart for consistency
    final invitedShopIds = fakeInvites[workerPhoneNumber] ?? [];
    return Future.value(
        invitedShopIds.map((id) => fakeShops[id]).where((shop) => shop != null).cast<ShopInfo>().toList());
  }
}