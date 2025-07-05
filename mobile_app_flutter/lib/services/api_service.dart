// dukani/mobile_app_flutter/lib/services/api_service.dart

import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async'; // Import for TimeoutException

// --- API Configuration (IMPORTANT: Update for Docker environment) ---
// If running Django backend in Docker:
// - For Android Emulator: Use '10.0.2.2' which is an alias for your host machine's localhost.
// - For Physical Android Device: Use your host machine's actual local IPv4 address (e.g., '192.168.1.100').
//   Ensure your Docker container is publishing the port (e.g., -p 8000:8000).
// - Ensure your Django development server is running with `python manage.py runserver 0.0.0.0:8000`
//   inside the Docker container to be accessible from outside.
const String API_BASE_URL = 'http://10.0.0.222:8000/api/'; // <-- UPDATED FOR ANDROID EMULATOR WITH DOCKER

// ApiService class to handle all API calls
class ApiService {
  // Method to post a new stock entry
  // It returns true on success, false on failure
  Future<bool> postStockEntry(Map<String, dynamic> data) async {
    final Uri url = Uri.parse('${API_BASE_URL}stock-entries/');
    print('ApiService: Attempting to POST to $url with data: $data'); // Debug print

    try {
      final response = await http.post(
        url,
        headers: <String, String>{
          'Content-Type': 'application/json; charset=UTF-8',
          // Add Authorization header if your API requires it (e.g., Token 'your_token')
          // 'Authorization': 'Token YOUR_AUTH_TOKEN',
        },
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 10)); // Set a timeout of 10 seconds

      if (response.statusCode == 201) { // 201 Created is typical for successful POST
        print('ApiService: Stock Entry POST successful! Response: ${response.body}'); // Debug print
        return true;
      } else {
        print('ApiService: Stock Entry POST failed! Status: ${response.statusCode}, Body: ${response.body}'); // Debug print
        // You might want to throw an exception or return a more detailed error object
        return false;
      }
    } on TimeoutException catch (e) {
      print('ApiService: Request timed out during Stock Entry POST: $e'); // Debug print for timeout
      return false; // Indicate failure due to timeout
    } catch (e) {
      print('ApiService: Network error during Stock Entry POST: $e'); // Debug print
      // You might want to throw an exception or return a more detailed error object
      return false;
    }
  }

  // You can add other API methods here as your app grows
  // Future<Product> fetchProductDetails(String barcode) async { ... }
  // Future<bool> postSaleEntry(Map<String, dynamic> data) async { ... }
}
