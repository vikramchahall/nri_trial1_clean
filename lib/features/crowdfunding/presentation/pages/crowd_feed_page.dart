import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:http/http.dart' as http;

import '../components/crowd_post_tile.dart';
import '../cubits/crowd_cubit.dart';
import '../cubits/crowd_states.dart';
import '../../domain/entities/crowd_post.dart';

class CrowdFeedPage extends StatefulWidget {
  const CrowdFeedPage({super.key});

  @override
  State<CrowdFeedPage> createState() => _CrowdFeedPageState();
}

class _CrowdFeedPageState extends State<CrowdFeedPage> {
  Map<String, dynamic>? _villageFollow;
  String? _villageProfileId;
  bool _villageLoading = true;
  Map<String, dynamic>? _weather;

  @override
  void initState() {
    super.initState();
    context.read<CrowdCubit>().fetchAllCrowds();
    _fetchVillageFollow();
  }

  Future<void> _fetchVillageFollow() async {
    final uid = Supabase.instance.client.auth.currentUser?.id;
    if (uid == null) {
      if (mounted) setState(() => _villageLoading = false);
      return;
    }

    try {
      final followData = await Supabase.instance.client
          .from('village_follows')
          .select()
          .eq('user_id', uid)
          .maybeSingle();

      if (followData == null) {
        if (mounted) setState(() => _villageLoading = false);
        return;
      }

      if (mounted) {
        setState(() {
          _villageFollow = followData;
          _villageProfileId = followData['village_profile_id'] as String?;
          _villageLoading = false;
        });
        _fetchWeather();
      }
    } catch (e) {
      debugPrint("❌ Error fetching village follow: $e");
      if (mounted) setState(() => _villageLoading = false);
    }
  }

  Future<void> _fetchWeather() async {
    if (_villageFollow == null) return;

    final city = (_villageFollow!['city'] ?? '').toString().trim();
    final block = (_villageFollow!['block_name'] ?? '').toString().trim();
    final query = city.isNotEmpty ? city : block;
    if (query.isEmpty) return;

    try {
      final geoUrl = Uri.parse(
        'https://nominatim.openstreetmap.org/search?q=$query,India&format=json&limit=1',
      );
      final geoRes = await http.get(
        geoUrl,
        headers: {'User-Agent': 'ConnectNRI/1.0'},
      );
      final geoData = jsonDecode(geoRes.body) as List;

      if (geoData.isEmpty) {
        debugPrint("⚠️ No location found for: $query");
        return;
      }

      final lat = geoData[0]['lat'];
      final lon = geoData[0]['lon'];

      final weatherUrl = Uri.parse(
        'https://api.open-meteo.com/v1/forecast?latitude=$lat&longitude=$lon&current=temperature_2m,weathercode&timezone=auto',
      );
      final weatherRes = await http.get(weatherUrl);
      final weatherData = jsonDecode(weatherRes.body);

      if (mounted) {
        setState(() {
          _weather = weatherData['current'];
        });
      }
    } catch (e) {
      debugPrint("❌ Weather fetch error: $e");
    }
  }

  Map<String, dynamic> _getWeatherInfo(int code) {
    if (code == 0) {
      return {'condition': 'Clear Sky', 'icon': Icons.wb_sunny, 'color': Colors.orange};
    } else if (code <= 3) {
      return {'condition': 'Partly Cloudy', 'icon': Icons.cloud, 'color': Colors.grey};
    } else if (code <= 48) {
      return {'condition': 'Foggy', 'icon': Icons.foggy, 'color': Colors.blueGrey};
    } else if (code <= 67) {
      return {'condition': 'Rainy', 'icon': Icons.grain, 'color': Colors.blue};
    } else if (code <= 77) {
      return {'condition': 'Snowy', 'icon': Icons.ac_unit, 'color': Colors.lightBlue};
    } else if (code <= 82) {
      return {'condition': 'Heavy Rain', 'icon': Icons.umbrella, 'color': Colors.indigo};
    } else {
      return {'condition': 'Thunderstorm', 'icon': Icons.thunderstorm, 'color': Colors.deepPurple};
    }
  }

