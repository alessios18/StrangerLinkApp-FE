import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:google_sign_in/google_sign_in.dart';
import '../models/user.dart';
import '../services/storage_service.dart';

class AuthRepository {
  final String baseUrl = 'http://192.168.2.101:8080/api';
  final StorageService _storageService = StorageService();

  Future<User?> getCurrentUser() async {
    final token = await _storageService.getToken();
    if (token == null) return null;

    try {
      final response = await http.get(
        Uri.parse('$baseUrl/auth/me'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return User.fromJson(jsonDecode(response.body));
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<User?> login(String username, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storageService.saveToken(data['token']);

        // Ora possiamo utilizzare direttamente i dati dell'utente dalla risposta
        return User.fromJson(data['user']);
      }
      return null;
    } catch (e) {
      print('Login error: $e');
      return null;
    }
  }

  Future<User?> register(String username, String email, String password) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'email': email,
          'password': password,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storageService.saveToken(data['token']);
        return User.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<User?> loginWithGoogle() async {
    try {
      final GoogleSignIn googleSignIn = GoogleSignIn(scopes: ['email', 'profile']);
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser == null) return null;

      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;

      final response = await http.post(
        Uri.parse('$baseUrl/auth/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': googleAuth.idToken,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        await _storageService.saveToken(data['token']);
        return User.fromJson(data);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  Future<void> logout() async {
    await _storageService.deleteToken();
  }
}