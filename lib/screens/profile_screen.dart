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

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _fetchUserData();
  }

  void _fetchUserData() async {
    if (user == null) return;
    final doc = await FirebaseFirestore.instance.collection('users').doc(user!.uid).get();
    setState(() {
      userData = doc.data();
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

        setState(() {
          userData?['photoUrl'] = downloadUrl;
        });
      } else {
        print('Upload failed: ${result.body}');
      }
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Stream<QuerySnapshot> _getGuides() {
    return FirebaseFirestore.instance
        .collection('forum_posts')
        .where('author', isEqualTo: user?.email ?? '')
        .snapshots();
  }

Stream<QuerySnapshot> _getLiked() {
  final uid = FirebaseAuth.instance.currentUser?.uid;
  return FirebaseFirestore.instance
      .collection('forum_posts')
      .where('likes', arrayContains: uid)
      .snapshots();
}

Widget _buildPostCard(Map<String, dynamic> data, String postId, {bool isLikedTab = false}) {
  final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
  final hasLiked = data['likes']?.contains(uid) ?? false;

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
        leading: (data['imageUrl'] != null && data['imageUrl'].toString().startsWith('http'))
            ? ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(data['imageUrl'], width: 56, height: 56, fit: BoxFit.cover),
              )
            : const Icon(Icons.image),
        title: Text(data['title'] ?? 'Untitled'),
        subtitle: Text(data['author'] ?? 'Unknown'),
        trailing: IconButton(
          icon: Icon(
            hasLiked ? Icons.favorite : Icons.favorite_border,
            color: Colors.redAccent,
          ),
          onPressed: () async {
            final ref = FirebaseFirestore.instance.collection('forum_posts').doc(postId);
            await ref.update({
              'likes': FieldValue.arrayRemove([uid])
            });
          },
        ),
      ),
    ),
  );
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

          return _buildPostCard(post, postId, isLikedTab: true);
          },
        );
      },
    );
  }

  // Widget _buildPostCard(Map<String, dynamic> data, String postId, bool isGuide) {
  //   final user = FirebaseAuth.instance.currentUser;
  //   final uid = user?.uid ?? '';
  //   final hasLiked = data['likes']?.contains(uid) ?? false;
  //   final hasSaved = data['saves']?.contains(uid) ?? false;

  //   Future<void> toggleField(String field, bool currentState) async {
  //     final uid = FirebaseAuth.instance.currentUser?.uid;
  //     if (uid == null) return;
  //     final ref = FirebaseFirestore.instance.collection('forum_posts').doc(postId);
  //     await ref.update({
  //       field: currentState
  //           ? FieldValue.arrayRemove([uid])
  //           : FieldValue.arrayUnion([uid]),
  //     });
  //   }

  //   return InkWell(
  //     onTap: isGuide
  //         ? () {
  //             Navigator.push(
  //               context,
  //               MaterialPageRoute(
  //                 builder: (_) => PostDetailsScreen(postId: postId),
  //               ),
  //             );
  //           }
  //         : null,
  //     child: Container(
  //       width: 180,
  //       margin: const EdgeInsets.symmetric(horizontal: 10),
  //       decoration: BoxDecoration(
  //         borderRadius: BorderRadius.circular(10),
  //         color: Colors.grey[200],
  //         image: data['imageUrl'] != null && data['imageUrl'].toString().startsWith('http')
  //             ? DecorationImage(
  //                 image: NetworkImage(data['imageUrl']),
  //                 fit: BoxFit.cover,
  //               )
  //             : null,
  //       ),
  //       child: Stack(
  //         children: [
  //           Positioned(
  //             bottom: 0,
  //             left: 0,
  //             right: 0,
  //             child: Container(
  //               color: Colors.black.withOpacity(0.5),
  //               padding: const EdgeInsets.all(8),
  //               child: Column(
  //                 crossAxisAlignment: CrossAxisAlignment.start,
  //                 children: [
  //                   Text(
  //                     data['title'] ?? '',
  //                     style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
  //                   ),
  //                   isGuide
  //                       ? Row(
  //                           children: [
  //                             PopupMenuButton<String>(
  //                               onSelected: (value) async {
  //                                 if (value == 'edit') {
  //                                   Navigator.push(
  //                                     context,
  //                                     MaterialPageRoute(
  //                                       builder: (_) => EditPostScreen(
  //                                         postId: postId,
  //                                         postData: data,
  //                                       ),
  //                                     ),
  //                                   );
  //                                 } else if (value == 'delete') {
  //                                   await FirebaseFirestore.instance
  //                                       .collection('forum_posts')
  //                                       .doc(postId)
  //                                       .delete();
  //                                 }
  //                               },
  //                               itemBuilder: (BuildContext context) => const [
  //                                 PopupMenuItem(value: 'edit', child: Text('Edit')),
  //                                 PopupMenuItem(value: 'delete', child: Text('Delete')),
  //                               ],
  //                               icon: const Icon(Icons.more_vert, color: Colors.white),
  //                             ),
  //                           ],
  //                         )
  //                       : Row(
  //                           children: [
  //                             IconButton(
  //                               icon: Icon(
  //                                 hasLiked ? Icons.favorite : Icons.favorite_border,
  //                                 color: Colors.redAccent,
  //                                 size: 20,
  //                               ),
  //                               tooltip: hasLiked ? 'Unlike' : 'Like',
  //                               onPressed: () => toggleField('likes', hasLiked),
  //                             ),
  //                             IconButton(
  //                               icon: Icon(
  //                                 hasSaved ? Icons.bookmark : Icons.bookmark_border,
  //                                 color: Colors.blueAccent,
  //                                 size: 20,
  //                               ),
  //                               tooltip: hasSaved ? 'Remove from saved' : 'Save',
  //                               onPressed: () => toggleField('saves', hasSaved),
  //                             ),
  //                           ],
  //                         ),
  //                 ],
  //               ),
  //             ),
  //           )
  //         ],
  //       ),
  //     ),
  //   );
  // }

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
          const SizedBox(height: 40),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              IconButton(
                icon: const Icon(Icons.more_vert),
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
          const SizedBox(height: 16),
          Text(displayName, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          Text(username, style: const TextStyle(color: Colors.grey)),
          const SizedBox(height: 16),
          OutlinedButton(
            onPressed: () {
              Navigator.push(context, MaterialPageRoute(builder: (_) => EditProfileScreen()));
            },
            child: const Text('Edit Profile'),
          ),
          ListTile(
            leading: const Icon(Icons.bookmark),
            title: const Text("Saved Posts"),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => ProfileSavedPostsScreen(showSaved: true),
                ),
              );
            },
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
