// lib/repositories/country_repository.dart
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/country.dart';
import '../services/storage_service.dart';

class CountryRepository {
  final String baseUrl = 'http://192.168.2.101:8080/api';
  final StorageService _storageService = StorageService();

  Future<List<Country>> getAllCountries() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/countries'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> countriesJson = jsonDecode(response.body);
        return countriesJson.map((countryJson) => Country.fromJson(countryJson)).toList();
      } else {
        throw Exception('Failed to load countries: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load countries: $e');
    }
  }
}