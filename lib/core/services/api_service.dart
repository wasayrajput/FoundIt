import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:foundit/core/state/app_state.dart';

class ApiService {
  // Dynamically resolve base API URL depending on platform (Web/Desktop vs Android Emulator vs Device)
  static String get baseUrl {
    if (kIsWeb) {
      return 'http://localhost:5000/api';
    }
    // Mobile device / Wi-Fi IP (Laptop Node.js backend)
    return 'http://192.168.0.105:5000/api';
  }

  /// Helper to format relative/absolute image URLs cleanly
  static String formatImageUrl(String relativeOrAbsoluteUrl) {
    if (relativeOrAbsoluteUrl.isEmpty) return '';
    final normalized = relativeOrAbsoluteUrl.replaceAll('\\', '/');
    if (normalized.startsWith('http://') ||
        normalized.startsWith('https://') ||
        normalized.startsWith('data:')) {
      return normalized;
    }
    final cleanHost = baseUrl.replaceAll('/api', '');
    final cleanPath = normalized.startsWith('/')
        ? normalized
        : '/$normalized';
    return '$cleanHost$cleanPath';
  }

  static String? _userToken;
  static String? get userToken => _userToken ?? AppState.instance.token;
  static set userToken(String? token) {
    _userToken = token;
    if (token != null) {
      AppState.instance.token = token;
    }
  }

