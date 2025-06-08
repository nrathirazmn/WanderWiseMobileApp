// [Trip Plan Tab updated to match user screenshot: day labels, checklist cards, etc. | Overview Tab now shows embedded guides | PostDetailsScreen logic enhanced: saving guides into existing or new trips with dialog]
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;
  const PostDetailsScreen({required this.postId, Key? key}) : super(key: key);

  @override
  State<PostDetailsScreen> createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
  int _selectedIndex = 0;

  void _onItemTapped(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pushReplacementNamed(context, '/main', arguments: index);
  }

  Future<void> _toggle(String field, List<dynamic> list, String postId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || postId.trim().isEmpty) return;
    final uid = user.uid;
    final ref = FirebaseFirestore.instance.collection('forum_posts').doc(postId);

    final updatedList = List<String>.from(list);
    if (updatedList.contains(uid)) {
      updatedList.remove(uid);
    } else {
      updatedList.add(uid);
    }

    await ref.update({field: updatedList});
  }

  void _saveGuideToTrip(String guideUrl) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final tripSnapshots = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .get();

    

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text("Save Guide To Trip"),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ...tripSnapshots.docs.map((doc) {
                final data = doc.data();
                return ListTile(

                  
                  leading: const Icon(Icons.folder),
                  title: Text(data['destination'] ?? 'Unnamed Trip'),
                  subtitle: Text((data['startDate'] as Timestamp?)?.toDate().toString().split(' ')[0] ?? ''),
                    onTap: () async {
                      final ref = FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('trips')
                          .doc(doc.id);

                      await ref.set({
                        'embeddedGuides': FieldValue.arrayUnion([guideUrl])
                      }, SetOptions(merge: true));

                      Navigator.pop(context);
                      await FirebaseFirestore.instance
                          .collection('forum_posts')
                          .doc(guideUrl) // this is postId
                          .update({
                            'saves': FieldValue.arrayUnion([uid])
                          });

                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Guide saved to trip and bookmarked!")),
                      );
                    }
                );
              }).toList(),
              const Divider(),
              ElevatedButton.icon(
                onPressed: () {
                  Navigator.pop(context);
                  Navigator.pushNamed(context, '/createTrip', arguments: {'guideUrl': guideUrl});
                },
                icon: const Icon(Icons.add),
                label: const Text("Create New Trip"),
              )

              
            ],
            
          ),
          
        ),
        
      ),
      
    );
  }

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(child: Image.network(imageUrl)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid ?? '';
    return Scaffold(
      appBar: AppBar(
        title: const Text('Guide Details', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
      ),
      body: StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('forum_posts')
            .doc(widget.postId)
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
          if (!snapshot.data!.exists) return const Center(child: Text('Post not found'));

          final postData = snapshot.data!.data() as Map<String, dynamic>;
          final likes = List<String>.from(postData['likes'] ?? []);
          final saves = List<String>.from(postData['saves'] ?? []);
          final imageUrl = postData['imageUrl'];
          final timestamp = postData['timestamp'] is Timestamp
              ? DateFormat.yMMMd().format((postData['timestamp'] as Timestamp).toDate())
              : '';
          final title = postData['title'] ?? '';
          final content = postData['content'] ?? '';
          final author = postData['author'] ?? 'Anonymous';

          return Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: Colors.brown[100],
                      child: Text(author[0].toUpperCase(), style: const TextStyle(color: Colors.white)),
                    ),
                    const SizedBox(width: 12),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(author, style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text(timestamp, style: const TextStyle(color: Colors.grey, fontSize: 12))
                      ],
                    )
                  ],
                ),
                const SizedBox(height: 16),
                Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                const SizedBox(height: 12),
                if (imageUrl != null && imageUrl.toString().startsWith('http'))
                  GestureDetector(
                    onTap: () => _showFullImage(imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Image.network(
                        imageUrl,
                        height: 220,
                        width: double.infinity,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 12),
                Text(content, style: const TextStyle(fontSize: 15)),
                const SizedBox(height: 20),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        likes.contains(uid) ? Icons.favorite : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () => _toggle('likes', likes, widget.postId),
                    ),
                    Text('${likes.length}'),
                    const SizedBox(width: 20),
                    IconButton(
                      icon: Icon(
                        saves.contains(uid) ? Icons.bookmark : Icons.bookmark_border,
                        color: Colors.brown,
                      ),
                    onPressed: () => _saveGuideToTrip(widget.postId),
                    ),
                    Text('${saves.length}'),
                    const Spacer(),
                    const Text('#guide', style: TextStyle(color: Colors.grey, fontSize: 12))
                  ],
                )
              ],
            ),
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
