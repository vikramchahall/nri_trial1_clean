import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:nri_trial1_clean/features/profile/presentation/pages/user_profile_page.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:nri_trial1_clean/features/crowdfunding/presentation/components/verification_badge.dart';

import '../../domain/entities/crowd_post.dart';
import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

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
            fallbackUrl: post.userProfileImageUrl,
          ),
        ),
        title: GestureDetector(
          onTap: () => _openProfile(context),
          child: _UserNameDisplay(
            userId: post.userId,
            fallbackName: post.userName,
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

/// 📝 USERNAME DISPLAY WITH BADGE
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
  bool _isDC = false;
  bool _isAdmin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _currentName = widget.fallbackName;
    _fetchLatestUserData();
  }

  Future<void> _fetchLatestUserData() async {
    if (_isLoading) return;
    
    setState(() => _isLoading = true);

    try {
      final response = await Supabase.instance.client
          .from('profiles')
          .select('username, is_dc, is_admin')
          .eq('id', widget.userId)
          .single();

      if (mounted) {
        final newName = response['username'] as String?;
        final isDC = response['is_dc'] == true;
        final isAdmin = response['is_admin'] == true;
        
        setState(() {
          if (newName != null) _currentName = newName;
          _isDC = isDC;
          _isAdmin = isAdmin;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch user data: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: Text(
            _currentName ?? 'Unknown User',
            style: const TextStyle(fontWeight: FontWeight.bold),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (_isDC || _isAdmin) ...[
          const SizedBox(width: 4),
          VerificationBadge(
            isDC: _isDC,
            isAdmin: _isAdmin,
            size: 14,
          ),
        ],
      ],
    );
  }
}

/// 👤 PROFILE AVATAR WITH BADGE
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
  bool _isDC = false;
  bool _isAdmin = false;
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
          .select('profile_image_url, image_version, is_dc, is_admin')
          .eq('id', widget.userId)
          .single();

      if (mounted) {
        final newUrl = response['profile_image_url'] as String?;
        final newVersion = response['image_version'] as int?;
        final isDC = response['is_dc'] == true;
        final isAdmin = response['is_admin'] == true;
        
        setState(() {
          _currentUrl = newUrl;
          _currentVersion = newVersion;
          _isDC = isDC;
          _isAdmin = isAdmin;
        });
      }
    } catch (e) {
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

    return Stack(
      children: [
        CircleAvatar(
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
        ),
        if (_isDC || _isAdmin)
          Positioned(
            right: 0,
            bottom: 0,
            child: VerificationBadge(
              isDC: _isDC,
              isAdmin: _isAdmin,
              size: 16,
            ),
          ),
      ],
    );
  }
}