  /// User / Admin Login API
  static Future<Map<String, dynamic>> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'password': password.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        userToken = data['token'];
        return {
          'success': true,
          'message': data['message'] ?? 'Login successful',
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Invalid email or password',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server. Make sure backend is running.',
      };
    }
  }

  /// Send 6-Digit Signup Verification OTP Email API
  static Future<Map<String, dynamic>> sendSignupOtp({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/send-signup-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'message': data['message'] ?? 'OTP sent to email',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to send OTP code',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server. Make sure backend is running.',
      };
    }
  }

  /// User Registration API
  static Future<Map<String, dynamic>> register({
    required String name,
    required String email,
    required String password,
    String phone = '',
    String otp = '',
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'name': name.trim(),
          'email': email.trim(),
          'password': password.trim(),
          'phone': phone.trim(),
          'otp': otp.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 201 && data['success'] == true) {
        userToken = data['token'];
        return {
          'success': true,
          'message': data['message'] ?? 'Registration successful',
          'token': data['token'],
          'user': data['user'],
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Registration failed',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server. Make sure backend is running.',
      };
    }
  }

  /// Forgot Password - Request 6-Digit OTP Email
  static Future<Map<String, dynamic>> forgotPassword({
    required String email,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email.trim()}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Failed to send OTP email',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server. Make sure backend is running.',
      };
    }
  }

  /// Verify 6-Digit OTP API
  static Future<Map<String, dynamic>> verifyOTP({
    required String email,
    required String otp,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/verify-otp'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Invalid OTP code',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server. Make sure backend is running.',
      };
    }
  }

  /// Reset Password API
  static Future<Map<String, dynamic>> resetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/auth/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'email': email.trim(),
          'otp': otp.trim(),
          'newPassword': newPassword.trim(),
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Failed to reset password',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server. Make sure backend is running.',
      };
    }
  }

  /// Upload Single Image File / Bytes API
  static Future<Map<String, dynamic>> uploadImageBytes({
    required List<int> bytes,
    required String filename,
  }) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/single'),
      );

      if (userToken != null) {
        request.headers['Authorization'] = 'Bearer $userToken';
      }

      request.files.add(
        http.MultipartFile.fromBytes(
          'image',
          bytes,
          filename: filename.isEmpty ? 'upload.jpg' : filename,
        ),
      );

      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'filePath': data['filePath'],
          'url': data['url'],
          'message': data['message'] ?? 'Image uploaded successfully',
        };
      } else {
        return {
          'success': false,
          'message': data['message'] ?? 'Failed to upload image',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend upload server.',
      };
    }
  }

  /// Create Post API
  static Future<Map<String, dynamic>> createPost({
    required String itemName,
    required bool isLost,
    required String category,
    required String description,
    required String date,
    required String locationName,
    String city = '',
    String phone = '',
    String email = '',
    double? latitude,
    double? longitude,
    List<String> images = const [],
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/posts'),
        headers: headers,
        body: jsonEncode({
          'itemName': itemName.trim(),
          'isLost': isLost,
          'category': category.trim(),
          'description': description.trim(),
          'date': date.trim(),
          'city': city.trim(),
          'locationName': locationName.trim(),
          'phone': phone.trim(),
          'email': email.trim(),
          'latitude': latitude,
          'longitude': longitude,
          'images': images,
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 201 && data['success'] == true,
        'message': data['message'] ?? 'Failed to create post',
        'post': data['post'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend post server.',
      };
    }
  }

  /// Get Approved Posts Feed API
  static Future<Map<String, dynamic>> getApprovedPosts({bool? isLost}) async {
    try {
      String url = '$baseUrl/posts';
      if (isLost != null) {
        url += '?isLost=$isLost';
      }

      final response = await http.get(Uri.parse(url));
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'posts': data['posts'] ?? [],
        };
      } else {
        return {
          'success': false,
          'posts': [],
          'message': data['message'] ?? 'Failed to load posts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'posts': [],
        'message': 'Unable to connect to backend server.',
      };
    }
  }

  /// Get Single Post By ID API
  static Future<Map<String, dynamic>> getPostById(String postId) async {
    try {
      final response = await http.get(Uri.parse('$baseUrl/posts/$postId'));
      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'post': data['post'],
      };
    } catch (e) {
      return {'success': false, 'post': null};
    }
  }

  /// Search & Filter Posts API
  static Future<Map<String, dynamic>> searchPosts({
    String? query,
    String? category,
    String? city,
    bool? isLost,
  }) async {
    try {
      final queryParams = <String, String>{};
      if (query != null && query.trim().isNotEmpty) queryParams['q'] = query.trim();
      if (category != null && category.trim().isNotEmpty) queryParams['category'] = category.trim();
      if (city != null && city.trim().isNotEmpty) queryParams['city'] = city.trim();
      if (isLost != null) queryParams['isLost'] = isLost.toString();

      final uri = Uri.parse('$baseUrl/posts/search').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'posts': data['posts'] ?? [],
        };
      } else {
        return {
          'success': false,
          'posts': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'posts': [],
      };
    }
  }

  /// Get User's Own Posts API
  static Future<Map<String, dynamic>> getMyPosts() async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/posts/my-posts'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'posts': data['posts'] ?? [],
        };
      } else {
        return {
          'success': false,
          'posts': [],
        };
      }
    } catch (e) {
      return {
        'success': false,
        'posts': [],
      };
    }
  }

  /// Delete Post API
  static Future<Map<String, dynamic>> deletePost(String postId) async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/posts/$postId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Failed to delete post',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server.',
      };
    }
  }

  /// Update User Profile API (Name, Email, Phone, Photo)
  static Future<Map<String, dynamic>> updateProfile({
    String? name,
    String? email,
    String? phone,
    String? photoUrl,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final bodyPayload = <String, dynamic>{};
      if (name != null) bodyPayload['name'] = name.trim();
      if (email != null) bodyPayload['email'] = email.trim();
      if (phone != null) bodyPayload['phone'] = phone.trim();
      if (photoUrl != null) bodyPayload['photoUrl'] = photoUrl.trim();

      final response = await http.put(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
        body: jsonEncode(bodyPayload),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Failed to update profile',
        'user': data['user'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server.',
      };
    }
  }

  /// Get Nearby Posts API using GPS coordinates & radius (km) via MongoDB GeoJSON $near
  static Future<Map<String, dynamic>> getNearbyPosts({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
    bool? isLost,
    String? category,
  }) async {
    try {
      final queryParams = <String, String>{
        'lat': latitude.toString(),
        'lng': longitude.toString(),
        'radius': radiusInKm.toString(),
      };
      if (isLost != null) queryParams['isLost'] = isLost.toString();
      if (category != null && category.trim().isNotEmpty) queryParams['category'] = category.trim();

      final uri = Uri.parse('$baseUrl/posts/nearby').replace(queryParameters: queryParams);
      final response = await http.get(uri);
      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data['success'] == true) {
        return {
          'success': true,
          'count': data['count'] ?? 0,
          'radiusInKm': data['radiusInKm'],
          'posts': data['posts'] ?? [],
        };
      } else {
        return {
          'success': false,
          'posts': [],
          'message': data['message'] ?? 'Failed to fetch nearby posts',
        };
      }
    } catch (e) {
      return {
        'success': false,
        'posts': [],
        'message': 'Unable to connect to backend nearby server.',
      };
    }
  }

  /// Get All Active User Chats API (Messaging disabled)
  static Future<Map<String, dynamic>> getUserChats() async {
    return {'success': true, 'chats': []};
  }

  /// Get Specific Post Chat History API (Messaging disabled)
  static Future<Map<String, dynamic>> getChatHistory(String postId) async {
    return {'success': false, 'message': 'Messaging disabled'};
  }

  /// Send Chat Message API (Messaging disabled)
  static Future<Map<String, dynamic>> sendChatMessage({
    required String postId,
    required String text,
  }) async {
    return {'success': false, 'message': 'Messaging disabled'};
  }

  /// Get Current User Details with Saved Posts API
  static Future<Map<String, dynamic>> getMe() async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/me'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'user': data['user'],
      };
    } catch (e) {
      return {
        'success': false,
        'user': null,
      };
    }
  }

  /// Get User's Bookmarked / Saved Posts API
  static Future<Map<String, dynamic>> getSavedPosts() async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/users/saved'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'savedPosts': data['savedPosts'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'savedPosts': [],
      };
    }
  }

  /// Toggle Bookmark / Save Post in MongoDB API
  static Future<Map<String, dynamic>> toggleSavePost(String postId) async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.post(
        Uri.parse('$baseUrl/users/saved/$postId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'isSaved': data['isSaved'] ?? false,
        'message': data['message'] ?? 'Bookmark toggled',
      };
    } catch (e) {
      return {
        'success': false,
        'isSaved': false,
        'message': 'Unable to connect to backend server.',
      };
    }
  }

  /// Get User Notifications API
  static Future<Map<String, dynamic>> getNotifications() async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'notifications': data['notifications'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'notifications': [],
      };
    }
  }

  /// Mark User Notifications as Read API
  static Future<Map<String, dynamic>> markNotificationsAsRead() async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.put(
        Uri.parse('$baseUrl/notifications/read'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
      };
    } catch (e) {
      return {'success': false};
    }
  }

  /// Delete Notifications API
  static Future<Map<String, dynamic>> deleteNotifications([List<String>? ids]) async {
    try {
      final headers = <String, String>{'Content-Type': 'application/json'};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/notifications'),
        headers: headers,
        body: jsonEncode({'ids': ids ?? []}),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
      };
    } catch (e) {
      return {'success': false};
    }
  }

  /// Delete Account API (Permanently removes logged-in user from DB)
  static Future<Map<String, dynamic>> deleteAccount() async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/users/profile'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Account deleted',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server.',
      };
    }
  }

  /// Admin: Get Pending Posts API
  static Future<Map<String, dynamic>> getPendingPosts() async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/pending-posts'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'count': data['count'] ?? 0,
        'posts': data['posts'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'posts': [],
      };
    }
  }

  /// Admin: Approve or Reject Post Status API
  static Future<Map<String, dynamic>> updatePostStatus({
    required String postId,
    required String status, // 'approved' or 'rejected'
    String? rejectionReason,
  }) async {
    try {
      final headers = <String, String>{
        'Content-Type': 'application/json',
      };
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.put(
        Uri.parse('$baseUrl/admin/posts/$postId/status'),
        headers: headers,
        body: jsonEncode({
          'status': status,
          'rejectionReason': rejectionReason ?? '',
        }),
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'Post status updated',
        'post': data['post'],
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server.',
      };
    }
  }

  /// Admin: Get All Users API
  static Future<Map<String, dynamic>> getAdminUsers() async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/users'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'users': data['users'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'users': [],
      };
    }
  }

  /// Admin: Delete User API
  static Future<Map<String, dynamic>> deleteAdminUser(String userId) async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.delete(
        Uri.parse('$baseUrl/admin/users/$userId'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'message': data['message'] ?? 'User deleted',
      };
    } catch (e) {
      return {
        'success': false,
        'message': 'Unable to connect to backend server.',
      };
    }
  }

  /// Admin: Get All Posts API (pending, approved, rejected)
  static Future<Map<String, dynamic>> getAllAdminPosts() async {
    try {
      final headers = <String, String>{};
      if (userToken != null) {
        headers['Authorization'] = 'Bearer $userToken';
      }

      final response = await http.get(
        Uri.parse('$baseUrl/admin/posts'),
        headers: headers,
      );

      final data = jsonDecode(response.body);
      return {
        'success': response.statusCode == 200 && data['success'] == true,
        'count': data['count'] ?? 0,
        'posts': data['posts'] ?? [],
      };
    } catch (e) {
      return {
        'success': false,
        'posts': [],
      };
    }
  }
}
