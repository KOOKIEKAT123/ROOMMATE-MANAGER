import 'package:flutter/material.dart';

class FadeInUp extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const FadeInUp({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(0, 20 * (1 - value)),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class ScaleIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;

  const ScaleIn({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 400),
    this.curve = Curves.elasticOut,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class SlideIn extends StatelessWidget {
  final Widget child;
  final Duration duration;
  final Curve curve;
  final Offset beginOffset;

  const SlideIn({
    Key? key,
    required this.child,
    this.duration = const Duration(milliseconds: 500),
    this.curve = Curves.easeOut,
    this.beginOffset = const Offset(-0.5, 0),
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: duration,
      curve: curve,
      builder: (context, value, child) {
        return Transform.translate(
          offset: Offset(
            beginOffset.dx * 100 * (1 - value),
            beginOffset.dy * 100 * (1 - value),
          ),
          child: Opacity(
            opacity: value,
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}

class FloatingActionButton3DPress extends StatefulWidget {
  final Widget child;
  final VoidCallback onPressed;
  final Duration pressDuration;

  const FloatingActionButton3DPress({
    Key? key,
    required this.child,
    required this.onPressed,
    this.pressDuration = const Duration(milliseconds: 100),
  }) : super(key: key);

  @override
  State<FloatingActionButton3DPress> createState() =>
      _FloatingActionButton3DPressState();
}

class _FloatingActionButton3DPressState
    extends State<FloatingActionButton3DPress>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.pressDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1, end: 0.95).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        _controller.forward();
      },
      onTapUp: (_) {
        _controller.reverse();
        widget.onPressed();
      },
      onTapCancel: () {
        _controller.reverse();
      },
      child: ScaleTransition(
        scale: _scaleAnimation,
        child: widget.child,
      ),
    );
  }
}
