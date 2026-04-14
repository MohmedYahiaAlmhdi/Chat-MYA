import 'package:flutter/material.dart';

class ChatInputField extends StatefulWidget {
  final TextEditingController controller;
  final VoidCallback onSend;
  final VoidCallback onVoice;
  final VoidCallback onImage;

  const ChatInputField({
    super.key,
    required this.controller,
    required this.onSend,
    required this.onVoice,
    required this.onImage,
  });

  @override
  State<ChatInputField> createState() => _ChatInputFieldState();
}

class _ChatInputFieldState extends State<ChatInputField> {
  bool isTyping = false;

  @override
  void initState() {
    super.initState();

    widget.controller.addListener(() {
      final typingNow = widget.controller.text.trim().isNotEmpty;

      if (typingNow != isTyping) {
        setState(() {
          isTyping = typingNow;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xFF020617),
        boxShadow: [BoxShadow(color: Colors.black45, blurRadius: 10)],
      ),
      child: Row(
        children: [
          /// 🖼️ زر الصورة
          IconButton(
            icon: const Icon(Icons.image, color: Colors.grey),
            onPressed: widget.onImage,
          ),

          /// 🎤 زر الصوت
          IconButton(
            icon: const Icon(Icons.mic, color: Colors.grey),
            onPressed: widget.onVoice,
          ),

          /// ✍️ TextField
          Expanded(
            child: TextField(
              controller: widget.controller,
              style: const TextStyle(color: Colors.white),
              decoration: const InputDecoration(
                hintText: "اكتب رسالة...",
                hintStyle: TextStyle(color: Colors.grey),
                border: InputBorder.none,
              ),
            ),
          ),

          /// 🚀 زر الإرسال (Animated)
          AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            curve: Curves.easeInOut,
            margin: const EdgeInsets.only(left: 6),
            child: GestureDetector(
              onTap: isTyping ? widget.onSend : null,
              child: AnimatedScale(
                duration: const Duration(milliseconds: 200),
                scale: isTyping ? 1.0 : 0.8,
                child: Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    gradient: isTyping
                        ? const LinearGradient(
                            colors: [Color(0xFF2563EB), Color(0xFF1D4ED8)],
                          )
                        : null,
                    color: isTyping ? null : Colors.grey,
                    shape: BoxShape.circle,
                    boxShadow: isTyping
                        ? [
                            const BoxShadow(
                              color: Colors.black45,
                              blurRadius: 6,
                              offset: Offset(0, 3),
                            ),
                          ]
                        : [],
                  ),
                  child: const Icon(Icons.send, color: Colors.white),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
