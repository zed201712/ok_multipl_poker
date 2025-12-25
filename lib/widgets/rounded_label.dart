import 'package:flutter/material.dart';

class RoundedLabel extends StatelessWidget {
  final String title;

  const RoundedLabel({super.key, required this.title});

  @override
  Widget build(BuildContext context) {
    return Chip(
      label: Text(title),
      backgroundColor: Colors.orange.withOpacity(0.2),
      shape: StadiumBorder(
        side: BorderSide(color: Colors.orange),
      ),
    )
    ;
  }
}