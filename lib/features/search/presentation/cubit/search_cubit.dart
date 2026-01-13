import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'package:nri_trial1_clean/features/storage/data/search_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  final SearchRepository repository;
  Timer? _debounce;

  SearchCubit(this.repository) : super(const SearchState());

  void onQueryChanged(String query) {
    _debounce?.cancel();

    final q = query.trim().toLowerCase();

    if (q.isEmpty) {
      emit(const SearchState());
      return;
    }

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      emit(state.copyWith(isSearching: true, isLoading: true));

      try {
        final results = await repository.searchUsers(q);
        emit(
          state.copyWith(
            isSearching: true,
            isLoading: false,
            results: results,
          ),
        );
      } catch (_) {
        emit(state.copyWith(isLoading: false));
      }
    });
  }

  void clear() {
    _debounce?.cancel();
    emit(const SearchState());
  }

  @override
  Future<void> close() {
    _debounce?.cancel();
    return super.close();
  }
}
