import 'package:supabase_flutter/supabase_flutter.dart';

class SearchRepository {
  const SearchRepository();

  static const int _pageSize = 10; // ✅ limit results like Instagram

  Future<List<Map<String, dynamic>>> searchUsers(
    String query, {
    int page = 0, // ✅ pagination support
  }) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select('id, username, profile_image_url, is_dc, is_admin')
        .ilike('username', '$query%') // ✅ starts with query, NOT contains
        .range(page * _pageSize, (page + 1) * _pageSize - 1); // ✅ fetch only 10 at a time

    final results = List<Map<String, dynamic>>.from(response);

    // ✅ Rank: isDC first → isAdmin second → alphabetical
    results.sort((a, b) {
      final aScore = a['is_dc'] == true
          ? 0
          : a['is_admin'] == true
              ? 1
              : 2;
      final bScore = b['is_dc'] == true
          ? 0
          : b['is_admin'] == true
              ? 1
              : 2;
      if (aScore != bScore) return aScore.compareTo(bScore);
      return (a['username'] as String)
          .compareTo(b['username'] as String); // ✅ alphabetical within same rank
    });

    return results;
  }
}