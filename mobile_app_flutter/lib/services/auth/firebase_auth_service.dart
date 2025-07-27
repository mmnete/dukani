// lib/services/auth/firebase_auth_service.dart

import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'i_auth_service.dart'; // Adjust import path
import 'local_storage_service.dart'; // Adjust import path

class FirebaseAuthService implements IAuthService {
  final firebase_auth.FirebaseAuth _auth;
  final FirebaseFirestore _firestore;
  final LocalStorageService _localStorageService;
  UserProfile? loggedInUser;

  FirebaseAuthService({required LocalStorageService localStorageService})
    : _auth =
          firebase_auth.FirebaseAuth.instance, // Still uses real Firebase Auth
      _firestore = FirebaseFirestore.instance, // Still uses real Firestore
      _localStorageService =
          localStorageService // Uses the provided instance
          {
    _initUser();
  }

  FirebaseAuthService.test({
    required firebase_auth.FirebaseAuth auth,
    required FirebaseFirestore firestore,
    required LocalStorageService localStorageService,
  }) : _auth = auth, // Assign the injected mock auth
       _firestore = firestore, // Assign the injected mock firestore
       _localStorageService = localStorageService {
    // Assign the injected mock local storage
    _initUser(); // Still call init user, which will now use the mocks
  }

  Future<void> _initUser() async {
    loggedInUser = await _localStorageService.getUserProfile();
  }

  @override
  Future<bool> sendVerificationCode(String phoneNumber) async {
    print('[FirebaseAuthService] Sending verification code to $phoneNumber');
    // NOTE: For phone authentication on web, you need to handle reCAPTCHA verifier.
    // For mobile, Firebase will handle SMS.
    await _auth.verifyPhoneNumber(
      phoneNumber: phoneNumber,
      verificationCompleted: (credential) async {
        // Auto-retrieve, auto-sign in
        print('Verification Completed: ${credential.smsCode}');
        // This callback is usually for Android auto-retrieval
        // You might want to sign in the user here directly
        // await _auth.signInWithCredential(credential);
      },
      verificationFailed: (error) {
        print('Verification Failed: ${error.message}');
        // Handle error cases like invalid phone number, quota exceeded, etc.
      },
      codeSent: (verificationId, resendToken) {
        print('Code Sent to $phoneNumber. Verification ID: $verificationId');
        // Store verificationId for later use in verifyCode
        // This is typically passed to the UI to prompt for OTP.
        // For Flutter web, you might need to show a reCAPTCHA widget here.
        // You would typically store the verificationId in a state management solution
        // or pass it directly back to the calling widget.
      },
      codeAutoRetrievalTimeout: (verificationId) {
        print(
          'Code Auto Retrieval Timeout for Verification ID: $verificationId',
        );
      },
      timeout: const Duration(seconds: 60), // Set timeout
    );
    return true; // Assume code sending was initiated
  }

