import 'package:dio/dio.dart';
import '../../../core/api_client.dart';
import 'hotel_model.dart';

class PaginatedHotels {
  PaginatedHotels({
    required this.items,
    required this.page,
    required this.hasMore,
  });
  final List<Hotel> items;
  final int page;
  final bool hasMore;
}

class HotelRepository {
  HotelRepository(this._apiClient);
  final ApiClient _apiClient;

  Future<PaginatedHotels> searchHotels({
    required String query,
    required int page,
    int pageSize = 5,
  }) async {
    try {
      final int finalLimit = pageSize < 1 ? 1 : (pageSize > 5 ? 5 : pageSize);
      // If the user typed a property code (8-char alphanumeric), try direct hotelIdSearch first
      final RegExp propCode = RegExp(r'^[A-Za-z0-9]{8}$');
      if (propCode.hasMatch(query)) {
        // ignore: avoid_print
        print('[searchHotels] direct hotelIdSearch for query=' + query);
        final Response<dynamic> direct = await _apiClient.post<dynamic>(
          '',
          data: <String, dynamic>{
            'action': 'getSearchResultListOfHotels',
            'getSearchResultListOfHotels': <String, dynamic>{
              'searchCriteria': <String, dynamic>{
                'checkIn': _todayPlus(30),
                'checkOut': _todayPlus(31),
                'rooms': 1,
                'adults': 2,
                'children': 0,
                'searchType': 'hotelIdSearch',
                'searchQuery': <String>[query],
                'accommodation': <String>[
                  'all',
                  'hotel',
                  'resort',
                  'apartment',
                  'Home Stay',
                  'guestHouse',
                  'hostel',
                  'Villa',
                ],
                'arrayOfExcludedSearchType': <String>['street'],
                'highPrice': '3000000',
                'lowPrice': '0',
                'limit': finalLimit,
                'preloaderList': <dynamic>[],
                'currency': 'INR',
                'rid': 1,
              },
            },
          },
        );
        final dynamic d = direct.data;
        final List<dynamic> arr =
            (d is Map &&
                d['data'] is Map &&
                d['data']['arrayOfHotelList'] is List)
            ? d['data']['arrayOfHotelList'] as List<dynamic>
            : <dynamic>[];
        if (arr.isNotEmpty) {
          final List<Hotel> hotels = arr.map((e) {
            final Map<String, dynamic> m = (e as Map).cast<String, dynamic>();
            final Map<String, dynamic>? img = (m['propertyImage'] as Map?)
                ?.cast<String, dynamic>();
            final Map<String, dynamic>? addr = (m['propertyAddress'] as Map?)
                ?.cast<String, dynamic>();
            return Hotel(
              id: (m['propertyCode'] ?? '').toString(),
              name: (m['propertyName'] ?? '').toString(),
              city: (addr?['city'] ?? '').toString(),
              state: (addr?['state'] ?? '').toString(),
              country: (addr?['country'] ?? '').toString(),
              imageUrl: (img?['fullUrl'])?.toString(),
              address: (addr?['street'])?.toString(),
            );
          }).toList();
          return PaginatedHotels(items: hotels, page: page, hasMore: false);
        }
      }

      // 1) Autocomplete to derive searchType/searchQuery
      final Response<dynamic> autoRes = await _apiClient.post<dynamic>(
        '',
        data: <String, dynamic>{
          'action': 'searchAutoComplete',
          'searchAutoComplete': <String, dynamic>{
            'inputText': query,
            'searchType': <String>[
              'byPropertyName',
              'byCity',
              'byState',
              'byCountry',
              'byStreet',
              'byRandom',
            ],
            'limit': 10,
          },
        },
      );

      String derivedType = 'hotelIdSearch';
      List<String> derivedQuery = <String>[];

      final dynamic autoData = autoRes.data;
      final Map<String, dynamic> autoList =
          (autoData is Map &&
              autoData['data'] is Map &&
              autoData['data']['autoCompleteList'] is Map)
          ? (autoData['data']['autoCompleteList'] as Map)
                .cast<String, dynamic>()
          : <String, dynamic>{};

      final prop = autoList['byPropertyName'];
      if (prop is Map &&
          prop['listOfResult'] is List &&
          (prop['listOfResult'] as List).isNotEmpty) {
        final Map<String, dynamic> firstItem =
            ((prop['listOfResult'] as List).first as Map)
                .cast<String, dynamic>();
        final Map<String, dynamic>? sa = (firstItem['searchArray'] as Map?)
            ?.cast<String, dynamic>();
        if (sa != null) {
          derivedType = (sa['type'] ?? 'hotelIdSearch').toString();
          final List<dynamic> q = (sa['query'] as List?) ?? <dynamic>[];
          derivedQuery = q.map((e) => e.toString()).toList();
        }
      } else {
        final city = autoList['byCity'];
        if (city is Map &&
            city['listOfResult'] is List &&
            (city['listOfResult'] as List).isNotEmpty) {
          final Map<String, dynamic> first =
              (city['listOfResult'] as List).first as Map<String, dynamic>;
          final Map<String, dynamic>? addr = (first['address'] as Map?)
              ?.cast<String, dynamic>();
          derivedType = 'citySearch';
          derivedQuery = <String>[
            (addr?['city'] ?? '').toString(),
            (addr?['state'] ?? '').toString(),
            (addr?['country'] ?? '').toString(),
          ];
        } else {
          final state = autoList['byState'];
          if (state is Map &&
              state['listOfResult'] is List &&
              (state['listOfResult'] as List).isNotEmpty) {
            final Map<String, dynamic> first =
                (state['listOfResult'] as List).first as Map<String, dynamic>;
            final Map<String, dynamic>? addr = (first['address'] as Map?)
                ?.cast<String, dynamic>();
            derivedType = 'stateSearch';
            derivedQuery = <String>[
              '',
              (addr?['state'] ?? '').toString(),
              (addr?['country'] ?? '').toString(),
            ];
          } else {
            final country = autoList['byCountry'];
            if (country is Map &&
                country['listOfResult'] is List &&
                (country['listOfResult'] as List).isNotEmpty) {
              final Map<String, dynamic> first =
                  (country['listOfResult'] as List).first
                      as Map<String, dynamic>;
              final Map<String, dynamic>? addr = (first['address'] as Map?)
                  ?.cast<String, dynamic>();
              derivedType = 'countrySearch';
              derivedQuery = <String>[
                '',
                '',
                (addr?['country'] ?? '').toString(),
              ];
            } else {
              final street = autoList['byStreet'];
              if (street is Map &&
                  street['listOfResult'] is List &&
                  (street['listOfResult'] as List).isNotEmpty) {
                final Map<String, dynamic> first =
                    (street['listOfResult'] as List).first
                        as Map<String, dynamic>;
                final Map<String, dynamic>? sa = (first['searchArray'] as Map?)
                    ?.cast<String, dynamic>();
                if (sa != null) {
                  derivedType = (sa['type'] ?? 'streetSearch').toString();
                  final List<dynamic> q = (sa['query'] as List?) ?? <dynamic>[];
                  derivedQuery = q.map((e) => e.toString()).toList();
                } else {
                  final Map<String, dynamic>? addr = (first['address'] as Map?)
                      ?.cast<String, dynamic>();
                  derivedType = 'streetSearch';
                  derivedQuery = <String>[
                    (addr?['street'] ?? '').toString(),
                    (addr?['city'] ?? '').toString(),
                    (addr?['state'] ?? '').toString(),
                    (addr?['country'] ?? '').toString(),
                  ];
                }
              }
            }
          }
        }
      }

      // Fallback: if autocomplete couldn't derive any query, try a direct city search using the user's input
      if (derivedQuery.isEmpty) {
        derivedType = 'citySearch';
        derivedQuery = <String>[query];
      }

      // 2) Get Search Result
      Future<Response<dynamic>> _postSearch({
        required String type,
        required List<String> queryArray,
        int? ridOverride,
        int? checkInOffsetDays,
      }) {
        return _apiClient.post<dynamic>(
          '',
          data: <String, dynamic>{
            'action': 'getSearchResultListOfHotels',
            'getSearchResultListOfHotels': <String, dynamic>{
              'searchCriteria': <String, dynamic>{
                'checkIn': _todayPlus(checkInOffsetDays ?? 30),
                'checkOut': _todayPlus((checkInOffsetDays ?? 30) + 1),
                'rooms': 1,
                'adults': 2,
                'children': 0,
                'searchType': type,
                'searchQuery': queryArray,
                'accommodation': <String>[
                  'all',
                  'hotel',
                  'resort',
                  'apartment',
                  'Home Stay',
                  'guestHouse',
                  'hostel',
                  'Villa',
                ],
                'arrayOfExcludedSearchType': <String>['street'],
                'highPrice': '3000000',
                'lowPrice': '0',
                'limit': finalLimit,
                'preloaderList': <dynamic>[],
                'currency': 'INR',
                'rid': ridOverride ?? 1,
              },
            },
          },
        );
      }

      // ignore: avoid_print
      print(
        '[searchHotels] derived type=' +
            derivedType +
            ' query=' +
            derivedQuery.toString(),
      );
      final Response<dynamic> response = await _postSearch(
        type: derivedType,
        queryArray: derivedQuery,
      );

      List<dynamic> arr;
      {
        final dynamic data = response.data;
        arr =
            (data is Map &&
                data['data'] is Map &&
                data['data']['arrayOfHotelList'] is List)
            ? data['data']['arrayOfHotelList'] as List<dynamic>
            : <dynamic>[];
        // ignore: avoid_print
        print(
          '[searchHotels] primary message=' +
              ((data is Map && data['message'] != null)
                  ? data['message'].toString()
                  : 'n/a') +
              ' count=' +
              arr.length.toString(),
        );
      }

      // If no results, try broader fallback types using the raw query (e.g., for inputs like "Goa")
      if (arr.isEmpty) {
        // Retry same type/query with different rid and farther dates
        const List<int> ridCandidates = <int>[0, 1, 2];
        const List<int> dateOffsets = <int>[60, 90, 180];
        for (final int rid in ridCandidates) {
          for (final int d in dateOffsets) {
            final Response<dynamic> resRetry = await _postSearch(
              type: derivedType,
              queryArray: derivedQuery,
              ridOverride: rid,
              checkInOffsetDays: d,
            );
            final dynamic dataR = resRetry.data;
            final List<dynamic> arrR =
                (dataR is Map &&
                    dataR['data'] is Map &&
                    dataR['data']['arrayOfHotelList'] is List)
                ? dataR['data']['arrayOfHotelList'] as List<dynamic>
                : <dynamic>[];
            // ignore: avoid_print
            print(
              '[searchHotels] retry rid=' +
                  rid.toString() +
                  ' d=' +
                  d.toString() +
                  ' count=' +
                  arrR.length.toString(),
            );
            if (arrR.isNotEmpty) {
              arr = arrR;
              break;
            }
          }
          if (arr.isNotEmpty) break;
        }

        // Endpoint tends to expect [city, state, country] in searchQuery for location-based types.
        final List<_FallbackAttempt> attempts = <_FallbackAttempt>[
          // street shape (street, city, state, country)
          _FallbackAttempt(
            type: 'streetSearch',
            queryArray: <String>[query, '', '', ''],
          ),
          _FallbackAttempt(
            type: 'citySearch',
            queryArray: <String>[query, '', ''],
          ),
          _FallbackAttempt(
            type: 'stateSearch',
            queryArray: <String>['', query, ''],
          ),
          _FallbackAttempt(
            type: 'countrySearch',
            queryArray: <String>['', '', query],
          ),
          // Also try minimal single-element arrays as a last resort
          _FallbackAttempt(type: 'streetSearch', queryArray: <String>[query]),
          _FallbackAttempt(type: 'citySearch', queryArray: <String>[query]),
          _FallbackAttempt(type: 'stateSearch', queryArray: <String>[query]),
          _FallbackAttempt(type: 'countrySearch', queryArray: <String>[query]),
        ];

        for (final _FallbackAttempt attempt in attempts) {
          final Response<dynamic> res2 = await _postSearch(
            type: attempt.type,
            queryArray: attempt.queryArray,
          );
          final dynamic data2 = res2.data;
          final List<dynamic> arr2 =
              (data2 is Map &&
                  data2['data'] is Map &&
                  data2['data']['arrayOfHotelList'] is List)
              ? data2['data']['arrayOfHotelList'] as List<dynamic>
              : <dynamic>[];
          // ignore: avoid_print
          print(
            '[searchHotels] fallback type=' +
                attempt.type +
                ' q=' +
                attempt.queryArray.toString() +
                ' count=' +
                arr2.length.toString(),
          );
          if (arr2.isNotEmpty) {
            arr = arr2;
            break;
          }
        }
      }

      // Final fallback: use popularStay to approximate location search when the
      // main search returns no inventory for broad inputs like state names.
      if (arr.isEmpty) {
        // ignore: avoid_print
        print('[searchHotels] falling back to popularStay for query=' + query);
        // Try byCity first
        final List<Hotel> byCity = await fetchPopularStays(
          PopularStayParams(
            limit: pageSize,
            entityType: 'Any',
            searchType: 'byCity',
            city: query,
            country: 'India',
            currency: 'INR',
          ),
        );
        if (byCity.isNotEmpty) {
          return PaginatedHotels(items: byCity, page: page, hasMore: false);
        }

        // Then try byState
        final List<Hotel> byState = await fetchPopularStays(
          PopularStayParams(
            limit: pageSize,
            entityType: 'Any',
            searchType: 'byState',
            state: query,
            country: 'India',
            currency: 'INR',
          ),
        );
        if (byState.isNotEmpty) {
          return PaginatedHotels(items: byState, page: page, hasMore: false);
        }
      }

      final List<Hotel> hotels = arr.map((e) {
        final Map<String, dynamic> m = (e as Map).cast<String, dynamic>();
        final Map<String, dynamic>? img = (m['propertyImage'] as Map?)
            ?.cast<String, dynamic>();
        final Map<String, dynamic>? addr = (m['propertyAddress'] as Map?)
            ?.cast<String, dynamic>();
        return Hotel(
          id: (m['propertyCode'] ?? '').toString(),
          name: (m['propertyName'] ?? '').toString(),
          city: (addr?['city'] ?? '').toString(),
          state: (addr?['state'] ?? '').toString(),
          country: (addr?['country'] ?? '').toString(),
          imageUrl: (img?['fullUrl'])?.toString(),
          address: (addr?['street'])?.toString(),
        );
      }).toList();

      final bool hasMore = hotels.length == pageSize;
      return PaginatedHotels(items: hotels, page: page, hasMore: hasMore);
    } on DioException catch (_) {
      return PaginatedHotels(items: <Hotel>[], page: page, hasMore: false);
    }
  }
}

