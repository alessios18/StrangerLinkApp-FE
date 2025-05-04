// lib/repositories/user_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../services/storage_service.dart';

class UserRepository {
  final String baseUrl = 'http://192.168.2.101:8080/api';
  final StorageService _storageService = StorageService();

  Future<List<User>> searchUsers({
    int? age,
    String? country,
    String? gender,
    bool usePreferences = true
  }) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      // Build search parameters
      final Map<String, dynamic> searchParams = {
        'usePreferences': usePreferences
      };

      if (age != null) searchParams['age'] = age;
      if (country != null) searchParams['country'] = country;
      if (gender != null) searchParams['gender'] = gender;

      final response = await http.post(
        Uri.parse('$baseUrl/search/users'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(searchParams),
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to search users: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to search users: $e');
    }
  }

  Future<List<User>> getRecentlyActiveUsers() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/recent'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> usersJson = jsonDecode(response.body);
        return usersJson.map((json) => User.fromJson(json)).toList();
      } else {
        throw Exception('Failed to get recent users: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get recent users: $e');
    }
  }

  Future<User?> getRandomMatch() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search/random-match'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      } else if (response.statusCode == 204) {
        // No match found
        return null;
      } else {
        throw Exception('Failed to get random match: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get random match: $e');
    }
  }
}