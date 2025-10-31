import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/api_client.dart';
import '../../session/visitor_token_repository.dart';
import '../data/hotel_model.dart';
import '../data/hotel_repository.dart';

final apiClientProvider = Provider<ApiClient>((ref) {
  final token = ref.watch(visitorTokenProvider);
  final client = ApiClient();
  if (token != null && token.isNotEmpty) {
    client.setVisitorToken(token);
  }
  return client;
});

final hotelRepositoryProvider = Provider<HotelRepository>((ref) {
  // Watch so the repository rebuilds when visitor token arrives
  final api = ref.watch(apiClientProvider);
  return HotelRepository(api);
});

class SearchState {
  const SearchState({
    required this.query,
    required this.items,
    required this.page,
    required this.isLoading,
    required this.hasMore,
  });

  final String query;
  final List<Hotel> items;
  final int page;
  final bool isLoading;
  final bool hasMore;

  SearchState copyWith({
    String? query,
    List<Hotel>? items,
    int? page,
    bool? isLoading,
    bool? hasMore,
  }) {
    return SearchState(
      query: query ?? this.query,
      items: items ?? this.items,
      page: page ?? this.page,
      isLoading: isLoading ?? this.isLoading,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}

class SearchNotifier extends StateNotifier<SearchState> {
  SearchNotifier(this._repo)
    : super(
        const SearchState(
          query: '',
          items: <Hotel>[],
          page: 1,
          isLoading: false,
          hasMore: false,
        ),
      );

  final HotelRepository _repo;

  Future<void> search(String query) async {
    state = state.copyWith(
      query: query,
      isLoading: true,
      items: <Hotel>[],
      page: 1,
    );
    final result = await _repo.searchHotels(query: query, page: 1);
    state = state.copyWith(
      items: result.items,
      page: result.page,
      hasMore: result.hasMore,
      isLoading: false,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoading || !state.hasMore) return;
    state = state.copyWith(isLoading: true);
    final nextPage = state.page + 1;
    final result = await _repo.searchHotels(query: state.query, page: nextPage);
    state = state.copyWith(
      items: <Hotel>[...state.items, ...result.items],
      page: result.page,
      hasMore: result.hasMore,
      isLoading: false,
    );
  }
}

final searchProvider = StateNotifierProvider<SearchNotifier, SearchState>((
  ref,
) {
  final repo = ref.watch(hotelRepositoryProvider);
  return SearchNotifier(repo);
});

final popularStaysProvider = FutureProvider.family<List<Hotel>, PopularStayParams>((ref, params) async {
  final repo = ref.watch(hotelRepositoryProvider);
  return repo.fetchPopularStays(params);
});
