import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../../auth/domain/entities/app_user.dart';
import '../../../../services/notification_service.dart';

class UserManagementPage extends StatefulWidget {
  const UserManagementPage({super.key});

  @override
  State<UserManagementPage> createState() => _UserManagementPageState();
}

class _UserManagementPageState extends State<UserManagementPage> {
  final supabase = Supabase.instance.client;
  final notificationService = NotificationService();
  
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
                title: const Text('Make Pind Leader'),
                subtitle: const Text('Features like black verification & asking for donations'),
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

  void _showNotificationDialog() {
    final titleController = TextEditingController();
    final messageController = TextEditingController();
    bool sendToAll = selectedUsers.isEmpty;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => AlertDialog(
          title: const Text('Send Push Notification'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue[50],
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.phone_android, color: Colors.blue[700]),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          sendToAll
                              ? 'Will appear as phone notification for all users'
                              : 'Will appear as phone notification for ${selectedUsers.length} users',
                          style: TextStyle(color: Colors.blue[900], fontSize: 13),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                if (selectedUsers.isNotEmpty)
                  SwitchListTile(
                    title: const Text('Send to all users instead'),
                    value: sendToAll,
                    onChanged: (val) => setState(() => sendToAll = val),
                  ),
                const SizedBox(height: 12),
                TextField(
                  controller: titleController,
                  decoration: const InputDecoration(
                    labelText: 'Notification Title',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.title),
                    hintText: 'E.g., Important Update',
                  ),
                  maxLength: 50,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: messageController,
                  decoration: const InputDecoration(
                    labelText: 'Notification Message',
                    border: OutlineInputBorder(),
                    prefixIcon: Icon(Icons.message),
                    hintText: 'E.g., Check the new announcement',
                  ),
                  maxLines: 4,
                  maxLength: 200,
                ),
              ],
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel'),
            ),
            ElevatedButton.icon(
              onPressed: () {
                if (titleController.text.isEmpty || messageController.text.isEmpty) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Please fill in all fields'),
                      backgroundColor: Colors.orange,
                    ),
                  );
                  return;
                }
                Navigator.pop(ctx);
                _sendPushNotifications(
                  titleController.text,
                  messageController.text,
                  sendToAll,
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue[700],
                foregroundColor: Colors.white,
              ),
              icon: const Icon(Icons.send),
              label: const Text('Send Push'),
            ),
          ],
        ),
      ),
    );
  }

 Future<void> _sendPushNotifications(String title, String message, bool sendToAll) async {
  try {
    // Show loading indicator
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Row(
            children: [
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                ),
              ),
              SizedBox(width: 12),
              Text('Sending push notifications...'),
            ],
          ),
          duration: Duration(seconds: 30),
          backgroundColor: Colors.blue,
        ),
      );
    }

    // ✅ Get current user ID
    final currentUserId = supabase.auth.currentUser?.id;

    // Determine target users
    List<String> targetUserIds;
    if (sendToAll) {
      // Send to ALL users (including yourself)
      targetUserIds = users.map((u) => u.uid).toList();
    } else {
      // Send to selected users + yourself
      targetUserIds = selectedUsers.toList();
      
      // ✅ Add yourself if not already in the list
      if (currentUserId != null && !targetUserIds.contains(currentUserId)) {
        targetUserIds.add(currentUserId);
      }
    }

    debugPrint('📤 Target users: ${targetUserIds.length}');

    // 1️⃣ Save in-app notifications to database
    final notifications = targetUserIds.map((userId) => {
      'user_id': userId,
      'title': title,
      'message': message,
      'is_read': false,
      'created_at': DateTime.now().toIso8601String(),
    }).toList();

    await supabase.from('notifications').insert(notifications);

    // 2️⃣ Get FCM tokens for target users
    final tokensResponse = await supabase
        .from('fcm_tokens')
        .select('token')
        .inFilter('user_id', targetUserIds);

    final fcmTokens = (tokensResponse as List)
        .map((row) => row['token'] as String)
        .toList();

    debugPrint('📤 Sending to ${fcmTokens.length} devices');

    // 3️⃣ Send push notifications via FCM
    final result = await notificationService.sendBulkPushNotifications(
      deviceTokens: fcmTokens,
      title: title,
      body: message,
      data: {
        'type': 'announcement',
        'timestamp': DateTime.now().toIso8601String(),
      },
    );

    debugPrint('✅ Sent: ${result['sent']}, Failed: ${result['failed']}');

    // Show success message
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              const Icon(Icons.check_circle, color: Colors.white),
              const SizedBox(width: 12),
              Expanded(
                child: Text('✓ Push sent to ${result['sent']} users (${result['failed']} failed)'),
              ),
            ],
          ),
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 4),
        ),
      );
    }

    setState(() {
      selectedUsers.clear();
    });
  } catch (e) {
    debugPrint('💥 Error: $e');
    if (mounted) {
      ScaffoldMessenger.of(context).clearSnackBars();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
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
            icon: const Icon(Icons.notifications_active),
            onPressed: _showNotificationDialog,
            tooltip: 'Send Notification',
          ),
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
    final hasActiveFilters = hasPanchayatFilter || filterIsAdmin != null || filterIsDC != null;
    
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
          if (filteredUsers.isNotEmpty && hasActiveFilters) ...[
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: _selectAllFiltered,
                icon: const Icon(Icons.check_box, size: 20),
                label: Text(
                  'Select All ${filteredUsers.length} Filtered Users',
                  style: const TextStyle(fontSize: 14),
                ),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.green[700],
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
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
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
      child: Row(
        children: [
          Flexible(
            flex: 2,
            child: Text(
              '${selectedUsers.length} selected',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const Spacer(),
          TextButton.icon(
            onPressed: () => setState(() => selectedUsers.clear()),
            icon: const Icon(Icons.clear, color: Colors.white, size: 18),
            label: const Text('Clear', style: TextStyle(color: Colors.white, fontSize: 12)),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              minimumSize: const Size(0, 36),
            ),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _showNotificationDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue[700],
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            icon: const Icon(Icons.notifications, size: 16),
            label: const Text('Notify', style: TextStyle(fontSize: 12)),
          ),
          const SizedBox(width: 4),
          ElevatedButton.icon(
            onPressed: _showBulkUpdateDialog,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: Colors.green[900],
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              minimumSize: const Size(0, 36),
            ),
            icon: const Icon(Icons.edit, size: 16),
            label: const Text('Roles', style: TextStyle(fontSize: 12)),
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

class UserDetailPage extends StatefulWidget {
  final AppUser user;
  final VoidCallback onUpdate;

  const UserDetailPage({super.key, required this.user, required this.onUpdate});

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
      await supabase.from('profiles').update({
        'is_admin': isAdmin,
        'is_dc': isDC,
      }).eq('id', widget.user.uid);
      
      widget.onUpdate();
      
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('User updated successfully'), backgroundColor: Colors.green),
        );
      }
    } catch (e) {
      setState(() => isSaving = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  Future<void> _deleteUser() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete User'),
        content: const Text('This action CANNOT be undone!'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    try {
      await supabase.from('profiles').delete().eq('id', widget.user.uid);
      widget.onUpdate();
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Details'),
        actions: [
          IconButton(icon: const Icon(Icons.delete, color: Colors.red), onPressed: _deleteUser),
          IconButton(icon: const Icon(Icons.save), onPressed: _saveChanges),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          SwitchListTile(
            title: const Text('Admin Access'),
            value: isAdmin,
            onChanged: (val) => setState(() => isAdmin = val),
          ),
          SwitchListTile(
            title: const Text('DC Access'),
            value: isDC,
            onChanged: (val) => setState(() => isDC = val),
          ),
        ],
      ),
    );
  }
}