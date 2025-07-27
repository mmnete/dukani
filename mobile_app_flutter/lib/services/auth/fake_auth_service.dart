// lib/services/auth/fake_auth_service.dart

import 'i_auth_service.dart'; // Adjust import path
import 'local_storage_service.dart'; // Adjust import path

// In-memory "database" for fake service
// Updated to use firstName, lastName, and profileName consistently
final Map<String, UserProfile> fakeUsers = {
  "1234567890": UserProfile(
    phoneNumber: "1234567890",
    firstName: "Alice",
    lastName: "Manager",
    profileName: "Alice M.",
    isManager: true,
    shopsOwned: ["shop_A"],
  ),
  "0987654321": UserProfile(
    phoneNumber: "0987654321",
    firstName: "Bob",
    lastName: "Worker",
    profileName: "Bob W.",
    isManager: false,
    invitedToShops: ["shop_A"],
  ),
  "1122334455": UserProfile(
    phoneNumber: "1122334455",
    firstName: "Charlie",
    lastName: "Worker",
    profileName: "Charlie C.",
    isManager: false,
    invitedToShops: ["shop_B"],
  ),
  "5544332211": UserProfile(
    phoneNumber: "5544332211",
    firstName: "Diana",
    lastName: "Manager",
    profileName: "Diana D.",
    isManager: true,
    shopsOwned: ["shop_B"],
  ),
};

// Simulate invited phone numbers (before they complete profile)
final Map<String, List<String>> fakeInvites = {
  "0987654321": ["shop_A"], // Bob is invited to Shop A
  "1122334455": ["shop_B"], // Charlie is invited to Shop B
  "9988776655": ["shop_A"], // New worker invited to shop A, not yet registered
};

class FakeAuthService implements IAuthService {
  UserProfile? loggedInUser;
  // 1. Declare the LocalStorageService field
  final LocalStorageService _localStorageService;

  // --- THIS IS YOUR NEW MAIN CONSTRUCTOR (FOR PRODUCTION) ---
  // It now REQUIRES a LocalStorageService instance
  FakeAuthService({required LocalStorageService localStorageService})
    : _localStorageService =
          localStorageService // Assign the provided instance
          {
    _initUser();
  }

  // Your existing test constructor (this remains unchanged and is correct for testing)
  FakeAuthService.test({required LocalStorageService localStorageService})
    : _localStorageService =
          localStorageService // Assign the provided instance
          {
    _initUser();
  }

  // 2. _initUser now uses the injected _localStorageService
  Future<void> _initUser() async {
    loggedInUser = await _localStorageService.getUserProfile();
  }

  @override
  Future<bool> sendVerificationCode(String phoneNumber) async {
    print('[FakeAuthService] Sending verification code to $phoneNumber');
    // Simulate sending an OTP. In a real scenario, this would involve an external service.
    return Future.value(true); // Always succeeds for fake service
  }

  @override
  Future<AuthResult> verifyCode(String phoneNumber, String code) async {
    print('[FakeAuthService] Verifying code $code for $phoneNumber');
    if (code != '123456') {
      return AuthResult(success: false, message: 'Invalid verification code.');
    }

    final user = fakeUsers[phoneNumber];
    if (user != null) {
      // User exists, log them in
      loggedInUser = user;
      await _localStorageService.saveUserProfile(user);
      return AuthResult(success: true, userProfile: user);
    } else {
      // New phone number, check if invited
      final invitedToShops = fakeInvites[phoneNumber];
      if (invitedToShops != null && invitedToShops.isNotEmpty) {
        return AuthResult(
          success: true,
          needsProfileCreation: true,
          isNewUser: true,
          userProfile: UserProfile(
            phoneNumber: phoneNumber,
            firstName: null, // New users don't have these until completeProfile
            lastName: null,
            profileName: '', // Empty, needs to be filled
            isManager: false,
            invitedToShops: invitedToShops,
          ),
        );
      } else {
        // Completely new user, potentially a manager
        return AuthResult(
          success: true,
          needsProfileCreation: true,
          isNewUser: true,
          userProfile: UserProfile(
            phoneNumber: phoneNumber,
            firstName: null, // New users don't have these until completeProfile
            lastName: null,
            profileName: '', // Empty, needs to be filled
            isManager: false,
          ),
        );
      }
    }
  }

