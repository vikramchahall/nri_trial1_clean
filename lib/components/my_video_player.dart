import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MyVideoPlayer extends StatefulWidget {
  final String videoUrl;
  const MyVideoPlayer({super.key, required this.videoUrl});

  @override
  State<MyVideoPlayer> createState() => _MyVideoPlayerState();
}

class _MyVideoPlayerState extends State<MyVideoPlayer> {
  late VideoPlayerController _controller;
  bool _isInitialized = false;

  @override
  void initState() {
    super.initState();

    // ✅ MODERN + COMPATIBLE CONTROLLER
    _controller = VideoPlayerController.networkUrl(
      Uri.parse(widget.videoUrl),
    )
      ..initialize().then((_) {
        if (!mounted) return;
        setState(() {
          _isInitialized = true; // show first frame
        });
      }).catchError((error) {
        debugPrint("🎥 Video Player Error: $error");
      });
  }

  @override
  void dispose() {
    _controller.dispose(); // 🔴 IMPORTANT: free resources
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!_isInitialized) {
      return Container(
        height: 350,
        color: Colors.black12,
        child: const Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    return GestureDetector(
      onTap: () {
        setState(() {
          _controller.value.isPlaying
              ? _controller.pause()
              : _controller.play();
        });
      },
      child: Stack(
        alignment: Alignment.center,
        children: [
          // 🎥 VIDEO FRAME
          AspectRatio(
            aspectRatio: _controller.value.aspectRatio,
            child: VideoPlayer(_controller),
          ),

          // ▶ PLAY OVERLAY (when paused)
          if (!_controller.value.isPlaying)
            CircleAvatar(
              radius: 30,
              backgroundColor: Colors.black45,
              child: const Icon(
                Icons.play_arrow,
                size: 40,
                color: Colors.white,
              ),
            ),
        ],
      ),
    );
  }
}
