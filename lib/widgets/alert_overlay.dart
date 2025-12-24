import 'package:flutter/material.dart';

class AlertOverlay extends StatelessWidget {
  final Widget child;
  final VoidCallback onTap;

  const AlertOverlay({
    super.key,
    required this.child,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Container(
          color: Colors.black.withOpacity(0.4),
          alignment: Alignment.center,
          child: child,
        ),
      ),
    );
  }
}

// Sample
//
// class DemoPage extends StatefulWidget {
//   const DemoPage({super.key});
//
//   @override
//   State<DemoPage> createState() => _DemoPageState();
// }
//
// class _DemoPageState extends State<DemoPage> {
//   bool showAlert = false;
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       body: Stack(
//         children: [
//           Center(
//             child: ElevatedButton(
//               onPressed: () {
//                 setState(() => showAlert = true);
//               },
//               child: const Text('Show Alert'),
//             ),
//           ),
//
//           if (showAlert)
//             AlertOverlay(
//               onClose: () {
//                 setState(() => showAlert = false);
//               },
//               child: _AlertContent(),
//             ),
//         ],
//       ),
//     );
//   }
// }
