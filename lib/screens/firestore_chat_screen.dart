import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirestoreChatScreen extends StatefulWidget {
  final String chatId; // This chatId should be passed from the previous screen
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
  final user = FirebaseAuth.instance.currentUser;

  // Fallback-safe chatId, if not passed correctly
  String get safeChatId {
    final ids = [user?.uid ?? '', widget.peerId];
    ids.sort();
    return '${ids[0]}_${ids[1]}';
  }

  // Send message to Firestore
  void _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty || user == null) return;

    final messageData = {
      'senderId': user!.uid,
      'text': text,
      'timestamp': FieldValue.serverTimestamp(),
    };

    try {
      // Add message to the "messages" subcollection
      await FirebaseFirestore.instance
          .collection('chats')
          .doc(safeChatId)
          .collection('messages')
          .add(messageData);

      // Update the last message and last timestamp in the "chats" document
      await FirebaseFirestore.instance.collection('chats').doc(safeChatId).set({
        'lastMessage': text,
        'lastTimestamp': FieldValue.serverTimestamp(),
        'participants': [user!.uid, widget.peerId],
      }, SetOptions(merge: true));

      _messageController.clear();
    } catch (e) {
      print("❌ Failed to send message: $e");
    }
  }

  // Build the message bubble for each message
  Widget _buildMessageBubble(Map<String, dynamic> msg) {
    bool isMe = msg['senderId'] == user?.uid;
    return Align(
      alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: EdgeInsets.symmetric(vertical: 4),
        padding: EdgeInsets.symmetric(vertical: 10, horizontal: 14),
        decoration: BoxDecoration(
          color: isMe ? Colors.teal[100] : Colors.grey[200],
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(msg['text']),
      ),
    );
  }

  // Message Stream for real-time updates
  Widget _buildMessageStream() {
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
          Expanded(child: _buildMessageStream()), // Displays all messages
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
                  onPressed: _sendMessage, // Sends message when clicked
                )
              ],
            ),
          ),
        ],
      ),
    );
  }
}
