import 'package:flutter/material.dart';

/// A reusable skeleton loader component with shimmer animation
class SkeletonLoader extends StatefulWidget {
  final Widget child;
  final bool isLoading;
  final Duration shimmerDuration;

  const SkeletonLoader({
    super.key,
    required this.child,
    required this.isLoading,
    this.shimmerDuration = const Duration(milliseconds: 1200),
  });

  @override
  State<SkeletonLoader> createState() => _SkeletonLoaderState();
}

class _SkeletonLoaderState extends State<SkeletonLoader>
    with TickerProviderStateMixin {
  late AnimationController _shimmerController;

  @override
  void initState() {
    super.initState();
    _shimmerController = AnimationController.unbounded(vsync: this)
      ..repeat(min: -0.5, max: 1.5, period: widget.shimmerDuration);
  }

  @override
  void dispose() {
    _shimmerController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.isLoading) {
      return widget.child;
    }

    return AnimatedBuilder(
      animation: _shimmerController,
      builder: (context, child) {
        final gradient = LinearGradient(
          colors: const [Color(0xFF1E1E1E), Color(0xFF2C2C2C), Color(0xFF1E1E1E)],
          stops: const [0.4, 0.5, 0.6],
          begin: const Alignment(-1.0, -0.3),
          end: const Alignment(1.0, 0.3),
          transform: _SlidingGradientTransform(slidePercent: _shimmerController.value),
        );
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => gradient.createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// Common skeleton shapes that can be reused across views
class SkeletonShapes {
  static Widget text({
    double? width,
    double height = 16,
    BorderRadius borderRadius = const BorderRadius.all(Radius.circular(4)),
  }) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: borderRadius,
      ),
    );
  }

  static Widget avatar({double radius = 20}) {
    return Container(
      width: radius * 2,
      height: radius * 2,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
      ),
    );
  }

  static Widget card({double? height, EdgeInsets padding = const EdgeInsets.all(16)}) {
    return Container(
      height: height,
      padding: padding,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
    );
  }

  static Widget listTile() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          SkeletonShapes.avatar(radius: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SkeletonShapes.text(width: double.infinity, height: 16),
                const SizedBox(height: 8),
                SkeletonShapes.text(width: 100, height: 12),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Sliding gradient transform for shimmer effect
class _SlidingGradientTransform extends GradientTransform {
  const _SlidingGradientTransform({
    required this.slidePercent,
  });

  final double slidePercent;

  @override
  Matrix4? transform(Rect bounds, {TextDirection? textDirection}) {
    return Matrix4.translationValues(bounds.width * slidePercent, 0.0, 0.0);
  }
}
