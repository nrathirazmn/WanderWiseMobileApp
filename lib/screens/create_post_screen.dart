import 'dart:io';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:image_picker/image_picker.dart';
import 'package:http/http.dart' as http;
import 'package:uuid/uuid.dart';

class CreatePostScreen extends StatefulWidget {
  @override
  _CreatePostScreenState createState() => _CreatePostScreenState();
}

class _CreatePostScreenState extends State<CreatePostScreen> {
  final _titleController = TextEditingController();
  final _contentController = TextEditingController();
  File? _selectedImage;
  bool _isUploading = false;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
      });
    }
  }

  Future<String?> _uploadToCloudinary(File file, String folder) async {
    final cloudName = 'dfi03udz5';
    final uploadPreset = 'wanderwise_unsigned';
    final fileName = const Uuid().v4();

    final url = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/image/upload');

    final request = http.MultipartRequest('POST', url)
      ..fields['upload_preset'] = uploadPreset
      ..fields['folder'] = folder
      ..files.add(await http.MultipartFile.fromPath('file', file.path, filename: '$fileName.jpg'));

    final response = await request.send();
    final result = await http.Response.fromStream(response);

    if (response.statusCode == 200) {
      final data = jsonDecode(result.body);
      return data['secure_url'];
    } else {
      print('Cloudinary upload failed: ${result.body}');
      return null;
    }
  }

  void _submitPost() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _contentController.text.trim().isEmpty) return;

    setState(() => _isUploading = true);

    String? imageUrl;
    if (_selectedImage != null) {
      imageUrl = await _uploadToCloudinary(_selectedImage!, 'forum_photos/');
    }

    final userDoc = await FirebaseFirestore.instance.collection('users').doc(user.uid).get();
    final userData = userDoc.data();
    final authorName = userData?['name'] ?? user.displayName ?? user.email ?? 'Anonymous';
    final authorPhoto = userData?['photoUrl'];

    final post = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'author': authorName,
      'authorPhoto': authorPhoto,
      'authorId': user.uid,
      'likes': [],
      'saves': [],
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
    };

    await FirebaseFirestore.instance.collection('forum_posts').add(post);

    setState(() => _isUploading = false);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Your post has been published!'),
        // backgroundColor: Colors.transparent,
      ),
    );

    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        automaticallyImplyLeading: false,
        backgroundColor: Colors.white,
        elevation: 0,
        title: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Row(
                children: const [
                  Icon(Icons.arrow_back, color: Colors.black),
                  SizedBox(width: 4),
                  Text('Create Post', style: TextStyle(color: Colors.black, fontWeight: FontWeight.bold)),
                ],
              ),
            ),
            if (!_isUploading)
              TextButton(
                onPressed: _submitPost,
                style: TextButton.styleFrom(shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20))),
                child: Text('Post', style: TextStyle(color: Colors.brown, fontWeight: FontWeight.w600)),
              ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  backgroundColor: Colors.brown.shade100,
                  backgroundImage: FirebaseAuth.instance.currentUser?.photoURL != null
                      ? NetworkImage(FirebaseAuth.instance.currentUser!.photoURL!)
                      : null,
                  radius: 24,
                  child: FirebaseAuth.instance.currentUser?.photoURL == null
                      ? Icon(Icons.person, color: Colors.white)
                      : null,
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      TextField(
                        controller: _titleController,
                        decoration: InputDecoration(
                          hintText: "Post title",
                          border: InputBorder.none,
                        ),
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      SizedBox(height: 4),
                      TextField(
                        controller: _contentController,
                        maxLines: null,
                        decoration: InputDecoration(
                          hintText: "Share some thoughts...",
                          border: InputBorder.none,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                IconButton(icon: Icon(Icons.image), onPressed: _pickImage),
                SizedBox(width: 4),
                Text("Add Image", style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
              ],
            ),
            Padding(
              padding: const EdgeInsets.only(left: 60),
              child: Text("🌍 #TravelTips ✈️ #WanderLog 🏞 #HiddenGems", style: TextStyle(color: Colors.grey.shade600, fontSize: 12)),
            ),
            if (_selectedImage != null)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.file(
                    _selectedImage!,
                    height: 180,
                    width: double.infinity,
                    fit: BoxFit.cover,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
