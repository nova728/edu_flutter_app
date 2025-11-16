import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_exception.dart';

class ApiClient {
  ApiClient({http.Client? httpClient, String? baseUrl})
      : _httpClient = httpClient ?? http.Client(),
        _baseUrl = baseUrl ?? const String.fromEnvironment(
          'API_BASE_URL',
          defaultValue: 'https://marlyn-unalleviative-annabel.ngrok-free.dev',
        );

  final http.Client _httpClient;
  final String _baseUrl;
  
  // 添加默认请求头
  static const Map<String, String> _headers = {
    'Content-Type': 'application/json; charset=utf-8',
    'ngrok-skip-browser-warning': 'true',
  };

  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? body,
  }) async {
    final uri = Uri.parse('$_baseUrl$path');
    final response = await _httpClient.post(
      uri,
      headers: _mergeHeaders(headers),
      body: jsonEncode(body ?? <String, dynamic>{}),
    );
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? headers,
    Map<String, dynamic>? query,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: query?.map((key, value) => MapEntry(key, value.toString())),
    );
    final response = await _httpClient.get(uri, headers: _mergeHeaders(headers));
    return _handleResponse(response);
  }

  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? query,
  }) async {
    final uri = Uri.parse('$_baseUrl$path').replace(
      queryParameters: query,
    );
    final mergedHeaders = {..._headers, if (headers != null) ...headers};

    final response = await _httpClient.delete(uri, headers: mergedHeaders);
    return _handleResponse(response);
  }

  Map<String, String> _mergeHeaders(Map<String, String>? headers) {
    return <String, String>{
      ..._headers,
      if (headers != null) ...headers,
    };
  }

  Map<String, dynamic> _handleResponse(http.Response response) {
    final statusCode = response.statusCode;
    if (statusCode < 200 || statusCode >= 300) {
      throw ApiException(_extractErrorMessage(response.body) ?? '请求失败', statusCode: statusCode);
    }
    if (response.body.isEmpty) {
      return <String, dynamic>{};
    }
    final decoded = jsonDecode(response.body);
    if (decoded is Map<String, dynamic>) {
      return decoded;
    }
    throw ApiException('无法解析服务器返回的数据', statusCode: statusCode);
  }

  String? _extractErrorMessage(String body) {
    try {
      final decoded = jsonDecode(body);
      if (decoded is Map<String, dynamic>) {
        return decoded['error']?.toString() ?? decoded['message']?.toString();
      }
      return body;
    } catch (_) {
      return body.isEmpty ? null : body;
    }
  }
}
