import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';

class EditPostScreen extends StatefulWidget {
  final String postId;
  final Map<String, dynamic> postData;

  const EditPostScreen({required this.postId, required this.postData});

  @override
  State<EditPostScreen> createState() => _EditPostScreenState();
}

class _EditPostScreenState extends State<EditPostScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _contentController;
  File? _newImage;
  bool _isUploading = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.postData['title']);
    _contentController = TextEditingController(text: widget.postData['content']);
  }

  Future<void> _pickNewImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(source: ImageSource.gallery);
    if (picked != null) {
      setState(() => _newImage = File(picked.path));
    }
  }

  Future<String?> _uploadImage(File file) async {
    final ref = FirebaseStorage.instance
        .ref()
        .child('forum_images/${widget.postId}.jpg');
    await ref.putFile(file);
    return await ref.getDownloadURL();
  }

  Future<void> _submitChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isUploading = true);

    String? imageUrl = widget.postData['imageUrl'];
    if (_newImage != null) {
      imageUrl = await _uploadImage(_newImage!);
    }

    await FirebaseFirestore.instance.collection('forum_posts').doc(widget.postId).update({
      'title': _titleController.text.trim(),
      'content': _contentController.text.trim(),
      'imageUrl': imageUrl,
    });

    setState(() => _isUploading = false);
    Navigator.pop(context);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Post updated successfully!')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Edit Post')),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              if (_newImage != null)
                Image.file(_newImage!, height: 200, fit: BoxFit.cover)
              else if (widget.postData['imageUrl'] != null)
                Image.network(widget.postData['imageUrl'], height: 200, fit: BoxFit.cover),
              TextButton.icon(
                onPressed: _pickNewImage,
                icon: Icon(Icons.image),
                label: Text('Change Image'),
              ),
              TextFormField(
                controller: _titleController,
                decoration: InputDecoration(labelText: 'Title'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Title required' : null,
              ),
              SizedBox(height: 12),
              TextFormField(
                controller: _contentController,
                maxLines: 5,
                decoration: InputDecoration(labelText: 'Content'),
                validator: (val) => val == null || val.trim().isEmpty ? 'Content required' : null,
              ),
              SizedBox(height: 24),
              _isUploading
                  ? CircularProgressIndicator()
                  : ElevatedButton.icon(
                      onPressed: _submitChanges,
                      icon: Icon(Icons.save),
                      label: Text('Save Changes'),
                    )
            ],
          ),
        ),
      ),
    );
  }
}
