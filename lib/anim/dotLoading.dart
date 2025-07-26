import 'package:flutter/material.dart';

class DotLoading extends StatefulWidget {
  final Color dotColor;
  final double dotSize;

  const DotLoading({
    Key? key,
    this.dotColor = const Color(0xFF1A3D63),
    this.dotSize = 12.0,
  }) : super(key: key);

  @override
  _DotLoadingState createState() => _DotLoadingState();
}

class _DotLoadingState extends State<DotLoading> with SingleTickerProviderStateMixin {
  late AnimationController _loadingController;
  late Animation<double> _dot1Animation;
  late Animation<double> _dot2Animation;
  late Animation<double> _dot3Animation;

  @override
  void initState() {
    super.initState();
    _loadingController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat();

    _dot1Animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.0, 0.3, curve: Curves.easeInOut),
      ),
    );

    _dot2Animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.2, 0.5, curve: Curves.easeInOut),
      ),
    );

    _dot3Animation = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _loadingController,
        curve: const Interval(0.4, 0.7, curve: Curves.easeInOut),
      ),
    );
  }

  @override
  void dispose() {
    _loadingController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ScaleTransition(
            scale: _dot1Animation,
            child: Container(
              width: widget.dotSize,
              height: widget.dotSize,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: widget.dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          ScaleTransition(
            scale: _dot2Animation,
            child: Container(
              width: widget.dotSize,
              height: widget.dotSize,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: widget.dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
          ScaleTransition(
            scale: _dot3Animation,
            child: Container(
              width: widget.dotSize,
              height: widget.dotSize,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: widget.dotColor,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ],
      ),
    );
  }
}