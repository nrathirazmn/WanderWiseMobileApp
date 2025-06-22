//Not used
// import 'package:cloud_firestore/cloud_firestore.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:flutter/material.dart';
// import '../services/ai_chat_service_openrouter.dart';

// class ChatScreen extends StatefulWidget {
//   final String? chatId;
//   final String? peerId;
//   final String peerName;
//   final String? peerPhoto;
//   final bool isAI;

//   const ChatScreen({
//     this.chatId,
//     this.peerId,
//     required this.peerName,
//     this.peerPhoto,
//     required this.isAI, required chatWith,
//   });

//   @override
//   _ChatScreenState createState() => _ChatScreenState();
// }

// class _ChatScreenState extends State<ChatScreen> {
//   final TextEditingController _controller = TextEditingController();
//   final AIChatService _chatService = AIChatService();
//   final currentUser = FirebaseAuth.instance.currentUser!;
//   bool _isLoading = false;

//   // Consistent and verified chatId
//   String get chatId {
//     final ids = [currentUser.uid, widget.peerId ?? ''];
//     ids.sort();
//     return '${ids[0]}_${ids[1]}';
//   }

//   Future<void> _sendMessage() async {
//     final message = _controller.text.trim();
//     if (message.isEmpty) return;

//     _controller.clear();
//     setState(() => _isLoading = true);

//     if (widget.isAI) {
//       try {
//         await FirebaseFirestore.instance.collection('ai_messages').add({
//           'from': currentUser.uid,
//           'text': message,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         final reply = await _chatService.sendMessage(message);

//         await FirebaseFirestore.instance.collection('ai_messages').add({
//           'from': 'ai',
//           'text': reply,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         setState(() => _isLoading = false);
//       } catch (e) {
//         print("❌ AI message error: $e");
//         setState(() => _isLoading = false);
//         _showErrorSnackBar("AI chat failed");
//       }
//     } else {
//       try {
//         final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);

//         await chatRef.collection('messages').add({
//           'from': currentUser.uid,
//           'text': message,
//           'timestamp': FieldValue.serverTimestamp(),
//         });

//         await chatRef.set({
//           'participants': [currentUser.uid, widget.peerId],
//           'lastMessage': message,
//           'lastTimestamp': FieldValue.serverTimestamp(),
//         }, SetOptions(merge: true));

//         setState(() => _isLoading = false);
//       } catch (e) {
//         print("❌ Buddy message error: $e");
//         setState(() => _isLoading = false);
//         _showErrorSnackBar("Send failed");
//       }
//     }
//   }

//   void _showErrorSnackBar(String message) {
//     ScaffoldMessenger.of(context).showSnackBar(
//       SnackBar(content: Text(message)),
//     );
//   }

//   Widget _buildMessageBubble(Map<String, dynamic> msg) {
//     final isMe = msg['from'] == currentUser.uid;
//     return Align(
//       alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
//       child: Container(
//         margin: const EdgeInsets.symmetric(vertical: 6, horizontal: 10),
//         padding: const EdgeInsets.all(12),
//         decoration: BoxDecoration(
//           color: isMe ? Colors.teal[100] : Colors.grey[300],
//           borderRadius: BorderRadius.circular(10),
//         ),
//         child: Text(msg['text'] ?? '', style: TextStyle(fontSize: 16)),
//       ),
//     );
//   }

//   Widget _buildMessageStream() {
//     final stream = widget.isAI
//         ? FirebaseFirestore.instance
//             .collection('ai_messages')
//             .orderBy('timestamp')
//             .snapshots()
//         : FirebaseFirestore.instance
//             .collection('chats')
//             .doc(chatId)
//             .collection('messages')
//             .orderBy('timestamp')
//             .snapshots();

//     return StreamBuilder<QuerySnapshot>(
//       stream: stream,
//       builder: (context, snapshot) {
//         if (snapshot.hasError) return Center(child: Text("Stream error"));
//         if (!snapshot.hasData) return Center(child: CircularProgressIndicator());
//         final docs = snapshot.data!.docs;
//         return ListView.builder(
//           itemCount: docs.length,
//           itemBuilder: (context, index) {
//             final msg = docs[index].data() as Map<String, dynamic>;
//             return _buildMessageBubble(msg);
//           },
//         );
//       },
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: Row(
//           children: [
//             if (widget.peerPhoto != null)
//               CircleAvatar(backgroundImage: NetworkImage(widget.peerPhoto!))
//             else
//               CircleAvatar(child: Icon(widget.isAI ? Icons.smart_toy : Icons.person)),
//             const SizedBox(width: 10),
//             Text(widget.peerName),
//           ],
//         ),
//       ),
//       body: Column(
//         children: [
//           Expanded(child: _buildMessageStream()),
//           if (_isLoading)
//             Padding(
//               padding: const EdgeInsets.all(8.0),
//               child: CircularProgressIndicator(),
//             ),
//           Padding(
//             padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
//             child: Row(
//               children: [
//                 Expanded(
//                   child: TextField(
//                     controller: _controller,
//                     decoration: const InputDecoration(
//                       hintText: 'Type your message...',
//                       border: OutlineInputBorder(),
//                     ),
//                   ),
//                 ),
//                 IconButton(
//                   icon: const Icon(Icons.send),
//                   onPressed: _sendMessage,
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }