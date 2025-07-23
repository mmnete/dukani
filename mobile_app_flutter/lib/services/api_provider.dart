import 'package:flutter/material.dart';
import '../models/models.dart';


abstract class ApiProvider {
  Future<Map<String, dynamic>> onboardShop({
    required String name,
    required String address,
    required String phoneNumber, // Shop's phone number
    required String managerFirebaseUid, // Firebase UID of the manager creating the shop
  });

  Future<Map<String, dynamic>> onboardManager({
    required String shopId,
    required String managerName,
    required String managerPhone,
    required String managerFirebaseUid, // Firebase UID of the manager being onboarded
  });

  Future<Map<String, dynamic>> inviteWorker({
    required String shopId,
    required String name,
    required String phoneNumber,
    required String managerFirebaseUid, // UID of the manager inviting the worker
  });

  Future<Map<String, dynamic>> getShopDetails(String shopId);
  Future<List<Shop>> getAllShops(); // New method to get all dummy shops

  // Existing methods
  Future<bool> postStockEntry(Map<String, dynamic> data);
  Future<bool> recordStockItem(Map<String, dynamic> item);
}