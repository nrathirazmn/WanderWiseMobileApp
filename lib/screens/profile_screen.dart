// (Updated ProfileScreen with real-time gradient updates from Firestore)
import 'dart:ui';
import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'edit_profile_screen.dart';
import 'my_trips_tab.dart';
import 'edit_post_screen.dart';
import 'post_details_screen.dart';
import 'profile_saved_posts_screen.dart' hide PostDetailsScreen;
import 'settings_screen.dart';
import 'how_to_screen.dart';
import 'faq_screen.dart';
import 'admin_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> with SingleTickerProviderStateMixin {
  final user = FirebaseAuth.instance.currentUser;
  late TabController _tabController;
  Map<String, dynamic>? userData;
  List<Color> headerGradient = [
    Color.fromARGB(255, 255, 95, 109),
    Color.fromARGB(255, 255, 195, 113),
  ];

  final Map<String, List<Color>> themes = {
    'Coral Crush': [Color(0xFFFF5F6D), Color(0xFFFFC371)],
    'Aqua Pop': [Color(0xFF00F260), Color(0xFF0575E6)],
    'Sand & Sea': [Color(0xFFFFE259), Color(0xFFFFA751)],
  };

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    FirebaseFirestore.instance.collection('users').doc(user!.uid).snapshots().listen((doc) {
      setState(() {
        userData = doc.data();
        final themeKey = userData?['headerGradient'] ?? 'Coral Crush';
        headerGradient = themes[themeKey] ?? headerGradient;
      });
    });
  }

  Future<void> _pickAndUploadProfileImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null && user != null) {
      final file = File(pickedFile.path);
      final cloudName = 'dfi03udz5';
      final uploadPreset = 'wanderwise_unsigned';

      final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

      final request = http.MultipartRequest('POST', url)
        ..fields['upload_preset'] = uploadPreset
        ..files.add(await http.MultipartFile.fromPath('file', file.path));

      final response = await request.send();
      final result = await http.Response.fromStream(response);

      if (response.statusCode == 200) {
        final data = jsonDecode(result.body);
        final downloadUrl = data['secure_url'];

        await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
          'photoUrl': downloadUrl,
        });
      } else {
        print('Upload failed: ${result.body}');
      }
    }
  }

  void _showGradientPicker() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: themes.entries.map((entry) {
            final name = entry.key;
            final colors = entry.value;
            return ListTile(
              leading: Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  gradient: LinearGradient(colors: colors),
                  shape: BoxShape.circle,
                ),
              ),
              title: Text(name),
              onTap: () async {
                Navigator.pop(context);
                await FirebaseFirestore.instance.collection('users').doc(user!.uid).update({
                  'headerGradient': name,
                });
              },
            );
          }).toList(),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (user == null) {
      return const Center(child: Text('Please log in to view your profile'));
    }

    final displayName = userData?['name'] ?? 'User';
    final username = userData?['social'] ?? '@${user!.email?.split('@')[0] ?? 'username'}';
    final photoUrl = userData?['photoUrl'] ?? user!.photoURL;
    final isAdmin = user?.email == 'nrathirazmn@gmail.com';

    return Scaffold(
      body: Column(
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.only(top: 60, bottom: 30),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: headerGradient,
              ),
            ),
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      icon: const Icon(Icons.more_vert, color: Colors.white),
                      onPressed: () => _showBottomMenu(context),
                    ),
                  ],
                ),
                Stack(
                  alignment: Alignment.bottomRight,
                  children: [
                    CircleAvatar(
                      radius: 50,
                      backgroundColor: Colors.teal.shade100,
                      backgroundImage: (photoUrl != null && photoUrl.startsWith('http'))
                          ? NetworkImage(photoUrl)
                          : null,
                      child: (photoUrl == null || !photoUrl.startsWith('http'))
                          ? Text(displayName.isNotEmpty ? displayName[0] : '?', style: const TextStyle(fontSize: 40))
                          : null,
                    ),
                    IconButton(
                      icon: const Icon(Icons.camera_alt, color: Colors.black54),
                      onPressed: _pickAndUploadProfileImage,
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white)),
                const SizedBox(height: 4),
                Text(username, style: const TextStyle(color: Colors.white70)),
                const SizedBox(height: 12),
                OutlinedButton(
                  style: OutlinedButton.styleFrom(foregroundColor: Colors.white, side: BorderSide(color: Colors.white)),
                  onPressed: () {
                    Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
                  },
                  child: const Text('Edit Profile'),
                ),
              ],
            ),
          ),
          if (isAdmin)
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text("Admin Panel"),
              onTap: () {
                Navigator.pushNamed(context, '/admin-update');
              },
            ),
          TabBar(
            controller: _tabController,
            labelColor: Theme.of(context).primaryColor,
            unselectedLabelColor: Colors.grey,
            tabs: const [
              Tab(text: 'Trips'),
              Tab(text: 'Guides'),
              Tab(text: 'Liked'),
            ],
          ),
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                MyTripsTab(),
                _buildPostList(_getGuides(), isGuide: true),
                _buildPostList(_getLiked()),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Stream<QuerySnapshot> _getGuides() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('forum_posts')
        .where('authorId', isEqualTo: uid)
        .snapshots();
  }

  Stream<QuerySnapshot> _getLiked() {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    return FirebaseFirestore.instance
        .collection('forum_posts')
        .where('likes', arrayContains: uid)
        .snapshots();
  }

  Widget _buildPostList(Stream<QuerySnapshot> stream, {bool isGuide = false}) {
    return StreamBuilder<QuerySnapshot>(
      stream: stream,
      builder: (ctx, AsyncSnapshot<QuerySnapshot> snap) {
        if (snap.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (!snap.hasData || snap.data!.docs.isEmpty) {
          return Center(child: Text('No posts found.', style: TextStyle(color: Colors.grey)));
        }

        final items = snap.data!.docs;
        return ListView.builder(
          padding: const EdgeInsets.only(top: 8),
          itemCount: items.length,
          shrinkWrap: true,
          physics: const AlwaysScrollableScrollPhysics(),
          itemBuilder: (ctx, i) {
            final post = items[i].data() as Map<String, dynamic>;
            final postId = items[i].id;

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
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  color: Colors.grey[100],
                ),
                child: ListTile(
                  leading: (post['imageUrl'] != null && post['imageUrl'].toString().startsWith('http'))
                      ? ClipRRect(
                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(post['imageUrl'], width: 56, height: 56, fit: BoxFit.cover),
                        )
                      : const Icon(Icons.image),
                  title: Text(post['title'] ?? 'Untitled'),
                  subtitle: Text(post['content'] ?? ''),
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showBottomMenu(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) {
        return ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Container(
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.85),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  ListTile(
                    leading: const Icon(Icons.settings),
                    title: const Text('Settings'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => SettingsPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.palette),
                    title: const Text('Change Header Theme'),
                    onTap: _showGradientPicker,
                  ),
                  ListTile(
                    leading: const Icon(Icons.help_outline),
                    title: const Text('Help & how-to'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => HowToPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.support_agent),
                    title: const Text('Feedback & support'),
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.push(context, MaterialPageRoute(builder: (_) => FAQPage()));
                    },
                  ),
                  ListTile(
                    leading: const Icon(Icons.logout),
                    title: const Text('Log out'),
                    onTap: () async {
                      await FirebaseAuth.instance.signOut();
                      Navigator.of(context).pushNamedAndRemoveUntil('/', (route) => false);
                    },
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}