  @override
  Future<AuthResult> verifyCode(String phoneNumber, String code) async {
    print('[FirebaseAuthService] Verifying code $code for $phoneNumber');
    try {
      // In a real scenario, `verificationId` would be obtained from `codeSent` callback
      // and passed here along with the code. For simplicity of placeholder, let's assume
      // a direct sign-in method if possible (or a mock of `PhoneAuthProvider.credential`).
      // For now, this is a placeholder.

      // This is highly simplified and won't work without actual `verificationId` from `sendVerificationCode`.
      // PhoneAuthCredential credential = PhoneAuthProvider.credential(
      //   verificationId: "YOUR_STORED_VERIFICATION_ID", // This needs to come from `codeSent`
      //   smsCode: code,
      // );
      // await _auth.signInWithCredential(credential);

      // --- Placeholder for actual Firebase interaction ---
      // For testing without actual Firebase, consider a mock or a simplified direct sign-in for testing purposes
      // or implement proper verificationId handling in your UI flow.

      // Simulate getting a Firebase user after successful verification (if using a mock or a simplified flow)
      final firebase_auth.User? currentUser =
          _auth.currentUser; // Or simulate this user

      if (currentUser == null) {
        // If no Firebase user is currently signed in (e.g., initial app launch, or verification failed)
        // This part might need to be re-evaluated depending on how your actual Firebase auth flow works.
        // Usually, `verifyCode` would lead to `signInWithCredential` and then `currentUser` would be available.
        // For now, keeping the placeholder as is, assuming a successful `signInWithCredential` would precede this.
        print('Warning: No Firebase user signed in after verifyCode attempt.');
        // For a more robust real implementation, if `signInWithCredential` failed,
        // you'd return an AuthResult indicating failure much earlier.
        // If currentUser is null here, it means the verification itself didn't lead to a signed-in user.
        // This part needs careful thought when integrating real Firebase.
      }

      // Fetch user profile from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(phoneNumber)
          .get();

      if (userDoc.exists) {
        final userData = UserProfile.fromJson(userDoc.data()!);
        loggedInUser = userData;
        await _localStorageService.saveUserProfile(userData);
        return AuthResult(success: true, userProfile: userData);
      } else {
        // New user, check for invitations
        final inviteDoc = await _firestore
            .collection('invitations')
            .doc(phoneNumber)
            .get();
        if (inviteDoc.exists) {
          final invitedToShops =
              (inviteDoc.data()?['shops'] as List<dynamic>?)
                  ?.map((e) => e as String)
                  .toList() ??
              [];
          return AuthResult(
            success: true,
            needsProfileCreation: true,
            isNewUser: true,
            userProfile: UserProfile(
              phoneNumber: phoneNumber,
              firstName: null, // New users typically don't have these yet
              lastName: null,
              profileName: '', // Empty, as it needs to be set
              isManager:
                  false, // Default to worker, can be changed during completeProfile
              invitedToShops: invitedToShops,
            ),
          );
        }
        return AuthResult(
          success: true,
          needsProfileCreation: true,
          isNewUser: true,
          userProfile: UserProfile(
            phoneNumber: phoneNumber,
            firstName: null, // New users typically don't have these yet
            lastName: null,
            profileName: '', // Empty, as it needs to be set
            isManager:
                false, // Default to worker, can be changed during completeProfile
          ),
        );
      }
    } catch (e) {
      print('Error during Firebase code verification: $e');
      return AuthResult(success: false, message: e.toString());
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
      '[FirebaseAuthService] Completing profile for $phoneNumber with firstName: $firstName, lastName: $lastName, profileName: $profileName',
    );
    try {
      final newUserProfile = UserProfile(
        phoneNumber: phoneNumber,
        firstName: firstName,
        lastName: lastName,
        profileName: profileName,
        isManager: isManager,
        shopsOwned: isManager ? [] : null, // Initialize empty list if manager
        invitedToShops:
            loggedInUser?.invitedToShops, // Carry over any existing invitations
      );

      // Save to Firestore
      await _firestore
          .collection('users')
          .doc(phoneNumber)
          .set(newUserProfile.toJson(), SetOptions(merge: true));

      // Remove from invitations collection if it was an invited user
      await _firestore.collection('invitations').doc(phoneNumber).delete();

      loggedInUser = newUserProfile;
      await _localStorageService.saveUserProfile(newUserProfile);
      return AuthResult(success: true, userProfile: newUserProfile);
    } catch (e) {
      print('Error completing profile: $e');
      return AuthResult(success: false, message: e.toString());
    }
  }

