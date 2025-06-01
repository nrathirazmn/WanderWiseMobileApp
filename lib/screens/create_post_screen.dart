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
  File? _selectedGuide;
  bool _isUploading = false;
  bool _isDraft = false;
  String? _previewImageUrl;
  String _category = 'explore';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() {
        _selectedImage = File(picked.path);
        _previewImageUrl = null;
      });
    }
  }

  Future<void> _pickGuideFile() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery); // can switch to file picker for PDFs
    if (picked != null) {
      setState(() {
        _selectedGuide = File(picked.path);
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

  void _submitPost({bool isDraft = false}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || _titleController.text.trim().isEmpty) return;

    setState(() => _isUploading = true);

    String? imageUrl;
    String? guideUrl;

    if (_selectedImage != null) {
      imageUrl = await _uploadToCloudinary(_selectedImage!, 'forum_photos/');
    }

    if (_selectedGuide != null) {
      guideUrl = await _uploadToCloudinary(_selectedGuide!, 'travel_guides/');
    }

    final post = {
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'author': user.displayName?.isNotEmpty == true ? user.displayName : user.email ?? 'Anonymous',
      'likes': [],
      'saves': [],
      'timestamp': FieldValue.serverTimestamp(),
      'imageUrl': imageUrl,
      'guideDownloadUrl': guideUrl ?? '',
      'isDraft': isDraft,
      'category': _category,
    };

    await FirebaseFirestore.instance.collection('forum_posts').add(post);

    setState(() => _isUploading = false);
    Navigator.pop(context);
  }

  void _previewImage() async {
    if (_selectedImage != null) {
      setState(() => _isUploading = true);
      final previewUrl = await _uploadToCloudinary(_selectedImage!, 'forum_photos/');
      setState(() {
        _previewImageUrl = previewUrl;
        _isUploading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Create Post')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (_selectedImage != null)
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: Image.file(
                      _selectedImage!,
                      height: 200,
                      width: double.infinity,
                      fit: BoxFit.cover,
                    ),
                  ),
                if (_previewImageUrl != null)
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 16),
                      Text('Preview Image:', style: TextStyle(fontWeight: FontWeight.bold)),
                      SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(10),
                        child: Image.network(
                          _previewImageUrl!,
                          height: 200,
                          width: double.infinity,
                          fit: BoxFit.cover,
                        ),
                      ),
                    ],
                  ),
                Center(
                  child: Wrap(
                    spacing: 12,
                    children: [
                      TextButton.icon(
                        onPressed: _pickImage,
                        icon: Icon(Icons.image),
                        label: Text('Upload Image'),
                      ),
                      TextButton.icon(
                        onPressed: _previewImage,
                        icon: Icon(Icons.preview),
                        label: Text('Preview'),
                      ),
                      TextButton.icon(
                        onPressed: _pickGuideFile,
                        icon: Icon(Icons.picture_as_pdf),
                        label: Text('Upload Guide (Optional)'),
                      ),
                    ],
                  ),
                ),
                if (_selectedGuide != null)
                  Text("Selected guide: ${_selectedGuide!.path.split('/').last}", style: TextStyle(color: Colors.grey[700])),
                SizedBox(height: 16),
                TextField(
                  controller: _titleController,
                  decoration: InputDecoration(
                    labelText: 'Title',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                TextField(
                  controller: _contentController,
                  maxLines: 5,
                  decoration: InputDecoration(
                    labelText: 'Content',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 16),
                DropdownButtonFormField<String>(
                  value: _category,
                  items: [
                    DropdownMenuItem(value: 'explore', child: Text('Places to Explore')),
                    DropdownMenuItem(value: 'guide', child: Text('User Guide and Experience')),
                  ],
                  onChanged: (value) => setState(() => _category = value!),
                  decoration: InputDecoration(
                    labelText: 'Category',
                    border: OutlineInputBorder(),
                  ),
                ),
                SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: _isUploading
                      ? Center(child: CircularProgressIndicator())
                      : Column(
                          children: [
                            ElevatedButton.icon(
                              icon: Icon(Icons.send),
                              label: Text('Post'),
                              onPressed: () => _submitPost(isDraft: false),
                              style: ElevatedButton.styleFrom(
                                padding: EdgeInsets.symmetric(vertical: 16),
                              ),
                            ),
                            SizedBox(height: 10),
                            OutlinedButton.icon(
                              icon: Icon(Icons.save_alt),
                              label: Text('Save as Draft'),
                              onPressed: () => _submitPost(isDraft: true),
                            ),
                          ],
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
