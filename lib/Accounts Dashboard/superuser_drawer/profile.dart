import 'dart:async';
import 'dart:io';
import 'package:attendance_app/hover_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:provider/provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/profileimagenotifier.dart';
import 'package:attendance_app/services/gdrive_service.dart';

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  File? _image;
  String? _imageUrl;

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = null; // Flutter Web doesn't support File, so don't store it
      });

      await _uploadImage(pickedFile);
    }
  }

  Future<void> _fetchProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final imageUrl = await GDriveService.getProfileImageUrl(user.uid);

      if (imageUrl != null) {
        setState(() {
          _imageUrl = imageUrl;
        });

        // Notify all listeners (including super_user_dashboard.dart)
        Provider.of<ProfileImageNotifier>(context, listen: false)
            .updateImageUrl(_imageUrl);
      }
    } catch (e) {
      print('Error fetching profile image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error fetching profile image: $e')),
      );
    }
  }

  Future<void> _uploadImage(XFile pickedFile) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
      return;
    }

    try {
      final imageUrl =
          await GDriveService.uploadProfileImage(pickedFile, firebaseUser.uid);

      setState(() {
        _imageUrl = imageUrl;
      });

      // Notify all listeners
      Provider.of<ProfileImageNotifier>(context, listen: false)
          .updateImageUrl(_imageUrl);

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Profile image updated successfully')),
      );
    } catch (e) {
      print('Error uploading image: $e');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error uploading image: $e')),
      );
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
          child: _imageUrl == null || _imageUrl!.isEmpty
              ? Icon(Icons.person,
                  size: MediaQuery.of(context).size.width / 12,
                  color: Colors.white)
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
