// lib/services/user_profile.dart (or i_auth_service.dart if you prefer keeping it with auth interfaces)

class UserProfile {
  final String phoneNumber;
  String? firstName;
  String? lastName;
  String? profileName;
  bool isManager;
  List<String>? shopsOwned; // List of shop IDs if the user is a manager or worker who joined shops
  List<String>? invitedToShops; // List of shop IDs if the user is a worker invited to shops
  String? currentShopId; // The ID of the currently selected shop (for preference storage)

  // Default constructor: Using named parameters for clarity and flexibility
  // 'phoneNumber' is now required as a named parameter as well for consistency
  UserProfile({
    required this.phoneNumber, // Phone number is essential and should always be provided
    this.firstName,
    this.lastName,
    required this.profileName, // Profile name is also required for a complete profile
    required this.isManager,
    this.shopsOwned,
    this.invitedToShops,
    this.currentShopId,
  });

  // Factory constructor for deserialization from JSON (e.g., from local storage)
  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      phoneNumber: json['phoneNumber'] as String, // Ensure type safety
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      profileName: json['profileName'] as String, // Assuming profileName is always present after creation
      isManager: json['isManager'] as bool,
      shopsOwned: (json['shopsOwned'] as List<dynamic>?)?.map((e) => e as String).toList(),
      invitedToShops: (json['invitedToShops'] as List<dynamic>?)?.map((e) => e as String).toList(),
      currentShopId: json['currentShopId'] as String?,
    );
  }

  // Method for serialization to JSON (e.g., for local storage)
  Map<String, dynamic> toJson() {
    return {
      'phoneNumber': phoneNumber,
      'firstName': firstName,
      'lastName': lastName,
      'profileName': profileName,
      'isManager': isManager,
      'shopsOwned': shopsOwned,
      'invitedToShops': invitedToShops,
      'currentShopId': currentShopId,
    };
  }

  // Method to create a copy with updated fields
  // Note: phoneNumber is 'final' so it cannot be changed via copyWith.
  // It's passed directly from the existing object.
  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? profileName,
    bool? isManager,
    List<String>? shopsOwned,
    List<String>? invitedToShops,
    String? currentShopId,
  }) {
    return UserProfile(
      phoneNumber: phoneNumber, // PhoneNumber remains unchanged as it's final
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      profileName: profileName ?? this.profileName,
      isManager: isManager ?? this.isManager,
      shopsOwned: shopsOwned ?? this.shopsOwned,
      invitedToShops: invitedToShops ?? this.invitedToShops,
      currentShopId: currentShopId ?? this.currentShopId,
    );
  }
}

class AuthResult {
  final bool success;
  final String? message;
  final UserProfile? userProfile;
  final bool? needsProfileCreation; // Indicates if the user needs to complete their profile (name, profileName)
  final bool? isNewUser; // Indicates if this is the very first time this phone number is seen

  AuthResult({
    required this.success,
    this.message,
    this.userProfile,
    this.needsProfileCreation,
    this.isNewUser,
  });
}

abstract class IAuthService {
  /// Initiates the phone number verification process (e.g., sends an OTP).
  /// Returns true if the code was sent successfully.
  Future<bool> sendVerificationCode(String phoneNumber);

  /// Verifies the OTP and attempts to log in or register the user.
  Future<AuthResult> verifyCode(String phoneNumber, String code);

  /// Completes the user's profile after initial phone number verification.
  /// This is for new users or users who need to set their name/profileName.
  ///
  /// The 'name' parameter is now split into firstName and lastName for better data structure.
  Future<AuthResult> completeProfile(
      String phoneNumber, String? firstName, String? lastName, String profileName, bool isManager);

  /// Accepts an invitation to a specific shop.
  Future<AuthResult> acceptInvitation(String phoneNumber, String shopId);

  /// Retrieves the currently logged-in user's profile from local storage/session.
  Future<UserProfile?> getLoggedInUser();

  /// Sets the currently active shop for the logged-in user.
  /// This updates the currentShopId in the UserProfile and saves it locally.
  Future<void> setCurrentShop(String shopId);

  /// Logs out the current user.
  Future<void> logout();
}