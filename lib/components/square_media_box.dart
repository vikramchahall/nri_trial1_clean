import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class SquareMediaBox extends StatefulWidget {
  final String url;
  final String type; // image | video

  const SquareMediaBox({
    super.key,
    required this.url,
    required this.type,
  });

  @override
  State<SquareMediaBox> createState() => _SquareMediaBoxState();
}

class _SquareMediaBoxState extends State<SquareMediaBox> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();

    if (widget.type == 'video') {
      _controller = VideoPlayerController.network(widget.url)
        ..initialize().then((_) {
          setState(() {});
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
    return AspectRatio(
      aspectRatio: 1, // 🔒 square
      child: Container(
        color: Colors.black,
        child: widget.type == 'video'
            ? _buildVideo()
            : _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    return Image.network(
      widget.url,
      fit: BoxFit.contain,
    );
  }

  Widget _buildVideo() {
    if (_controller == null || !_controller!.value.isInitialized) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      alignment: Alignment.center,
      children: [
        VideoPlayer(_controller!),

        // ▶️ PLAY / ⏸ PAUSE BUTTON
        GestureDetector(
          onTap: () {
            setState(() {
              _controller!.value.isPlaying
                  ? _controller!.pause()
                  : _controller!.play();
            });
          },
          child: Icon(
            _controller!.value.isPlaying
                ? Icons.pause_circle_filled
                : Icons.play_circle_filled,
            size: 56,
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
