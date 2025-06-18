import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class MessageScreen extends StatefulWidget {
  @override
  _MessageScreenState createState() => _MessageScreenState();
}

class _MessageScreenState extends State<MessageScreen> {
  final user = FirebaseAuth.instance.currentUser;
  int _selectedIndex = 0;

  String _getInitials(String? name) {
    if (name == null || name.trim().isEmpty) return '?';
    final parts = name.trim().split(' ');
    if (parts.length == 1) return parts[0][0].toUpperCase();
    return (parts[0][0] + parts[1][0]).toUpperCase();
  }

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pushReplacementNamed(context, '/main', arguments: index);
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return Center(child: Text("Please log in to view messages."));
    }

    return Scaffold(
      appBar: AppBar(title: Text('Messages')),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('chats')
            .where('participants', arrayContains: user?.uid)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return Center(child: CircularProgressIndicator());

          final chats = snapshot.data!.docs;

          return ListView(
            children: [
              Padding(
                padding: EdgeInsets.all(10),
                child: Text('Pinned', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              Card(
                color: Colors.teal[50],
                margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                child: ListTile(
                  leading: CircleAvatar(child: Icon(Icons.smart_toy)),
                  title: Text('AI Travel Assistant'),
                  subtitle: Text('Ask anything about your travel'),
                  onTap: () {
                    Navigator.pushNamed(
                      context,
                      '/chat',
                      arguments: {
                        'isAI': true,
                        'peerName': 'AI Travel Assistant',
                      },
                    );
                  },
                ),
              ),
              Padding(
                padding: EdgeInsets.all(10),
                child: Text('Chats with Buddies', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ),
              ...chats.map((doc) {
                final data = doc.data() as Map<String, dynamic>;
                final participants = (data['participants'] as List?) ?? [];
                final otherUserId = participants.firstWhere(
                  (uid) => uid != user?.uid,
                  orElse: () => null,
                );

                if (otherUserId == null) return SizedBox.shrink();

                final unreadCount = data['unreadCount']?[user?.uid] ?? 0;

                return FutureBuilder<DocumentSnapshot>(
                  future: FirebaseFirestore.instance.collection('users').doc(otherUserId).get(),
                  builder: (context, userSnap) {
                    if (!userSnap.hasData) return SizedBox.shrink();
                    final userData = userSnap.data!.data() as Map<String, dynamic>;
                    return Card(
                      margin: EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      child: ListTile(
                        leading: CircleAvatar(
                          backgroundImage: userData['photoUrl'] != null
                              ? NetworkImage(userData['photoUrl'])
                              : null,
                          backgroundColor: Colors.brown[200],
                          child: userData['photoUrl'] == null
                              ? Text(
                                  _getInitials(userData['name']),
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                )
                              : null,
                        ),
                        title: Text(
                          "${userData['name'] ?? 'Unknown'} from ${userData['nationality'] ?? 'Unknown'}",
                        ),
                        subtitle: Text(data['lastMessage'] ?? ''),
                        trailing: unreadCount > 0
                            ? CircleAvatar(
                                radius: 10,
                                backgroundColor: Colors.red,
                                child: Text(
                                  '$unreadCount',
                                  style: TextStyle(color: Colors.white, fontSize: 12),
                                ),
                              )
                            : null,
                        onTap: () async {
                          await FirebaseFirestore.instance
                              .collection('chats')
                              .doc(doc.id)
                              .update({
                            'unreadCount.${user?.uid}': 0,
                          });

                          Navigator.pushNamed(
                            context,
                            '/chat',
                            arguments: {
                              'isAI': false,
                              'chatId': doc.id,
                              'peerId': otherUserId,
                              'peerName': userData['name'],
                              'peerPhoto': userData['photoUrl'],
                            },
                          );
                        },
                      ),
                    );
                  },
                );
              }).toList(),
            ],
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 86, 35, 1),
        unselectedItemColor: Colors.grey,
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Homepage'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Convert'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Itinerary'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }
}
