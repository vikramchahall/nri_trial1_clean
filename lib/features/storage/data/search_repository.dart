import 'package:supabase_flutter/supabase_flutter.dart';

class SearchRepository {
  const SearchRepository();

  Future<List<Map<String, dynamic>>> searchUsers(String query) async {
    final response = await Supabase.instance.client
        .from('profiles')
        .select()
        .ilike('username', '%$query%');

    return List<Map<String, dynamic>>.from(response);
  }
}
