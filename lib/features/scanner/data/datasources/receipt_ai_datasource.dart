import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

class ReceiptAiException implements Exception {
  final String message;
  const ReceiptAiException(this.message);

  @override
  String toString() => 'ReceiptAiException: $message';
}

class ReceiptAiDataSource {
  static const _apiUrl = String.fromEnvironment('SCANNER_API_URL');
  static const _appKey = String.fromEnvironment('SCANNER_APP_KEY');
  static const _timeout = Duration(seconds: 45);

  final http.Client _client;

  ReceiptAiDataSource({http.Client? client})
    : _client = client ?? http.Client();

  bool get isEnabled => _apiUrl.isNotEmpty;

  Future<Map<String, dynamic>> scan(String imagePath) async {
    final bytes = await File(imagePath).readAsBytes();

    final http.Response response;
    try {
      response = await _client
          .post(
            Uri.parse('$_apiUrl/scan'),
            headers: {'content-type': 'application/json', 'x-app-key': _appKey},
            body: jsonEncode({
              'image': base64Encode(bytes),
              'media_type': _mediaTypeFor(imagePath),
            }),
          )
          .timeout(_timeout);
    } catch (e) {
      throw ReceiptAiException('request failed: $e');
    }

    if (response.statusCode != 200) {
      throw ReceiptAiException('HTTP ${response.statusCode}: ${response.body}');
    }

    final decoded = jsonDecode(response.body);
    if (decoded is! Map<String, dynamic>) {
      throw const ReceiptAiException('unexpected response shape');
    }
    return decoded;
  }

  String _mediaTypeFor(String path) {
    final lower = path.toLowerCase();
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.webp')) return 'image/webp';
    if (lower.endsWith('.gif')) return 'image/gif';
    return 'image/jpeg';
  }
}
