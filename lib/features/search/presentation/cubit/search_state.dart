class SearchState {
  final bool isSearching;
  final bool isLoading;
  final List<Map<String, dynamic>> results;

  const SearchState({
    this.isSearching = false,
    this.isLoading = false,
    this.results = const [],
  });

  SearchState copyWith({
    bool? isSearching,
    bool? isLoading,
    List<Map<String, dynamic>>? results,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      isLoading: isLoading ?? this.isLoading,
      results: results ?? this.results,
    );
  }
}
