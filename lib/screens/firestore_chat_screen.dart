import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreChatScreen extends StatefulWidget {
  final String chatId; // Optional, safeChatId will be used instead
  final String peerId;
  final String peerName;
  final String? peerPhoto;

  const FirestoreChatScreen({
    required this.chatId,
    required this.peerId,
    required this.peerName,
    this.peerPhoto,
  });

  @override
  _FirestoreChatScreenState createState() => _FirestoreChatScreenState();
}

class _FirestoreChatScreenState extends State<FirestoreChatScreen> {
  final TextEditingController _messageController = TextEditingController();
  String? currentUserId;

  @override
  void initState() {
    super.initState();
    currentUserId = FirebaseAuth.instance.currentUser?.uid;
    print("✅ INIT | My UID: $currentUserId");
  }

  String get safeChatId {
    final ids = [currentUserId ?? '', widget.peerId];
    ids.sort();
    final id = '${ids[0]}_${ids[1]}';
    print("🧩 Using chatId: $id");
    return id;
  }

  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || currentUserId == null) return;

    final messageData = {
      'senderId': currentUserId,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(safeChatId)
          .collection('messages')
          .add(messageData);

      await FirebaseFirestore.instance.collection('chats').doc(safeChatId).set({
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'participants': [currentUserId, widget.peerId],
      }, SetOptions(merge: true));

      _messageController.clear();
    } catch (e) {
      print("❌ Failed to send message: $e");
    }
  }

  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    final isMe = msg['senderId'] == currentUserId;
    final messageText = msg['text'] ?? '';

    print("💬 '$messageText' | senderId: ${msg['senderId']} | isMe: $isMe");

    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(messageText),
      ),
    );
  }

  Widget _buildMessageStream() {
    print("🟢 Stream connected to: chats/$safeChatId/messages");

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('chats')
          .doc(safeChatId)
          .collection('messages')
          .orderBy('timestamp')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) return Center(child: Text("Error loading chat"));
        if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

        final messages = snapshot.data!.docs;

        return ListView.builder(
          padding: EdgeInsets.all(10),
          itemCount: messages.length,
          itemBuilder: (context, index) {
            final data = messages[index].data() as Map<String, dynamic>;
            return _buildMessageBubble(data);
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            if (widget.peerPhoto != null)
              CircleAvatar(backgroundImage: NetworkImage(widget.peerPhoto!))
            else
              CircleAvatar(child: Icon(Icons.person)),
            SizedBox(width: 10),
            Text(widget.peerName),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(child: _buildMessageStream()),
          Divider(height: 1),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: InputDecoration(hintText: 'Type a message...'),
                  ),
                ),
                IconButton(
                  icon: Icon(Icons.send, color: Colors.teal),
                  onPressed: _sendMessage,
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