  @override
  Future<AuthResult> completeProfile(
    String phoneNumber,
    String? firstName,
    String? lastName,
    String profileName,
    bool isManager,
  ) async {
    print(
      '[FakeAuthService] Completing profile for $phoneNumber: FirstName=$firstName, LastName=$lastName, ProfileName=$profileName, Manager=$isManager',
    );
    UserProfile? user = fakeUsers[phoneNumber];

    if (user != null) {
      // Update existing profile
      user = user.copyWith(
        firstName: firstName,
        lastName: lastName,
        profileName: profileName,
        isManager: isManager,
      );
      // Ensure shopsOwned is initialized if becoming manager
      if (isManager && user.shopsOwned == null) {
        user.shopsOwned = [];
      }
    } else {
      // Create new user profile
      final invitedToShops = fakeInvites[phoneNumber] ?? [];
      user = UserProfile(
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        profileName: profileName,
        isManager: isManager,
        shopsOwned: isManager ? [] : null,
        invitedToShops: invitedToShops.isNotEmpty ? invitedToShops : null,
      );
      fakeUsers[phoneNumber] = user;
      fakeInvites.remove(
        phoneNumber,
      ); // Remove from invites once profile is created
    }

    loggedInUser = user;
    await _localStorageService.saveUserProfile(user);
    return AuthResult(success: true, userProfile: user);
  }

  @override
  Future<AuthResult> acceptInvitation(String phoneNumber, String shopId) async {
    print(
      '[FakeAuthService] Accepting invitation for $phoneNumber to shop $shopId',
    );
    UserProfile? user = fakeUsers[phoneNumber];

    if (user == null || user.isManager) {
      return AuthResult(
        success: false,
        message: "Only workers can accept invitations.",
      );
    }

    // Ensure user.invitedToShops is initialized to an empty list if null, for safety
    List<String> userInvites = List.from(user.invitedToShops ?? []);

    if (userInvites.contains(shopId)) {
      // Check if the invitation actually exists in user's profile
      List<String> updatedShopsOwned = List.from(user.shopsOwned ?? []);
      if (!updatedShopsOwned.contains(shopId)) {
        updatedShopsOwned.add(shopId); // Add shop to owned list
      }

      // Remove the accepted shop from the user's invitedToShops list
      List<String> updatedInvitedToShops = userInvites
          .where((id) => id != shopId)
          .toList();

      // Create the updated user profile
      user = user.copyWith(
        shopsOwned: updatedShopsOwned,
        // Set to an empty list if no invites, for consistency with test
        invitedToShops: updatedInvitedToShops.isEmpty
            ? []
            : updatedInvitedToShops,
        currentShopId: shopId, // Set currentShopId explicitly after accepting
      );

      // Update in-memory fake DB
      fakeUsers[phoneNumber] = user;
      // Update internal logged-in user state
      loggedInUserForTest = user;
      // Save to fake local storage
      await _localStorageService.saveUserProfile(user);

      // Also update the fakeInvites map to reflect acceptance (manager's view)
      if (fakeInvites.containsKey(phoneNumber)) {
        fakeInvites[phoneNumber]!.remove(shopId);
        if (fakeInvites[phoneNumber]!.isEmpty) {
          fakeInvites.remove(
            phoneNumber,
          ); // Remove the user entry if no more invites
        }
      }

      return AuthResult(
        success: true,
        userProfile: user,
        message: 'Successfully joined $shopId',
      );
    } else {
      return AuthResult(
        success: false,
        message:
            'No invitation found for $phoneNumber to shop $shopId in user profile.',
      );
    }
  }

  @override
  Future<UserProfile?> getLoggedInUser() async {
    return loggedInUser;
  }

  @override
  Future<void> setCurrentShop(String shopId) async {
    if (loggedInUserForTest == null) {
      // Or throw an error, depending on your error handling strategy
      print('[FakeAuthService] No user logged in to set current shop.');
      return;
    }

    // OPTIONAL: Check if the shopId is actually owned by the user
    // This is good practice to prevent setting to an invalid shop.
    final userShops = loggedInUserForTest!.shopsOwned ?? [];
    final userManagedShops = loggedInUserForTest!.shopsOwned ?? [];
    if (!userShops.contains(shopId) && !userManagedShops.contains(shopId)) {
      print('[FakeAuthService] User does not own or manage shop: $shopId');
      // You might want to return an error or AuthResult here too.
      return;
    }

    // Only update and save if the shopId is actually changing
    if (loggedInUserForTest!.currentShopId != shopId) {
      print(
        '[FakeAuthService] Current shop set to $shopId for ${loggedInUserForTest!.phoneNumber}',
      );
      loggedInUserForTest = loggedInUserForTest!.copyWith(
        currentShopId: shopId,
      );
      await _localStorageService.saveUserProfile(loggedInUserForTest!);
    } else {
      print(
        '[FakeAuthService] Current shop already $shopId, no change needed.',
      );
    }
  }

  @override
  Future<void> logout() async {
    print('[FakeAuthService] Logging out user.');
    loggedInUser = null;
    await _localStorageService.clearUserProfile();
    return Future.value();
  }

  UserProfile? get loggedInUserForTest => loggedInUser; // Getter for testing
  set loggedInUserForTest(UserProfile? user) =>
      loggedInUser = user; // Setter for testing
}