  @override
  Future<AuthResult> acceptInvitation(String phoneNumber, String shopId) async {
    print(
      '[FirebaseAuthService] Accepting invitation for $phoneNumber to shop $shopId',
    );
    try {
      final userDocRef = _firestore.collection('users').doc(phoneNumber);
      final userDoc = await userDocRef.get();

      if (!userDoc.exists) {
        return AuthResult(
          success: false,
          message: "User profile not found. User must complete profile first.",
        );
      }
      final userProfile = UserProfile.fromJson(userDoc.data()!);

      if (userProfile.isManager) {
        return AuthResult(
          success: false,
          message: "Managers cannot accept invitations.",
        );
      }

      // 1. Get the list of invited shops from the UserProfile itself (from Firestore)
      List<String> userInvitedToShops = List.from(
        userProfile.invitedToShops ?? [],
      );

      // 2. Check if the user is actually invited to this shop from their profile's list
      if (!userInvitedToShops.contains(shopId)) {
        return AuthResult(
          success: false,
          message:
              'No invitation found for $phoneNumber to shop $shopId in user profile.',
        );
      }

      // 3. Update shopsOwned
      final List<String> currentShopsOwned = List.from(
        userProfile.shopsOwned ?? [],
      );
      if (!currentShopsOwned.contains(shopId)) {
        currentShopsOwned.add(shopId);
      }

      // 4. Update invitedToShops for the user profile (remove the accepted shop)
      final List<String> updatedUserInvitedShops = userInvitedToShops
          .where((id) => id != shopId)
          .toList();

      // 5. Update user profile in Firestore
      await userDocRef.update({
        'shopsOwned': currentShopsOwned,
        // Set to an empty array in Firestore if the list is empty (consistent with test expectation)
        'invitedToShops': updatedUserInvitedShops.isEmpty
            ? [] // Send empty array, not FieldValue.delete()
            : updatedUserInvitedShops,
        'currentShopId': shopId,
      });

      // --- Handle the separate 'invitations' collection document ---
      // This collection typically stores invitations sent BY managers TO workers.
      // We need to update or delete the invitation record from here as well.
      final invitationDocRef = _firestore
          .collection('invitations')
          .doc(phoneNumber);
      final invitationDoc = await invitationDocRef.get();

      if (invitationDoc.exists) {
        List<String> invitationShops =
            (invitationDoc.data()?['shops'] as List<dynamic>?)
                ?.map((e) => e as String)
                .toList() ??
            [];

        invitationShops.remove(shopId); // Remove from the invitation document

        if (invitationShops.isEmpty) {
          await invitationDocRef
              .delete(); // Delete the whole invitation doc if no more invites
        } else {
          await invitationDocRef.update({
            'shops': invitationShops,
          }); // Update if still has shops
        }
      }
      // --- End of invitations collection handling ---

      // 6. Update local state and save to local storage
    loggedInUser = userProfile.copyWith(
        shopsOwned: currentShopsOwned,
        // Keep this consistent with Firestore update: an empty list when empty
        invitedToShops: updatedUserInvitedShops.isEmpty
            ? []
            : updatedUserInvitedShops,
        currentShopId: shopId,
      );
      await _localStorageService.saveUserProfile(loggedInUser!);

      return AuthResult(
        success: true,
        userProfile: loggedInUser,
        message: 'Successfully joined $shopId',
      );
    } catch (e) {
      print('Error accepting invitation: $e');
      return AuthResult(success: false, message: e.toString());
    }
  }

  @override
  Future<UserProfile?> getLoggedInUser() async {
    return loggedInUser;
  }

  @override
  Future<void> setCurrentShop(String shopId) async {
    if (loggedInUser == null) {
      print(
        '[FirebaseAuthService] Cannot set current shop: No user logged in.',
      );
      return;
    }

    // Ensure the user actually has access to this shop (either owns it or is invited/joined)
    bool hasAccess =
        (loggedInUser!.shopsOwned?.contains(shopId) == true) ||
        (loggedInUser!.invitedToShops?.contains(shopId) == true) ||
        (loggedInUser!.shopsOwned == null &&
            loggedInUser!.invitedToShops ==
                null); // Consider if this is a brand new user with no shops yet.

    // A more robust check might involve fetching the shop from UserService to confirm existence and user's role.
    // For MVP, relying on the user's local profile shopsOwned/invitedToShops is sufficient.
    // If it's a new manager creating their first shop, currentShopId will be set after shop creation.

    if (hasAccess) {
      loggedInUser = loggedInUser!.copyWith(currentShopId: shopId);
      await _localStorageService.saveUserProfile(loggedInUser!);
      print(
        '[FirebaseAuthService] Current shop set to $shopId for ${loggedInUser!.phoneNumber}',
      );

      // Optional: If you want to persist this to Firestore, you would do it here:
      // await _firestore.collection('users').doc(loggedInUser!.phoneNumber).update({
      //   'currentShopId': shopId,
      // });
    } else {
      print(
        '[FirebaseAuthService] User ${loggedInUser!.phoneNumber} does not have access to shop $shopId.',
      );
    }
  }

  @override
  Future<void> logout() async {
    print('[FirebaseAuthService] Logging out user.');
    await _auth.signOut();
    loggedInUser = null;
    await _localStorageService.clearUserProfile();
  }

  // Inside your FirebaseAuthService class (as suggested in comments)
  // ...
  UserProfile? get loggedInUserForTest => loggedInUser; // Getter for testing
  set loggedInUserForTest(UserProfile? user) =>
      loggedInUser = user; // Setter for testing
  // ...
}
