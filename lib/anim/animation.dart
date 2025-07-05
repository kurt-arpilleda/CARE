import 'package:flutter/material.dart';

class FadeSlideTransition extends StatelessWidget {
  final Animation<Offset> position;
  final Animation<double> opacity;
  final Widget child;

  const FadeSlideTransition({
    Key? key,
    required this.position,
    required this.opacity,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return SlideTransition(
      position: position,
      child: FadeTransition(
        opacity: opacity,
        child: child,
      ),
    );
  }
}
