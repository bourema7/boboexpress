import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http_parser/http_parser.dart';
import '../config/app_config.dart';

class ApiService {
  final String baseUrl;
  final FlutterSecureStorage _storage = const FlutterSecureStorage();

  ApiService({String? baseUrl}) : baseUrl = baseUrl ?? AppConfig.baseUrl;

  Future<Map<String, String>> _getHeaders() async {
    final token = await _storage.read(key: 'access_token');
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  Future<http.Response> get(String path) async {
    final headers = await _getHeaders();
    try {
      final response = await http
          .get(Uri.parse('$baseUrl$path'), headers: headers)
          .timeout(const Duration(seconds: 15));
      return response;
    } catch (e) {
      return http.Response(
          jsonEncode({'detail': 'Erreur réseau ou timeout'}), 503);
    }
  }

  Future<http.Response> post(String path, dynamic body) async {
    final headers = await _getHeaders();
    try {
      return await http
          .post(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      return http.Response(
          jsonEncode({'detail': 'Le serveur ne répond pas ou délai dépassé'}),
          503);
    }
  }

  Future<http.Response> patch(String path, dynamic body) async {
    final headers = await _getHeaders();
    try {
      return await http
          .patch(
            Uri.parse('$baseUrl$path'),
            headers: headers,
            body: jsonEncode(body),
          )
          .timeout(const Duration(seconds: 15));
    } catch (e) {
      return http.Response(
          jsonEncode({'detail': 'Le serveur ne répond pas ou délai dépassé'}),
          503);
    }
  }

  // Produits CRUD
  Future<List<dynamic>> getProducts(
      {int? categoryId,
      String? query,
      String? ordering,
      bool? isNew,
      bool? isPromo}) async {
    try {
      String path = '/products/products/';
      List<String> params = [];
      if (categoryId != null) params.add('category_id=$categoryId');
      if (query != null && query.isNotEmpty) params.add('search=$query');
      if (ordering != null) params.add('ordering=$ordering');
      if (isNew == true) params.add('is_new=true');
      if (isPromo == true) params.add('is_promo=true');

      if (params.isNotEmpty) {
        path += '?' + params.join('&');
      }
      final response = await get(path);
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  Future<Map<String, dynamic>> saveProductDetails(
      {Map<String, String>? data,
      List<int>? imageBytes,
      String? fileName,
      int? productId}) async {
    try {
      final token = await _storage.read(key: 'access_token');
      final uri = Uri.parse(productId == null
          ? '$baseUrl/products/products/'
          : '$baseUrl/products/products/$productId/');

      final request =
          http.MultipartRequest(productId == null ? 'POST' : 'PATCH', uri);

      if (token != null) {
        request.headers['Authorization'] = 'Bearer $token';
      }

      if (data != null) {
        request.fields.addAll(data);
      }

      if (imageBytes != null && fileName != null) {
        request.files.add(http.MultipartFile.fromBytes(
          'image',
          imageBytes,
          filename: fileName,
          contentType: MediaType('image', 'jpeg'),
        ));
      }

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode == 201 || response.statusCode == 200) {
        return {
          'success': true,
          'data': jsonDecode(utf8.decode(response.bodyBytes)),
        };
      } else {
        return {
          'success': false,
          'status': response.statusCode,
          'message': response.body
        };
      }
    } catch (e) {
      return {'success': false, 'status': 500, 'message': e.toString()};
    }
  }

  Future<bool> deleteProduct(int id) async {
    final response = await delete('/products/products/$id/');
    return response.statusCode == 204;
  }

  Future<http.Response> delete(String path) async {
    final headers = await _getHeaders();
    return http.delete(Uri.parse('$baseUrl$path'), headers: headers);
  }

  // Panier
  Future<Map<String, dynamic>> getCart() async {
    try {
      final response = await get('/products/cart/');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      return {};
    }
    return {};
  }

  Future<bool> addToCart(int productId,
      {int quantity = 1, int? variantId}) async {
    final response = await post('/products/cart/add/', {
      'product': productId,
      'quantity': quantity,
      if (variantId != null) 'variant': variantId,
    });
    return response.statusCode == 201 || response.statusCode == 200;
  }

  Future<bool> removeFromCart(int itemId) async {
    final response = await post('/products/cart/remove_item/', {
      'item_id': itemId,
    });
    return response.statusCode == 200;
  }

  Future<bool> updateCartItem(int itemId, int quantity) async {
    final response = await post('/products/cart/update_item/', {
      'item_id': itemId,
      'quantity': quantity,
    });
    return response.statusCode == 200;
  }

  // Commandes
  Future<List<dynamic>> getAddresses() async {
    try {
      final response = await get('/users/addresses/');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  Future<Map<String, dynamic>> createOrder(
      Map<String, dynamic> orderData) async {
    try {
      final response = await post('/orders/orders/', orderData);
      if (response.statusCode == 201) {
        return {
          'success': true,
          'data': jsonDecode(utf8.decode(response.bodyBytes))
        };
      }
      // Essayer de décoder le message d'erreur si c'est du JSON
      try {
        final errorData = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'message':
              errorData['detail'] ?? errorData['message'] ?? response.body
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Erreur serveur (${response.statusCode})'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<List<dynamic>> getOrders() async {
    try {
      final response = await get('/orders/orders/');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  Future<Map<String, dynamic>?> getOrderById(int orderId) async {
    final response = await get('/orders/orders/$orderId/');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return null;
  }

  Future<bool> toggleFavorite(int productId) async {
    final response =
        await post('/products/products/$productId/toggle_favorite/', {});
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getFavorites() async {
    final response = await get('/products/products/favorites/');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  Future<bool> postReview(int productId, int rating, String comment) async {
    final response = await post('/products/reviews/', {
      'product': productId,
      'rating': rating,
      'comment': comment,
    });
    return response.statusCode == 201;
  }

  Future<Map<String, dynamic>> initPayment(int orderId,
      {String? momoType}) async {
    final response = await post('/orders/orders/$orderId/init_payment/', {
      if (momoType != null) 'momo_type': momoType,
    });
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return {'success': false, 'message': 'Erreur de paiement'};
  }

  Future<Map<String, dynamic>> verifyOTP(int orderId, String otp) async {
    final response =
        await post('/orders/orders/$orderId/verify_otp/', {'otp': otp});
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<Map<String, dynamic>> confirmPayment(int orderId, String otp) async {
    final response =
        await post('/orders/orders/$orderId/confirm_payment/', {'otp': otp});
    return jsonDecode(utf8.decode(response.bodyBytes));
  }

  Future<List<dynamic>> getNotifications() async {
    try {
      final response = await get('/notifications/');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  // Super Admin Methods
  Future<Map<String, dynamic>?> getDashboardStats() async {
    final response = await get('/analytics/dashboard/');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return null;
  }

  Future<List<dynamic>> getUsers() async {
    final response = await get('/users/admin/users/');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  Future<bool> updateUserRole(int userId, String role) async {
    final response = await patch('/users/admin/users/$userId/', {'role': role});
    return response.statusCode == 200 || response.statusCode == 204;
  }

  Future<Map<String, dynamic>> adminUpdateUser(
      int userId, Map<String, dynamic> data) async {
    try {
      final response = await patch('/users/admin/users/$userId/', data);

      // Vérifier si la réponse est du JSON avant de décoder
      final contentType = response.headers['content-type'] ?? '';
      if (response.statusCode == 200 &&
          contentType.contains('application/json')) {
        return {
          'success': true,
          'data': jsonDecode(utf8.decode(response.bodyBytes))
        };
      } else {
        String msg = 'Erreur serveur (${response.statusCode})';
        try {
          if (contentType.contains('application/json')) {
            final errorData = jsonDecode(utf8.decode(response.bodyBytes));
            msg = errorData['detail'] ?? errorData['message'] ?? msg;
          }
        } catch (_) {}
        return {'success': false, 'message': msg};
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<Map<String, dynamic>> adminCreateUser(
      String username, String email, String password, String role) async {
    try {
      final response = await post('/auth/register/', {
        'username': username,
        'email': email,
        'password': password,
        'password2': password,
        'role': role,
      });
      if (response.statusCode == 201) {
        return {'success': true};
      }
      try {
        final data = jsonDecode(utf8.decode(response.bodyBytes));
        return {
          'success': false,
          'message': data['detail'] ?? data['message'] ?? response.body
        };
      } catch (_) {
        return {
          'success': false,
          'message': 'Erreur serveur (${response.statusCode})'
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erreur de connexion: $e'};
    }
  }

  Future<bool> blockUser(int userId, bool block) async {
    final action = block ? 'block' : 'unblock';
    final response = await post('/users/admin/users/$userId/$action/', {});
    return response.statusCode == 200;
  }

  Future<bool> sendBroadcast(
      String title, String message, String targetRole) async {
    final response = await post('/notifications/broadcast/', {
      'title': title,
      'message': message,
      'target_role': targetRole,
    });
    return response.statusCode == 200;
  }

  Future<Map<String, dynamic>?> getDriverStats() async {
    final response = await get('/analytics/drivers/');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return null;
  }

  Future<bool> assignDriver(int orderId, int driverId) async {
    final response = await post('/orders/orders/$orderId/assign_driver/', {
      'driver_id': driverId,
    });
    return response.statusCode == 200;
  }

  Future<List<dynamic>> getAvailableDrivers() async {
    try {
      final response = await get('/users/available-drivers/');
      if (response.statusCode == 200) {
        return jsonDecode(utf8.decode(response.bodyBytes));
      }
    } catch (_) {
      return [];
    }
    return [];
  }

  // Category CRUD
  Future<List<dynamic>> getCategories() async {
    final response = await get('/products/categories/');
    if (response.statusCode == 200) {
      return jsonDecode(utf8.decode(response.bodyBytes));
    }
    return [];
  }

  Future<bool> createCategory(
      String name, String? description, String? imageUrl) async {
    final response = await post('/products/categories/', {
      'name': name,
      'description': description ?? '',
      'icon_url': imageUrl ?? '',
    });
    return response.statusCode == 201;
  }

  Future<bool> updateCategory(
      int id, String name, String? description, String? imageUrl) async {
    final response = await patch('/products/categories/$id/', {
      'name': name,
      'description': description ?? '',
      'icon_url': imageUrl ?? '',
    });
    return response.statusCode == 200;
  }

  Future<bool> deleteCategory(int id) async {
    final response = await delete('/products/categories/$id/');
    return response.statusCode == 204;
  }

  Future<bool> createVariant(
      int productId, Map<String, dynamic> variantData) async {
    final response =
        await post('/products/products/$productId/variants/', variantData);
    return response.statusCode == 201;
  }
}
