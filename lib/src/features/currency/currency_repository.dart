import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:dio/dio.dart';
import '../../core/api_client.dart';
import '../hotels/providers/hotel_providers.dart';

class CurrencyInfo {
  CurrencyInfo({required this.code, required this.name, required this.symbol});
  final String code;
  final String name;
  final String symbol;
}

class CurrencyRepository {
  CurrencyRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<List<CurrencyInfo>> getCurrencyList({String baseCode = 'INR'}) async {
    try {
      final Response<dynamic> res = await _apiClient.post<dynamic>(
        '',
        data: <String, dynamic>{
          'action': 'getCurrencyList',
          'getCurrencyList': <String, dynamic>{'baseCode': baseCode},
        },
      );
      final dynamic data = res.data;
      if (data is Map && data['status'] == true && data['data'] is Map && data['data']['currencyList'] is List) {
        return (data['data']['currencyList'] as List)
            .map((e) => (e as Map).cast<String, dynamic>())
            .map((m) => CurrencyInfo(
                  code: (m['currencyCode'] ?? '').toString(),
                  name: (m['currencyName'] ?? '').toString(),
                  symbol: (m['currencySymbol'] ?? '').toString(),
                ))
            .toList();
      }
      return <CurrencyInfo>[];
    } on DioException {
      return <CurrencyInfo>[];
    }
  }
}

final currencyRepositoryProvider = Provider<CurrencyRepository>((ref) {
  final api = ref.watch(apiClientProvider);
  return CurrencyRepository(api);
});

final currencyListProvider = FutureProvider.family<List<CurrencyInfo>, String>((ref, baseCode) async {
  return ref.read(currencyRepositoryProvider).getCurrencyList(baseCode: baseCode);
});


