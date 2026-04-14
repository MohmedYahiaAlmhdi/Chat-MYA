import 'dart:convert';
import 'dart:io';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class ChatController extends GetxController {
  var allChats = <String, dynamic>{}.obs;
  var currentChatId = "".obs;
  var messages = <Map<String, dynamic>>[].obs;
  var isLoading = false.obs;
  final box = GetStorage();
  final uuid = const Uuid();
  final String apiKey = dotenv.env['API_KEY'] ?? "";

  @override
  void onInit() {
    super.onInit();
    _loadAllChats();
  }

  void _loadAllChats() {
    Map<String, dynamic>? stored = box.read<Map<String, dynamic>>(
      'all_sessions',
    );
    if (stored != null) {
      allChats.assignAll(stored);
      if (allChats.isNotEmpty) {
        currentChatId.value = allChats.keys.first;
      } else {
        createNewChat();
      }
      _loadCurrentMessages();
    } else {
      createNewChat();
    }
  }

  void createNewChat() {
    String newId = uuid.v4();
    allChats[newId] = {
      "title": "محادثة جديدة",
      "messages": <Map<String, dynamic>>[],
    };
    currentChatId.value = newId;
    _loadCurrentMessages();
    _saveToDisk();
  }

  void switchChat(String chatId) {
    currentChatId.value = chatId;
    _loadCurrentMessages();
  }

  void _loadCurrentMessages() {
    var chatData = allChats[currentChatId.value];
    if (chatData != null) {
      List<dynamic> chatMessages = chatData["messages"];
      messages.assignAll(
        chatMessages.map((e) => Map<String, dynamic>.from(e)).toList(),
      );
    }
  }

  void _saveToDisk() {
    allChats[currentChatId.value]["messages"] = messages.toList();
    box.write('all_sessions', allChats);
  }

  Future<void> sendMessage(String message) async {
    if (message.trim().isEmpty) return;

    if (messages.isEmpty) {
      allChats[currentChatId.value]["title"] = message.length > 20
          ? "${message.substring(0, 20)}..."
          : message;
    }

    messages.add({"role": "user", "content": message});
    _saveToDisk();

    messages.add({"role": "assistant", "content": ""});
    int botIndex = messages.length - 1;
    isLoading.value = true;

    try {
      final request = http.Request(
        "POST",
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
      );

      request.headers.addAll({
        "Authorization": "Bearer $apiKey",
        "Content-Type": "application/json",
      });

      request.body = jsonEncode({
        "model": "openai/gpt-3.5-turbo",
        "stream": true,
        "messages": messages.sublist(0, messages.length - 1).map((m) {
          return {"role": m["role"], "content": m["content"]};
        }).toList(),
      });

      final response = await request.send();

      response.stream.transform(utf8.decoder).listen((chunk) {
        final lines = chunk.split("\n");
        for (var line in lines) {
          if (line.startsWith("data: ")) {
            final jsonStr = line.replaceFirst("data: ", "").trim();
            if (jsonStr == "[DONE]") {
              isLoading.value = false;
              _saveToDisk();
              return;
            }
            try {
              final data = jsonDecode(jsonStr);
              final delta = data["choices"]?[0]?["delta"];
              if (delta != null && delta["content"] != null) {
                messages[botIndex]["content"] += delta["content"];
                messages.refresh();
              }
            } catch (_) {}
          }
        }
      }, onDone: () => _saveToDisk());
    } catch (e) {
      messages[botIndex]["content"] = "⚠️ خطأ: $e";
      isLoading.value = false;
      _saveToDisk();
    }
  }

  Future<void> sendImage(File imageFile) async {
    isLoading.value = true;
    try {
      final bytes = await imageFile.readAsBytes();
      final base64Image = base64Encode(bytes);

      messages.add({"role": "user", "content": "[📷 صورة تم إرسالها]"});
      messages.add({"role": "assistant", "content": "🔍 جاري تحليل الصورة..."});
      _saveToDisk();

      int botIndex = messages.length - 1;

      final response = await http.post(
        Uri.parse("https://openrouter.ai/api/v1/chat/completions"),
        headers: {
          "Authorization": "Bearer $apiKey",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "model": "openai/gpt-4o-mini",
          "messages": [
            {
              "role": "user",
              "content": [
                {"type": "text", "text": "ما في هذه الصورة؟"},
                {
                  "type": "image_url",
                  "image_url": {"url": "data:image/png;base64,$base64Image"},
                },
              ],
            },
          ],
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        messages[botIndex]["content"] =
            data["choices"][0]["message"]["content"];
      } else {
        messages[botIndex]["content"] = "❌ فشل تحليل الصورة";
      }
    } catch (e) {
      messages.add({"role": "assistant", "content": "⚠️ خطأ: $e"});
    } finally {
      isLoading.value = false;
      _saveToDisk();
    }
  }

  void deleteCurrentChat() {
    allChats.remove(currentChatId.value);
    if (allChats.isEmpty) {
      createNewChat();
    } else {
      currentChatId.value = allChats.keys.first;
      _loadCurrentMessages();
    }
    box.write('all_sessions', allChats);
  }

  void clearAllData() {
    allChats.clear();
    messages.clear();
    box.remove('all_sessions');
    createNewChat();
  }

    // 🗑️ حذف محادثة محددة بمعرفها
  void deleteChat(String chatId) {
    allChats.remove(chatId);
    
    // إذا كانت المحادثة المحذوفة هي النشطة حالياً
    if (currentChatId.value == chatId) {
      if (allChats.isEmpty) {
        createNewChat();
      } else {
        currentChatId.value = allChats.keys.first;
        _loadCurrentMessages();
      }
    }
    
    box.write('all_sessions', allChats);
  }
}
