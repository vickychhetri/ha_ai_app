import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:file_selector/file_selector.dart';
import 'local_storage.dart';

const String BASE_URL = "http://91.107.184.128:8080";
// Android emulator: 10.0.2.2
// iOS simulator: http://localhost:8080
// Physical device: http://<your_pc_ip>:8080

class ChatScreen extends StatefulWidget {
  const ChatScreen({Key? key}) : super(key: key);

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final List<Map<String, String>> _messages = [
    {"sender": "ai", "text": "Hi 👋 I'm your assistant. How can I help you?"}
  ];
  final TextEditingController _controller = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToBottom();
    });
  }

  // Send text to AI
  Future<void> _sendMessage() async {
    final text = _controller.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({"sender": "user", "text": text});
      _controller.clear();
      _loading = true;
    });

    _scrollToBottom();

    try {
      final res = await http.post(
        Uri.parse("$BASE_URL/chat"),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode({
          "query": text,
          "user_id": LocalStorage.getUserId(),
        }),
      );

      String reply;
      if (res.statusCode == 200) {
        final data = jsonDecode(res.body);
        reply = data["answer"] ?? "No response";
      } else {
        reply = "⚠️ Server error: ${res.statusCode}";
      }

      setState(() {
        _messages.add({"sender": "ai", "text": reply});
      });
    } catch (e) {
      setState(() {
        _messages.add({"sender": "ai", "text": "⚠️ Error: $e"});
      });
    } finally {
      setState(() {
        _loading = false;
      });
      _scrollToBottom();
    }
  }

  // Scroll to bottom of chat
  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  // Pick and upload file
  Future<void> _uploadFile() async {
    try {
      final typeGroup = XTypeGroup(label: 'documents', extensions: ['pdf']);
      final XFile? file = await openFile(acceptedTypeGroups: [typeGroup]);

      if (file == null) return; // user cancelled

      final uri = Uri.parse("$BASE_URL/upload-file");
      final request = http.MultipartRequest("POST", uri);
      request.fields['user_id'] = LocalStorage.getUserId();
      request.files.add(await http.MultipartFile.fromPath("file", file.path));

      final response = await request.send();

      if (response.statusCode == 200) {
        setState(() {
          _messages.add({
            "sender": "ai",
            "text": "📄 File \"${file.name}\" uploaded successfully."
          });
        });
      } else {
        setState(() {
          _messages.add({"sender": "ai", "text": "❌ Upload failed"});
        });
      }
      _scrollToBottom();
    } catch (e) {
      setState(() {
        _messages.add({"sender": "ai", "text": "⚠️ Upload error: $e"});
      });
      _scrollToBottom();
    }
  }

  // Logout user
  Future<void> _logout() async {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text("Logout"),
          content: const Text("Are you sure you want to logout?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text("Cancel"),
            ),
            TextButton(
              onPressed: () async {
                Navigator.of(context).pop();
                await LocalStorage.logout();
                Navigator.pushNamedAndRemoveUntil(
                    context,
                    '/login',
                        (route) => false
                );
              },
              child: const Text("Logout", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  // Chat bubble widget
  Widget _buildMessage(Map<String, String> msg, int index) {
    final isUser = msg["sender"] == "user";

    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isUser ? MainAxisAlignment.end : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (!isUser) ...[
            const CircleAvatar(
              backgroundColor: Color(0xFF075E54),
              radius: 16,
              child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
            ),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: isUser ? const Color(0xFFDCF8C6) : Colors.white,
                borderRadius: BorderRadius.only(
                  topLeft: const Radius.circular(12),
                  topRight: const Radius.circular(12),
                  bottomLeft: Radius.circular(isUser ? 12 : 4),
                  bottomRight: Radius.circular(isUser ? 4 : 12),
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black12,
                    blurRadius: 1,
                    offset: const Offset(0, 1),
                  ),
                ],
              ),
              child: Text(
                msg["text"] ?? "",
                style: TextStyle(
                  color: Colors.black87,
                  fontSize: 16,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (isUser) ...[
            const SizedBox(width: 8),
            const CircleAvatar(
              backgroundColor: Color(0xFF075E54),
              radius: 16,
              child: Icon(Icons.person, color: Colors.white, size: 16),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildTypingIndicator() {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const CircleAvatar(
            backgroundColor: Color(0xFF075E54),
            radius: 16,
            child: Icon(Icons.smart_toy, color: Colors.white, size: 16),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
                bottomRight: Radius.circular(12),
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black12,
                  blurRadius: 1,
                  offset: const Offset(0, 1),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildTypingDot(),
                const SizedBox(width: 3),
                _buildTypingDot(),
                const SizedBox(width: 3),
                _buildTypingDot(),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTypingDot() {
    return Container(
      width: 8,
      height: 8,
      decoration: const BoxDecoration(
        color: Colors.grey,
        shape: BoxShape.circle,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFE5DDD5),
      appBar: AppBar(
        backgroundColor: const Color(0xFF075E54),
        elevation: 1,
        title: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Colors.white,
              radius: 18,
              child: Icon(Icons.smart_toy, color: Color(0xFF075E54), size: 18),
            ),
            const SizedBox(width: 12),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "Sangrah AI",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Text(
                  "Logged in as ${LocalStorage.getUserEmail()}",
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.attach_file, color: Colors.white, size: 22),
            onPressed: _uploadFile,
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert, color: Colors.white, size: 22),
            onSelected: (value) {
              if (value == 'logout') {
                _logout();
              }
            },
            itemBuilder: (BuildContext context) => [
              const PopupMenuItem<String>(
                value: 'logout',
                child: Row(
                  children: [
                    Icon(Icons.logout, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Logout', style: TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Date banner
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DDD5),
                  borderRadius: BorderRadius.circular(18),
                ),
                child: Text(
                  "TODAY",
                  style: TextStyle(
                    color: Colors.grey[700],
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            // Chat messages
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFE5DDD5),
                  image: const DecorationImage(
                    image: AssetImage("assets/chat_bg.png"),
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black,
                      BlendMode.dstATop,
                    ),
                  ),
                ),
                child: ListView.builder(
                  controller: _scrollController,
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _messages.length + (_loading ? 1 : 0),
                  itemBuilder: (context, index) {
                    // Handle loading indicator at the end
                    if (_loading && index == _messages.length) {
                      return _buildTypingIndicator();
                    }

                    // Direct index access since list is not reversed
                    final msg = _messages[index];
                    return _buildMessage(msg, index);
                  },
                ),
              ),
            ),

            // Input field
            Container(
              padding: const EdgeInsets.all(8),
              color: const Color(0xFFF0F0F0),
              child: Row(
                children: [
                  // Emoji button
                  IconButton(
                    icon: const Icon(Icons.emoji_emotions_outlined,
                        color: Colors.grey, size: 24),
                    onPressed: () {},
                  ),

                  // Attachment button
                  IconButton(
                    icon: const Icon(Icons.attach_file,
                        color: Colors.grey, size: 24),
                    onPressed: _uploadFile,
                  ),

                  // Text field
                  Expanded(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(24),
                      ),
                      child: TextField(
                        controller: _controller,
                        decoration: const InputDecoration(
                          hintText: "Type a message...",
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(vertical: 12),
                        ),
                        maxLines: null,
                        textInputAction: TextInputAction.send,
                        onSubmitted: (_) => _sendMessage(),
                      ),
                    ),
                  ),

                  // Send button
                  const SizedBox(width: 8),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF075E54),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send, color: Colors.white, size: 22),
                      onPressed: _sendMessage,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}