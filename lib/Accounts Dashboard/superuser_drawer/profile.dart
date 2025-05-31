import 'dart:async';
import 'dart:io';
import 'dart:typed_data';
import 'package:attendance_app/hover_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:ftpconnect/ftpconnect.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  final supabase = Supabase.instance.client;
  File? _image;
  String? _imageUrl;
  
  // FTP connection details
  final String _ftpHost = '202.57.47.34';
  final String _ftpUser = 'att_app';
  final String _ftpPass = 'ragMANOK2kx@dci';
  final String _ftpDirectory = '/profiles/';

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(source: ImageSource.gallery);

    if (pickedFile != null) {
      setState(() {
        _image = null;
      });

      await _uploadImageToFtp(pickedFile);
    }
  }

  // Upload image to FTP server
  Future<void> _uploadImageToFtp(XFile pickedFile) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      // Show loading indicator
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Uploading image to server...")),
      );

      // Create FTP connection
      final FTPConnect ftpConnect = FTPConnect(
        _ftpHost,
        user: _ftpUser,
        pass: _ftpPass,
        timeout: 30,
      );
      
      // Connect to the FTP server
      await ftpConnect.connect();
      
      // Change to the target directory
      await ftpConnect.changeDirectory(_ftpDirectory);
      
      // Generate filename based on user ID
      final fileName = '${user.uid}.jpg';
      
      if (kIsWeb) {
        // For web: create a temporary file from bytes
        final bytes = await pickedFile.readAsBytes();
        
        // Since we can't directly write to a file on web,
        // we need to upload the bytes directly
        await _uploadBytesToFtp(ftpConnect, bytes, fileName);
      } else {
        // For mobile: upload the file directly
        final file = File(pickedFile.path);
        final result = await ftpConnect.uploadFile(file, sRemoteName: fileName);
        
        if (result) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("✅ Uploaded successfully!")),
          );
          _fetchProfileImage();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("❌ Upload failed")),
          );
        }
      }
      
      // Always disconnect when done
      await ftpConnect.disconnect();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("❌ Error: $e")),
      );
    }
  }
  
  // Helper method to upload bytes on web
  Future<void> _uploadBytesToFtp(FTPConnect ftpConnect, Uint8List bytes, String fileName) async {
    if (!kIsWeb) {
      // For non-web platforms, create a temporary file
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/$fileName');
      await tempFile.writeAsBytes(bytes);
      
      final result = await ftpConnect.uploadFile(tempFile, sRemoteName: fileName);
      
      if (result) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("✅ Uploaded successfully!")),
        );
        _fetchProfileImage();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("❌ Upload failed")),
        );
      }
      
      // Delete temporary file
      await tempFile.delete();
    } else {
      // For web, we'd need a different approach since ftpconnect
      // might not work correctly on web. Consider a server-side relay
      // or an API that handles the FTP upload.
      
      // This is a placeholder for web implementation
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("⚠️ Web FTP uploads require a server-side relay")),
      );
    }
  }

  Future<void> _fetchProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    // Update to point to your FTP server
    // You'll need a web server to access these files - FTP is not for serving files
    final imageUrl = 'http://202.57.47.34/profiles/${user.uid}.jpg';

    setState(() {
      _imageUrl = "$imageUrl?t=${DateTime.now().millisecondsSinceEpoch}";
    });
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
          child: _imageUrl == null || _imageUrl!.isEmpty
              ? Icon(
                  Icons.person,
                  size: MediaQuery.of(context).size.width / 12,
                  color: Colors.white,
                )
              : ClipOval(
                  child: Image.network(
                    _imageUrl!,
                    fit: BoxFit.cover,
                    width: MediaQuery.of(context).size.width / 8 * 2,
                    height: MediaQuery.of(context).size.width / 8 * 2,
                    errorBuilder: (context, error, stackTrace) {
                      return Icon(
                        Icons.person,
                        size: MediaQuery.of(context).size.width / 12,
                        color: Colors.white,
                      );
                    },
                  ),
                ),
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