import 'dart:async';

import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/services/error_message_service.dart';

class ErrorOverlayWidget extends StatefulWidget {
  final ErrorMessageService errorMessageService;

  const ErrorOverlayWidget({
    super.key,
    required this.errorMessageService,
  });

  @override
  State<ErrorOverlayWidget> createState() => _ErrorOverlayWidgetState();
}

class _ErrorOverlayWidgetState extends State<ErrorOverlayWidget> {
  final List<String> _errorMessages = [];
  StreamSubscription? _errorSubscription;

  @override
  void initState() {
    super.initState();
    _errorSubscription = widget.errorMessageService.errorStream.listen((message) {
      if (mounted) {
        setState(() {
          _errorMessages.add(message);
        });
      }
    });
  }

  @override
  void dispose() {
    _errorSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessages.isEmpty) {
      return const SizedBox.shrink();
    }

    return Positioned(
      top: 0,
      left: 0,
      width: 300,
      child: Material(
        color: Colors.transparent,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Padding(
              padding: const EdgeInsets.all(4.0),
              child: TextButton(
                onPressed: () => setState(() => _errorMessages.clear()),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black.withOpacity(0.7),
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                ),
                child: const Text(
                  'Clear Errors',
                  style: TextStyle(color: Colors.white),
                ),
              ),
            ),
            Container(
              constraints: const BoxConstraints(
                maxHeight: 200,
              ),
              child: ListView.builder(
                shrinkWrap: true,
                padding: EdgeInsets.zero,
                itemCount: _errorMessages.length,
                itemBuilder: (context, index) {
                  final message = _errorMessages[index];
                  return Container(
                    margin:
                        const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                    color: Colors.red.withOpacity(0.8),
                    child: ListTile(
                      dense: true,
                      title: Text(message,
                          style: const TextStyle(color: Colors.white)),
                      trailing: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () =>
                              setState(() => _errorMessages.removeAt(index))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
