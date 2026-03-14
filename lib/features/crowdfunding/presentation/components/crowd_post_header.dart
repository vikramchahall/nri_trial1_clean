import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:share_plus/share_plus.dart';
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

  // ✅ Share deep link — points to your GitHub Pages redirect

  @override
  Widget build(BuildContext context) {
    final currentUser = context.read<AuthCubit>().currentUser;
    final canDelete =
        currentUser?.uid == post.userId || (currentUser?.isDC ?? false);
    final isOwnPost = currentUser?.uid == post.userId;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8),
      child: ListTile(
        contentPadding: EdgeInsets.zero,
        leading: GestureDetector(
          onTap: () => _openProfile(context),
          child: _ProfileAvatar(
            key: ValueKey('avatar_${post.userId}'),
            userId: post.userId,
            fallbackUrl: post.userProfileImageUrl,
          ),
        ),
        title: GestureDetector(
          onTap: () => _openProfile(context),
          child: _UserNameDisplay(
            key: ValueKey(post.userId),
            userId: post.userId,
            fallbackName: post.userName,
          ),
        ),
        subtitle: Text(
          DateFormat('dd MMM, yyyy').format(post.timestamp),
          style: const TextStyle(fontSize: 11),
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (currentUser != null && !isOwnPost)
              _FollowButton(
                currentUserId: currentUser.uid,
                targetUserId: post.userId,
              ),
            PopupMenuButton<String>(
              icon: const Icon(Icons.more_vert),
              onSelected: (value) {
                if (value == 'delete') _confirmDelete(context);
                if (value == 'report') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text("Post reported. Thank you!"),
                    ),
                  );
                }
              },
              itemBuilder: (_) => [
                if (canDelete)
                  const PopupMenuItem(
                    value: 'delete',
                    child: Row(
                      children: [
                        Icon(Icons.delete_outline, color: Colors.red, size: 20),
                        SizedBox(width: 8),
                        Text("Delete Post",
                            style: TextStyle(color: Colors.red)),
                      ],
                    ),
                  ),
              
                const PopupMenuItem(
                  value: 'report',
                  child: Row(
                    children: [
                      Icon(Icons.flag_outlined,
                          color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text("Report Post"),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
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

// ===============================
// ✅ FOLLOW BUTTON — OPTIMIZED
// ===============================
class _FollowButton extends StatefulWidget {
  final String currentUserId;
  final String targetUserId;

  const _FollowButton({
    required this.currentUserId,
    required this.targetUserId,
  });

  @override
  State<_FollowButton> createState() => _FollowButtonState();
}

class _FollowButtonState extends State<_FollowButton> {
  bool _isFollowing = false;
  bool _isLoading = true;

  static final Map<String, bool> _followCache = {};

  String get _cacheKey => '${widget.currentUserId}_${widget.targetUserId}';

  @override
  void initState() {
    super.initState();
    if (_followCache.containsKey(_cacheKey)) {
      _isFollowing = _followCache[_cacheKey]!;
      _isLoading = false;
    } else {
      _checkFollowStatus();
    }
  }

  Future<void> _checkFollowStatus() async {
    try {
      final response = await Supabase.instance.client
          .from('follows')
          .select('follower_id')
          .eq('follower_id', widget.currentUserId)
          .eq('following_id', widget.targetUserId)
          .maybeSingle();

      final isFollowing = response != null;
      _followCache[_cacheKey] = isFollowing;

      if (mounted) {
        setState(() {
          _isFollowing = isFollowing;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _toggleFollow() async {
    final wasFollowing = _isFollowing;
    setState(() {
      _isFollowing = !_isFollowing;
      _followCache[_cacheKey] = _isFollowing;
    });

    try {
      if (wasFollowing) {
        await Supabase.instance.client
            .from('follows')
            .delete()
            .eq('follower_id', widget.currentUserId)
            .eq('following_id', widget.targetUserId);
      } else {
        await Supabase.instance.client.from('follows').insert({
          'follower_id': widget.currentUserId,
          'following_id': widget.targetUserId,
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isFollowing = wasFollowing;
          _followCache[_cacheKey] = wasFollowing;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const SizedBox(
        width: 60,
        height: 24,
        child: Center(
          child: SizedBox(
            width: 14,
            height: 14,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        ),
      );
    }

    return GestureDetector(
      onTap: _toggleFollow,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
        decoration: BoxDecoration(
          color: _isFollowing ? Colors.transparent : Colors.green,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: _isFollowing ? Colors.grey : Colors.green,
            width: 1.2,
          ),
        ),
        child: Text(
          _isFollowing ? "Following" : "Follow",
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: _isFollowing ? Colors.black87 : Colors.white,
          ),
        ),
      ),
    );
  }
}

// ===============================
// 📝 USERNAME DISPLAY WITH BADGE
// ===============================
class _UserNameDisplay extends StatefulWidget {
  final String userId;
  final String fallbackName;

  const _UserNameDisplay({
    super.key,
    required this.userId,
    required this.fallbackName,
  });

  @override
  State<_UserNameDisplay> createState() => _UserNameDisplayState();
}

class _UserNameDisplayState extends State<_UserNameDisplay> {
  static final Map<String, Map<String, dynamic>> _userCache = {};

  String? _currentName;
  bool _isDC = false;
  bool _isAdmin = false;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    if (_userCache.containsKey(widget.userId)) {
      final cached = _userCache[widget.userId]!;
      _currentName = cached['username'];
      _isDC = cached['is_dc'] ?? false;
      _isAdmin = cached['is_admin'] ?? false;
    } else {
      _fetchLatestUserData();
    }
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

        _userCache[widget.userId] = {
          'username': newName,
          'is_dc': isDC,
          'is_admin': isAdmin,
        };

        setState(() {
          if (newName != null) _currentName = newName;
          _isDC = isDC;
          _isAdmin = isAdmin;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch user data: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Flexible(
          child: _isLoading
              ? Container(
                  width: 80,
                  height: 12,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(4),
                  ),
                )
              : Text(
                  _currentName ?? 'Unknown User',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                  overflow: TextOverflow.ellipsis,
                ),
        ),
        if (!_isLoading && (_isDC || _isAdmin)) ...[
          const SizedBox(width: 4),
          VerificationBadge(isDC: _isDC, isAdmin: _isAdmin, size: 14),
        ],
      ],
    );
  }
}

// ===============================
// 👤 PROFILE AVATAR WITH BADGE
// ===============================
class _ProfileAvatar extends StatefulWidget {
  final String userId;
  final String? fallbackUrl;

  const _ProfileAvatar({
    super.key,
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
        setState(() {
          _currentUrl = response['profile_image_url'] as String?;
          _currentVersion = response['image_version'] as int?;
          _isDC = response['is_dc'] == true;
          _isAdmin = response['is_admin'] == true;
        });
      }
    } catch (e) {
      debugPrint('Failed to fetch avatar: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
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