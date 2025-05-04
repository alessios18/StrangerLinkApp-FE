import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
import '../models/profile.dart';
import '../services/storage_service.dart';

class ProfileRepository {
  final String baseUrl = 'http://192.168.2.101:8080/api';
  final StorageService _storageService = StorageService();

  Future<Profile> getCurrentUserProfile() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Profile.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load profile: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<Profile> getProfileByUserId(int userId) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/profiles/$userId'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return Profile.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to load profile: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to load profile: $e');
    }
  }

  Future<Profile> updateProfile(Profile profile) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.put(
        Uri.parse('$baseUrl/profiles/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(profile.toJson()),
      );

      if (response.statusCode == 200) {
        return Profile.fromJson(jsonDecode(response.body));
      } else {
        throw Exception('Failed to update profile: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to update profile: $e');
    }
  }

  Future<String> uploadProfileImage(File imageFile) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      // Create multipart request
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/profiles/me/image'),
      );

      // Add authorization header
      request.headers.addAll({
        'Authorization': 'Bearer $token',
      });

      // Get file extension
      final fileExtension = imageFile.path.split('.').last.toLowerCase();

      // Determine content type based on file extension
      String contentType;
      switch (fileExtension) {
        case 'jpg':
        case 'jpeg':
          contentType = 'image/jpeg';
          break;
        case 'png':
          contentType = 'image/png';
          break;
        case 'gif':
          contentType = 'image/gif';
          break;
        default:
          contentType = 'application/octet-stream';
      }

      // Add file to request
      request.files.add(
        await http.MultipartFile.fromPath(
          'file',
          imageFile.path,
          contentType: MediaType.parse(contentType),
        ),
      );

      // Send request
      final streamedResponse = await request.send();

      // Get response
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        return responseData['profileImageUrl'] ?? '';
      } else {
        throw Exception('Failed to upload image: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to upload image: $e');
    }
  }

  Future<List<Profile>> searchProfiles({int? age, String? country, String? gender}) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      // Build search parameters
      final Map<String, dynamic> searchParams = {};
      if (age != null) searchParams['age'] = age.toString();
      if (country != null) searchParams['country'] = country;
      if (gender != null) searchParams['gender'] = gender;

      final response = await http.post(
        Uri.parse('$baseUrl/users/search'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode(searchParams),
      );

      if (response.statusCode == 200) {
        final List<dynamic> profilesJson = jsonDecode(response.body);
        return profilesJson.map((profileJson) => Profile.fromJson(profileJson)).toList();
      } else {
        throw Exception('Failed to search profiles: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to search profiles: $e');
    }
  }

  Future<void> addInterestToProfile(String interest) async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.post(
        Uri.parse('$baseUrl/interests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'name': interest}),
      );

      if (response.statusCode != 200) {
        throw Exception('Failed to add interest: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to add interest: $e');
    }
  }

  Future<List<String>> getAllInterests() async {
    final token = await _storageService.getToken();
    if (token == null) {
      throw Exception('Authentication token not found');
    }

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/interests'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> interestsJson = jsonDecode(response.body);
        return interestsJson.map((interestJson) => interestJson['name'] as String).toList();
      } else {
        throw Exception('Failed to get interests: ${response.statusCode} ${response.body}');
      }
    } catch (e) {
      throw Exception('Failed to get interests: $e');
    }
  }
}