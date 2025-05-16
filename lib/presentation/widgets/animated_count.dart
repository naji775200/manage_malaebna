import 'package:flutter/material.dart';

class AnimatedCount extends StatefulWidget {
  final int count;
  final TextStyle? style;
  final Duration duration;
  final String? prefix;
  final String? suffix;

  const AnimatedCount({
    super.key,
    required this.count,
    this.style,
    this.duration = const Duration(milliseconds: 800),
    this.prefix,
    this.suffix,
  });

  @override
  State<AnimatedCount> createState() => _AnimatedCountState();
}

class _AnimatedCountState extends State<AnimatedCount>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;
  late int _oldCount;

  @override
  void initState() {
    super.initState();
    _oldCount = widget.count;
    _controller = AnimationController(
      vsync: this,
      duration: widget.duration,
    );
    _animation = CurvedAnimation(
      parent: _controller,
      curve: Curves.easeInOut,
    );
  }

  @override
  void didUpdateWidget(AnimatedCount oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.count != widget.count) {
      _oldCount = oldWidget.count;
      _controller.forward(from: 0.0);
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        final value =
            _oldCount + (_animation.value * (widget.count - _oldCount)).round();
        return Text(
          '${widget.prefix ?? ''}$value${widget.suffix ?? ''}',
          style: widget.style,
        );
      },
    );
  }
}
