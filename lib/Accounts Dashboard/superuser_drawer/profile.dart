import 'dart:io';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_dashboard.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final supabase = Supabase.instance.client;
  File? _image;
  String? _imageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = File(pickedFile.path);
      });
      await _uploadImage(pickedFile);
    }
  }

  Future<void> _fetchProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final fileName = 'profile_${user.uid}.jpg'; // Use Firebase UID
      final imageUrl =
          supabase.storage.from('profile-pictures').getPublicUrl(fileName);
      setState(() {
        _imageUrl = imageUrl;
      });
    }
  }

  Future<void> _uploadImage(XFile pickedFile) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      print("User is not authenticated");
      return;
    }

    try {
      final bytes = await pickedFile.readAsBytes();
      final fileExt = pickedFile.path.split('.').last;
      final fileName =
          'profile_${firebaseUser.uid}.$fileExt'; // Use Firebase UID

      await supabase.storage.from('profile-pictures').uploadBinary(
          fileName, bytes,
          fileOptions: const FileOptions(upsert: true) // Allow overwriting
          );

      final imageUrl =
          supabase.storage.from('profile-pictures').getPublicUrl(fileName);

      setState(() {
        _imageUrl = imageUrl;
      });

      print("Uploaded Image URL: $_imageUrl");
    } catch (e) {
      print("Error uploading image: $e");
    }
  }

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Spacer(),
        CircleAvatar(
          radius: MediaQuery.of(context).size.width / 17,
          backgroundColor: Colors.grey,
          backgroundImage: _imageUrl != null && _imageUrl!.isNotEmpty
              ? NetworkImage(_imageUrl!)
              : null,
          child: _imageUrl == null
              ? Icon(Icons.person,
                  size: MediaQuery.of(context).size.width / 12,
                  color: Colors.white)
              : null,
          // Only apply error handling if there is an image URL
          onBackgroundImageError: _imageUrl != null && _imageUrl!.isNotEmpty
              ? (_, __) {
                  setState(() {
                    _imageUrl = null; // Reset image if loading fails
                  });
                }
              : null,
        ),
        SizedBox(height: MediaQuery.of(context).size.width / 40),
        GestureDetector(
          onTap: _pickImage,
          child: Container(
            height: MediaQuery.of(context).size.width / 35,
            width: MediaQuery.of(context).size.width / 8,
            decoration: BoxDecoration(
              color: Color.fromARGB(255, 11, 55, 99),
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width / 150),
            ),
            child: Center(
              child: Text(
                "Edit Photo",
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width / 80,
                    color: Colors.white,
                    fontFamily: "R"),
              ),
            ),
          ),
        ).showCursorOnHover,
      ],
    );
  }
}
