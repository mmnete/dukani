import 'package:flutter/material.dart';

abstract class ApiProvider {
  Future<Map<String, dynamic>> onboardShop({
    required String name,
    required String address,
    required BuildContext context, // Removed manager details, added context
  });

  Future<Map<String, dynamic>> onboardManager({
    required String shopId,
    required String managerName,
    required String managerPhone,
    required BuildContext context, // Added context
  });

  Future<bool> postStockEntry(Map<String, dynamic> data);

  Future<bool> recordStockItem(Map<String, dynamic> item);

  Future<Map<String, dynamic>> inviteWorker({
    required String shopId,
    required String name,
    required String phone,
  });
}