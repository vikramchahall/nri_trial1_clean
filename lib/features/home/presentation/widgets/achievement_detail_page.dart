import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';



class AchievementDetailPage extends StatelessWidget {
  final Map<String, dynamic> achievement;

  const AchievementDetailPage({
    super.key,
    required this.achievement,
  });

  void _showDeleteDialog(BuildContext context) {
    // Get current user's isDC status from AuthCubit
    final user = context.read<AuthCubit>().currentUser;
    final canDelete = user?.isDC ?? false;
    
    if (!canDelete) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("You don't have permission to delete achievements"),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text("Delete Achievement"),
        content: const Text("Are you sure you want to delete this achievement? This action cannot be undone."),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text("Cancel"),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(dialogContext);
              await _deleteAchievement(context);
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text("Delete"),
          ),
        ],
      ),
    );
  }

  Future<void> _deleteAchievement(BuildContext context) async {
    try {
      final supabase = Supabase.instance.client;

      // Delete image from storage if exists
      if (achievement['image_url'] != null) {
        final url = achievement['image_url'] as String;
        // Extract file path from the full URL
        final uri = Uri.parse(url);
        final pathSegments = uri.pathSegments;
        // Path format: /storage/v1/object/public/official_media/achievements/...
        if (pathSegments.length > 4) {
          final filePath = pathSegments.sublist(4).join('/');
          await supabase.storage
              .from('official_media')
              .remove([filePath]);
        }
      }

      // Delete from database
      await supabase.from('achievements').delete().eq('id', achievement['id']);

      if (context.mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Achievement deleted successfully"),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Error deleting: $e"),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final imageUrl = achievement['image_url'] as String?;
    final title = achievement['title'] as String? ?? 'Achievement';
    final shortDesc = achievement['short_description'] as String?;
    final fullDetails = achievement['full_details'] as String?;
    final timestamp = achievement['timestamp'] as String?;

    return Scaffold(
      backgroundColor: Colors.white,
      body: Builder(
        builder: (context) {
          // Get current user's isDC status
          final user = context.read<AuthCubit>().currentUser;
          final canDelete = user?.isDC ?? false;

          return CustomScrollView(
            slivers: [
              // App Bar with Image
              SliverAppBar(
                expandedHeight: 300,
                pinned: true,
                backgroundColor: Colors.grey.shade800,
                actions: canDelete ? [
                  IconButton(
                    icon: const Icon(Icons.delete_outline, color: Colors.red),
                    onPressed: () => _showDeleteDialog(context),
                    tooltip: "Delete Achievement",
                  ),
                ] : null,
                flexibleSpace: FlexibleSpaceBar(
                  background: imageUrl != null
                      ? Stack(
                          fit: StackFit.expand,
                          children: [
                            Image.network(
                              imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (context, error, stackTrace) {
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Icon(
                                    Icons.image_not_supported,
                                    size: 80,
                                    color: Colors.grey.shade400,
                                  ),
                                );
                              },
                              loadingBuilder: (context, child, loadingProgress) {
                                if (loadingProgress == null) return child;
                                return Container(
                                  color: Colors.grey.shade200,
                                  child: Center(
                                    child: CircularProgressIndicator(
                                      value: loadingProgress.expectedTotalBytes != null
                                          ? loadingProgress.cumulativeBytesLoaded /
                                              loadingProgress.expectedTotalBytes!
                                          : null,
                                    ),
                                  ),
                                );
                              },
                            ),
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.transparent,
                                    Colors.black.withOpacity(0.7),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        )
                      : Container(
                          color: Colors.grey.shade200,
                          child: Center(
                            child: Icon(
                              Icons.workspace_premium,
                              size: 100,
                              color: Colors.grey.shade400,
                            ),
                          ),
                        ),
                ),
              ),

              // Content
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Date Badge
                      if (timestamp != null)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            _formatDate(timestamp),
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      const SizedBox(height: 16),

                      // Title
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Short Description
                      if (shortDesc != null && shortDesc.isNotEmpty) ...[
                        Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.grey.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.grey.shade200,
                              width: 1,
                            ),
                          ),
                          child: Text(
                            shortDesc,
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                      ],

                      // Divider
                      Divider(color: Colors.grey.shade300, height: 32),

                      // Full Details Section
                      Text(
                        "Details",
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: Colors.grey.shade900,
                        ),
                      ),
                      const SizedBox(height: 12),
                      
                      Text(
                        fullDetails ?? 'No additional details provided.',
                        style: TextStyle(
                          fontSize: 16,
                          color: Colors.grey.shade700,
                          height: 1.6,
                        ),
                      ),
                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  String _formatDate(String timestamp) {
    try {
      final date = DateTime.parse(timestamp);
      final now = DateTime.now();
      final difference = now.difference(date);

      if (difference.inDays == 0) {
        return "Today";
      } else if (difference.inDays == 1) {
        return "Yesterday";
      } else if (difference.inDays < 7) {
        return "${difference.inDays} days ago";
      } else {
        final months = [
          'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
          'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'
        ];
        return "${date.day} ${months[date.month - 1]} ${date.year}";
      }
    } catch (e) {
      return timestamp;
    }
  }
}

