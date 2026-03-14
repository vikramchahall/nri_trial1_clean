import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:nri_trial1_clean/features/storage/data/search_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepository repository;
  Timer? _debounce;
  String _lastQuery = '';

  SearchCubit(this.repository) : super(const SearchState());

  void onQueryChanged(String query) {
    _debounce?.cancel();
    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      emit(const SearchState());
      return;
    }

    _lastQuery = q;

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      emit(state.copyWith(isSearching: true, isLoading: true, page: 0));

      try {
        final results = await repository.searchUsers(q, page: 0);
        emit(state.copyWith(
          isSearching: true,
          isLoading: false,
          results: results,
          page: 0,
          hasMore: results.length == 10, // ✅ if we got 10, there might be more
        ));
      } catch (_) {
        emit(state.copyWith(isLoading: false));
      }
    });
  }

  // ✅ load more results
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;

    final nextPage = state.page + 1;
    emit(state.copyWith(isLoadingMore: true));

    try {
      final more = await repository.searchUsers(_lastQuery, page: nextPage);
      emit(state.copyWith(
        isLoadingMore: false,
        results: [...state.results, ...more], // ✅ append to existing
        page: nextPage,
        hasMore: more.length == 10,
      ));
    } catch (_) {
      emit(state.copyWith(isLoadingMore: false));
    }
  }

  void clear() {
    _debounce?.cancel();
    _lastQuery = '';
    emit(const SearchState());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}