import 'package:flutter/material.dart';

class AnimatedBarChart extends StatefulWidget {
  final List<Map<String, dynamic>> data;
  final String xAxisKey;
  final String valueKey;
  final Color barColor;
  final Duration animationDuration;

  const AnimatedBarChart({
    super.key,
    required this.data,
    required this.xAxisKey,
    required this.valueKey,
    this.barColor = Colors.blue,
    this.animationDuration = const Duration(milliseconds: 800),
  });

  @override
  State<AnimatedBarChart> createState() => _AnimatedBarChartState();
}

class _AnimatedBarChartState extends State<AnimatedBarChart>
    with SingleTickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _animation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (widget.data.isEmpty) {
      return const Center(
        child: Text('No data available'),
      );
    }

    // Find the maximum value for scaling
    final maxValue = widget.data.fold<double>(
        0,
        (max, item) => max > (item[widget.valueKey] as num).toDouble()
            ? max
            : (item[widget.valueKey] as num).toDouble());

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return Column(
          children: [
            SizedBox(
              height: 200,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: List.generate(
                    widget.data.length,
                    (index) {
                      final item = widget.data[index];
                      final value = (item[widget.valueKey] as num).toDouble();
                      final label = item[widget.xAxisKey].toString();
                      final barHeight =
                          (value / maxValue) * 150 * _animation.value;

                      return _buildBar(
                        context,
                        label,
                        value.toString(),
                        barHeight,
                      );
                    },
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildBar(
    BuildContext context,
    String label,
    String value,
    double height,
  ) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Container(
          width: 30,
          height: height,
          decoration: BoxDecoration(
            color: widget.barColor,
            borderRadius: const BorderRadius.vertical(
              top: Radius.circular(8),
            ),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
