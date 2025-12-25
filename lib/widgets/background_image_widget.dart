import 'package:flutter/material.dart';

class BackgroundImageWidget extends StatelessWidget {
  final String imagePath;
  final Widget child;

  const BackgroundImageWidget({super.key, required this.imagePath, required this.child});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        Positioned.fill(
          child: Image.asset(
            imagePath,
            fit: BoxFit.cover,
          ),
        ),
        Positioned.fill(
          child: Container(
            color: Colors.black.withOpacity(0.3),
          ),
        ),
        Positioned.fill(
          child: child,
        ),
        // Center(
        //   child: Text(
        //     'Game Start',
        //     style: TextStyle(color: Colors.white, fontSize: 24),
        //   ),
        // ),
      ],
    );

  }
}