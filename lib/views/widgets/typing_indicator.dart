import 'package:flutter/material.dart';

class TypingIndicator extends StatefulWidget {
  const TypingIndicator({super.key});

  @override
  State<TypingIndicator> createState() => _TypingIndicatorState();
}

class _TypingIndicatorState extends State<TypingIndicator>
    with SingleTickerProviderStateMixin {
  late AnimationController controller;

  @override
  void initState() {
    super.initState();

    controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    controller.dispose(); // ✅ تنظيف الذاكرة
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height:
          24, // ✅ تم زيادة الارتفاع قليلاً لاستيعاب حركة القفز (bounce) بدون قص
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: List.generate(3, (i) {
          return AnimatedBuilder(
            animation: controller,
            builder: (_, __) {
              final double value = ((controller.value + i * 0.2) % 1.0);

              /// 🔥 حركة ناعمة (curve)
              final double animationValue = Curves.easeInOut.transform(value);

              /// ✅ opacity آمن (0 → 1)
              final double opacity = (0.3 + animationValue * 0.7).clamp(
                0.0,
                1.0,
              );

              /// 🔥 bounce خفيف
              final double translateY = -animationValue * 6;

              return Transform.translate(
                offset: Offset(0, translateY),
                child: Opacity(
                  opacity: opacity,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 3),
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(
                      color:
                          Colors.white, // يمكنك تغيير اللون حسب تصميم التطبيق
                      shape: BoxShape.circle,
                    ),
                  ),
                ),
              );
            },
          );
        }),
      ),
    );
  }
}
