import 'dart:async';
import 'dart:io';
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

  // The `_pickImage` method is responsible for allowing the user to pick an image from their device's gallery using the ImagePicker package.
// It begins by creating an instance of the `ImagePicker` class and then triggers the `pickImage` method, which opens the gallery for the user to select an image.
// If the user selects a file (i.e., `pickedFile` is not null), the method first clears any previously stored image by setting `_image` to null.
// This is a workaround for Flutter Web, as it does not support storing a `File` object directly.
// The method then calls the `_uploadImage` function, passing the selected `pickedFile` as an argument, which handles the process of uploading the image to a cloud storage provider like Supabase.
// If no image is selected (i.e., `pickedFile` is null), the method does nothing and simply exits.
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

  // The `_fetchProfileImage` method is responsible for fetching the profile image of the currently authenticated user from Supabase storage.
// The method starts by checking if a user is authenticated via FirebaseAuth. If no user is logged in, it returns early without any further action.
// It constructs a `filePrefix` based on the user's UID, ensuring that only files related to the user's profile image are considered.
// The method then retrieves a list of all files in the 'profile-pictures' storage bucket on Supabase and tries to find the user's file by matching the prefix of the file name.
// If a matching file is found, it constructs the public URL for the image using `getPublicUrl` and ensures the URL is properly formatted, fixing any malformed parts (e.g., the ":http:" issue).
// To force the browser to refresh the image (avoiding cached versions), a timestamp is added as a query parameter to the URL.
// Finally, the method updates the state with the new image URL, which will cause the UI to reload and display the latest profile image.
// If no file is found for the user, a SnackBar is shown to inform the user that no profile image was found.
  Future<void> _fetchProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    final filePrefix =
        'profile_${user.uid}'; // Match all files starting with this
    final response = await supabase.storage.from('profile-pictures').list();

    FileObject? userFile;
    try {
      userFile =
          response.firstWhere((file) => file.name.startsWith(filePrefix));
    } catch (e) {
      userFile = null; // Handle case where no file is found
    }

    if (userFile != null) {
      String imageUrl =
          supabase.storage.from('profile-pictures').getPublicUrl(userFile.name);

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
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('No Profile Image Found for user')));
    }
  }

  // The `_uploadImage` method is responsible for uploading the selected image file to a cloud storage service (in this case, Supabase).
// The method starts by verifying that the user is authenticated by checking the current Firebase user.
// If the user is not logged in, the method simply returns without performing any actions.
// It then reads the image file as bytes and extracts the file extension and MIME type to ensure the image is properly formatted for upload.
// The file name is generated dynamically using the user's UID to ensure the file is unique and associated with the correct user.
// The method proceeds to upload the image file to the 'profile-pictures' storage bucket on Supabase, using the `uploadBinary` function.
// The file is uploaded with specific options, such as allowing updates to the file if it already exists and setting the correct content type based on the file extension.
// After the image upload completes, the method calls `_fetchProfileImage()` to refresh and display the latest profile image for the user.
// If any errors occur during this process, a SnackBar is displayed to inform the user of the issue.
  Future<void> _uploadImage(XFile pickedFile) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) {
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

      // 🔄 Fetch latest profile image
      await _fetchProfileImage();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

// the `_fetchProfileImage()` method, which is responsible for fetching the user's
// profile image from a storage or backend (such as Firebase). By placing the
// `_fetchProfileImage()` call here, it ensures that the profile image is loaded
// as soon as the widget is initialized, providing a smooth user experience.
// The widget will then update the UI once the image URL is fetched, allowing
// the profile image to be displayed to the user.
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
          // This will Trigger the _pickImage Method
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
