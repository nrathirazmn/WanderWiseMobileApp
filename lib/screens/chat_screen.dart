import 'package:flutter/material.dart';
import '../services/ai_chat_service_openrouter.dart';

class ChatScreen extends StatefulWidget {
  final String chatWith;
  const ChatScreen({required this.chatWith});

  @override
  _ChatScreenState createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final TextEditingController _controller = TextEditingController();
  final List<Map<String, String>> _messages = [];
  final AIChatService _chatService = AIChatService();
  bool _isLoading = false;

  void _sendMessage() async {
    final message = _controller.text.trim();
    if (message.isEmpty) return;

    setState(() {
      _messages.add({'sender': 'me', 'text': message});
      _controller.clear();
      _isLoading = true;
    });

    if (widget.chatWith == 'AI Travel Assistant') {
      try {
        final reply = await _chatService.sendMessage(message);
        setState(() {
          _messages.add({'sender': 'ai', 'text': reply});
          _isLoading = false;
        });
      } catch (e) {
        setState(() {
          _messages.add({'sender': 'ai', 'text': 'Sorry, I couldn\'t get a response.'});
          _isLoading = false;
        });
      }
    } else {
      setState(() {
        _messages.add({'sender': widget.chatWith, 'text': 'Thanks for your message!'});
        _isLoading = false;
      });
    }
  }

  Widget _buildMessage(Map<String, String> msg) {
    bool isMe = msg['sender'] == 'me';
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 5, horizontal: 10),
        padding: EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal[100] : Colors.grey[300],
          borderRadius: BorderRadius.circular(10),
        ),
        child: Text(msg['text'] ?? ''),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.chatWith)),
      body: Column(
        children: [
          Expanded(
            child: ListView.builder(
              itemCount: _messages.length,
              itemBuilder: (context, index) => _buildMessage(_messages[index]),
            ),
          ),
          if (_isLoading)
            Padding(
              padding: EdgeInsets.all(8),
              child: CircularProgressIndicator(),
            ),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: _controller,
                  decoration: InputDecoration(hintText: 'Type your message...'),
                ),
              ),
              IconButton(icon: Icon(Icons.send), onPressed: _sendMessage),
            ],
          ),
        ],
      ),
    );
  }
}
