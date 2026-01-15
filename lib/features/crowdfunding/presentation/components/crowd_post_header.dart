import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nri_trial1_clean/features/profile/presentation/pages/user_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../domain/entities/crowd_post.dart';
import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../profile/presentation/pages/profile_page.dart';

class CrowdPostHeader extends StatelessWidget {
  final CrowdPost post;

  const CrowdPostHeader({
    super.key,
    required this.post,
  });

  void _openProfile(BuildContext context) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => UserProfilePage(uid: post.userId),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;

    final canDelete =
        currentUser?.uid == post.userId || (currentUser?.isDC ?? false);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: GestureDetector(
          onTap: () => _openProfile(context),
          child: _ProfileAvatar(
            userId: post.userId,
            fallbackUrl: post.userProfileImageUrl, // Pass cached data
          ),
        ),
        title: GestureDetector(
          onTap: () => _openProfile(context),
          child: _UserNameDisplay(
            userId: post.userId,
            fallbackName: post.userName, // Show immediately, update if changed
          ),
        ),
        subtitle: Text(
          DateFormat('dd MMM, yyyy').format(post.timestamp),
          style: const TextStyle(fontSize: 11),
        ),
        trailing: canDelete
            ? IconButton(
                icon: const Icon(Icons.delete_outline, color: Colors.red),
                onPressed: () => _confirmDelete(context),
              )
            : null,
      ),
    );
  }

  void _confirmDelete(BuildContext context) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Delete Post?"),
        content: const Text(
          "This action cannot be undone.\nAre you sure you want to delete this post?",
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () {
              Navigator.pop(context);
              context.read<CrowdCubit>().deleteCrowd(post.id);
            },
            child: const Text(
              "Delete",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}

/// 📝 USERNAME DISPLAY (OPTIMIZED WITH FALLBACK)
class _UserNameDisplay extends StatefulWidget {
  final String userId;
  final String fallbackName;

  const _UserNameDisplay({
    required this.userId,
    required this.fallbackName,
  });

  @override
  State<_UserNameDisplay> createState() => _UserNameDisplayState();
}

class _UserNameDisplayState extends State<_UserNameDisplay> {
  String? _currentName;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentName = widget.fallbackName;
    _fetchLatestUsername();
  }

  Future<void> _fetchLatestUsername() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username')
          .eq('id', widget.userId)
          .single();

      if (mounted) {
        final newName = response['username'] as String?;
        if (newName != null && newName != _currentName) {
          setState(() => _currentName = newName);
        }
      }
    } catch (e) {
      // Silently fail and keep using fallback
      debugPrint('Failed to fetch username: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Text(
      _currentName ?? 'Unknown User',
      style: const TextStyle(fontWeight: FontWeight.bold),
    );
  }
}

/// 👤 PROFILE AVATAR (OPTIMIZED WITH FALLBACK)
class _ProfileAvatar extends StatefulWidget {
  final String userId;
  final String? fallbackUrl;

  const _ProfileAvatar({
    required this.userId,
    this.fallbackUrl,
  });

  @override
  State<_ProfileAvatar> createState() => _ProfileAvatarState();
}

class _ProfileAvatarState extends State<_ProfileAvatar> {
  String? _currentUrl;
  int? _currentVersion;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentUrl = widget.fallbackUrl;
    _fetchLatestAvatar();
  }

  Future<void> _fetchLatestAvatar() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('profile_image_url, image_version')
          .eq('id', widget.userId)
          .single();

      if (mounted) {
        final newUrl = response['profile_image_url'] as String?;
        final newVersion = response['image_version'] as int?;
        
        if (newUrl != _currentUrl || newVersion != _currentVersion) {
          setState(() {
            _currentUrl = newUrl;
            _currentVersion = newVersion;
          });
        }
      }
    } catch (e) {
      // Silently fail and keep using fallback
      debugPrint('Failed to fetch avatar: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final url = _currentUrl;
    final version = _currentVersion;

    return CircleAvatar(
      radius: 20,
      backgroundColor: Colors.grey[200],
      backgroundImage: (url != null && url.isNotEmpty)
          ? NetworkImage(
              version != null && version > 0 ? "$url?v=$version" : url,
            )
          : null,
      child: (url == null || url.isEmpty)
          ? const Icon(Icons.person, color: Colors.grey, size: 20)
          : null,
    );
  }
}