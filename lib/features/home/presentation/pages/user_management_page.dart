// ============================================
// FILE: user_management_page.dart
// Location: lib/features/official_updates/presentation/pages/user_management_page.dart
// ============================================

import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/app_user.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final supabase = Supabase.instance.client;
  List<AppUser> users = [];
  List<AppUser> filteredUsers = [];
  Set<String> selectedUsers = {};
  TextEditingController searchController = TextEditingController();
  String? filterPanchayat;
  bool? filterIsAdmin;
  bool? filterIsDC;
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => isLoading = true);
    
    try {
      final response = await supabase
          .from('profiles')
          .select()
          .order('created_at', ascending: false);
      
      setState(() {
        users = (response as List)
            .map((json) => AppUser.fromJson(json))
            .toList();
        filteredUsers = users;
        isLoading = false;
      });
    } catch (e) {
      setState(() => isLoading = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading users: $e')),
        );
      }
    }
  }

  void _applyFilters() {
    setState(() {
      filteredUsers = users.where((user) {
        bool matches = true;
        
        if (searchController.text.isNotEmpty) {
          final search = searchController.text.toLowerCase();
          matches = matches && 
            (user.username.toLowerCase().contains(search) ||
             user.email.toLowerCase().contains(search) ||
             user.panchayatId.toLowerCase().contains(search));
        }
        
        if (filterPanchayat != null && filterPanchayat == 'has_panchayat') {
          matches = matches && user.panchayatId.isNotEmpty;
        }
        
        if (filterIsAdmin != null) {
          matches = matches && user.isAdmin == filterIsAdmin;
        }
        
        if (filterIsDC != null) {
          matches = matches && user.isDC == filterIsDC;
        }
        
        return matches;
      }).toList();
    });
  }

  void _clearFilters() {
    setState(() {
      searchController.clear();
      filterPanchayat = null;
      filterIsAdmin = null;
      filterIsDC = null;
      filteredUsers = users;
      selectedUsers.clear();
    });
  }

  Future<void> _bulkUpdateRole(bool isAdmin, bool isDC) async {
    try {
      for (var userId in selectedUsers) {
        await supabase
            .from('profiles')
            .update({
              'is_admin': isAdmin,
              'is_dc': isDC,
            })
            .eq('id', userId);
      }
      
      await _loadUsers();
      
      setState(() {
        selectedUsers.clear();
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Roles updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating roles: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showBulkUpdateDialog() {
    bool makeAdmin = false;
    bool makeDC = false;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: Text('Update ${selectedUsers.length} Users'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              CheckboxListTile(
                title: const Text('Make Admin'),
                subtitle: const Text('Can access special admin features'),
                value: makeAdmin,
                onChanged: (val) => setState(() => makeAdmin = val ?? false),
              ),
              CheckboxListTile(
                title: const Text('Make DC'),
                subtitle: const Text('Can manage users and create announcements'),
                value: makeDC,
                onChanged: (val) => setState(() => makeDC = val ?? false),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(ctx);
                _bulkUpdateRole(makeAdmin, makeDC);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
              ),
              child: const Text('Update'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'USER MANAGEMENT',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        centerTitle: true,
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[900],
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadUsers,
            tooltip: 'Refresh',
          ),
        ],
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSearchAndFilter(),
                if (selectedUsers.isNotEmpty) _buildBulkActionBar(),
                Expanded(
                  child: filteredUsers.isEmpty
                      ? const Center(child: Text('No users found'))
                      : ListView.builder(
                          padding: const EdgeInsets.all(16),
                          itemCount: filteredUsers.length,
                          itemBuilder: (ctx, i) => _buildUserCard(filteredUsers[i]),
                        ),
                ),
              ],
            ),
    );
  }

  Widget _buildSearchAndFilter() {
    final hasPanchayatFilter = filterPanchayat != null;
    
    return Container(
      color: Colors.white,
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          TextField(
            controller: searchController,
            decoration: InputDecoration(
              hintText: 'Search by name, email, or panchayat ID',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: searchController.text.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        searchController.clear();
                        _applyFilters();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            onChanged: (_) => _applyFilters(),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                _buildFilterChip(
                  'With Panchayat ID',
                  hasPanchayatFilter,
                  () {
                    setState(() {
                      filterPanchayat = hasPanchayatFilter ? null : 'has_panchayat';
                    });
                    _applyFilters();
                  },
                ),
                _buildFilterChip(
                  'Admin Only',
                  filterIsAdmin == true,
                  () {
                    setState(() {
                      filterIsAdmin = filterIsAdmin == true ? null : true;
                    });
                    _applyFilters();
                  },
                ),
                _buildFilterChip(
                  'DC Only',
                  filterIsDC == true,
                  () {
                    setState(() {
                      filterIsDC = filterIsDC == true ? null : true;
                    });
                    _applyFilters();
                  },
                ),
                _buildFilterChip(
                  'Clear Filters',
                  false,
                  _clearFilters,
                  color: Colors.red[100],
                  textColor: Colors.red[900],
                ),
              ],
            ),
          ),
          if (filteredUsers.isNotEmpty && filterPanchayat != null) ...[
            const SizedBox(height: 12),
            ElevatedButton.icon(
              onPressed: _selectAllFiltered,
              icon: const Icon(Icons.check_box),
              label: Text('Select All ${filteredUsers.length} Users'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green[700],
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 45),
              ),
            ),
          ],
        ],
      ),
    );
  }
  
  void _selectAllFiltered() {
    setState(() {
      selectedUsers.clear();
      for (var user in filteredUsers) {
        selectedUsers.add(user.uid);
      }
    });
  }

  Widget _buildFilterChip(String label, bool selected, VoidCallback onTap,
      {Color? color, Color? textColor}) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        label: Text(label),
        selected: selected,
        onSelected: (_) => onTap(),
        backgroundColor: color,
        labelStyle: TextStyle(color: textColor),
      ),
    );
  }

  Widget _buildBulkActionBar() {
    return Container(
      color: Colors.green[700],
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        children: [
          Text(
            '${selectedUsers.length} selected',
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => selectedUsers.clear()),
            icon: const Icon(Icons.clear, color: Colors.white),
            label: const Text('Clear', style: TextStyle(color: Colors.white)),
          ),
          const SizedBox(width: 8),
          ElevatedButton.icon(
            onPressed: _showBulkUpdateDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green[900],
            ),
            icon: const Icon(Icons.edit),
            label: const Text('Update Roles'),
          ),
        ],
      ),
    );
  }

  Widget _buildUserCard(AppUser user) {
    final isSelected = selectedUsers.contains(user.uid);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 2,
      child: InkWell(
        onTap: () => _showUserDetails(user),
        onLongPress: () {
          setState(() {
            if (isSelected) {
              selectedUsers.remove(user.uid);
            } else {
              selectedUsers.add(user.uid);
            }
          });
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Checkbox(
                value: isSelected,
                onChanged: (val) {
                  setState(() {
                    if (val == true) {
                      selectedUsers.add(user.uid);
                    } else {
                      selectedUsers.remove(user.uid);
                    }
                  });
                },
              ),
              CircleAvatar(
                backgroundColor: Colors.green[100],
                child: Text(
                  user.username.isNotEmpty ? user.username[0].toUpperCase() : '?',
                  style: TextStyle(
                    color: Colors.green[900],
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user.username,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      user.email,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    if (user.panchayatId.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        'Panchayat: ${user.panchayatId}',
                        style: TextStyle(color: Colors.grey[600], fontSize: 12),
                      ),
                    ],
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  if (user.isAdmin)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.blue[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'Admin',
                        style: TextStyle(
                          color: Colors.blue[900],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  if (user.isDC)
                    Container(
                      margin: const EdgeInsets.only(top: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.purple[100],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        'DC',
                        style: TextStyle(
                          color: Colors.purple[900],
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showUserDetails(AppUser user) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (ctx) => UserDetailPage(
          user: user,
          onUpdate: () => _loadUsers(),
        ),
      ),
    );
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }
}

// ============================================
// USER DETAIL PAGE
// ============================================

class UserDetailPage extends StatefulWidget {
  final AppUser user;
  final VoidCallback onUpdate;

  const UserDetailPage({
    super.key,
    required this.user,
    required this.onUpdate,
  });

  @override
  State<UserDetailPage> createState() => _UserDetailPageState();
}

class _UserDetailPageState extends State<UserDetailPage> {
  final supabase = Supabase.instance.client;
  late bool isAdmin;
  late bool isDC;
  bool isSaving = false;

  @override
  void initState() {
    super.initState();
    isAdmin = widget.user.isAdmin;
    isDC = widget.user.isDC;
  }

  Future<void> _saveChanges() async {
    setState(() => isSaving = true);
    
    try {
      await supabase
          .from('profiles')
          .update({
            'is_admin': isAdmin,
            'is_dc': isDC,
          })
          .eq('id', widget.user.uid);
      
      widget.onUpdate();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('User updated successfully'),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error updating user: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('User Details'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.green[900],
        elevation: 0,
        actions: [
          if (isSaving)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(16.0),
                child: SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _saveChanges,
              tooltip: 'Save Changes',
            ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              color: Colors.white,
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundColor: Colors.green[100],
                    child: Text(
                      widget.user.username.isNotEmpty 
                          ? widget.user.username[0].toUpperCase() 
                          : '?',
                      style: TextStyle(
                        color: Colors.green[900],
                        fontWeight: FontWeight.bold,
                        fontSize: 36,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    widget.user.username,
                    style: const TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    widget.user.userType,
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            _buildSection('Contact Information', [
              _buildInfoRow(Icons.email, 'Email', widget.user.email),
              if (widget.user.phone.isNotEmpty)
                _buildInfoRow(Icons.phone, 'Phone', widget.user.phone),
            ]),
            _buildSection('Location', [
              if (widget.user.city.isNotEmpty)
                _buildInfoRow(Icons.location_city, 'City', widget.user.city),
              if (widget.user.town.isNotEmpty)
                _buildInfoRow(Icons.location_on, 'Town', widget.user.town),
              if (widget.user.blockName.isNotEmpty)
                _buildInfoRow(Icons.business, 'Block', widget.user.blockName),
              if (widget.user.panchayatId.isNotEmpty)
                _buildInfoRow(Icons.gavel, 'Panchayat ID', widget.user.panchayatId),
            ]),
            _buildSection('Roles & Permissions', [
              SwitchListTile(
                title: const Text('Admin Access'),
                subtitle: const Text('Can access special admin features'),
                value: isAdmin,
                onChanged: (val) => setState(() => isAdmin = val),
                activeColor: Colors.blue,
              ),
              SwitchListTile(
                title: const Text('DC Access'),
                subtitle: const Text('Can manage users and create announcements'),
                value: isDC,
                onChanged: (val) => setState(() => isDC = val),
                activeColor: Colors.purple,
              ),
            ]),
            _buildSection('Social Stats', [
              ListTile(
                leading: Icon(Icons.people_outline, color: Colors.green[700]),
                title: const Text('Following'),
                trailing: Text(
                  '${widget.user.following.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              ListTile(
                leading: Icon(Icons.people, color: Colors.green[700]),
                title: const Text('Followers'),
                trailing: Text(
                  '${widget.user.followers.length}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ]),
          ],
        ),
      ),
    );
  }

  Widget _buildSection(String title, List<Widget> children) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      color: Colors.white,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              title,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const Divider(height: 1),
          ...children,
        ],
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return ListTile(
      leading: Icon(icon, color: Colors.green[700]),
      title: Text(label, style: TextStyle(color: Colors.grey[600])),
      subtitle: Text(value, style: const TextStyle(fontSize: 16)),
    );
  }
}