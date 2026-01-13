import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class UserCounter extends StatelessWidget {
  const UserCounter({super.key});

  Future<int> _getUserCount() async {
    final supabase = Supabase.instance.client;
    final response = await supabase.from('profiles').select('id');
    return response.length;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<int>(
      future: _getUserCount(),
      builder: (context, snapshot) {
        final count = snapshot.data ?? 0;

        return Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.green.shade900, Colors.green.shade600],
            ),
            borderRadius: BorderRadius.circular(25),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "LIVE COMMUNITY",
                    style: TextStyle(
                      color: Colors.white70,
                      letterSpacing: 1.5,
                      fontSize: 10,
                    ),
                  ),
                  SizedBox(height: 5),
                  Text(
                    "Registered Volunteers",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              Text(
                "$count",
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 40,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
