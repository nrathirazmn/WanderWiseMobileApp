import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'create_post_screen.dart';
import 'post_details_screen.dart';
import 'dart:math';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String? _username;
  String? _photoUrl;
  String? _age;
  String? _nationality;
  String? _contact;
  String? _social;

  @override
  void initState() {
    super.initState();
    _loadUserProfile();
  }

Future<void> _loadUserProfile() async {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  if (uid == null) return;

  final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
  final data = doc.data();

if (data != null && mounted) {
  setState(() {
    _username = data['name'];
    _age = data['age']?.toString();
    _nationality = data['nationality'];
    _contact = data['contact'];
    _social = data['social'];
    _photoUrl = data.containsKey('photoUrl') ? data['photoUrl'] : null;
  });
}

}

  void _showDestinationPopup(BuildContext context) {
    final controller = TextEditingController();
    final List<String> customOptions = [];
    final List<String> defaultOptions = [
      "Tokyo", "Bali", "Barcelona", "Seoul", "New Zealand",
      "London", "Iceland", "Cape Town", "Paris", "Marrakech"
    ];
    String? chosen;
    bool useCustom = false;

    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setState) => AlertDialog(
            title: Text('🎯 Not Sure on Your Next Destination?'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (chosen == null) ...[
                    Text("Here’s a surprise suggestion for you!"),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () {
                        final pick = (defaultOptions.toList()..shuffle()).first;
                        setState(() => chosen = pick);
                      },
                      child: Text("Decide for Me"),
                    ),
                    TextButton(
                      onPressed: () => setState(() => useCustom = true),
                      child: Text("Choose from My List →"),
                    ),
                  ],
                  if (useCustom && chosen == null) ...[
                    TextField(
                      controller: controller,
                      decoration: InputDecoration(hintText: 'Add a destination'),
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) {
                          setState(() {
                            customOptions.add(value.trim());
                            controller.clear();
                          });
                        }
                      },
                    ),
                    Wrap(
                      spacing: 6,
                      children: customOptions
                          .map((e) => Chip(
                                label: Text(e),
                                onDeleted: () => setState(() => customOptions.remove(e)),
                              ))
                          .toList(),
                    ),
                    SizedBox(height: 8),
                    ElevatedButton(
                      onPressed: customOptions.length < 2
                          ? null
                          : () {
                              final pick = (customOptions.toList()..shuffle()).first;
                              setState(() => chosen = pick);
                            },
                      child: Text("Spin from My List"),
                    ),
                  ],
                  if (chosen != null) ...[
                    SizedBox(height: 12),
                    Text('🎉 You should visit:', style: TextStyle(fontWeight: FontWeight.bold)),
                    SizedBox(height: 8),
                    Text(chosen!, style: TextStyle(fontSize: 18, color: const Color.fromARGB(255, 86, 35, 1))),
                    SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => Navigator.pushNamed(context, '/itinerary'),
                      child: Text('Start Planning Now'),
                    )
                  ]
                ],
              ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: Text('Close')),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSection(String title, List<DocumentSnapshot> posts) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Text(title, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
        ),
        SizedBox(
          height: 220,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;
              return _buildPostCard(data, posts[index].id);
            },
          ),
        ),
      ],
    );
  }

  Widget _buildPostCard(Map<String, dynamic> data, String postId) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';
    final hasLiked = data['likes']?.contains(uid) ?? false;
    final hasSaved = data['saves']?.contains(uid) ?? false;

    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => PostDetailsScreen(postId: postId),
          ),
        );
      },
      child: Container(
        width: 180,
        margin: const EdgeInsets.symmetric(horizontal: 10),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(10),
          color: Colors.grey[200],
          image: data['imageUrl'] != null && data['imageUrl'].toString().startsWith('http')
              ? DecorationImage(
                  image: NetworkImage(data['imageUrl']), fit: BoxFit.cover)
              : null,
        ),
        child: Stack(
          children: [
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              child: Container(
                color: Colors.black.withOpacity(0.5),
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(data['title'] ?? '', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    Row(
                      children: [
                        IconButton(
                          icon: Icon(
                            hasLiked ? Icons.favorite : Icons.favorite_border,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _toggleAction(postId, 'likes', hasLiked),
                        ),
                        IconButton(
                          icon: Icon(
                            hasSaved ? Icons.bookmark : Icons.bookmark_border,
                            color: Colors.white,
                            size: 20,
                          ),
                          onPressed: () => _toggleAction(postId, 'saves', hasSaved),
                        ),
                      ],
                    )
                  ],
                ),
              ),
            )
          ],
        ),
      ),
    );
  }

  Future<void> _toggleAction(String postId, String field, bool currentlyHas) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;
    final postRef = FirebaseFirestore.instance.collection('forum_posts').doc(postId);
    await postRef.update({
      field: currentlyHas
          ? FieldValue.arrayRemove([uid])
          : FieldValue.arrayUnion([uid])
    });
  }

  Widget _buildAIChatBanner() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () => Navigator.pushNamed(context, '/chat', arguments: {
          'isAI': true,
          'peerName': 'AI Travel Assistant',
        }),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 86, 35, 1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: const Color.fromARGB(255, 252, 252, 252)),
          ),
          child: Row(
            children: [
              Icon(Icons.smart_toy, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('AI Travel Assistant', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Ask anything about your trip!', style: TextStyle(color: Colors.white, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildUserCard() {
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(16),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.brown[100],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              CircleAvatar(
                backgroundImage: _photoUrl != null ? NetworkImage(_photoUrl!) : null,
                radius: 35,
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(_username ?? 'User', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                    Text("Age: $_age y/o"),
                    Text("Nationality: $_nationality"),
                    Text("Contact: $_contact"),
                    Text("Socials: $_social"),
                  ],
                ),
              )
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildDestinationSpinBanner() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: GestureDetector(
        onTap: () => _showDestinationPopup(context),
        child: Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 86, 35, 1),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: Colors.white),
          ),
          child: Row(
            children: [
              Icon(Icons.casino, color: Colors.white),
              SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Not Sure on Your Next Destination?', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.white)),
                    Text('Let WanderWise choose it for you or choose from your own list!', style: TextStyle(color: Colors.white70, fontSize: 12)),
                  ],
                ),
              ),
              Icon(Icons.arrow_forward_ios, size: 16, color: Colors.white),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar( 
        automaticallyImplyLeading: false, //to remove the backbutton
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          children: [
            Image.asset('assets/WWlogo.png', height: 32),
            const SizedBox(width: 10),
            const Text(
              'WanderWise',
              style: TextStyle(
                color: Colors.black,
                fontWeight: FontWeight.bold,
                fontSize: 20,
              ),
            ),
          ],
        ),
        actions: [
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.message, color: Colors.black),
              onPressed: () {
                print('🧭 Navigating to /messages');
                Navigator.pushNamed(context, '/messages');
              },
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          Navigator.push(context, MaterialPageRoute(builder: (_) => CreatePostScreen()));
        },
        child: const Icon(Icons.add),
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('forum_posts').snapshots(),
        builder: (context, AsyncSnapshot<QuerySnapshot> snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          final posts = snapshot.data!.docs;
          final guides = posts.where((d) =>
            (d.data() as Map<String, dynamic>)['isDraft'] == false &&
            ['guide', 'explore'].contains((d.data() as Map<String, dynamic>)['category'])
          ).toList();
          return ListView(
            children: [
              _buildAIChatBanner(),
              _buildUserCard(),
              _buildDestinationSpinBanner(),
              _buildSection("📒 User Guide and Experience", guides),
            ],
          );
        },
      ),
    );
  }
}





