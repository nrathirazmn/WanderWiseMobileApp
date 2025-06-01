// PostDetailsScreen (full code)
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';

class PostDetailsScreen extends StatelessWidget {
  final String postId;
  final DocumentSnapshot postData;

  const PostDetailsScreen({required this.postId, required this.postData});

  Future<void> _toggle(String type, bool isActive) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;
    final uid = user.uid;
    final ref = FirebaseFirestore.instance.collection('forum_posts').doc(postId);

    await ref.update({
      type: isActive ? FieldValue.arrayRemove([uid]) : FieldValue.arrayUnion([uid])
    });
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    final likes = List<String>.from(postData['likes']);
    final saves = List<String>.from(postData['saves']);
    final isLiked = likes.contains(uid);
    final isSaved = saves.contains(uid);

    return Scaffold(
      appBar: AppBar(title: Text(postData['title'] ?? 'Post')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (postData['imageUrl'] != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(10),
                child: Image.network(postData['imageUrl'], fit: BoxFit.cover),
              ),
            SizedBox(height: 16),
            Text(postData['content'] ?? '', style: TextStyle(fontSize: 16)),
            SizedBox(height: 16),
            Row(
              children: [
                IconButton(
                  icon: Icon(isLiked ? Icons.favorite : Icons.favorite_border),
                  onPressed: () => _toggle('likes', isLiked),
                ),
                IconButton(
                  icon: Icon(isSaved ? Icons.bookmark : Icons.bookmark_border),
                  onPressed: () => _toggle('saves', isSaved),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ProfileSavedPostsScreen (shows liked & saved posts)
class ProfileSavedPostsScreen extends StatelessWidget {
  final bool showSaved; // true = saved, false = liked

  const ProfileSavedPostsScreen({Key? key, required this.showSaved}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    final query = FirebaseFirestore.instance
        .collection('forum_posts')
        .where(showSaved ? 'saves' : 'likes', arrayContains: uid);

    return Scaffold(
      appBar: AppBar(
        title: Text(showSaved ? 'Saved Posts' : 'Liked Posts'),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: query.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return Center(child: CircularProgressIndicator());
          }

          final posts = snapshot.data!.docs;

          if (posts.isEmpty) {
            return Center(child: Text('No posts to display.'));
          }

          return ListView.builder(
            itemCount: posts.length,
            itemBuilder: (context, index) {
              final data = posts[index].data() as Map<String, dynamic>;
              final postId = posts[index].id;

              return ListTile(
                leading: data['imageUrl'] != null
                    ? Image.network(data['imageUrl'], width: 50, fit: BoxFit.cover)
                    : Icon(Icons.article),
                title: Text(data['title'] ?? 'Untitled'),
                subtitle: Text(
                  (() {
                    final content = (data['content'] ?? '').toString();
                    return content.length > 50 ? content.substring(0, 50) + '...' : content;
                  })(),
                ),
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PostDetailsScreen(postId: postId, postData: posts[index]),
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
