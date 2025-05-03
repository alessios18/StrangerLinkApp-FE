import 'package:flutter_secure_storage/flutter_secure_storage.dart';

class StorageService {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  Future<void> saveToken(String token) async {
    await _storage.write(key: 'jwtToken', value: token);
  }

  Future<String?> getToken() async {
    return await _storage.read(key: 'jwtToken');
  }

  Future<void> deleteToken() async {
    await _storage.delete(key: 'jwtToken');
  }
}