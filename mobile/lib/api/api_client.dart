import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config.dart';

/// An error returned by the FinBridge API, or a network problem.
class ApiException implements Exception {
  ApiException(this.code, this.message, {this.status, this.details});

  final String code;
  final String message;
  final int? status;
  final Map<String, dynamic>? details;

  /// True when the request may or may not have reached the server.
  bool get isNetwork => code == 'NETWORK' || code == 'TIMEOUT';

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient({http.Client? client, this.onUnauthorised}) : _http = client ?? http.Client();

  final http.Client _http;
  String? token;

  /// Called when the server says the session is no longer valid.
  void Function()? onUnauthorised;

  Uri _uri(String path, [Map<String, String>? query]) =>
      Uri.parse('${AppConfig.apiUrl}$path').replace(queryParameters: query);

  Map<String, String> get _headers => {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      };

  Future<dynamic> get(String path, {Map<String, String>? query}) =>
      _send(() => _http.get(_uri(path, query), headers: _headers));

  Future<dynamic> post(String path, [Map<String, dynamic>? body]) => _send(
      () => _http.post(_uri(path), headers: _headers, body: jsonEncode(body ?? {})));

  Future<dynamic> _send(Future<http.Response> Function() request) async {
    http.Response res;
    try {
      res = await request().timeout(const Duration(seconds: 20));
    } on TimeoutException {
      throw ApiException('TIMEOUT', 'The server did not respond. Check the transaction status before trying again.');
    } on SocketException {
      throw ApiException('NETWORK', 'No connection to the FinBridge server. Check your internet connection.');
    } on http.ClientException {
      throw ApiException('NETWORK', 'No connection to the FinBridge server. Check your internet connection.');
    }

    if (res.statusCode == 204 || res.body.isEmpty) return null;
    dynamic data;
    try {
      data = jsonDecode(res.body);
    } catch (_) {
      throw ApiException('BAD_RESPONSE', 'Unexpected reply from the server', status: res.statusCode);
    }
    if (res.statusCode >= 400) {
      final err = (data is Map ? data['error'] : null) as Map<String, dynamic>? ?? {};
      final code = err['code'] as String? ?? 'ERROR';
      if (res.statusCode == 401 && token != null && code != 'INVALID_CREDENTIALS') {
        onUnauthorised?.call();
      }
      throw ApiException(
        code,
        err['message'] as String? ?? 'Request failed',
        status: res.statusCode,
        details: err['details'] as Map<String, dynamic>?,
      );
    }
    return data;
  }
}
