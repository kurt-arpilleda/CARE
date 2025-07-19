import 'package:flutter/material.dart';

class ShimmerProfile extends StatefulWidget {
  const ShimmerProfile({Key? key}) : super(key: key);

  @override
  _ShimmerProfileState createState() => _ShimmerProfileState();
}

class _ShimmerProfileState extends State<ShimmerProfile>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    )..repeat();

    _animation = Tween<double>(
      begin: -1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOutSine,
    ));
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Widget _buildShimmerElement({
    required double width,
    required double height,
    double borderRadius = 8.0,
    bool isCircular = false,
    EdgeInsets? margin,
  }) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: const [
                Colors.transparent,
                Colors.white,
                Colors.transparent,
              ],
              stops: [
                (_animation.value - 0.3).clamp(0.0, 1.0),
                _animation.value.clamp(0.0, 1.0),
                (_animation.value + 0.3).clamp(0.0, 1.0),
              ],
            ).createShader(bounds);
          },
          child: Container(
            width: width,
            height: height,
            margin: margin,
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.8),
              borderRadius: isCircular ? null : BorderRadius.circular(borderRadius),
              shape: isCircular ? BoxShape.circle : BoxShape.rectangle,
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return UserAccountsDrawerHeader(
      decoration: const BoxDecoration(color: Color(0xFF1A3D63)),
      accountName: _buildShimmerElement(
        width: 120,
        height: 16,
        borderRadius: 8,
      ),
      accountEmail: _buildShimmerElement(
        width: 160,
        height: 14,
        borderRadius: 7,
        margin: const EdgeInsets.only(top: 4),
      ),
      currentAccountPicture: _buildShimmerElement(
        width: 72,
        height: 72,
        isCircular: true,
      ),
    );
  }
}