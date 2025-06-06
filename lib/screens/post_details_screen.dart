import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import 'trip_details_screen.dart';

class PostDetailsScreen extends StatefulWidget {
  final String postId;

  const PostDetailsScreen({required this.postId, Key? key}) : super(key: key);

  @override
  _PostDetailsScreenState createState() => _PostDetailsScreenState();
}

class _PostDetailsScreenState extends State<PostDetailsScreen> {
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

  void _showFullImage(String imageUrl) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: InteractiveViewer(
          child: Image.network(imageUrl),
        ),
      ),
    );
  }

  Future<void> _showTripSaveDialog(String guideUrl) async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final tripsSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('trips')
        .orderBy('startDate')
        .get();

    final existingTrips = tripsSnapshot.docs;
    String? selectedTripId;
    String newTripName = '';
    DateTime? startDate;
    DateTime? endDate;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: const Text('Add Guide to Trip'),
              content: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'You\'ll be able to download the guide from your profile after adding it to a trip.',
                      style: TextStyle(fontSize: 13, color: Colors.grey),
                    ),
                    const SizedBox(height: 12),
                    if (existingTrips.isNotEmpty)
                      DropdownButtonFormField<String>(
                        hint: const Text('Select an existing trip'),
                        items: existingTrips.map((doc) {
                          return DropdownMenuItem(
                            value: doc.id,
                            child: Text(doc['destination'] ?? 'Unnamed Trip'),
                          );
                        }).toList(),
                        onChanged: (value) => selectedTripId = value,
                      )
                    else
                      const Text('No existing trips found. You can create a new one.'),
                    const SizedBox(height: 20),
                    const Divider(),
                    const Text('Create New Trip', style: TextStyle(fontWeight: FontWeight.bold)),
                    TextField(
                      decoration: const InputDecoration(labelText: 'Trip Name'),
                      onChanged: (value) => newTripName = value,
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(startDate == null
                                ? 'Start Date'
                                : DateFormat.yMMMd().format(startDate!)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => startDate = picked);
                              }
                            },
                          ),
                        ),
                        Expanded(
                          child: TextButton.icon(
                            icon: const Icon(Icons.date_range),
                            label: Text(endDate == null
                                ? 'End Date'
                                : DateFormat.yMMMd().format(endDate!)),
                            onPressed: () async {
                              final picked = await showDatePicker(
                                context: context,
                                initialDate: DateTime.now(),
                                firstDate: DateTime(2020),
                                lastDate: DateTime(2100),
                              );
                              if (picked != null) {
                                setState(() => endDate = picked);
                              }
                            },
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (selectedTripId != null && selectedTripId!.trim().isNotEmpty) {
                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('trips')
                          .doc(selectedTripId)
                          .update({
                        'embeddedGuides': FieldValue.arrayUnion([widget.postId]),
                      });
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('Guide added to existing trip!')),
                      );
                    } else if (newTripName.trim().isNotEmpty) {
                      if (startDate == null || endDate == null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Please select start and end dates.')),
                        );
                        return;
                      }

                      await FirebaseFirestore.instance
                          .collection('users')
                          .doc(uid)
                          .collection('trips')
                          .add({
                        'destination': newTripName.trim(),
                        'startDate': startDate,
                        'endDate': endDate,
                        'embeddedGuides': [widget.postId],
                      });

                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text('New trip created with guide!')),
                      );
                    }
                  },
                  child: const Text('Save Trip'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    final uid = user?.uid ?? '';

    return Scaffold(
      appBar: AppBar(),
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
              ? DateFormat.yMMMMd().add_jm().format(
                  (postData['timestamp'] as Timestamp).toDate())
              : '';
          final title = postData['title'] ?? '';
          final content = postData['content'] ?? '';
          final guideDownloadUrl = postData['guideDownloadUrl'] ?? '';

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('by ${postData['author'] ?? 'Anonymous'}',
                    style: TextStyle(color: Colors.grey[600])),
                if (timestamp.isNotEmpty)
                  Text(timestamp,
                      style: TextStyle(color: Colors.grey[500], fontSize: 12)),
                const SizedBox(height: 16),
                Text(content, style: const TextStyle(fontSize: 16)),
                const SizedBox(height: 16),
                if (imageUrl != null && imageUrl.toString().startsWith('http'))
                  GestureDetector(
                    onTap: () => _showFullImage(imageUrl),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(10),
                      child: Image.network(
                        imageUrl,
                        width: double.infinity,
                        height: 220,
                        fit: BoxFit.cover,
                      ),
                    ),
                  ),
                const SizedBox(height: 16),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      icon: Icon(
                        likes.contains(uid)
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: Colors.red,
                      ),
                      onPressed: () => _toggle('likes', likes, widget.postId),
                    ),
                    Text('${likes.length}'),
                    IconButton(
                      icon: Icon(
                        saves.contains(uid)
                            ? Icons.bookmark
                            : Icons.bookmark_border,
                        color: Colors.blueGrey,
                      ),
                      onPressed: () async {
                        await _toggle('saves', saves, widget.postId);
                        _showTripSaveDialog(guideDownloadUrl);
                      },
                    ),
                    Text('${saves.length}'),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
