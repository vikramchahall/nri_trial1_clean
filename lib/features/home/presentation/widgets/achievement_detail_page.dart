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
  final supabase = Supabase.instance.client;

  try {
    debugPrint("🔍 Deleting achievement with ID: ${achievement['id']}");
    debugPrint("🔍 Image URL: ${achievement['image_url']}");

    /// 🧹 Delete media from storage (same as official posts)
    if (achievement['image_url'] != null) {
      final uri = Uri.parse(achievement['image_url'] as String);
      final path = uri.pathSegments
          .skipWhile((e) => e != 'official_media')
          .skip(1)
          .join('/');

      debugPrint("🖼️ Deleting image at path: $path");

      await supabase.storage
          .from('official_media')
          .remove([path]);
      
      debugPrint("✅ Image deleted from storage");
    }

    /// 🗑️ Delete DB row (from achievements table)
    debugPrint("🗑️ Deleting from achievements table...");
    
    await supabase
        .from('achievements')
        .delete()
        .eq('id', achievement['id']);
    
    debugPrint("✅ Achievement deleted from database");

    if (context.mounted) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Achievement deleted successfully"),
          backgroundColor: Colors.green,
        ),
      );
    }
  } on PostgrestException catch (e) {
    debugPrint("❌ PostgrestException: ${e.code} - ${e.message}");
    debugPrint("   Details: ${e.details}");
    debugPrint("   Hint: ${e.hint}");
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Database error: ${e.message}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } catch (e, stackTrace) {
    debugPrint("❌ Error deleting achievement: $e");
    debugPrint("Stack trace: $stackTrace");
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Error: $e"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  }
}
/* 
=== DEBUGGING STEPS ===

1. Run the app and try to delete an achievement
2. Check your console/logs for these messages:
   - 🔍 Achievement data (ID, title, image URL)
   - 🖼️ Image path being deleted
   - 🗑️ Database deletion attempt
   - ✅ or ❌ Success/error messages

3. Common issues to check:

   ISSUE: ID type mismatch
   - Check if achievement['id'] is a String or int
   - Your database might expect UUID, int, or bigint
   
   ISSUE: RLS (Row Level Security) policies
   - Your Supabase might have RLS enabled
   - Only DC users can delete, but RLS might not recognize them
   
   ISSUE: Wrong table name
   - Verify the table is called 'achievements' (not 'official_updates')
   
   ISSUE: No matching row
   - The achievement might have already been deleted
   - Or the ID doesn't match any row

4. Share the console output with me so I can help diagnose!

=== ALTERNATIVE: Check your Supabase RLS policies ===

Go to Supabase Dashboard > Authentication > Policies
Check the 'achievements' table policies:

DELETE policy should look like:
USING (
  auth.uid() IN (
    SELECT id FROM profiles WHERE is_dc = true
  )
)

OR if using a different field:
USING (
  EXISTS (
    SELECT 1 FROM profiles 
    WHERE id = auth.uid() 
    AND is_dc = true
  )
)
*/

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

