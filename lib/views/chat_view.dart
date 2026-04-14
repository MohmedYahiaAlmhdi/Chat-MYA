import 'dart:io';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';

import '../controllers/chat_controller.dart';
import '../services/voice_service.dart';
import 'widgets/input_field.dart';
import 'widgets/message_bubble.dart';
import 'widgets/typing_indicator.dart';

class ChatView extends StatefulWidget {
  const ChatView({super.key});

  @override
  State<ChatView> createState() => _ChatViewState();
}

class _ChatViewState extends State<ChatView> {
  final ChatController controller = Get.put(ChatController());
  final TextEditingController textController = TextEditingController();
  final ScrollController scrollController = ScrollController();

  // --- Functions (Logic) ---

  void scrollToBottom() {
    if (!scrollController.hasClients) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollController.animateTo(
        scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 500),
        curve: Curves.elasticOut,
      );
    });
  }

  Future<void> handleVoice() async {
    final voice = VoiceService();
    String? text = await voice.listen();
    if (text != null && text.trim().isNotEmpty) {
      controller.sendMessage(text);
    }
  }

  Future<void> handleImage() async {
    final picker = ImagePicker();
    final file = await picker.pickImage(source: ImageSource.gallery);
    if (file != null) {
      controller.sendImage(File(file.path));
    }
  }

  void handleSend() {
    final text = textController.text.trim();
    if (text.isEmpty) return;
    controller.sendMessage(text);
    textController.clear();
  }

  @override
  void dispose() {
    textController.dispose();
    scrollController.dispose();
    super.dispose();
  }

  // --- UI Sections (Widgets) ---

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: const Color(0xFF02050A),
      drawer: _buildDrawer(), // ✅ إضافة الـ Drawer هنا
      appBar: _buildAppBar(),
      body: Stack(
        children: [
          _buildBackgroundGlow(),
          SafeArea(
            child: Column(
              children: [
                _buildMessagesList(),
                _buildTypingIndicator(),
                _buildInputArea(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // 1. AppBar المطور بتأثير الزجاج
  PreferredSizeWidget _buildAppBar() {
    return PreferredSize(
      preferredSize: const Size.fromHeight(70),
      child: ClipRRect(
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
          child: AppBar(
            backgroundColor: Colors.white.withValues(alpha: 0.05),
            elevation: 0,
            leading: Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu_rounded, color: Colors.white),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
            title: Column(
              children: [
                const Text(
                  "Chat MYA",
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 1.2,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 4),
                _buildStatusIndicator(),
              ],
            ),
            centerTitle: true,
          ),
        ),
      ),
    );
  }

  // 2. مؤشر الحالة (Online)
  Widget _buildStatusIndicator() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: Colors.greenAccent,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 5),
        const Text(
          "Online",
          style: TextStyle(fontSize: 12, color: Colors.greenAccent),
        ),
      ],
    );
  }

  // 3. زر حذف المحادثة
  Widget _buildDeleteButton() {
    return Container(
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        shape: BoxShape.circle,
      ),
      child: IconButton(
        icon: const Icon(Icons.delete_sweep_rounded, color: Colors.redAccent),
        onPressed: () => _showDeleteDialog(),
      ),
    );
  }

  // 4. الخلفية المشعة (Glow Background)
  Widget _buildBackgroundGlow() {
    return Positioned(
      top: -100,
      right: -100,
      child: Container(
        width: 300,
        height: 300,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: Colors.blueAccent.withValues(alpha: 0.15),
        ),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 50, sigmaY: 50),
          child: Container(),
        ),
      ),
    );
  }

  // 5. قائمة الرسائل (ListView)
  Widget _buildMessagesList() {
    return Expanded(
      child: Obx(() {
        // التمرير للأسفل عند إضافة رسالة جديدة
        WidgetsBinding.instance.addPostFrameCallback((_) => scrollToBottom());

        return ListView.builder(
          controller: scrollController,
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 10),
          itemCount: controller.messages.length,
          itemBuilder: (context, index) {
            final msg = controller.messages[index];
            final isUser = msg["role"] == "user";

            return MessageBubble(text: msg["content"] ?? "", isUser: isUser);
          },
        );
      }),
    );
  }

  // 6. مؤشر جاري الكتابة
  Widget _buildTypingIndicator() {
    return Obx(() {
      if (!controller.isLoading.value) return const SizedBox.shrink();
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        alignment: Alignment.centerLeft,
        child: const TypingIndicator(),
      );
    });
  }

  // 7. منطقة إدخال النص والملحقات
  Widget _buildInputArea() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFF0B1220),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: ChatInputField(
        controller: textController,
        onSend: handleSend,
        onVoice: handleVoice,
        onImage: handleImage,
      ),
    );
  }

  // 8. نافذة تأكيد الحذف
  void _showDeleteDialog() {
    Get.defaultDialog(
      title: "مسح المحادثة",
      middleText: "هل أنت متأكد من مسح جميع الرسائل؟",
      backgroundColor: const Color(0xFF151B29),
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      textConfirm: "نعم",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.clearAllData();
        Get.back();
      },
    );
  }

  // ✅ الـ Drawer الجانبي لعرض المحادثات السابقة
  // 🌀 الـ Drawer الجانبي بقائمة المحادثات وسلة الحذف الأسطورية
  Widget _buildDrawer() {
    return Drawer(
      backgroundColor: const Color(0xFF0B1220),
      child: SafeArea(
        child: Column(
          children: [
            // رأس القائمة
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    Colors.blueAccent.withValues(alpha: 0.2),
                    Colors.purpleAccent.withValues(alpha: 0.05),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                border: Border(
                  bottom: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.chat_bubble_rounded,
                    color: Colors.blueAccent,
                    size: 28,
                  ),
                  const SizedBox(width: 12),
                  const Text(
                    "محادثاتي",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  // زر محادثة جديدة مع تأثير نبض
                  GestureDetector(
                    onTap: () {
                      controller.createNewChat();
                      Get.back();
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: Colors.blueAccent.withValues(alpha: 0.2),
                        border: Border.all(
                          color: Colors.blueAccent.withValues(alpha: 0.5),
                          width: 1.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.add_comment_rounded,
                        color: Colors.blueAccent,
                        size: 24,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // قائمة المحادثات القابلة للحذف
            Expanded(
              child: Obx(() {
                if (controller.allChats.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.chat_bubble_outline,
                          size: 60,
                          color: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          "لا توجد محادثات",
                          style: TextStyle(
                            color: Colors.white.withValues(alpha: 0.5),
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 8),
                        TextButton.icon(
                          onPressed: () {
                            controller.createNewChat();
                            Get.back();
                          },
                          icon: const Icon(Icons.add),
                          label: const Text("ابدأ محادثة جديدة"),
                          style: TextButton.styleFrom(
                            foregroundColor: Colors.blueAccent,
                          ),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  itemCount: controller.allChats.keys.length,
                  itemBuilder: (context, index) {
                    String id = controller.allChats.keys.elementAt(index);
                    var chat = controller.allChats[id];
                    bool isSelected = id == controller.currentChatId.value;
                    String title = chat?['title'] ?? "محادثة ${index + 1}";

                    return Dismissible(
                      key: Key(id),
                      direction: DismissDirection.endToStart,
                      background: Container(
                        alignment: Alignment.centerRight,
                        padding: const EdgeInsets.only(right: 20),
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.redAccent.withValues(alpha: 0.8),
                              Colors.deepOrangeAccent.withValues(alpha: 0.8),
                            ],
                          ),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(
                          Icons.delete_forever_rounded,
                          color: Colors.white,
                          size: 30,
                        ),
                      ),
                      onDismissed: (direction) {
                        // حذف المحادثة مباشرة بعد السحب
                        controller.deleteChat(id);
                        Get.snackbar(
                          "تم الحذف",
                          "تم نقل المحادثة إلى سلة المهملات",
                          snackPosition: SnackPosition.BOTTOM,
                          backgroundColor: Colors.redAccent.withValues(
                            alpha: 0.8,
                          ),
                          colorText: Colors.white,
                          duration: const Duration(seconds: 2),
                        );
                      },
                      child: Container(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          gradient: isSelected
                              ? LinearGradient(
                                  colors: [
                                    Colors.blueAccent.withValues(alpha: 0.15),
                                    Colors.purpleAccent.withValues(alpha: 0.05),
                                  ],
                                )
                              : null,
                          borderRadius: BorderRadius.circular(16),
                          border: isSelected
                              ? Border.all(
                                  color: Colors.blueAccent.withValues(
                                    alpha: 0.5,
                                  ),
                                  width: 1.5,
                                )
                              : null,
                        ),
                        child: ListTile(
                          leading: AnimatedContainer(
                            duration: const Duration(milliseconds: 300),
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected
                                  ? Colors.blueAccent.withValues(alpha: 0.2)
                                  : Colors.white.withValues(alpha: 0.05),
                            ),
                            child: Icon(
                              isSelected
                                  ? Icons.chat_bubble
                                  : Icons.chat_bubble_outline,
                              color: isSelected
                                  ? Colors.blueAccent
                                  : Colors.white70,
                              size: 22,
                            ),
                          ),
                          title: Text(
                            title,
                            style: TextStyle(
                              color: isSelected
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.8),
                              fontWeight: isSelected
                                  ? FontWeight.bold
                                  : FontWeight.normal,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          subtitle: Text(
                            "آخر تحديث: ${_getFormattedTime(chat)}",
                            style: TextStyle(
                              color: Colors.white.withValues(alpha: 0.4),
                              fontSize: 11,
                            ),
                          ),
                          trailing: AnimatedOpacity(
                            opacity: isSelected ? 0.0 : 1.0,
                            duration: const Duration(milliseconds: 200),
                            child: IconButton(
                              icon: const Icon(
                                Icons.delete_outline_rounded,
                                color: Colors.redAccent,
                                size: 22,
                              ),
                              onPressed: () => _confirmDeleteChat(id, title),
                              splashRadius: 20,
                              tooltip: "حذف المحادثة",
                            ),
                          ),
                          onTap: () {
                            controller.switchChat(id);
                            Get.back();
                          },
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 4,
                          ),
                        ),
                      ),
                    );
                  },
                );
              }),
            ),

            // تذييل القائمة - مسح جميع المحادثات
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(
                    color: Colors.white.withValues(alpha: 0.1),
                    width: 1,
                  ),
                ),
              ),
              child: GestureDetector(
                onTap: () => _confirmClearAllChats(),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [Colors.redAccent, Colors.deepOrangeAccent],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                    ),
                    borderRadius: BorderRadius.circular(18),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.redAccent.withValues(alpha: 0.5),
                        blurRadius: 20,
                        spreadRadius: 1,
                      ),
                    ],
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.delete_sweep_rounded,
                        color: Colors.white,
                        size: 30,
                      ),
                      SizedBox(width: 12),
                      Text(
                        "مسح جميع المحادثات",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // دالة مساعدة لتنسيق الوقت (اختيارية)
  String _getFormattedTime(dynamic chat) {
    // يمكنك إضافة حقل timestamp في المحادثة عند التعديل
    // هنا نعرض فقط مؤشراً
    return "الآن";
  }

  // تأكيد حذف محادثة محددة
  void _confirmDeleteChat(String chatId, String title) {
    Get.defaultDialog(
      title: "حذف المحادثة",
      middleText: "هل أنت متأكد من حذف \"$title\"؟",
      backgroundColor: const Color(0xFF151B29),
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      textConfirm: "حذف",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.deleteChat(chatId);
        Get.back();
        Get.snackbar(
          "تم الحذف",
          "تم حذف المحادثة بنجاح",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
  }

  // تأكيد مسح جميع المحادثات
  void _confirmClearAllChats() {
    Get.defaultDialog(
      title: "مسح الكل",
      middleText: "سيتم حذف جميع المحادثات نهائياً. هل أنت متأكد؟",
      backgroundColor: const Color(0xFF151B29),
      titleStyle: const TextStyle(color: Colors.white),
      middleTextStyle: const TextStyle(color: Colors.white70),
      textConfirm: "مسح الكل",
      textCancel: "إلغاء",
      confirmTextColor: Colors.white,
      buttonColor: Colors.redAccent,
      onConfirm: () {
        controller.clearAllData();
        Get.back();
        Get.snackbar(
          "تم المسح",
          "تم حذف جميع المحادثات",
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: Colors.redAccent.withValues(alpha: 0.8),
          colorText: Colors.white,
        );
      },
    );
  }
}
