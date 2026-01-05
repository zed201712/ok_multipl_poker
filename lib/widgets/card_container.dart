import 'package:flutter/material.dart';
import 'package:ok_multipl_poker/widgets/rounded_label.dart';

enum TitlePosition { left, top, right, bottom }

class CardContainer extends StatelessWidget {
  final String title;
  final Widget child;
  final TitlePosition position;
  final Color _color;
  final EdgeInsets _padding;
  final BorderRadius _borderRadius;

  CardContainer({
    super.key,
    this.title = '',
    required this.child,
    this.position = TitlePosition.top,
    Color? color,
    EdgeInsets? padding,
    BorderRadius? borderRadius,
  })  : _color = color ?? Colors.black.withValues(alpha: 0.1),
        _padding = padding ?? const EdgeInsets.all(8.0),
        _borderRadius = borderRadius ?? const BorderRadius.all(Radius.circular(8));

  @override
  Widget build(BuildContext context) {
    Widget content = child;

    if (title.isNotEmpty) {
      switch (position) {
        case TitlePosition.top:
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RoundedLabel(title: title),
              const SizedBox(height: 6),
              child,
            ],
          );
          break;
        case TitlePosition.bottom:
          content = Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              child,
              const SizedBox(height: 6),
              RoundedLabel(title: title),
            ],
          );
          break;
        case TitlePosition.left:
          content = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              RoundedLabel(title: title),
              const SizedBox(width: 6),
              child,
            ],
          );
          break;
        case TitlePosition.right:
          content = Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              child,
              const SizedBox(width: 6),
              RoundedLabel(title: title),
            ],
          );
          break;
      }
    }

    return Container(
        padding: _padding,
        decoration: BoxDecoration(
          color: _color,
          borderRadius: _borderRadius,
        ),
        child: content
    );
  }
}
