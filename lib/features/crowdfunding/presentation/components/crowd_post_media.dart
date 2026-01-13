import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../domain/entities/crowd_post.dart';
import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';
import '../../../../components/my_video_player.dart';

class CrowdPostMedia extends StatelessWidget {
  final CrowdPost post;

  const CrowdPostMedia({
    super.key,
    required this.post,
  });

  @override
  Widget build(BuildContext context) {
    final mediaUrl = post.imageUrl;

    final isVideo =
        mediaUrl.toLowerCase().contains('.mp4') ||
        mediaUrl.toLowerCase().contains('.mov');

    return GestureDetector(
      onDoubleTap: () {
        final user = context.read<AuthCubit>().currentUser;
        if (user == null) return;

        context.read<CrowdCubit>().toggleLike(
              post.id,
              user.uid,
            );
      },
      child: AspectRatio(
        aspectRatio: 1,
        child: isVideo
            ? MyVideoPlayer(videoUrl: mediaUrl)
            : Image.network(
                mediaUrl,
                fit: BoxFit.cover,
              ),
      ),
    );
  }
}
