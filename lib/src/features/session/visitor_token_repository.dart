import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';

class VisitorTokenRepository {
  VisitorTokenRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<String?> registerDevice() async {
    try {
      final Response<dynamic> res = await _apiClient.post<dynamic>(
        '',
        data: <String, dynamic>{
          'action': 'deviceRegister',
          'deviceRegister': <String, dynamic>{
            'deviceModel': 'Flutter',
            'deviceFingerprint': 'flutter/dev',
            'deviceBrand': 'Flutter',
            'deviceId': 'flutter-device',
            'deviceName': 'Flutter App',
            'deviceManufacturer': 'Flutter',
            'deviceProduct': 'Flutter',
            'deviceSerialNumber': 'unknown',
          },
        },
      );
      final dynamic data = res.data;
      if (data is Map &&
          data['status'] == true &&
          data['data'] is Map &&
          data['data']['visitorToken'] != null) {
        return data['data']['visitorToken'].toString();
      }
      return null;
    } catch (_) {
      return null;
    }
  }
}

class VisitorTokenNotifier extends StateNotifier<String?> {
  VisitorTokenNotifier(this._repo) : super(null);
  final VisitorTokenRepository _repo;

  Future<void> ensureRegistered() async {
    if (state != null && state!.isNotEmpty) return;
    final token = await _repo.registerDevice();
    if (token != null) {
      state = token;
    }
  }
}

final visitorTokenProvider =
    StateNotifierProvider<VisitorTokenNotifier, String?>((ref) {
      // Use an isolated ApiClient to avoid circular dependencies
      final repo = VisitorTokenRepository(ApiClient());
      final notifier = VisitorTokenNotifier(repo);
      // Fire and forget registration attempt
      notifier.ensureRegistered();
      return notifier;
    });
