import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MyMediaGridTile extends StatefulWidget {
  final String url;
  const MyMediaGridTile({super.key, required this.url});

  @override
  State<MyMediaGridTile> createState() => _MyMediaGridTileState();
}

class _MyMediaGridTileState extends State<MyMediaGridTile> with AutomaticKeepAliveClientMixin {
  VideoPlayerController? _controller;
  bool isVideo = false;
  bool _isInitialized = false;

  @override
  bool get wantKeepAlive => true; // Keeps the thumbnail loaded while scrolling

  @override
  void initState() {
    super.initState();
    
    // Check if the URL is a video
    final String path = widget.url.toLowerCase();
    isVideo = path.contains(".mp4") || path.contains(".mov") || path.contains(".m4v");

    if (isVideo) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          // Seek to 1 second to get a good preview frame
          _controller!.seekTo(const Duration(seconds: 1));
          if (mounted) {
            setState(() {
              _isInitialized = true;
            });
          }
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
    super.build(context); // Required for AutomaticKeepAlive

    if (!isVideo) {
      return Image.network(
        widget.url,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => Container(
          color: Colors.grey[200],
          child: const Icon(Icons.broken_image, color: Colors.grey),
        ),
      );
    }

    // Video Preview logic
    return Stack(
      fit: StackFit.expand,
      children: [
        _isInitialized
            ? FittedBox(
                fit: BoxFit.cover,
                clipBehavior: Clip.hardEdge,
                child: SizedBox(
                  width: _controller!.value.size.width,
                  height: _controller!.value.size.height,
                  child: VideoPlayer(_controller!),
                ),
              )
            : Container(color: Colors.grey[200]),
        
        // VIDEO INDICATOR ICON
        const Positioned(
          top: 5,
          right: 5,
          child: Icon(Icons.videocam, color: Colors.white, size: 18),
        ),
        
        // Slight dark overlay to make the icon pop
        Container(color: Colors.black12),
      ],
    );
  }
}