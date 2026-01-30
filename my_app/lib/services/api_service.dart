import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

class ApiService {
  // Use 10.0.2.2 for Android Emulator, localhost for iOS/Web/Desktop
  static final String _baseUrl = kIsWeb || defaultTargetPlatform == TargetPlatform.windows 
      ? "http://127.0.0.1:5050" 
      : "http://10.0.2.2:5050";

  // --- Appointments ---

  static Future<Map<String, dynamic>?> fetchSingleAppointment(String id) async {
    try {
      final url = "$_baseUrl/appointments/single/$id?t=${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("API fetchSingleAppointment error: $e");
      return null;
    }
  }

  static Future<List<Map<String, dynamic>>> fetchAppointments(String uid, String role) async {
    try {
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      // Use Uri.https or Uri.http for cleaner parameter building
      final url = "$_baseUrl/appointments?uid=$uid&role=$role&t=$timestamp";
      
      debugPrint("API: GET $url");
      final response = await http.get(Uri.parse(url)).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        return List<Map<String, dynamic>>.from(jsonDecode(response.body));
      }
      return [];
    } catch (e) {
      debugPrint("API fetchAppointments error: $e");
      return [];
    }
  }

  static Future<void> createAppointment(Map<String, dynamic> data) async {
    try {
      final response = await http.post(
        Uri.parse("$_baseUrl/appointments"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 201) {
        throw 'Failed to create appointment';
      }
    } catch (e) {
      throw 'Server error: $e';
    }
  }

  static Future<void> updateAppointment(String id, Map<String, dynamic> data) async {
    try {
      final response = await http.put(
        Uri.parse("$_baseUrl/appointments/$id"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw 'Failed to update appointment';
      }
    } catch (e) {
      throw 'Server error: $e';
    }
  }

  static Future<void> deleteAppointment(String id) async {
    try {
      final response = await http.delete(
        Uri.parse("$_baseUrl/appointments/$id"),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode != 200) {
        throw 'Failed to delete appointment';
      }
    } catch (e) {
      throw 'Server error: $e';
    }
  }

  // --- Users ---

  static Future<List<Map<String, dynamic>>> fetchFaculties() async {
    try {
      final response = await http.get(Uri.parse("$_baseUrl/faculty"))
          .timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        List<dynamic> data = jsonDecode(response.body);
        return data.map((item) => Map<String, dynamic>.from(item)).toList();
      } else {
        return [];
      }
    } catch (e) {
      return [];
    }
  }

  static Future<void> saveUser(Map<String, dynamic> data) async {
    final url = "$_baseUrl/users";
    try {
      debugPrint("API: POST to $url");
      final response = await http.post(
        Uri.parse(url),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(data),
      ).timeout(const Duration(seconds: 5));
      debugPrint("API: Response Code ${response.statusCode}");
    } catch (e) {
      debugPrint("API saveUser error: $e");
    }
  }

  static Future<Map<String, dynamic>?> fetchUserProfile(String uid) async {
    try {
      // Add timestamp to prevent browser caching of old profile data
      final url = "$_baseUrl/users/$uid?t=${DateTime.now().millisecondsSinceEpoch}";
      final response = await http.get(Uri.parse(url))
          .timeout(const Duration(seconds: 5));
      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      debugPrint("API fetchUserProfile error: $e");
      return null;
    }
  }
}
