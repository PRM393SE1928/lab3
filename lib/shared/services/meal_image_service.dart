import 'dart:convert';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';

class MealImageService {
  Future<String> upload(Uint8List bytes, String mimeType) async {
    final token = await FirebaseAuth.instance.currentUser?.getIdToken();
    if (token == null) {
      throw const MealImageException('Hãy đăng nhập để lưu ảnh.');
    }
    const configured = String.fromEnvironment('MEAL_AI_BACKEND_URL');
    final base = configured.isNotEmpty
        ? Uri.parse(configured).replace(path: '/api/meal-images', query: null)
        : Uri.parse(
            kIsWeb
                ? 'http://localhost:51889/api/meal-images'
                : 'http://10.0.2.2:51889/api/meal-images',
          );
    try {
      final request = http.MultipartRequest('POST', base)
        ..headers['Authorization'] = 'Bearer $token'
        ..files.add(
          http.MultipartFile.fromBytes(
            'image',
            bytes,
            filename: 'meal',
            contentType: MediaType.parse(mimeType),
          ),
        );
      final response = await http.Response.fromStream(
        await request.send().timeout(const Duration(seconds: 45)),
      );
      if (response.statusCode == 401) {
        throw const MealImageException('Phiên đăng nhập đã hết hạn.');
      }
      if (response.statusCode != 200) {
        throw const MealImageException(
          'Không thể lưu ảnh. Hãy kiểm tra cấu hình dịch vụ và thử lại.',
        );
      }
      final data = jsonDecode(response.body);
      final url = data is Map ? data['url'] : null;
      if (url is! String || Uri.tryParse(url)?.scheme != 'https') {
        throw const MealImageException(
          'Dịch vụ trả về địa chỉ ảnh không hợp lệ.',
        );
      }
      return url;
    } on MealImageException {
      rethrow;
    } catch (_) {
      throw const MealImageException(
        'Không thể kết nối để lưu ảnh. Hãy thử lại.',
      );
    }
  }
}

class MealImageException implements Exception {
  const MealImageException(this.message);
  final String message;
}
