import 'dart:async';
import 'dart:io';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_dashboard.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'dart:typed_data';

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
      _image = null; // Flutter Web doesn't support File, so don't store it
    });

    // ✅ Pass `pickedFile` directly to upload function
    await _uploadImage(pickedFile);
  }
}

  Future<void> _fetchProfileImage() async {
  final user = FirebaseAuth.instance.currentUser;
  if (user == null) return;

  final filePrefix = 'profile_${user.uid}'; // Match all files starting with this
  final response = await supabase.storage.from('profile-pictures').list();

  FileObject? userFile;
  try {
    userFile = response.firstWhere((file) => file.name.startsWith(filePrefix));
  } catch (e) {
    userFile = null; // Handle case where no file is found
  }

  if (userFile != null) {
    String imageUrl = supabase.storage.from('profile-pictures').getPublicUrl(userFile.name);

    // 🛠️ Ensure URL does NOT contain an extra ":http:"
    if (imageUrl.contains(':http:')) {
      imageUrl = imageUrl.replaceAll(':http:', ''); // Fix malformed URL
    }

    // 🔄 Add timestamp to force refresh
    final timestamp = DateTime.now().millisecondsSinceEpoch;
    imageUrl = "$imageUrl?t=$timestamp";

    setState(() {
      _imageUrl = imageUrl;
    });

    print("✅ Fixed Profile Image URL: $_imageUrl");
  } else {
    print("❌ No profile image found for user: ${user.uid}");
  }
}


  Future<void> _uploadImage(XFile pickedFile) async {
  final firebaseUser = FirebaseAuth.instance.currentUser;
  if (firebaseUser == null) {
    print("❌ User is not authenticated");
    return;
  }

  try {
    // ✅ Read the image as bytes (Works on Flutter Web & Mobile)
    Uint8List bytes = await pickedFile.readAsBytes();

    // ✅ Extract file extension correctly
    String fileExt = pickedFile.name.split('.').last;
    String fileName = 'profile_${firebaseUser.uid}.$fileExt';

    // ✅ Determine MIME type properly
    String mimeType = "image/$fileExt";
    if (fileExt == "jpg") mimeType = "image/jpeg"; // Special case for JPG

    await supabase.storage.from('profile-pictures').uploadBinary(
      fileName, 
      bytes,
      fileOptions: FileOptions(upsert: true, contentType: mimeType),
    );

    print("✅ Image uploaded successfully: $fileName");

    // 🔄 Fetch latest profile image
    await _fetchProfileImage();
  } catch (e) {
    print("❌ Error uploading image: $e");
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
