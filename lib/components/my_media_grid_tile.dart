import 'package:flutter/material.dart';
import 'package:video_player/video_player.dart';

class MyMediaGridTile extends StatefulWidget {
  final String url;
  const MyMediaGridTile({super.key, required this.url});

  @override
  State<MyMediaGridTile> createState() => _MyMediaGridTileState();
}

class _MyMediaGridTileState extends State<MyMediaGridTile> {
  VideoPlayerController? _controller;
  bool isVideo = false;

  @override
  void initState() {
    super.initState();
    // Detect if it is a video
    isVideo = widget.url.toLowerCase().contains(".mp4") || 
              widget.url.toLowerCase().contains(".mov");

    if (isVideo) {
      _controller = VideoPlayerController.networkUrl(Uri.parse(widget.url))
        ..initialize().then((_) {
          // Seek to the 1st second to get a "preview" frame
          _controller!.seekTo(const Duration(seconds: 1));
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
    if (!isVideo) {
      return Image.network(widget.url, fit: BoxFit.cover);
    }

    // Video Thumbnail View
    return Stack(
      fit: StackFit.expand,
      children: [
        _controller != null && _controller!.value.isInitialized
            ? VideoPlayer(_controller!)
            : Container(color: Colors.grey[200]), // Loading state
        
        // VIDEO INDICATOR ICON (Industry Standard)
        const Positioned(
          top: 8,
          right: 8,
          child: Icon(Icons.videocam, color: Colors.white, size: 18),
        ),
        
        // Darken the thumbnail slightly
        Container(color: Colors.black12),
      ],
    );
  }
}