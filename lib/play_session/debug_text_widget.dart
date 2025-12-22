import 'package:flutter/material.dart';

class DebugTextWidget extends StatefulWidget {
  final VoidCallback onGet;
  final Function(String) onSet;
  final TextEditingController controller;

  const DebugTextWidget({
    super.key,
    required this.onGet,
    required this.onSet,
    required this.controller,
  });

  @override
  State<DebugTextWidget> createState() => _DebugTextWidgetState();
}

class _DebugTextWidgetState extends State<DebugTextWidget> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      color: Colors.black.withOpacity(0.7),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('Debug State Editor', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          SizedBox(
            height: 150,
            child: TextField(
              controller: widget.controller,
              maxLines: null,
              expands: true,
              style: const TextStyle(color: Colors.white, fontSize: 12),
              decoration: const InputDecoration(
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              ElevatedButton(
                onPressed: widget.onGet,
                child: const Text('Get'),
              ),
              const SizedBox(width: 8),
              ElevatedButton(
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                onPressed: () => widget.onSet(widget.controller.text),
                child: const Text('Set'),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
