// dukani/mobile_app_flutter/lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import './api_provider.dart';
import 'package:flutter/material.dart';

// --- API Configuration ---
// Change this URL in one place to switch between local/dev/prod backend easily
class ApiConfig {
  static String baseUrl = 'http://10.0.0.222:8000/api/';

  // Example method to update baseUrl at runtime if needed
  static void updateBaseUrl(String newUrl) {
    baseUrl = newUrl;
  }
}

class ApiService implements ApiProvider {
  // POST a new stock entry
  @override
  Future<bool> postStockEntry(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}stock-entries/');
    print('ApiService: POST stock entry to $url with data: $data');

    try {
      final response = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        print('ApiService: Stock entry POST success: ${response.body}');
        return true;
      } else {
        print(
          'ApiService: Stock entry POST failed. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } on TimeoutException catch (e) {
      print('ApiService: Timeout posting stock entry: $e');
      return false;
    } catch (e) {
      print('ApiService: Error posting stock entry: $e');
      return false;
    }
  }


  @override
  Future<bool> recordStockItem(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}stock-entries/');
    print('ApiService: POST stock entry to $url with data: $data');

    try {
      final response = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode(data),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        print('ApiService: Stock entry POST success: ${response.body}');
        return true;
      } else {
        print(
          'ApiService: Stock entry POST failed. Status: ${response.statusCode}, Body: ${response.body}',
        );
        return false;
      }
    } on TimeoutException catch (e) {
      print('ApiService: Timeout posting stock entry: $e');
      return false;
    } catch (e) {
      print('ApiService: Error posting stock entry: $e');
      return false;
    }
  }

  // POST to onboard a new shop
  @override
  Future<Map<String, dynamic>> onboardShop({
    required String name,
    required String address,
    required BuildContext context,
  }) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}shops/onboard-shop/');
    String managerName = '';
    String managerPhone = '';
    print('ApiService: POST onboard shop to $url');

    try {
      final response = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
            },
            body: jsonEncode({
              'name': name,
              'address': address,
              'manager_name': managerName,
              'manager_phone': managerPhone,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        print('ApiService: Shop onboarded successfully: $data');
        return {'success': true, 'shop_id': data['shop_id']};
      } else {
        final errorData = jsonDecode(response.body);
        print(
          'ApiService: Failed to onboard shop. Status: ${response.statusCode}, Body: $errorData',
        );
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Unknown error',
        };
      }
    } on TimeoutException catch (e) {
      print('ApiService: Timeout onboarding shop: $e');
      return {'success': false, 'message': 'Request timed out'};
    } catch (e) {
      print('ApiService: Error onboarding shop: $e');
      return {'success': false, 'message': 'Unexpected error occurred'};
    }
  }

  @override
  Future<Map<String, dynamic>> inviteWorker({
    required String shopId,
    required String name,
    required String phone,
  }) async {
    final Uri url = Uri.parse('${ApiConfig.baseUrl}shops/$shopId/invite-worker/');

    try {
      final response = await http
          .post(
            url,
            headers: <String, String>{
              'Content-Type': 'application/json; charset=UTF-8',
              // Add Authorization header here if needed
            },
            body: jsonEncode({
              'first_name': name,
              'phone_number': phone,
              // Optionally add 'email' if you want
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode == 201) {
        final data = jsonDecode(response.body);
        return {
          'success': true,
          'invite_code': data['invite_code'],
          'worker_id': data['worker_id'],
        };
      } else {
        final errorData = jsonDecode(response.body);
        return {
          'success': false,
          'message': errorData['detail'] ?? 'Unknown error',
        };
      }
    } on TimeoutException catch (e) {
      return {'success': false, 'message': 'Request timed out: $e'};
    } catch (e) {
      return {'success': false, 'message': 'Error inviting worker: $e'};
    }
  }

  @override
  Future<Map<String, dynamic>> onboardManager({
    required String shopId,
    required String managerName,
    required String managerPhone,
    required BuildContext context,
  }) async {
    final url = Uri.parse('${ApiConfig.baseUrl}}shops/$shopId/onboard-manager/');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'manager_name': managerName,
        'manager_phone': managerPhone,
      }),
    );

    if (response.statusCode == 201 || response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to onboard manager: ${response.body}');
    }
  }
}
