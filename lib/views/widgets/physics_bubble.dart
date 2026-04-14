import 'package:flutter/material.dart';

class PhysicsBubble extends StatefulWidget {
  final Widget child;

  const PhysicsBubble({super.key, required this.child});

  @override
  State<PhysicsBubble> createState() => _PhysicsBubbleState();
}

class _PhysicsBubbleState extends State<PhysicsBubble>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;
  late Animation<double> scale;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 500),
    );

    scale = CurvedAnimation(
      parent: controller,
      curve: Curves.elasticOut, // 🔥 حركة نابضة
    );

    controller.forward();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: scale,
      child: widget.child,
    );
  }
}