import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/models.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as fb_auth; // Alias to avoid conflict with our User class

class UserSessionProvider with ChangeNotifier {
  // Firebase Auth instance
  final fb_auth.FirebaseAuth _auth = fb_auth.FirebaseAuth.instance;
  // Firebase Firestore instance
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // The full User object (Manager or Worker) for the current session
  User? _currentUser;
  bool _isLoading = true; // To indicate if session data is being loaded or auth state is resolving
  String? _verificationId; // Stores the verification ID received from Firebase Phone Auth
  int? _resendToken; // Stores the resend token for phone auth
  String? _authError; // Stores authentication-related errors

  // Public getters
  User? get currentUser => _currentUser;
  String? get userId => _currentUser?.firebaseUid; // Get Firebase UID from currentUser
  String? get shopId => _currentUser?.shopId; // Get shopId from currentUser
  UserType get userType => _currentUser?.userType ?? UserType.worker; // Default to worker if unknown
  bool get isLoading => _isLoading;
  bool get isAuthenticated => _currentUser?.firebaseUid != null; // Check if Firebase UID is present
  String? get verificationId => _verificationId;
  int? get resendToken => _resendToken;
  String? get authError => _authError;

  UserSessionProvider() {
    // Listen to Firebase Auth state changes
    _auth.authStateChanges().listen((fb_auth.User? fbUser) async {
      if (fbUser == null) {
        // User is signed out
        _currentUser = null;
        _verificationId = null;
        _resendToken = null;
        print('User signed out. currentUser is now null.');
      } else {
        // User is signed in via Firebase Auth
        print('Firebase user signed in: UID = ${fbUser.uid}');
        await _fetchAndSetCurrentUser(fbUser.uid, fbUser.phoneNumber); // Fetch additional user data from Firestore
      }
      _isLoading = false; // Auth state resolved
      _authError = null; // Clear any previous auth errors
      notifyListeners();
    });
  }

  // Fetches user-specific data from Firestore and constructs the User object
  Future<void> _fetchAndSetCurrentUser(String uid, String? phoneNumber) async {
    try {
      final userDoc = await _firestore.collection('users').doc(uid).get();
      if (userDoc.exists) {
        final data = userDoc.data();
        if (data != null) {
          // Add firebaseUid and phoneNumber to the data map if not already there
          // This ensures the User.fromJson factory has all necessary info
          data['firebaseUid'] = uid;
          data['phoneNumber'] = phoneNumber; // Use phone number from Firebase Auth

          _currentUser = User.fromJson(data); // Construct the specific User (Worker/Manager)
          print('Fetched user data: $_currentUser');
        } else {
          // Should not happen if userDoc.exists is true, but for safety
          _currentUser = null;
          print('User document data is null for UID: $uid');
        }
      } else {
        // This means the user just signed in via phone auth but doesn't have
        // their Firestore profile (role, shopId) yet. This is a new user.
        print('User document not found for UID: $uid. This is likely a new user.');
        // Create a basic User object with just Firebase UID and phone number
        // This allows the UI to proceed to role selection for new users.
        _currentUser = Worker( // Use Worker as a generic base for unassigned users
          name: 'New User', // Placeholder name
          phoneNumber: phoneNumber ?? 'N/A',
          firebaseUid: uid
        );
      }
    } catch (e) {
      print('Error fetching user data: $e');
      _authError = 'Failed to load user profile.';
      _currentUser = null; // Clear current user on error
    }
  }

