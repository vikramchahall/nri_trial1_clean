import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:image_picker/image_picker.dart';
import 'package:image/image.dart' as img;

import '../cubits/crowd_cubit.dart';
import '../../../auth/presentation/cubits/auth_cubit.dart';

class UploadCrowdPage extends StatefulWidget {
  const UploadCrowdPage({super.key});

  @override
  State<UploadCrowdPage> createState() => _UploadCrowdPageState();
}

class _UploadCrowdPageState extends State<UploadCrowdPage> {
  final TextEditingController _captionController = TextEditingController();
  final TextEditingController _targetController = TextEditingController();

  Uint8List? _selectedMediaBytes;
  Offset _imageOffset = Offset.zero; // 🔥 Track drag position
  bool _isFileTypeVideo = false;

  bool _isUploading = false;
  bool _isDonationPost = false;

  // ===============================
  // 📷 PICK MEDIA
  // ===============================
  Future<void> _pickMedia(bool isVideo) async {
    if (_isUploading) return;

    final picker = ImagePicker();
    XFile? file;

    if (isVideo) {
      file = await picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(seconds: 30),
      );
    } else {
      file = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1080,
        imageQuality: 70,
      );
    }

    if (file != null) {
      final bytes = await file.readAsBytes();
      setState(() {
        _selectedMediaBytes = bytes;
        _isFileTypeVideo = isVideo;
        _imageOffset = Offset.zero; // Reset position when new image picked
      });
    }
  }

  // ===============================
  // ✂️ CROP IMAGE BASED ON USER'S DRAG POSITION
  // ===============================
  Future<Uint8List?> _cropImageToSquare(Uint8List imageBytes, Offset offset) async {
    try {
      // Decode image
      final img.Image? originalImage = img.decodeImage(imageBytes);
      if (originalImage == null) return imageBytes;

      // Get the smaller dimension to make a square
      final size = originalImage.width < originalImage.height 
          ? originalImage.width 
          : originalImage.height;

      // Calculate crop position based on drag offset
      // Invert the offset since dragging right means we want to see the left part
      int x = (-offset.dx).round();
      int y = (-offset.dy).round();

      // Center the crop if no dragging occurred
      if (offset == Offset.zero) {
        x = (originalImage.width - size) ~/ 2;
        y = (originalImage.height - size) ~/ 2;
      } else {
        // Adjust based on image vs display size ratio
        final screenWidth = MediaQuery.of(context).size.width;
        final scaleX = originalImage.width / screenWidth;
        final scaleY = originalImage.height / screenWidth;
        
        x = (originalImage.width / 2 - offset.dx * scaleX).round() - (size ~/ 2);
        y = (originalImage.height / 2 - offset.dy * scaleY).round() - (size ~/ 2);
      }

      // Clamp values to prevent out-of-bounds
      x = x.clamp(0, originalImage.width - size);
      y = y.clamp(0, originalImage.height - size);

      // Crop to square
      final croppedImage = img.copyCrop(
        originalImage,
        x: x,
        y: y,
        width: size,
        height: size,
      );

      // Encode back to bytes
      return Uint8List.fromList(img.encodeJpg(croppedImage, quality: 85));
    } catch (e) {
      debugPrint("❌ Crop error: $e");
      return imageBytes; // Return original if crop fails
    }
  }

  // ===============================
  // ⬆️ UPLOAD WITH CROPPING
  // ===============================
  Future<void> _upload() async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(milliseconds: 10));

    final user = context.read<AuthCubit>().currentUser;

    if (user == null) {
      _stopLoading("User not logged in");
      return;
    }

    if (_selectedMediaBytes == null) {
      _stopLoading("Please select an image or video");
      return;
    }

    double targetValue = 0;
    if (_isDonationPost) {
      targetValue = double.tryParse(_targetController.text) ?? 0;
      if (targetValue <= 0) {
        _stopLoading("Enter valid donation amount");
        return;
      }
    }

    String fileName = DateTime.now().millisecondsSinceEpoch.toString();
    fileName += _isFileTypeVideo ? ".mp4" : ".jpg";

    try {
      Uint8List finalBytes = _selectedMediaBytes!;

      // 🔥 CROP IMAGE if it's an image (not video) and user dragged it
      if (!_isFileTypeVideo) {
        final croppedBytes = await _cropImageToSquare(_selectedMediaBytes!, _imageOffset);
        if (croppedBytes != null) {
          finalBytes = croppedBytes;
          debugPrint("✅ Image cropped to square with offset: $_imageOffset");
        }
      }

      await context.read<CrowdCubit>().createCrowdPost(
            text: _captionController.text,
            imageBytes: finalBytes, // 🔥 Upload cropped image
            target: targetValue,
            uId: user.uid,
            uName: user.username,
            customFileName: fileName,
          );

      if (mounted) Navigator.pop(context);
    } catch (e) {
      debugPrint("Upload error: $e");
      _stopLoading("Upload failed. Try again.");
    }
  }

  void _stopLoading(String message) {
    setState(() => _isUploading = false);
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  // ===============================
  // 🖥 UI
  // ===============================
  @override
  Widget build(BuildContext context) {
    final user = context.read<AuthCubit>().currentUser;
    final isAdmin = user?.isAdmin ?? false;

    return Stack(
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("New Post"),
            actions: [
              IconButton(
                icon: const Icon(Icons.done),
                onPressed: _isUploading ? null : _upload,
              ),
            ],
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              children: [
                // ✅ DRAGGABLE PREVIEW WITH CROP INFO
                if (_selectedMediaBytes != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Icon(Icons.crop_square, size: 16, color: Colors.grey.shade600),
                            const SizedBox(width: 6),
                            Text(
                              "Preview (Drag to adjust crop)",
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey.shade700,
                              ),
                            ),
                          ],
                        ),
                      ),
                      _isFileTypeVideo
                          ? Container(
                              width: double.infinity,
                              height: MediaQuery.of(context).size.width,
                              margin: const EdgeInsets.only(bottom: 20),
                              decoration: const BoxDecoration(
                                color: Colors.black,
                              ),
                              child: const Center(
                                child: Icon(Icons.videocam,
                                    color: Colors.white, size: 50),
                              ),
                            )
                          : _DraggableImagePreview(
                              imageBytes: _selectedMediaBytes!,
                              width: MediaQuery.of(context).size.width,
                              initialOffset: _imageOffset,
                              onOffsetChanged: (offset) {
                                setState(() {
                                  _imageOffset = offset;
                                });
                              },
                            ),
                    ],
                  ),

                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickMedia(false),
                        child: _pickerTile(
                          icon: Icons.image,
                          label: "Pick Image",
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _pickMedia(true),
                        child: _pickerTile(
                          icon: Icons.videocam,
                          label: "Pick Video",
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),

                // ADMIN-ONLY DONATION TOGGLE
                if (isAdmin)
                  SwitchListTile(
                    title: const Text(
                      "Post for Donation?",
                      style: TextStyle(fontWeight: FontWeight.bold),
                    ),
                    value: _isDonationPost,
                    onChanged: _isUploading
                        ? null
                        : (v) => setState(() => _isDonationPost = v),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.grey.shade600),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            "Donation posts are only available for Admin users",
                            style: TextStyle(
                              color: Colors.grey.shade700,
                              fontSize: 14,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                if (_isDonationPost && isAdmin) ...[
                  const SizedBox(height: 15),
                  TextField(
                    controller: _targetController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                      labelText: "Target Amount (₹)",
                      prefixIcon: Icon(Icons.currency_rupee),
                    ),
                  ),
                ],

                const SizedBox(height: 15),

                TextField(
                  controller: _captionController,
                  maxLines: 3,
                  decoration: const InputDecoration(
                    labelText: "Caption / Description",
                  ),
                ),
              ],
            ),
          ),
        ),

        if (_isUploading)
          Container(
            color: Colors.black.withOpacity(0.35),
            child: const Center(
              child: CircularProgressIndicator(strokeWidth: 3),
            ),
          ),
      ],
    );
  }

  Widget _pickerTile({required IconData icon, required String label}) {
    return Container(
      height: 120,
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 40),
          const SizedBox(height: 8),
          Text(label),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _captionController.dispose();
    _targetController.dispose();
    super.dispose();
  }
}

