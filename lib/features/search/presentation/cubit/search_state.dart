class SearchState {
  final bool isSearching;
  final bool isLoading;
  final bool isLoadingMore; // ✅ for "load more" button
  final List<Map<String, dynamic>> results;
  final int page; // ✅ track current page
  final bool hasMore; // ✅ whether more results exist

  const SearchState({
    this.isSearching = false,
    this.isLoading = false,
    this.isLoadingMore = false,
    this.results = const [],
    this.page = 0,
    this.hasMore = false,
  });

  SearchState copyWith({
    bool? isSearching,
    bool? isLoading,
    bool? isLoadingMore,
    List<Map<String, dynamic>>? results,
    int? page,
    bool? hasMore,
  }) {
    return SearchState(
      isSearching: isSearching ?? this.isSearching,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      results: results ?? this.results,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
    );
  }
}