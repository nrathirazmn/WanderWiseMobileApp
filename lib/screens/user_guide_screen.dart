import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'post_details_screen.dart';

class UserGuidesScreen extends StatefulWidget {
  const UserGuidesScreen({super.key});

  @override
  State<UserGuidesScreen> createState() => _UserGuidesScreenState();
}

class _UserGuidesScreenState extends State<UserGuidesScreen> {
  int _selectedIndex = 5; // index of 'Guides' tab

  void _onItemTapped(int index) {
    if (index == _selectedIndex) return;

    Navigator.pushReplacementNamed(context, '/main', arguments: index);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('User Guides & Experiences'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder(
        stream: FirebaseFirestore.instance.collection('forum_posts').snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final guides = snapshot.data!.docs.where((d) {
            final data = d.data() as Map<String, dynamic>;
            return data['isDraft'] == false && ['guide', 'explore'].contains(data['category']);
          }).toList();

          return ListView.builder(
            itemCount: guides.length,
            itemBuilder: (context, index) {
              final data = guides[index].data() as Map<String, dynamic>;
              final postId = guides[index].id;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: GestureDetector(
                  onTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => PostDetailsScreen(postId: postId)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          data['imageUrl'] ?? '',
                          width: 120,
                          height: 90,
                          fit: BoxFit.cover,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['title'] ?? 'No Title',
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'By ${data['author'] ?? data['authorName'] ?? 'Unknown'}',
                              style: const TextStyle(fontSize: 13, color: Colors.grey),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              _formatTimestamp(data['timestamp']),
                              style: const TextStyle(fontSize: 12, color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        selectedItemColor: const Color.fromARGB(255, 86, 35, 1),
        items: const [
          BottomNavigationBarItem(icon: Icon(Icons.home), label: 'Homepage'),
          BottomNavigationBarItem(icon: Icon(Icons.attach_money), label: 'Convert'),
          // BottomNavigationBarItem(icon: Icon(Icons.favorite), label: 'Travel Buddy'),
          BottomNavigationBarItem(icon: Icon(Icons.calendar_today), label: 'Itinerary'),
          BottomNavigationBarItem(icon: Icon(Icons.person), label: 'Profile'),
        ],
      ),
    );
  }

  String _formatTimestamp(Timestamp? timestamp) {
    if (timestamp == null) return '';
    final date = timestamp.toDate();
    return '${date.day}/${date.month}/${date.year}';
  }
}
