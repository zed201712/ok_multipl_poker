import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/widgets/rounded_label.dart';

class CardContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final Color _color;
  final EdgeInsets _padding;
  final BorderRadius _borderRadius;

  CardContainer({
    super.key,
    this.title = '',
    required this.child,
    Color? color,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  })  : _color = color ?? Colors.black.withValues(alpha: 0.1),
        _padding = padding ?? const EdgeInsets.all(8.0),
        _borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    return Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: _borderRadius,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // 上一次出的牌 (Last Played Hand) - 顯示在上方或顯眼處
            if (title.isNotEmpty) ...[
              RoundedLabel(title: title),
              //const SizedBox(height: 20),
            ],
            child,
          ],
        )
    );
  }
}