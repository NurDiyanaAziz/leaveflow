import 'package:flutter/material.dart';

class ImageViewerScreen extends StatelessWidget {
  final String url;
  final String fileName;

  const ImageViewerScreen({super.key, required this.url, required this.fileName});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black, // Dark background looks professional for media
      appBar: AppBar(
        title: Text(fileName, style: const TextStyle(fontSize: 16)),
        backgroundColor: Colors.black,
        foregroundColor: Colors.white,
      ),
      body: Center(
        // InteractiveViewer enables Pinch-to-Zoom
        child: InteractiveViewer(
          panEnabled: true, // Allow moving around
          minScale: 0.5,
          maxScale: 4.0,    // Allow zooming in 4x
          child: Image.network(
            url,
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const CircularProgressIndicator(color: Colors.white);
            },
            errorBuilder: (context, error, stackTrace) => 
                const Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.broken_image, color: Colors.white, size: 50),
                    Text("Could not load image", style: TextStyle(color: Colors.white)),
                  ],
                ),
          ),
        ),
      ),
    );
  }
}