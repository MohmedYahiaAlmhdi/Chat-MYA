import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../controllers/chat_controller.dart';

class ChatDrawer extends StatelessWidget {
  const ChatDrawer({super.key});

  @override
  Widget build(BuildContext context) {
    final ChatController controller = Get.find();

    return Drawer(
      backgroundColor: const Color(0xFF0B1220),
      child: Column(
        children: [
          _buildHeader(controller),
          Expanded(child: _buildChatList(controller)),
          _buildFooter(),
        ],
      ),
    );
  }

  Widget _buildHeader(ChatController controller) {
    return DrawerHeader(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          ElevatedButton.icon(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF4F46E5),
              minimumSize: const Size(double.infinity, 50),
            ),
            onPressed: () => controller.createNewChat(),
            icon: const Icon(Icons.add, color: Colors.white),
            label: const Text(
              "محادثة جديدة",
              style: TextStyle(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChatList(ChatController controller) {
    return Obx(
      () => ListView.builder(
        itemCount: controller.allChats.length,
        itemBuilder: (context, index) {
          String id = controller.allChats.keys.elementAt(index);
          String title = controller.allChats[id]["title"];
          bool isSelected = id == controller.currentChatId.value;

          return ListTile(
            selected: isSelected,
            selectedTileColor: Colors.white.withValues(alpha: 0.05),
            leading: Icon(
              Icons.chat_bubble_outline,
              color: isSelected ? Colors.blueAccent : Colors.white60,
            ),
            title: Text(
              title,
              style: TextStyle(
                color: isSelected ? Colors.blueAccent : Colors.white,
                fontSize: 14,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            onTap: () => controller.switchChat(id),
          );
        },
      ),
    );
  }

  Widget _buildFooter() {
    return const Padding(
      padding: EdgeInsets.all(16.0),
      child: Text(
        "AI Assistant v1.0",
        style: TextStyle(color: Colors.white24, fontSize: 10),
      ),
    );
  }
}
