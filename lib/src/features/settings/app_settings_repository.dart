import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../hotels/providers/hotel_providers.dart';

class AppSettingsRepository {
  AppSettingsRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<Map<String, dynamic>?> fetchSettings() async {
    try {
      final Response<dynamic> res = await _apiClient.post<dynamic>('appSetting/');
      final dynamic data = res.data;
      if (data is Map && data['status'] == true && data['data'] is Map) {
        return (data['data'] as Map).cast<String, dynamic>();
      }
      return null;
    } on DioException {
      return null;
    }
  }
}

final appSettingsRepositoryProvider = Provider<AppSettingsRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return AppSettingsRepository(api);
});

final appSettingsProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  return ref.read(appSettingsRepositoryProvider).fetchSettings();
});