class PopularStayParams {
  const PopularStayParams({
    this.limit = 10,
    this.entityType = 'Any',
    required this.searchType, // byCity, byState, byCountry, byRandom
    this.country,
    this.state,
    this.city,
    this.currency = 'INR',
  });

  final int limit;
  final String entityType;
  final String searchType;
  final String? country;
  final String? state;
  final String? city;
  final String currency;

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is PopularStayParams &&
        other.limit == limit &&
        other.entityType == entityType &&
        other.searchType == searchType &&
        other.country == country &&
        other.state == state &&
        other.city == city &&
        other.currency == currency;
  }

  @override
  int get hashCode {
    return Object.hash(
      limit,
      entityType,
      searchType,
      country,
      state,
      city,
      currency,
    );
  }
}

extension PopularStayApi on HotelRepository {
  Future<List<Hotel>> fetchPopularStays(PopularStayParams params) async {
    try {
      final Response<dynamic> res = await _apiClient.post<dynamic>(
        '',
        data: <String, dynamic>{
          'action': 'popularStay',
          'popularStay': <String, dynamic>{
            'limit': params.limit,
            'entityType': params.entityType,
            'filter': <String, dynamic>{
              'searchType': params.searchType,
              'searchTypeInfo': <String, dynamic>{
                if (params.country != null) 'country': params.country,
                if (params.state != null) 'state': params.state,
                if (params.city != null) 'city': params.city,
              },
            },
            'currency': params.currency,
          },
        },
      );

      final dynamic data = res.data;
      final List<dynamic> list =
          (data is Map && data['status'] == true && data['data'] is List)
          ? data['data'] as List<dynamic>
          : <dynamic>[];

      return list.map((e) {
        final Map<String, dynamic> m = (e as Map).cast<String, dynamic>();
        final Map<String, dynamic>? addr = (m['propertyAddress'] as Map?)
            ?.cast<String, dynamic>();
        return Hotel(
          id: (m['propertyCode'] ?? '').toString(),
          name: (m['propertyName'] ?? '').toString(),
          city: (addr?['city'] ?? '').toString(),
          state: (addr?['state'] ?? '').toString(),
          country: (addr?['country'] ?? '').toString(),
          imageUrl: (m['propertyImage'])?.toString(),
          address: (addr?['street'])?.toString(),
        );
      }).toList();
    } on DioException {
      return <Hotel>[];
    }
  }
}

class _FallbackAttempt {
  _FallbackAttempt({required this.type, required this.queryArray});
  final String type;
  final List<String> queryArray;
}

String _todayPlus(int days) {
  final now = DateTime.now();
  final d = now.add(Duration(days: days));
  return '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}