// ===============================
// 🎨 DRAGGABLE IMAGE PREVIEW
// ===============================
class _DraggableImagePreview extends StatefulWidget {
  final Uint8List imageBytes;
  final double width;
  final Offset initialOffset;
  final ValueChanged<Offset> onOffsetChanged;

  const _DraggableImagePreview({
    required this.imageBytes,
    required this.width,
    required this.initialOffset,
    required this.onOffsetChanged,
  });

  @override
  State<_DraggableImagePreview> createState() => _DraggableImagePreviewState();
}

class _DraggableImagePreviewState extends State<_DraggableImagePreview> {
  late Offset _imageOffset;
  Size? _imageSize;

  @override
  void initState() {
    super.initState();
    _imageOffset = widget.initialOffset;
    _loadImageSize();
  }

  // Get actual image dimensions
  Future<void> _loadImageSize() async {
    final image = await decodeImageFromList(widget.imageBytes);
    if (mounted) {
      setState(() {
        _imageSize = Size(image.width.toDouble(), image.height.toDouble());
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.width;

    return Container(
      width: size,
      height: size,
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: Colors.black,
        border: Border.all(color: Colors.grey.shade400, width: 2),
      ),
      child: Stack(
        children: [
          // Image with constrained dragging
          ClipRect(
            child: GestureDetector(
              onPanUpdate: (details) {
                setState(() {
                  Offset newOffset = _imageOffset + details.delta;
                  
                  // 🔥 CONSTRAIN THE OFFSET to prevent black areas
                  if (_imageSize != null) {
                    // Calculate max drag limits based on image aspect ratio
                    final imageAspect = _imageSize!.width / _imageSize!.height;
                    
                    if (imageAspect > 1) {
                      // Wide image - can drag horizontally
                      final maxX = (size * (imageAspect - 1)) / 2;
                      newOffset = Offset(
                        newOffset.dx.clamp(-maxX, maxX),
                        0, // No vertical drag for wide images
                      );
                    } else {
                      // Tall image - can drag vertically
                      final maxY = (size * (1 / imageAspect - 1)) / 2;
                      newOffset = Offset(
                        0, // No horizontal drag for tall images
                        newOffset.dy.clamp(-maxY, maxY),
                      );
                    }
                  }
                  
                  _imageOffset = newOffset;
                });
                widget.onOffsetChanged(_imageOffset);
              },
              child: Transform.translate(
                offset: _imageOffset,
                child: Image.memory(
                  widget.imageBytes,
                  fit: BoxFit.cover,
                  width: size,
                  height: size,
                ),
              ),
            ),
          ),

          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.bottomCenter,
                  end: Alignment.topCenter,
                  colors: [
                    Colors.black.withOpacity(0.7),
                    Colors.transparent,
                  ],
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.pan_tool,
                    color: Colors.white.withOpacity(0.9),
                    size: 16,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "Drag to adjust crop area",
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          ),

          if (_imageOffset != Offset.zero)
            Positioned(
              top: 8,
              right: 8,
              child: GestureDetector(
                onTap: () {
                  setState(() {
                    _imageOffset = Offset.zero;
                  });
                  widget.onOffsetChanged(Offset.zero);
                },
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.black.withOpacity(0.6),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.refresh,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

