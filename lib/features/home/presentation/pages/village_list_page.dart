import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../profile/presentation/pages/user_profile_page.dart';

class VillageListPage extends StatefulWidget {
  const VillageListPage({super.key});

  @override
  State<VillageListPage> createState() => _VillageListPageState();
}

class _VillageListPageState extends State<VillageListPage> {
  final _searchController = TextEditingController();
  List<Map<String, dynamic>> _allVillages = [];
  List<Map<String, dynamic>> _filteredVillages = [];
  bool _isLoading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _fetchVillages();
    _searchController.addListener(_onSearch);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _fetchVillages() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('id, username, panchayat_id, city, block_name, phone, profile_image_url')
          .order('username', ascending: true);

      final all = List<Map<String, dynamic>>.from(response);

      // ✅ Filter locally — only profiles WITH panchayat_id
      final villages = all.where((v) {
        final p = v['panchayat_id'];
        return p != null && p.toString().trim().isNotEmpty;
      }).toList();

      debugPrint("✅ Total profiles: ${all.length}");
      debugPrint("✅ Profiles with panchayat_id: ${villages.length}");

      if (mounted) {
        setState(() {
          _allVillages = villages;
          _filteredVillages = villages;
          _isLoading = false;
        });
      }
    } catch (e) {
      debugPrint("❌ Error fetching villages: $e");
      if (mounted) {
        setState(() {
          _isLoading = false;
          _error = e.toString();
        });
      }
    }
  }

  void _onSearch() {
    final query = _searchController.text.toLowerCase().trim();
    setState(() {
      if (query.isEmpty) {
        _filteredVillages = _allVillages;
      } else {
        _filteredVillages = _allVillages.where((v) {
          final name = (v['username'] ?? '').toString().toLowerCase();
          final panchayat = (v['panchayat_id'] ?? '').toString().toLowerCase();
          final city = (v['city'] ?? '').toString().toLowerCase();
          final block = (v['block_name'] ?? '').toString().toLowerCase();
          return name.contains(query) ||
              panchayat.contains(query) ||
              city.contains(query) ||
              block.contains(query);
        }).toList();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          "Connect Your Village",
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 0,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(60),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search by name, panchayat ID, city...",
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          _onSearch();
                        },
                      )
                    : null,
                filled: true,
                fillColor: Colors.grey.shade100,
                contentPadding: const EdgeInsets.symmetric(vertical: 10),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),
        ),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error_outline,
                          size: 48, color: Colors.red.shade300),
                      const SizedBox(height: 12),
                      Text(
                        "Error loading villages",
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _error!,
                        style: TextStyle(
                            color: Colors.red.shade300, fontSize: 12),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      ElevatedButton(
                        onPressed: _fetchVillages,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.green,
                          foregroundColor: Colors.white,
                        ),
                        child: const Text("Retry"),
                      ),
                    ],
                  ),
                )
              : _filteredVillages.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.villa,
                              size: 60, color: Colors.grey.shade400),
                          const SizedBox(height: 12),
                          Text(
                            _searchController.text.isNotEmpty
                                ? "No villages match your search"
                                : "No villages with Panchayat ID found",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _fetchVillages,
                      child: ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: _filteredVillages.length,
                        separatorBuilder: (_, __) =>
                            const SizedBox(height: 10),
                        itemBuilder: (context, index) {
                          return _VillageCard(
                              village: _filteredVillages[index]);
                        },
                      ),
                    ),
    );
  }
}

class _VillageCard extends StatelessWidget {
  final Map<String, dynamic> village;

  const _VillageCard({required this.village});

  @override
  Widget build(BuildContext context) {
    final imageUrl = village['profile_image_url'] as String? ?? '';
    final name = village['username'] as String? ?? 'Unknown';
    final panchayatId = village['panchayat_id'] as String? ?? '';
    final city = village['city'] as String? ?? '';
    final block = village['block_name'] as String? ?? '';
    final phone = village['phone'] as String? ?? '';
    final uid = village['id'] as String;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => UserProfilePage(uid: uid)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            // ✅ Profile Image
            ClipOval(
              child: imageUrl.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: imageUrl,
                      width: 56,
                      height: 56,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _placeholder(),
                      errorWidget: (_, __, ___) => _placeholder(),
                    )
                  : _placeholder(),
            ),

            const SizedBox(width: 14),

            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Name
                  Text(
                    name,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 15,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Panchayat ID
                  Row(
                    children: [
                      Icon(Icons.account_balance,
                          size: 13, color: Colors.green.shade700),
                      const SizedBox(width: 4),
                      Flexible(
                        child: Text(
                          "Panchayat: $panchayatId",
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.green.shade700,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),

                  // Block + City
                  if (block.isNotEmpty || city.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.location_on_outlined,
                            size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            [
                              if (block.isNotEmpty) block,
                              if (city.isNotEmpty) city,
                            ].join(', '),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],

                  // Phone
                  if (phone.isNotEmpty) ...[
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Icon(Icons.phone_outlined,
                            size: 13, color: Colors.grey.shade600),
                        const SizedBox(width: 4),
                        Text(
                          phone,
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 8),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }

  Widget _placeholder() {
    return Container(
      width: 56,
      height: 56,
      color: Colors.grey.shade200,
      child: const Icon(Icons.person, color: Colors.grey, size: 28),
    );
  }
}