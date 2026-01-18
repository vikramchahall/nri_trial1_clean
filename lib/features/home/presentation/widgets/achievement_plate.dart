import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

/// Widget that displays a horizontal scrollable list of achievement cards with auto-scroll
class AchievementPlate extends StatefulWidget {
  const AchievementPlate({super.key});

  @override
  State<AchievementPlate> createState() => _AchievementPlateState();
}

class _AchievementPlateState extends State<AchievementPlate> {
  final PageController _pageController = PageController(viewportFraction: 0.85);
  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _scrollLeft() {
    if (_currentPage > 0) {
      _pageController.previousPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  void _scrollRight(int maxPage) {
    if (_currentPage < maxPage) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final supabase = Supabase.instance.client;

    return StreamBuilder<List<Map<String, dynamic>>>(
      stream: supabase
          .from('achievements')
          .stream(primaryKey: ['id'])
          .order('timestamp', ascending: false)
          .limit(10),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const SizedBox(
            height: 180,
            child: Center(child: CircularProgressIndicator()),
          );
        }

        final achievements = snapshot.data!;
        
        if (achievements.isEmpty) {
          return Container(
            height: 180,
            margin: const EdgeInsets.symmetric(horizontal: 20),
            decoration: BoxDecoration(
              color: Colors.grey.shade900,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.workspace_premium,
                    size: 48,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "No achievements yet",
                    style: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return SizedBox(
          height: 180,
          child: Stack(
            children: [
              // Page View with Cards
              PageView.builder(
                controller: _pageController,
                onPageChanged: (index) {
                  setState(() {
                    _currentPage = index;
                  });
                },
                itemCount: achievements.length,
                itemBuilder: (context, index) {
                  final achievement = achievements[index];
                  final imageUrl = achievement['image_url'] as String?;
                  final title = achievement['title'] as String? ?? 'Achievement';

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => AchievementDetailPage(
                            achievement: achievement,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      margin: const EdgeInsets.symmetric(horizontal: 8),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 12,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: Stack(
                          fit: StackFit.expand,
                          children: [
                            // Background Image (if exists)
                            if (imageUrl != null)
                              Image.network(
                                imageUrl,
                                fit: BoxFit.cover,
                                errorBuilder: (context, error, stackTrace) {
                                  return Container(
                                    color: Colors.grey.shade900,
                                  );
                                },
                              )
                            else
                              Container(
                                color: Colors.grey.shade900,
                              ),
                            
                            // Dark Tint Overlay
                            Container(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withOpacity(0.6),
                                    Colors.black.withOpacity(0.8),
                                  ],
                                ),
                              ),
                            ),
                            
                            // Text Content
                            Padding(
                              padding: const EdgeInsets.all(20),
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Achievement Icon
   
                                  // Title
                                  Text(
                                    title,
                                    style: const TextStyle(
                                      fontSize: 22,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.white,
                                      height: 1.2,
                                    ),
                                    maxLines: 3,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  
                                  const SizedBox(height: 8),
                                  
                                  // Tap to view hint
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.touch_app,
                                        color: Colors.white.withOpacity(0.7),
                                        size: 14,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        "Tap to view details",
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.white.withOpacity(0.7),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
              
              // Left Arrow
              if (_currentPage > 0)
                Positioned(
                  left: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(left: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_left),
                        onPressed: _scrollLeft,
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              
              // Right Arrow
              if (_currentPage < achievements.length - 1)
                Positioned(
                  right: 0,
                  top: 0,
                  bottom: 0,
                  child: Center(
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.2),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: IconButton(
                        icon: const Icon(Icons.chevron_right),
                        onPressed: () => _scrollRight(achievements.length - 1),
                        color: Colors.grey.shade800,
                      ),
                    ),
                  ),
                ),
              
              // Page Indicator Dots
              Positioned(
                bottom: 12,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    achievements.length,
                    (index) => Container(
                      margin: const EdgeInsets.symmetric(horizontal: 3),
                      width: _currentPage == index ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _currentPage == index
                            ? Colors.white
                            : Colors.white.withOpacity(0.4),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

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
    debugPrint("🔍 Starting achievement deletion...");
    debugPrint("   Achievement ID: ${achievement['id']}");
    debugPrint("   Image URL: ${achievement['image_url']}");

    /// 🧹 Delete media from storage FIRST (using official posts pattern)
    if (achievement['image_url'] != null && achievement['image_url'] != '') {
      final imageUrl = achievement['image_url'] as String;
      
      try {
        final uri = Uri.parse(imageUrl);
        
        // Use the SAME pattern as official posts deletion
        final path = uri.pathSegments
            .skipWhile((e) => e != 'official_media')
            .skip(1)
            .join('/');

        debugPrint("🖼️ Deleting image at path: $path");

        if (path.isNotEmpty) {
          await supabase.storage
              .from('official_media')
              .remove([path]);
          
          debugPrint("✅ Image deleted from storage");
        }
      } catch (imageError) {
        debugPrint("⚠️ Image deletion failed: $imageError");
        // Continue anyway - don't let image deletion stop database deletion
      }
    }

    /// 🗑️ Delete from database
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
    
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Database error: ${e.message}"),
          backgroundColor: Colors.red,
          duration: const Duration(seconds: 5),
        ),
      );
    }
  } catch (e) {
    debugPrint("❌ Error deleting achievement: $e");
    
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