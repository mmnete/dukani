// lib/services/auth/firebase_user_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'i_user_service.dart'; // Adjust import path

class FirebaseUserService implements IUserService {
  final FirebaseFirestore _firestore;

  FirebaseUserService({required FirebaseFirestore firestore})
      : _firestore = firestore;

  // Add this constructor for testing purposes
  FirebaseUserService.test({required FirebaseFirestore firestore}) : _firestore = firestore;


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
        '[FirebaseUserService] Creating shop "$shopName" for manager $managerPhoneNumber in $city, $country');
    try {
      final newShopRef = _firestore.collection('shops').doc();
      await newShopRef.set({
        'name': shopName,
        'managerPhoneNumber': managerPhoneNumber,
        'storeType': storeType,
        'businessRegistrationNumber': businessRegistrationNumber,
        // Universal Address Components storage
        'streetAddress': streetAddress,
        'streetAddress2': streetAddress2,
        'city': city,
        'region': region,
        'postalCode': postalCode,
        'country': country, // Store the required country
        'storePhoneNumber': storePhoneNumber,
        'storeEmail': storeEmail,
        'createdAt': FieldValue.serverTimestamp(),
      });

      // Update manager's user profile with the new shop ID
      final managerUserRef = _firestore.collection('users').doc(managerPhoneNumber);
      await managerUserRef.update({
        'shopsOwned': FieldValue.arrayUnion([newShopRef.id])
      });
      return newShopRef.id;
    } catch (e) {
      print('Error creating shop: $e');
      rethrow; // Re-throw to be handled by the calling code
    }
  }

  @override
  Future<bool> inviteWorkerToShop(
      String managerPhoneNumber, String shopId, String workerPhoneNumber) async {
    print(
        '[FirebaseUserService] Inviting worker $workerPhoneNumber to shop $shopId by manager $managerPhoneNumber');
    try {
      // Optional: Verify manager owns the shop (can also be handled by Firestore security rules)
      final shopDoc = await _firestore.collection('shops').doc(shopId).get();
      if (!shopDoc.exists || shopDoc.data()?['managerPhoneNumber'] != managerPhoneNumber) {
        return false;
      }

      // Create or update an invitation document for the worker
      final invitationRef = _firestore.collection('invitations').doc(workerPhoneNumber);
      await invitationRef.set({
        'shops': FieldValue.arrayUnion([shopId]),
        'invitedBy': managerPhoneNumber, // Optional: track who invited
      }, SetOptions(merge: true));
      return true;
    } catch (e) {
      print('Error inviting worker: $e');
      return false;
    }
  }

  @override
  Future<List<ShopInfo>> getShopsOwnedByManager(String managerPhoneNumber) async {
    print('[FirebaseUserService] Getting shops owned by manager $managerPhoneNumber');
    try {
      final shopsSnapshot = await _firestore.collection('shops').where('managerPhoneNumber', isEqualTo: managerPhoneNumber).get();
      // When mapping documents, we need to manually include the doc.id for the 'id' field
      return shopsSnapshot.docs.map((doc) => ShopInfo.fromJson({'id': doc.id, ...doc.data()})).toList();
    } catch (e) {
      print('Error getting shops owned by manager: $e');
      return [];
    }
  }

  @override
  Future<List<ShopInfo>> getInvitedShopsForWorker(String workerPhoneNumber) async {
    print('[FirebaseUserService] Getting invited shops for worker $workerPhoneNumber');
    try {
      final invitationDoc = await _firestore.collection('invitations').doc(workerPhoneNumber).get();
      if (invitationDoc.exists) {
        final invitedShopIds = (invitationDoc.data()?['shops'] as List<dynamic>?)?.map((e) => e as String).toList() ?? [];
        if (invitedShopIds.isEmpty) return [];

        // Fetch shop details for each invited shop ID
        final shopPromises = invitedShopIds.map((shopId) async {
          final shopDoc = await _firestore.collection('shops').doc(shopId).get();
          // Ensure 'id' is included when creating ShopInfo from Firestore data
          return shopDoc.exists ? ShopInfo.fromJson({'id': shopDoc.id, ...shopDoc.data()!}) : null;
        }).toList();

        final shops = await Future.wait(shopPromises);
        return shops.where((shop) => shop != null).cast<ShopInfo>().toList();
      }
      return [];
    } catch (e) {
      print('Error getting invited shops for worker: $e');
      return [];
    }
  }
}

