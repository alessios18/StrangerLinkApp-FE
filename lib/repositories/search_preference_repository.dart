// lib/repositories/search_preference_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/search_preference.dart';
import '../services/storage_service.dart';

class SearchPreferenceRepository {
  final String baseUrl = 'http://192.168.2.101:8080/api';
  final StorageService _storageService = StorageService();

  Future<SearchPreference> getSearchPreferences() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/search-preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return SearchPreference.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load search preferences: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load search preferences: $e');
    }
  }

  Future<SearchPreference> updateSearchPreferences(SearchPreference preferences) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/search-preferences'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(preferences.toJson()),
      );

      if (response.statusCode == 200) {
        return SearchPreference.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update search preferences: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update search preferences: $e');
    }
  }
}