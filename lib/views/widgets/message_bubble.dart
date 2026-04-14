import 'package:flutter/material.dart';
import 'package:flutter/services.dart'; // لعمل النسخ (Clipboard)
import 'package:flutter_markdown/flutter_markdown.dart'; // لعرض الأكواد والنصوص المنسقة

class MessageBubble extends StatelessWidget {
  final String text;
  final bool isUser;

  const MessageBubble({super.key, required this.text, required this.isUser});

  @override
  Widget build(BuildContext context) {
    // 🎭 أنيميشن الانزلاق والظهور (TweenAnimationBuilder)
    return TweenAnimationBuilder(
      duration: const Duration(milliseconds: 600),
      // Curves.elasticOut يعطي حركة فيزيائية مرنة (Bounce)
      curve: Curves.elasticOut,
      tween: Tween<double>(begin: 0.0, end: 1.0),
      builder: (context, double value, child) {
        return Opacity(
          opacity: value.clamp(0.0, 1.0),
          child: Transform.translate(
            // حركة جانبية خفيفة تأتي من اليمين للمستخدم ومن اليسار للبوت
            offset: Offset(isUser ? (1 - value) * 40 : (value - 1) * 40, 0),
            child: child,
          ),
        );
      },
      child: GestureDetector(
        // نسخ النص عند النقر المطول
        onLongPress: () {
          Clipboard.setData(ClipboardData(text: text));
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text("تم نسخ النص إلى الحافظة"),
              duration: Duration(seconds: 1),
            ),
          );
        },
        child: Align(
          alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
            padding: const EdgeInsets.all(14),
            constraints: BoxConstraints(
              maxWidth:
                  MediaQuery.of(context).size.width *
                  0.75, // تحديد العرض بـ 75% من الشاشة
            ),
            decoration: BoxDecoration(
              // 🎨 تدرج لوني احترافي
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isUser
                    ? [
                        const Color(0xFF4F46E5),
                        const Color(0xFF3B82F6),
                      ] // لون المستخدم (أزرق متوهج)
                    : [
                        const Color(0xFF1E293B),
                        const Color(0xFF0F172A),
                      ], // لون البوت (داكن فخم)
              ),
              borderRadius: BorderRadius.only(
                topLeft: const Radius.circular(20),
                topRight: const Radius.circular(20),
                bottomLeft: Radius.circular(isUser ? 20 : 0),
                bottomRight: Radius.circular(isUser ? 0 : 20),
              ),
              // ✨ توهج خفيف لرسالة المستخدم (Glow)
              boxShadow: [
                BoxShadow(
                  color: isUser
                      ? Colors.blueAccent.withValues(alpha: 0.3)
                      : Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            // 📝 دعم الـ Markdown لعرض الأكواد والنتائج بشكل جميل
            child: isUser
                ? Text(
                    text,
                    style: const TextStyle(color: Colors.white, fontSize: 15),
                  )
                : MarkdownBody(
                    data: text,
                    selectable: true,
                    styleSheet: MarkdownStyleSheet(
                      p: const TextStyle(
                        color: Colors.white,
                        fontSize: 15,
                        height: 1.5,
                      ),
                      code: TextStyle(
                        backgroundColor: Colors.black.withValues(alpha: 0.4),
                        color: Colors.cyanAccent,
                        fontFamily: 'monospace',
                        fontSize: 13,
                      ),
                      codeblockDecoration: BoxDecoration(
                        color: Colors.black.withValues(alpha: 0.5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white10),
                      ),
                      h1: const TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                      listBullet: const TextStyle(color: Colors.white),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
