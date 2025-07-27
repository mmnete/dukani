// lib/services/i_user_service.dart

class ShopInfo {
  final String id;
  final String name;
  final String managerPhoneNumber;
  final String? storeType; // e.g., "Grocery", "Apparel", "Electronics"
  final String? businessRegistrationNumber; 

  // Universal Address Components
  final String? streetAddress;
  final String? streetAddress2; // Optional: Apt, Suite, Floor, etc.
  final String? city;
  final String? region; // State, Province, or Region (e.g., California, Dodoma)
  final String? postalCode; // ZIP code, Post code (optional)
  final String country; // Country is essential for unique identification

  final String? storePhoneNumber; // Main contact phone number for the store
  final String? storeEmail; // Optional email address for the store

  ShopInfo({
    required this.id,
    required this.name,
    required this.managerPhoneNumber,
    this.storeType,
    this.businessRegistrationNumber,
    // Universal Address Components
    this.streetAddress,
    this.streetAddress2,
    this.city,
    this.region,
    this.postalCode,
    required this.country, // Make country required
    this.storePhoneNumber,
    this.storeEmail,
  });

  factory ShopInfo.fromJson(Map<String, dynamic> json) {
    return ShopInfo(
      id: json['id'] as String,
      name: json['name'] as String,
      managerPhoneNumber: json['managerPhoneNumber'] as String,
      businessRegistrationNumber: json['businessRegistrationNumber'] as String?,
      storeType: json['storeType'] as String?,
      // Universal Address Components parsing
      streetAddress: json['streetAddress'] as String?,
      streetAddress2: json['streetAddress2'] as String?,
      city: json['city'] as String?,
      region: json['region'] as String?,
      postalCode: json['postalCode'] as String?,
      country: json['country'] as String, // Country is required
      storePhoneNumber: json['storePhoneNumber'] as String?,
      storeEmail: json['storeEmail'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'managerPhoneNumber': managerPhoneNumber,
      'businessRegistrationNumber': businessRegistrationNumber,
      'storeType': storeType,
      // Universal Address Components serialization
      'streetAddress': streetAddress,
      'streetAddress2': streetAddress2,
      'city': city,
      'region': region,
      'postalCode': postalCode,
      'country': country, // Country is required
      'storePhoneNumber': storePhoneNumber,
      'storeEmail': storeEmail,
    };
  }

  // Add a copyWith method for immutability and easy updates
  ShopInfo copyWith({
    String? id,
    String? name,
    String? managerPhoneNumber,
    String? businessRegistrationNumber,
    String? storeType,
    String? streetAddress,
    String? streetAddress2,
    String? city,
    String? region,
    String? postalCode,
    String? country, // Country can be updated, but often remains constant
    String? storePhoneNumber,
    String? storeEmail,
  }) {
    return ShopInfo(
      id: id ?? this.id,
      name: name ?? this.name,
      managerPhoneNumber: managerPhoneNumber ?? this.managerPhoneNumber,
      businessRegistrationNumber: businessRegistrationNumber ?? this.businessRegistrationNumber,
      storeType: storeType ?? this.storeType,
      streetAddress: streetAddress ?? this.streetAddress,
      streetAddress2: streetAddress2 ?? this.streetAddress2,
      city: city ?? this.city,
      region: region ?? this.region,
      postalCode: postalCode ?? this.postalCode,
      country: country ?? this.country,
      storePhoneNumber: storePhoneNumber ?? this.storePhoneNumber,
      storeEmail: storeEmail ?? this.storeEmail,
    );
  }
}

abstract class IUserService {
  /// Creates a new shop. Only accessible by managers.
  /// Now includes granular and universal shop address details.
  Future<String> createShop(
    String shopName,
    String managerPhoneNumber, {
    String? storeType,
    String? businessRegistrationNumber,
    // Universal Address Components
    String? streetAddress,
    String? streetAddress2,
    String? city,
    String? region,
    String? postalCode,
    required String country, // Country is now required here
    String? storePhoneNumber,
    String? storeEmail,
  });

  /// Invites a worker to a specific shop. Only accessible by managers.
  Future<bool> inviteWorkerToShop(
      String managerPhoneNumber, String shopId, String workerPhoneNumber);

  /// Gets a list of shops owned by a manager.
  Future<List<ShopInfo>> getShopsOwnedByManager(String managerPhoneNumber);

  /// Gets a list of shops a worker has been invited to.
  Future<List<ShopInfo>> getInvitedShopsForWorker(String workerPhoneNumber);
}
