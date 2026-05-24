import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class AuthService extends ChangeNotifier {
  final FlutterSecureStorage _storage = const FlutterSecureStorage();
  final String baseUrl;
  String? _token;
  String? _lastAuthError;
  Map<String, dynamic>? _userProfile;
  bool _isInitialized = false;

  AuthService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  String? get token => _token;
  String? get lastAuthError => _lastAuthError;
  bool get isAuthenticated => _token != null;
  bool get isInitialized => _isInitialized;
  Map<String, dynamic>? get userProfile => _userProfile;
  bool get isAdmin =>
      _userProfile != null &&
      (_userProfile!['role'] == 'admin' ||
          _userProfile!['is_staff'] == true ||
          _userProfile!['is_superuser'] == true);
  bool get isSeller =>
      _userProfile != null &&
      (_userProfile!['role'] == 'seller' || _userProfile!['role'] == 'admin');
  bool get isDelivery =>
      _userProfile != null &&
      (_userProfile!['role'] == 'delivery' || _userProfile!['role'] == 'admin');

  Future<void> loadToken() async {
    _token = await _storage.read(key: 'access_token');
    _isInitialized = true;
    _isInitialized = true;
    if (_token != null) {
      notifyListeners();
      await fetchProfile();
    }
    notifyListeners();
  }

  Future<void> fetchProfile() async {
    if (_token == null) return;
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/users/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        _userProfile = jsonDecode(utf8.decode(response.bodyBytes));
        notifyListeners();
      } else if (response.statusCode == 401) {
        // Token expiré ou invalide
        await logout();
      }
    } catch (_) {
      return;
    }
  }

  Future<bool> login(String username, String password) async {
    _lastAuthError = null;
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/token/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username.trim(),
              'password': password.trim(),
            }),
          )
          .timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _token = data['access'];
        await _storage.write(key: 'access_token', value: _token);
        await fetchProfile();
        return true;
      }
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        _lastAuthError = data['detail']?.toString() ??
            data['message']?.toString() ??
            'Connexion refusée (${response.statusCode})';
      } catch (_) {
        _lastAuthError = 'Connexion refusée (${response.statusCode})';
      }
    } catch (e) {
      _lastAuthError = 'Erreur de connexion: $e';
      return false;
    }
    return false;
  }

  Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
    String role, {
    String? companyName,
    String? phone,
    String? city,
  }) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/auth/register/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'username': username,
              'email': email,
              'password': password,
              'password2': password,
              'role': role,
              'company_name': companyName ?? '',
              'phone': phone ?? '',
              'city': city ?? '',
            }),
          )
          .timeout(const Duration(seconds: 15));

      final responseText = utf8.decode(response.bodyBytes);
      dynamic data;
      try {
        data = jsonDecode(responseText);
      } catch (_) {
        return {
          'success': false,
          'message':
              'Le serveur ne repond pas en JSON. Verifie que l API est demarree et que BASE_URL est correcte.'
        };
      }

      if (response.statusCode == 201) {
        final loginSuccess = await login(username, password);
        return {'success': loginSuccess, 'message': 'Inscription réussie'};
      } else {
        // Extraire le premier message d'erreur du dictionnaire JSON
        String errorMsg = 'Erreur lors de l\'inscription';
        if (data is Map) {
          final firstError = data.values.first;
          errorMsg =
              firstError is List ? firstError.first : firstError.toString();
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<void> logout() async {
    _token = null;
    _userProfile = null;
    await _storage.deleteAll();
    notifyListeners();
  }

  Future<bool> updateAvailability(bool available) async {
    if (_token == null) return false;
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/driver/location/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({'is_available': available}),
      );
      if (response.statusCode == 200) {
        _userProfile!['is_available'] = available;
        notifyListeners();
        return true;
      }
    } catch (_) {
      return false;
    }
    return false;
  }

  Future<Map<String, dynamic>> changePassword(
      String oldPassword, String newPassword) async {
    if (_token == null) return {'success': false, 'message': 'Non authentifié'};
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/change-password/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          'old_password': oldPassword,
          'new_password': newPassword,
        }),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['detail']};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Erreur lors du changement'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<Map<String, dynamic>> requestPasswordReset(String identifier) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/password-reset/request/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({'identifier': identifier.trim()}),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': response.statusCode == 200,
        'message': data['detail'] ?? 'Demande envoyee',
        if (data['debug_code'] != null) 'debug_code': data['debug_code'],
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<Map<String, dynamic>> confirmPasswordReset(
      String identifier, String code, String newPassword) async {
    try {
      final response = await http
          .post(
            Uri.parse('$baseUrl/users/password-reset/confirm/'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'identifier': identifier.trim(),
              'code': code.trim(),
              'new_password': newPassword,
            }),
          )
          .timeout(const Duration(seconds: 15));
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      return {
        'success': response.statusCode == 200,
        'message': data['detail'] ?? 'Mot de passe mis a jour',
      };
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfile(
      {String? email, String? firstName, String? lastName}) async {
    if (_token == null) return {'success': false, 'message': 'Non authentifié'};
    try {
      final response = await http.patch(
        Uri.parse('$baseUrl/users/me/'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_token',
        },
        body: jsonEncode({
          if (email != null) 'email': email,
          if (firstName != null) 'first_name': firstName,
          if (lastName != null) 'last_name': lastName,
        }),
      );
      final data = jsonDecode(utf8.decode(response.bodyBytes));
      if (response.statusCode == 200) {
        await fetchProfile(); // S'assurer que le profil est frais
        return {'success': true, 'message': 'Profil mis à jour'};
      } else {
        String errorMsg = 'Erreur lors de la mise à jour';
        if (data is Map) {
          if (data.containsKey('email')) {
            errorMsg = data['email'] is List
                ? data['email'][0]
                : data['email'].toString();
          } else if (data.containsKey('detail')) {
            errorMsg = data['detail'].toString();
          }
        }
        return {'success': false, 'message': errorMsg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<Map<String, dynamic>> updateProfileImage(
      String filePath, Uint8List? bytes) async {
    if (_token == null) return {'success': false, 'message': 'Non authentifié'};
    try {
      final request =
          http.MultipartRequest('PATCH', Uri.parse('$baseUrl/users/me/'));
      request.headers['Authorization'] = 'Bearer $_token';

      if (kIsWeb && bytes != null) {
        request.files.add(http.MultipartFile.fromBytes('profile_image', bytes,
            filename: 'profile.jpg'));
      } else {
        request.files
            .add(await http.MultipartFile.fromPath('profile_image', filePath));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(utf8.decode(response.bodyBytes));

      if (response.statusCode == 200) {
        _userProfile = data;
        notifyListeners();
        return {'success': true, 'message': 'Photo de profil mise à jour'};
      } else {
        return {
          'success': false,
          'message': data['detail'] ?? 'Erreur lors de l\'envoi'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }
}
