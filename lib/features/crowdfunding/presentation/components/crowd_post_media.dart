import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/crowd_post.dart';
import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../../components/my_video_player.dart';

class CrowdPostMedia extends StatefulWidget {
  final CrowdPost post;

  const CrowdPostMedia({
    super.key,
    required this.post,
  });

  @override
  State<CrowdPostMedia> createState() => _CrowdPostMediaState();
}

class _CrowdPostMediaState extends State<CrowdPostMedia>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scale;
  late Animation<double> _opacity;

  bool _showHeart = false;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 450),
    );

    _scale = Tween<double>(begin: 0.6, end: 1.4).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _opacity = Tween<double>(begin: 1, end: 0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _controller.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        setState(() => _showHeart = false);
        _controller.reset();
      }
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _onDoubleTap() {
    final user = context.read<AuthCubit>().currentUser;
    if (user == null) return;

    // ❤️ LIKE LOGIC (unchanged)
    context.read<CrowdCubit>().toggleLike(
          widget.post.id,
          user.uid,
        );

    // ❤️ SHOW HEART
    setState(() => _showHeart = true);
    _controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    final mediaUrl = widget.post.imageUrl;
    final isVideo =
        mediaUrl.toLowerCase().contains('.mp4') ||
        mediaUrl.toLowerCase().contains('.mov');

    return GestureDetector(
      onDoubleTap: _onDoubleTap,
      child: Stack(
        alignment: Alignment.center,
        children: [
          AspectRatio(
            aspectRatio: 1,
            child: isVideo
                ? MyVideoPlayer(videoUrl: mediaUrl)
                : Image.network(
                    mediaUrl,
                    fit: BoxFit.cover,
                  ),
          ),

          // ❤️ HEART OVERLAY
          if (_showHeart)
            AnimatedBuilder(
              animation: _controller,
              builder: (_, __) => Opacity(
                opacity: _opacity.value,
                child: Transform.scale(
                  scale: _scale.value,
                  child: const Icon(
                    Icons.favorite,
                    color: Colors.white,
                    size: 110,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
