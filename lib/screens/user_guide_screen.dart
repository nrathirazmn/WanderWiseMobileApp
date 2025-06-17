import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'post_details_screen.dart';

class UserGuidesScreen extends StatefulWidget {
  const UserGuidesScreen({super.key});

  @override
  State<UserGuidesScreen> createState() => _UserGuidesScreenState();
}

class _UserGuidesScreenState extends State<UserGuidesScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;
    setState(() => _selectedIndex = index);
    Navigator.pushReplacementNamed(context, '/main',  arguments: 3);
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8F8F8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0.5,
        centerTitle: true,
        title: const Text('User Guides & Experiences',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black)),
        iconTheme: const IconThemeData(color: Colors.black),
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            Container(
              margin: const EdgeInsets.fromLTRB(16, 16, 16, 10),
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Color.fromARGB(255, 255, 255, 255),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "✈️ Start Planning Your Next Adventure",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF5D4037),
                    ),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    "Explore real stories & travel ideas written by fellow travelers.",
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.brown,
                    ),
                  ),
                  const SizedBox(height: 12),
                  StreamBuilder(
                    stream: FirebaseFirestore.instance
                        .collection('forum_posts')
                        .where('isDraft', isEqualTo: false)
                        .where('category', whereIn: ['guide', 'explore'])
                        .orderBy('timestamp', descending: false)
                        .limit(1)
                        .snapshots(),
                    builder: (context, snapshot) {
                      if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                        return SizedBox();
                      }
                      final data = snapshot.data!.docs.first.data() as Map<String, dynamic>;
                      final postId = snapshot.data!.docs.first.id;

                      return GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => PostDetailsScreen(postId: postId),
                          ),
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(12),
                          child: Image.network(
                            data['imageUrl'] ?? '',
                            height: 160,
                            width: double.infinity,
                            fit: BoxFit.cover,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  "Explore Guides",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
            ),
            StreamBuilder(
              stream: FirebaseFirestore.instance.collection('forum_posts').snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                final guides = snapshot.data!.docs.where((d) {
                  final data = d.data() as Map<String, dynamic>;
                  return data['isDraft'] == false && ['guide', 'explore'].contains(data['category']);
                }).toList();

                if (guides.isEmpty) {
                  return const Center(child: Text('No guides yet. Be the first to post!'));
                }

                return Column(
                  children: List.generate(guides.length, (index) {
                    final data = guides[index].data() as Map<String, dynamic>;
                    final postId = guides[index].id;
                    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
                    final hasLiked = data['likes']?.contains(uid) ?? false;
                    final hasSaved = data['saves']?.contains(uid) ?? false;

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => PostDetailsScreen(postId: postId),
                        ),
                      ),
                      child: Container(
                        margin: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(20),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              offset: Offset(0, 4),
                            )
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                CircleAvatar(
                                  backgroundColor: Colors.brown[100],
                                  child: Text(
                                    (data['author'] ?? 'U')[0].toUpperCase(),
                                    style: const TextStyle(color: Colors.white),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(data['author'] ?? 'Unknown',
                                        style: const TextStyle(
                                            fontWeight: FontWeight.bold, fontSize: 14)),
                                    Text(_formatTimestamp(data['timestamp']),
                                        style: const TextStyle(fontSize: 11, color: Colors.grey)),
                                  ],
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            if (data['imageUrl'] != null && data['imageUrl'].toString().startsWith('http'))
                              ClipRRect(
                                borderRadius: BorderRadius.circular(14),
                                child: Image.network(
                                  data['imageUrl'],
                                  height: 180,
                                  width: double.infinity,
                                  fit: BoxFit.cover,
                                ),
                              ),
                            const SizedBox(height: 12),
                            Text(
                              data['title'] ?? 'Untitled',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 6),
                            Text(
                              '${data['content']?.toString().substring(0, data['content'].toString().length > 100 ? 100 : data['content'].toString().length)}...'
                                  .trim(),
                              style: const TextStyle(fontSize: 13, color: Colors.black87),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                const Text('#guide',
                                    style: TextStyle(color: Colors.grey, fontSize: 12)),
                                const Spacer(),
                                Icon(Icons.favorite,
                                    size: 16, color: hasLiked ? Colors.red : Colors.grey),
                                const SizedBox(width: 4),
                                Text('${(data['likes'] as List?)?.length ?? 0}',
                                    style: const TextStyle(fontSize: 12)),
                                const SizedBox(width: 12),
                                Icon(Icons.bookmark,
                                    size: 16, color: hasSaved ? Colors.brown : Colors.grey),
                                const SizedBox(width: 4),
                                Text('${(data['saves'] as List?)?.length ?? 0}',
                                    style: const TextStyle(fontSize: 12)),
                              ],
                            )
                          ],
                        ),
                      ),
                    );
                  }),
                );
              },
            )
          ],
        ),
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
