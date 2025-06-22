
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'dart:ui';
import 'package:lottie/lottie.dart';
import 'forum_screen.dart';
import 'edit_travel_buddy_screen.dart';

class SwipeBuddyScreen extends StatefulWidget {
  @override
  _SwipeBuddyScreenState createState() => _SwipeBuddyScreenState();
}

class _SwipeBuddyScreenState extends State<SwipeBuddyScreen> {
  final currentUser = FirebaseAuth.instance.currentUser;
  List<DocumentSnapshot> users = [];
  int index = 0;
  int _selectedIndex = 0;
  bool isProcessingMatch = false;

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    Navigator.pushReplacementNamed(context, '/main', arguments: index);
  }

  bool isTravelBuddyActive = true; // assume true until proven otherwise

  @override
  void initState() {
    super.initState();
    _checkTravelBuddyStatus();
    _loadUsers();
  }

  Future<void> _checkTravelBuddyStatus() async {
    final currentUserDoc = await FirebaseFirestore.instance
        .collection('users')
        .doc(currentUser!.uid)
        .get();

    if (currentUserDoc.exists && currentUserDoc.data()?['showInTravelBuddy'] != true) {
      setState(() => isTravelBuddyActive = false);
      _showActivateDialog(); // show dialog immediately
    }
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

  Stream<List<DocumentSnapshot>> getLikedProfilesStream() async* {
    final currentUid = currentUser?.uid;
    if (currentUid == null) yield [];

    yield* FirebaseFirestore.instance
        .collection('users')
        .doc(currentUid)
        .snapshots()
        .asyncMap((doc) async {
          final List<dynamic> likedUids = doc.data()?['likes'] ?? [];
          if (likedUids.isEmpty) return [];

          final likedSnapshot = await FirebaseFirestore.instance
              .collection('users')
              .where('uid', whereIn: likedUids.length > 10 ? likedUids.sublist(0, 10) : likedUids)
              .get();

          return likedSnapshot.docs;
        });
  }

  void _showActivateDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => Stack(
        children: [
          BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
            child: Container(color: Colors.black.withOpacity(0.2)),
          ),
          AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
            title: Row(
              children: const [
                Icon(Icons.travel_explore, color: Colors.brown),
                SizedBox(width: 8),
                Text("Travel Buddy!"),
              ],
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Lottie.asset(
                  'assets/TravelBuddy.json', 
                  height: 120,
                ),
                const SizedBox(height: 12),
                Text(
                  "Want to connect with fellow travelers? Enable Travel Buddy to get started!",
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 14, color: Colors.black87),
                ),
              ],
            ),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () {
                        Navigator.pushReplacementNamed(context, '/main', arguments: 0); //Going back to forumscreen
                      },
                      style: TextButton.styleFrom(
                        foregroundColor: Colors.brown,
                        backgroundColor: Colors.white,
                        side: BorderSide(color: Colors.brown),
                      ),
                      child: const Text("Not now"),
                    ),
                  ),
                  const SizedBox(width: 12), // spacing between buttons
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: () async {
                        await FirebaseFirestore.instance
                            .collection('users')
                            .doc(currentUser!.uid)
                            .update({'showInTravelBuddy': true});
                        setState(() => isTravelBuddyActive = true);
                        Navigator.pop(context);
                        _loadUsers();
                      },
                      label: const Text("Enable", style: TextStyle(color: Colors.white)),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.brown,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _likeUser() async {
    if (isProcessingMatch || index >= users.length) return;
    setState(() => isProcessingMatch = true);

    final likedUser = users[index];
    final data = likedUser.data() as Map<String, dynamic>;
    final likedUid = data['uid'];
    final myUid = currentUser!.uid;

    final myRef = FirebaseFirestore.instance.collection('users').doc(myUid);
    final likedRef = FirebaseFirestore.instance.collection('users').doc(likedUid);

    print("👍 You liked: $likedUid");

    await myRef.update({'likes': FieldValue.arrayUnion([likedUid])});

    final likedSnapshot = await likedRef.get(const GetOptions(source: Source.server));
    final likedLikes = List<String>.from(likedSnapshot.data()?['likes'] ?? []);

    print("🔁 Their likes: $likedLikes");

    if (likedLikes.contains(myUid)) {
      print("✅ Matched with: $likedUid");

      // Update both users' matches
      await myRef.update({'matches': FieldValue.arrayUnion([likedUid])});
      await likedRef.update({'matches': FieldValue.arrayUnion([myUid])});

      if (!mounted) {
        setState(() {
          isProcessingMatch = false;
          index++;
        });
        return;
      }

      try {
        print("🪟 Showing match dialog...");
        await showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("🎉 It's a Match!"),
            content: Text("You and ${data['name']} like each other!"),
            actions: [
              TextButton(
                onPressed: () {
                  Navigator.pop(ctx);
                  setState(() {
                    isProcessingMatch = false;
                    index++;
                  });
                },
                child: const Text("Later"),
              ),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(ctx);
                  final chatId = [myUid, likedUid]..sort();
                  final chatRef = FirebaseFirestore.instance.collection('chats').doc("${chatId[0]}_${chatId[1]}");
                  final messagesRef = chatRef.collection('messages');

                  await chatRef.set({
                    'participants': [myUid, likedUid],
                    'lastMessage': 'Hey 👋',
                    'lastTimestamp': FieldValue.serverTimestamp(),
                  });

                  await messagesRef.add({
                    'from': myUid,
                    'text': 'Hey 👋',
                    'timestamp': FieldValue.serverTimestamp(),
                  });

                  if (!mounted) return;
                  setState(() {
                    isProcessingMatch = false;
                    index++;
                  });

                  Navigator.pushNamed(context, '/chat', arguments: {
                    'chatId': "${chatId[0]}_${chatId[1]}",
                    'peerId': likedUid,
                    'peerName': data['name'],
                    'peerPhoto': data['photoUrl'],
                    'isAI': false,
                  });
                },
                child: const Text("Say Hi"),
              ),
            ],
          ),
        );
      } catch (e) {
        print("❌ Error showing match dialog: $e");
        setState(() {
          isProcessingMatch = false;
          index++;
        });
      }
    } else {
      print("❌ No match. Moving to next card...");
      _nextCard();
      setState(() => isProcessingMatch = false);
    }
  }

  void _nextCard() async {
    if (index < users.length) {
      final dislikedUid = users[index]['uid'];
      await FirebaseFirestore.instance.collection('users').doc(currentUser!.uid).update({
        'dislikes': FieldValue.arrayUnion([dislikedUid])
      });
    }
    setState(() {
      index = index + 1;
    });
  }

  Widget _buildMyProfileCard() {
    final user = FirebaseAuth.instance.currentUser;

    return FutureBuilder<DocumentSnapshot>(
      future: FirebaseFirestore.instance.collection('users').doc(user?.uid).get(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return SizedBox.shrink();

        final data = snapshot.data!.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'You';
        final photoUrl = data['photoUrl'];
        final bio = (data['bio'] ?? '').toString().trim().isEmpty
            ? 'Tap to write your travel story...'
            : data['bio'];

        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(builder: (_) => EditTravelBuddyScreen()),
            );
            setState(() {}); 
          },
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.brown.shade50,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.brown.shade100),
              boxShadow: [
                BoxShadow(
                  color: Colors.brown.shade100.withOpacity(0.3),
                  blurRadius: 10,
                  offset: Offset(0, 4),
                ),
              ],
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      radius: 34,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      backgroundColor: Colors.brown.shade200,
                      child: photoUrl == null ? Icon(Icons.person, size: 34, color: Colors.white) : null,
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text("👤 $name", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                          SizedBox(height: 4),
                          Text("Your Travel Buddy Profile", style: TextStyle(color: Colors.brown[700], fontSize: 13)),
                        ],
                      ),
                    ),
                    Icon(Icons.arrow_forward_ios_rounded, size: 18, color: Colors.brown.shade400),
                  ],
                ),
                SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.brown.shade100),
                  ),
                  child: Text(
                    bio,
                    style: TextStyle(fontSize: 14, color: Colors.grey[800]),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    if (index >= users.length) {
      return Scaffold(
        backgroundColor: Colors.white,
        body: Center(child: Text("No more travel buddies to show.")),
      );
    }

    if (!isTravelBuddyActive) {
      return Scaffold(
        appBar: AppBar(title: Text('Travel Buddy')),
        body: Center(child: Text('Activating Travel Buddy...')),
      );
    }

    final user = users[index];
    final data = user.data() as Map<String, dynamic>;
    final name = data['name'] ?? 'User';
    final photoUrl = data['photoUrl'];
    final bio = data['bio']?.toString().trim().isNotEmpty == true ? data['bio'] : 'Loves to travel!';

    return Scaffold(
      backgroundColor: Color(0xFFF9FAFB),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        title: Text('Travel Buddy', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            const SizedBox(height: 10),
            _buildMyProfileCard(),
            StreamBuilder<List<DocumentSnapshot>>(
              stream: getLikedProfilesStream(),
              builder: (context, snapshot) {
                if (!snapshot.hasData || snapshot.data!.isEmpty) return SizedBox.shrink();
                final likedProfiles = snapshot.data!;
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text("New Matches", style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      height: 140,
                      padding: EdgeInsets.symmetric(horizontal: 16),
                      child: ListView.builder(
                        scrollDirection: Axis.horizontal,
                        itemCount: likedProfiles.length,
                        itemBuilder: (context, i) {
                          final likedData = likedProfiles[i].data() as Map<String, dynamic>;
                          final likedName = likedData['name'] ?? 'User';
                          final likedPhotoUrl = likedData['photoUrl'];
                          final likedBio = likedData['bio']?.toString().trim().isNotEmpty == true ? likedData['bio'] : 'No bio available';

                          return GestureDetector(
                            onTap: () => showDialog(
                              context: context,
                              builder: (_) => AlertDialog(
                                title: Text(likedName),
                                content: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    CircleAvatar(
                                      radius: 50,
                                      backgroundImage: likedPhotoUrl != null ? NetworkImage(likedPhotoUrl) : null,
                                      child: likedPhotoUrl == null ? Icon(Icons.person, size: 50) : null,
                                    ),
                                    SizedBox(height: 12),
                                    Text(likedBio, textAlign: TextAlign.center),
                                  ],
                                ),
                              ),
                            ),
                            child: Container(
                              margin: EdgeInsets.only(right: 12),
                              child: Column(
                                children: [
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundImage: likedPhotoUrl != null ? NetworkImage(likedPhotoUrl) : null,
                                    child: likedPhotoUrl == null ? Icon(Icons.person, size: 35) : null,
                                  ),
                                  const SizedBox(height: 6),
                                  Text(likedName, style: TextStyle(fontSize: 13)),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                );
              },
            ),
            Text('Your next travelmate awaits...', style: TextStyle(fontSize: 14, color: Colors.grey[600])),
            const SizedBox(height: 16),
            Card(
              color: Colors.white,
              elevation: 6,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              child: Container(
                height: 300,
                width: 280,
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundImage: photoUrl != null ? NetworkImage(photoUrl) : null,
                      child: photoUrl == null ? const Icon(Icons.person, size: 60) : null,
                    ),
                    const SizedBox(height: 16),
                    Text(name, style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 8),
                    Text(bio, textAlign: TextAlign.center),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                FloatingActionButton(
                  backgroundColor: Color(0xFFFF6B6B),
                  onPressed: _nextCard,
                  child: const Icon(Icons.close),
                ),
                FloatingActionButton(
                  backgroundColor: Color(0xFF50C878),
                  onPressed: () {
                    print("💚 Like button pressed");
                    _likeUser();
                  },
                  child: const Icon(Icons.favorite),
                ),
              ],
            ),
            const SizedBox(height: 30),
          ],
        ),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: Color(0xFF562301),
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
