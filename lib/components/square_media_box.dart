import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:video_player/video_player.dart';

class SquareMediaBox extends StatefulWidget {
  final String url;
  final String type;

  const SquareMediaBox({super.key, required this.url, required this.type});

  @override
  State<SquareMediaBox> createState() => _SquareMediaBoxState();
}

class _SquareMediaBoxState extends State<SquareMediaBox> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.type == 'video') {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          if (mounted) setState(() {});
        });
    }
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: widget.type == 'video' ? _buildVideo() : _buildImage(),
    );
  }

  Widget _buildImage() {
    return AspectRatio(
      aspectRatio: 1,
      child: CachedNetworkImage(
        imageUrl: widget.url,
        fit: BoxFit.cover,
        placeholder: (context, url) => Container(
          color: Colors.grey.shade200,
          child: const Center(child: CircularProgressIndicator()),
        ),
        errorWidget: (context, url, error) => Container(
          color: Colors.grey.shade200,
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      ),
    );
  }

Widget _buildVideo() {
  if (_controller == null || !_controller!.value.isInitialized) {
    return AspectRatio(
      aspectRatio: 1,
      child: Container(
        color: Colors.grey.shade200,
        child: const Center(child: CircularProgressIndicator()),
      ),
    );
  }

  return AspectRatio(
    aspectRatio: _controller!.value.aspectRatio,
    child: Stack(
      alignment: Alignment.bottomCenter,
      children: [
        VideoPlayer(_controller!),

        // ✅ Transparent overlay captures taps
        Positioned.fill(
          child: GestureDetector(
            behavior: HitTestBehavior.opaque, // ✅ KEY FIX
            onTap: () => setState(() {
              _controller!.value.isPlaying
                  ? _controller!.pause()
                  : _controller!.play();
            }),
          ),
        ),

        // Progress bar
        VideoProgressIndicator(
          _controller!,
          allowScrubbing: true,
          colors: VideoProgressColors(
            playedColor: Colors.green,
            bufferedColor: Colors.white38,
            backgroundColor: Colors.black26,
          ),
          padding: const EdgeInsets.symmetric(vertical: 4),
        ),
      ],
    ),
  );
}
}