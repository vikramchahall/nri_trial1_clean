import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';


class OfficialUpdatesPage extends StatefulWidget {
  const OfficialUpdatesPage({super.key});

  @override
  State<OfficialUpdatesPage> createState() => _OfficialUpdatesPageState();
}

class _OfficialUpdatesPageState extends State<OfficialUpdatesPage> {
  final supabase = Supabase.instance.client;



  // ✅ ADD HELPER FUNCTION HERE (inside State class)
  Future<int> _getUserCount() async {
    final response = await supabase
        .from('profiles')
        .select('id');

    return response.length;
  }

  // =========================
  // 1️⃣ ACHIEVEMENT PLATE
  // =========================
  Widget _buildAchievementPlate() {
    final List<Map<String, dynamic>> data = [
      {"title": "100% Electrified", "icon": Icons.bolt, "color": Colors.orange},
      {"title": "New School Lab", "icon": Icons.computer, "color": Colors.blue},
      {"title": "Clean Water Project", "icon": Icons.water_drop, "color": Colors.cyan},
    ];

    return SizedBox(
      height: 110,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 15),
        itemCount: data.length,
        itemBuilder: (context, index) => Container(
          width: 140,
          margin: const EdgeInsets.only(right: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 10,
              )
            ],
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: data[index]['color'].withOpacity(0.1),
                child: Icon(
                  data[index]['icon'],
                  color: data[index]['color'],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                data[index]['title'],
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // =========================
  // 2️⃣ LIVE USER COUNTER
  // =========================
 Widget _buildUserCounter() {
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


  // =========================
  // 3️⃣ OFFICIAL POST DIALOG
  // =========================
  void _showOfficialPostDialog(BuildContext context) {
    final titleController = TextEditingController();
    final messageController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom,
          left: 20,
          right: 20,
          top: 20,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text(
              "New Official Update",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: titleController,
              decoration: const InputDecoration(hintText: "Update Title"),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: messageController,
              maxLines: 3,
              decoration: const InputDecoration(hintText: "Detailed Message"),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.image),
                  label: const Text("Photo"),
                ),
                const SizedBox(width: 10),
                ElevatedButton.icon(
                  onPressed: () {},
                  icon: const Icon(Icons.videocam),
                  label: const Text("Video"),
                ),
              ],
            ),
            const SizedBox(height: 20),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[800],
                ),
                onPressed: () {
                  // TODO:
                  // 1. Upload media to Supabase Storage
                  // 2. Insert into `official_updates` table
                  Navigator.pop(context);
                },
                child: const Text(
                  "Post to Village",
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  // =========================
  // 4️⃣ OFFICIAL FEED PLACEHOLDER
  // =========================
 Widget _buildOfficialFeed() {
  final supabase = Supabase.instance.client;

  return StreamBuilder<List<Map<String, dynamic>>>(
    stream: supabase
        .from('official_updates')
        .stream(primaryKey: ['id'])
        .order('timestamp', ascending: false),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final updates = snapshot.data!;
      if (updates.isEmpty) {
        return const Center(child: Text("No official updates yet."));
      }

      return ListView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 15, vertical: 12),
        itemCount: updates.length,
        itemBuilder: (context, index) {
          final data = updates[index];

          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            decoration: BoxDecoration(
              color: Colors.green[700],
              borderRadius: BorderRadius.circular(15),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.all(15),
              title: Text(
                data['title'] ?? '',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              subtitle: Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data['message'] ?? '',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 14,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _formatDate(data['timestamp']),
                      style: const TextStyle(
                        color: Colors.white60,
                        fontSize: 11,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      );
    },
  );
}


  // =========================
  // 5️⃣ FINAL PAGE LAYOUT
  // =========================
  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser; // ✅ ADD THIS LINE
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "OFFICIAL",
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[900],
        elevation: 0,
      actions: [
  if (user?.isDC ?? false)
    IconButton(
      icon: const Icon(Icons.add_business),
      onPressed: () => _showOfficialPostDialog(context),
    ),
],

      ),
      body: ListView(
        children: [
          _buildUserCounter(),
          const Padding(
            padding: EdgeInsets.only(left: 20, top: 10, bottom: 15),
            child: Text(
              "Village Achievements",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          _buildAchievementPlate(),
          const Divider(height: 40),
          const Padding(
            padding: EdgeInsets.only(left: 20, bottom: 10),
            child: Text(
              "Latest Announcements",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
            ),
          ),
          _buildOfficialFeed(),
        ],
      ),
    );
  }
}
String _formatDate(dynamic timestamp) {
  if (timestamp == null) return '';
  try {
    return DateTime.parse(timestamp.toString())
        .toLocal()
        .toString()
        .split(' ')
        .first;
  } catch (_) {
    return '';
  }
}