  Widget _buildWeatherWidget() {
    if (_weather == null) return const SizedBox.shrink();

    final temp = (_weather!['temperature_2m'] ?? 0).toStringAsFixed(0);
    final code = (_weather!['weathercode'] ?? 0) as int;
    final info = _getWeatherInfo(code);

    return Padding(
      padding: const EdgeInsets.only(right: 14),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(info['icon'] as IconData, size: 16, color: info['color'] as Color),
          const SizedBox(width: 3),
          Text(
            "$temp°C",
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  void _showWeatherDetails() {
    if (_weather == null || _villageFollow == null) return;

    final temp = (_weather!['temperature_2m'] ?? 0).toStringAsFixed(1);
    final code = (_weather!['weathercode'] ?? 0) as int;
    final city = (_villageFollow!['city'] ?? '').toString();
    final block = (_villageFollow!['block_name'] ?? '').toString();
    final info = _getWeatherInfo(code);

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Icon(info['icon'] as IconData, size: 64, color: info['color'] as Color),
            const SizedBox(height: 12),
            Text(
              "$temp°C",
              style: const TextStyle(fontSize: 48, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              info['condition'] as String,
              style: TextStyle(fontSize: 18, color: Colors.grey.shade600),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.location_on_outlined, size: 16, color: Colors.grey.shade500),
                const SizedBox(width: 4),
                Text(
                  [
                    if (block.isNotEmpty) block,
                    if (city.isNotEmpty) city,
                  ].join(', '),
                  style: TextStyle(fontSize: 14, color: Colors.grey.shade500),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              "Source: Open-Meteo & OpenStreetMap",
              style: TextStyle(fontSize: 11, color: Colors.grey.shade400),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          children: [
            const Text(
              "V I L L A G E  F E E D",
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
            if (!_villageLoading && _villageFollow != null)
              Text(
                "Welcome to ${[
                  if ((_villageFollow!['block_name'] ?? '').toString().isNotEmpty)
                    _villageFollow!['block_name'],
                  if ((_villageFollow!['city'] ?? '').toString().isNotEmpty)
                    _villageFollow!['city'],
                ].join(', ')}",
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                  color: Colors.grey.shade600,
                ),
              ),
          ],
        ),
        centerTitle: true,
        elevation: 0,
        // ✅ Only weather, no three dots
        actions: [
          if (_weather != null)
            GestureDetector(
              onTap: _showWeatherDetails,
              child: _buildWeatherWidget(),
            ),
        ],
      ),
      body: BlocBuilder<CrowdCubit, CrowdState>(
        builder: (context, state) {
          if (state is CrowdLoading && _villageLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (state is CrowdLoaded) {
            final allPosts = state.crowds;

            final villagePosts = _villageProfileId != null
                ? allPosts.where((p) => p.userId == _villageProfileId).toList()
                : <CrowdPost>[];

            return RefreshIndicator(
              onRefresh: () async {
                context.read<CrowdCubit>().fetchAllCrowds();
                await _fetchVillageFollow();
              },
              child: ListView(
                padding: EdgeInsets.zero,
                children: [

                  // ===============================
                  // 🏡 VILLAGE POSTS SECTION
                  // ===============================
                  if (!_villageLoading && _villageFollow != null) ...[
                    if (villagePosts.isEmpty)
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 20, horizontal: 16),
                        child: Text(
                          "No posts from your village yet.",
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 13,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else
                      ...villagePosts.map((post) => CrowdPostTile(crowdPost: post)),

                    // ✅ Divider
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                      child: Row(
                        children: [
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 10),
                            child: Text(
                              "All Posts",
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade400,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                          Expanded(child: Divider(color: Colors.grey.shade300)),
                        ],
                      ),
                    ),
                  ],

                  // ===============================
                  // 📰 ALL POSTS (NORMAL FEED)
                  // ===============================
                  if (allPosts.isEmpty)
                    const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text("No causes yet.")),
                    )
                  else
                    ...allPosts.map((post) => CrowdPostTile(crowdPost: post)),
                ],
              ),
            );
          }

          return const Center(child: Text("Error loading feed"));
        },
      ),
    );
  }
}