  /// Initiates phone number verification by sending an OTP SMS.
  /// The `codeSent` callback will update `_verificationId` and `_resendToken`.
  /// The UI should listen to these changes to navigate to the OTP entry screen.
  Future<void> initiatePhoneAuth(String phoneNumber) async {
    _isLoading = true;
    _authError = null; // Clear previous errors
    notifyListeners();

    try {
      await _auth.verifyPhoneNumber(
        phoneNumber: phoneNumber,
        verificationCompleted: (fb_auth.PhoneAuthCredential credential) async {
          // AUTO-RETRIEVAL: This callback is fired when a credential is automatically verified
          // on Android devices (e.g., SMS auto-read). Sign in the user immediately.
          print('Verification completed: ${credential.smsCode}');
          await _auth.signInWithCredential(credential);
          // The authStateChanges listener will handle updating _currentUser
        },
        verificationFailed: (fb_auth.FirebaseAuthException e) {
          // Handle verification failure (e.g., invalid phone number, quota exceeded)
          print('Verification failed: ${e.code} - ${e.message}');
          _authError = e.message ?? 'Phone verification failed.';
          _isLoading = false;
          notifyListeners();
        },
        codeSent: (String verificationId, int? resendToken) {
          // OTP code sent to the phone number
          print('Code sent to $phoneNumber. Verification ID: $verificationId');
          _verificationId = verificationId;
          _resendToken = resendToken; // Store resend token for resend functionality
          _isLoading = false; // Stop loading, as code is sent
          notifyListeners();
          // UI should now navigate to OTP entry screen using _verificationId
        },
        codeAutoRetrievalTimeout: (String verificationId) {
          // Auto-retrieval timeout
          print('Auto-retrieval timeout for $verificationId');
          _verificationId = verificationId; // Still keep verificationId in case user manually enters
          _isLoading = false;
          notifyListeners();
        },
        timeout: const Duration(seconds: 60), // OTP timeout
      );
    } catch (e) {
      print('Error initiating phone auth: $e');
      _authError = 'Failed to initiate phone verification.';
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Signs in the user using the provided SMS code and the stored verification ID.
  /// Returns true on successful sign-in, false on failure.
  Future<bool> signInWithPhoneNumber(String smsCode) async {
    _isLoading = true;
    _authError = null; // Clear previous errors
    notifyListeners();

    try {
      if (_verificationId == null) {
        _authError = 'Verification ID is missing. Please re-enter phone number.';
        return false;
      }
      fb_auth.PhoneAuthCredential credential = fb_auth.PhoneAuthProvider.credential(
        verificationId: _verificationId!,
        smsCode: smsCode,
      );
      await _auth.signInWithCredential(credential);
      // The authStateChanges listener will handle updating _currentUser
      print('Signed in with phone number successfully.');
      return true;
    } on fb_auth.FirebaseAuthException catch (e) {
      print('Sign in with phone number failed: ${e.message}');
      _authError = e.message ?? 'Invalid OTP or sign-in failed.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Completes the user's registration by storing their role and shop ID in Firestore.
  /// This should be called *after* a new user successfully signs in via phone auth.
  Future<bool> completeRegistration({
    required UserType userType,
    required String name,
    required String phoneNumber,
    String? shopId,
  }) async {
    _isLoading = true;
    _authError = null; // Clear previous errors
    notifyListeners();
    try {
      if (_currentUser?.firebaseUid == null) {
        _authError = 'No authenticated user to complete registration for.';
        return false;
      }

      // Create the data map for Firestore
      final Map<String, dynamic> userData = {
        'firstName': '',
        'lastName': '',
        'name': name,
        'phoneNumber': phoneNumber, // Use the phone number provided during registration
        'userType': userType.toString().split('.').last, // 'manager' or 'worker'
        'shopId': shopId,
        'createdAt': FieldValue.serverTimestamp(),
      };

      // Store additional user data in Firestore
      await _firestore.collection('users').doc(_currentUser!.firebaseUid!).set(
        userData,
        SetOptions(merge: true), // Use merge to update existing doc if it exists (e.g., from authStateChanges)
      );

      // Update local _currentUser state immediately for responsiveness
      if (userType == UserType.manager) {
        _currentUser = Manager(
          //firstName: '',
          //lastName: '',
          id: _currentUser!.id, // Preserve existing ID if any, or generate new
          name: name,
          phoneNumber: phoneNumber,
          firebaseUid: _currentUser!.firebaseUid,
          shopId: shopId,
        );
      } else {
        _currentUser = Worker(
          //firstName: '',
          //lastName: '',
          id: _currentUser!.id, // Preserve existing ID if any, or generate new
          name: name,
          phoneNumber: phoneNumber,
          firebaseUid: _currentUser!.firebaseUid,
          shopId: shopId,
        );
      }
      print('User registration completed: Role = ${userType.toString().split('.').last}');
      return true;
    } catch (e) {
      print('Error completing registration: $e');
      _authError = 'Failed to complete registration.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Logs out the current user.
  Future<void> logoutUser() async {
    _isLoading = true;
    _authError = null;
    notifyListeners();
    try {
      await _auth.signOut();
      // The authStateChanges listener will handle clearing _currentUser
      print('User logged out.');
    } catch (e) {
      print('Error during logout: $e');
      _authError = 'Error during logout.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // This method would only clear local SharedPreferences, not Firebase Auth state.
  Future<void> clearLocalSessionCache() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('userId'); // Remove any old cached IDs
    await prefs.remove('shopId'); // Remove any old cached IDs
    print('Local session cache cleared.');
  }
}
