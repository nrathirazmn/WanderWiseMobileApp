import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';

class SwipeBuddyScreen extends StatefulWidget {
  @override
  _SwipeBuddyScreenState createState() => _SwipeBuddyScreenState();
}

class _SwipeBuddyScreenState extends State<SwipeBuddyScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  List<DocumentSnapshot> users = [];
  int index = 0;

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (currentUser == null) return;

    final currentUserDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final myData = currentUserDoc.data();
    final List<dynamic> liked = myData?['likes'] ?? [];
    final List<dynamic> matches = myData?['matches'] ?? [];
    final List<dynamic> disliked = myData?['dislikes'] ?? [];

    final snapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', isNotEqualTo: currentUser!.uid)
        .where('showInTravelBuddy', isEqualTo: true)
        .get();

    setState(() {
      users = snapshot.docs.where((doc) {
        final uid = doc['uid'];
        return !liked.contains(uid) && !matches.contains(uid) && !disliked.contains(uid);
      }).toList();
    });
  }

  void _likeUser() async {
    if (index >= users.length) return;

    final likedUser = users[index];
    final data = likedUser.data() as Map<String, dynamic>;
    final likedUid = data['uid'];
    final myUid = currentUser!.uid;

    final myRef = FirebaseFirestore.instance.collection('users').doc(myUid);
    final likedRef = FirebaseFirestore.instance.collection('users').doc(likedUid);

    await myRef.update({
      'likes': FieldValue.arrayUnion([likedUid])
    });

    final likedSnapshot = await likedRef.get();
    List<String> likedLikes = [];

    if (likedSnapshot.exists && likedSnapshot.data()!.containsKey('likes')) {
      likedLikes = List<String>.from(likedSnapshot['likes']);
    }

    if (likedLikes.contains(myUid)) {
      await myRef.update({
        'matches': FieldValue.arrayUnion([likedUid])
      });
      await likedRef.update({
        'matches': FieldValue.arrayUnion([myUid])
      });

      showDialog(
        context: context,
        builder: (_) => AlertDialog(
          title: Text("\u{1F389} It's a Match!"),
          content: Text("You and ${data['name']} like each other!\nWould you like to send a Hi \u{1F44B} now?"),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context);
                _nextCard();
              },
              child: Text("Maybe Later"),
            ),
            ElevatedButton(
              onPressed: () async {
                Navigator.pop(context);

                final List<String> sorted = [myUid, likedUid]..sort();
                final chatId = "${sorted[0]}_${sorted[1]}";
                final chatRef = FirebaseFirestore.instance.collection('chats').doc(chatId);
                final messagesRef = chatRef.collection('messages');

                await chatRef.set({
                  'participants': [myUid, likedUid],
                  'lastMessage': 'Hey \u{1F44B}',
                  'lastTimestamp': FieldValue.serverTimestamp(),
                });

                await messagesRef.add({
                  'from': myUid,
                  'text': 'Hey \u{1F44B}',
                  'timestamp': FieldValue.serverTimestamp(),
                });

                Navigator.pushNamed(
                  context,
                  '/chat',
                  arguments: {
                    'chatId': chatId,
                    'peerId': likedUid,
                    'peerName': data['name'],
                    'peerPhoto': data['photoUrl'],
                    'isAI': false,
                  },
                );
              },
              child: Text("Yes, Send Hi \u{1F44B}"),
            ),
          ],
        ),
      );

      return;
    }

    _nextCard();
  }

  void _nextCard() async {
    if (index < users.length) {
      final dislikedUser = users[index];
      final dislikedUid = dislikedUser['uid'];
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'dislikes': FieldValue.arrayUnion([dislikedUid])
      });
    }
    setState(() {
      index = index + 1;
    });
  }

  void _showLikedProfiles() async {
    final myDoc = await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).get();
    final List<dynamic> likedUids = myDoc.data()?['likes'] ?? [];

    if (likedUids.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("No liked profiles yet.")));
      return;
    }

    final likedSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('uid', whereIn: likedUids.length > 10 ? likedUids.sublist(0, 10) : likedUids)
        .get();

    final likedUsers = likedSnapshot.docs;

    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) {
        return ListView.builder(
          itemCount: likedUsers.length,
          itemBuilder: (_, i) {
            final data = likedUsers[i].data() as Map<String, dynamic>;
            return ListTile(
              leading: CircleAvatar(
                backgroundImage: data['photoUrl'] != null ? NetworkImage(data['photoUrl']) : null,
                child: data['photoUrl'] == null ? Icon(Icons.person) : null,
              ),
              title: Text(data['name'] ?? 'User'),
              subtitle: Text(data['bio'] ?? 'No bio'),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (index >= users.length) {
      return Center(child: Text("No more travel buddies to show."));
    }

    final user = users[index];
    final data = user.data() as Map<String, dynamic>;
    final name = data.containsKey('name') ? data['name'] : 'User';
    final photoUrl = data.containsKey('photoUrl') ? data['photoUrl'] : null;
    final bio = data.containsKey('bio') ? data['bio'] : 'Loves to travel!';

    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(height: 5),
          Text('Travel Buddy', 
            style: TextStyle(
              fontSize: 24, 
              fontWeight: FontWeight.bold,
              color: const Color.fromARGB(255, 86, 35, 1),
              )
              ),
          SizedBox(height: 8),
          Text('Find your travelmate buddy here!', 
            style: TextStyle(
              fontSize: 14, 
              color: Colors.black54
              )
              ),
          SizedBox(height: 15),
            TextButton.icon(
            onPressed: _showLikedProfiles,
            icon: Icon(Icons.people),
            label: Text("View Liked"),
          ),
          SizedBox(height: 10),
          Card(
            elevation: 6,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            child: Container(
              height: 300,
              width: 280,
              padding: EdgeInsets.all(16),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 50,
                    backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                    child: photoUrl == null ? Icon(Icons.person, size: 60) : null,
                  ),
                  SizedBox(height: 16),
                  Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text(bio, textAlign: TextAlign.center),
                ],
              ),
            ),
          ),
          SizedBox(height: 20),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: [
              FloatingActionButton(onPressed: _nextCard, child: Icon(Icons.close)),
              FloatingActionButton(onPressed: _likeUser, child: Icon(Icons.favorite)),
            ],
          ),
          SizedBox(height: 20),
        ],
      ),
    );
  }
}