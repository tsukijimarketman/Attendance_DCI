import 'dart:async';
import 'package:attendance_app/hover_extensions.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:image_picker/image_picker.dart';
import 'dart:typed_data';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:dio/dio.dart'; // Add Dio for better HTTP handling

// Conditionally import dart:io based on platform
import 'dart:io' if (dart.library.html) 'dart:html' as html;

// Define a global stream controller for profile image updates
final StreamController<String?> profileImageUpdateController = StreamController<String?>.broadcast();

class Profile extends StatefulWidget {
  const Profile({super.key});

  @override
  State<Profile> createState() => _ProfileState();
}

class _ProfileState extends State<Profile> {
  String? _imageUrl;
  bool _isUploading = false;
  bool _isLoading = true; // Track image loading state
  bool _isDisposed = false; // Track disposed state
  StreamSubscription? _profileImageSubscription;
  final Dio _dio = Dio(); // Initialize Dio for HTTP requests

  /// Allows the user to pick an image from the gallery
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final pickedFile = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );

    if (pickedFile != null) {
      setState(() {
        _isUploading = true;
      });

      // Pass pickedFile directly to upload function
      await _uploadImage(pickedFile);
      
      // Refresh the profile image immediately after upload
      await _refreshProfileImage();
      
      setState(() {
        _isUploading = false;
      });
    }
  }

  /// Uploads the selected image to company's API using Dio for better error handling
  Future<void> _uploadImage(XFile pickedFile) async {
    final firebaseUser = FirebaseAuth.instance.currentUser;
    if (firebaseUser == null) return;

    try {
      debugPrint('Starting upload process');
      
      // Read the image as bytes
      Uint8List bytes = await pickedFile.readAsBytes();

      // Extract file extension and ensure it's valid
      String originalExt = pickedFile.name.split('.').last.toLowerCase();
      
      // Validate file extension
      List<String> validExtensions = ['png', 'jpg', 'jpeg', 'jfif'];
      String fileExt = validExtensions.contains(originalExt) 
          ? originalExt 
          : 'jpg'; // Default to jpg if invalid

      // Create filename with user ID and appropriate extension
      String fileName = 'profile_${firebaseUser.uid}.$fileExt';
      
      debugPrint('Uploading with filename: $fileName');
      String uploadEndpoint = '${ProfileImageUtil.baseApiUrl}/uploadprofiles';
      debugPrint('To endpoint: $uploadEndpoint');

      // Create FormData for Dio
      FormData formData = FormData.fromMap({
        "file": MultipartFile.fromBytes(
          bytes,
          filename: fileName,
        ),
      });

      // Try two different approaches for uploading
      try {
        // Approach 1: Using Dio
        var dioResponse = await _dio.post(
          uploadEndpoint,
          data: formData,
          options: Options(
            headers: {
              "Content-Type": "multipart/form-data",
            },
            receiveTimeout: const Duration(seconds: 30),
            sendTimeout: const Duration(seconds: 30),
          ),
        );
        
        debugPrint('Dio upload response: ${dioResponse.statusCode} - ${dioResponse.data}');
        
        if (dioResponse.statusCode == 200 || dioResponse.statusCode == 201) {
          if (!_isDisposed) {
            // Update image timestamp to trigger cache refresh
            await _saveProfileUpdateTimestamp();
            
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile picture updated successfully')));
          }
          return; // Success! No need to try the second approach
        }
      } catch (dioError) {
        debugPrint('Dio upload error: $dioError');
        // Continue to the next approach
      }

      // Approach 2: Using http package with more detailed logging
      try {
        // Create a multipart request
        String uploadEndpoint = '${ProfileImageUtil.baseApiUrl}/uploadprofiles';
        var request = http.MultipartRequest('POST', Uri.parse(uploadEndpoint));
        
        // Add the file to the request
        request.files.add(http.MultipartFile.fromBytes(
          'file', // This name must match what the API expects
          bytes,
          filename: fileName,
        ));

        // Print request details for debugging
        debugPrint('http request headers: ${request.headers}');
        debugPrint('http request fields: ${request.fields}');
        debugPrint('http request files: ${request.files.length} files');

        // Send the request with extended timeout
        var response = await request.send().timeout(const Duration(seconds: 30));
        var responseBody = await response.stream.bytesToString();
        
        debugPrint('http upload status code: ${response.statusCode}');
        debugPrint('http upload response: $responseBody');

        if (response.statusCode == 200 || response.statusCode == 201) {
          if (!_isDisposed) {
            // Update image timestamp to trigger cache refresh
            await _saveProfileUpdateTimestamp();
            
            ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Profile picture updated successfully')));
          }
        } else {
          if (!_isDisposed) {
            ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(content: Text('Failed to upload: ${response.statusCode} - $responseBody')));
          }
        }
      } catch (httpError) {
        debugPrint('http upload error: $httpError');
        if (!_isDisposed) {
          ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text("Upload failed: $httpError")));
        }
      }
    } catch (e) {
      debugPrint('General error uploading image: $e');
      if (!_isDisposed) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text("Error uploading image: $e")));
      }
    }
  }

  /// Refreshes the profile image after upload
  Future<void> _refreshProfileImage() async {
    setState(() {
      _isLoading = true;
    });
    
    final imageUrl = await ProfileImageUtil.fetchProfileImage();
    
    if (!_isDisposed) {
      setState(() {
        _imageUrl = imageUrl;
        _isLoading = false;
      });
    }
  }

  /// Saves the current timestamp when profile was updated
  Future<void> _saveProfileUpdateTimestamp() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      await prefs.setInt('profile_image_timestamp', timestamp);
    } catch (e) {
      debugPrint('Error saving profile update timestamp: $e');
    }
  }

  @override
  void dispose() {
    _isDisposed = true;
    _profileImageSubscription?.cancel();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    // Fetch image on initialization
    _refreshProfileImage();
    
    // Set up listener for profile image updates
    _profileImageSubscription = profileImageUpdateController.stream.listen((imageUrl) {
      if (!_isDisposed) {
        setState(() {
          _imageUrl = imageUrl;
          _isLoading = false;
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Spacer(),
        Stack(
          alignment: Alignment.center,
          children: [
            // Profile image with error handling
            FutureBuilder<bool>(
              // Check API connectivity first
              future: ProfileImageUtil.testApiConnection(),
              builder: (context, snapshot) {
                // If we're still checking connectivity
                if (!snapshot.hasData) {
                  return _buildLoadingAvatar();
                }
                
                // If server is unreachable
                if (snapshot.data == false) {
                  return _buildErrorAvatar(Icons.cloud_off, "Server unreachable");
                }
                
                // If server is reachable but we don't have an image URL yet
                if (_imageUrl == null || _imageUrl!.isEmpty) {
                  if (_isLoading) {
                    return _buildLoadingAvatar();
                  } else {
                    return _buildDefaultAvatar();
                  }
                }
                
                // If we have an image URL, try to load it
                return _buildProfileAvatar();
              },
            ),
            if (_isUploading)
              Container(
                width: MediaQuery.of(context).size.width / 17 * 2,
                height: MediaQuery.of(context).size.width / 17 * 2,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: CircularProgressIndicator(
                    color: Colors.white,
                    strokeWidth: 2.0,
                  ),
                ),
              ),
          ],
        ),
        SizedBox(height: MediaQuery.of(context).size.width / 40),
        GestureDetector(
          onTap: _isUploading ? null : _pickImage,
          child: Container(
            height: MediaQuery.of(context).size.width / 35,
            width: MediaQuery.of(context).size.width / 8,
            decoration: BoxDecoration(
              color: _isUploading 
                ? Colors.grey
                : const Color.fromARGB(255, 11, 55, 99),
              borderRadius: BorderRadius.circular(
                  MediaQuery.of(context).size.width / 150),
            ),
            child: Center(
              child: Text(
                _isUploading ? "Uploading..." : "Edit Photo",
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
  
  // Helper methods for avatar states
  Widget _buildLoadingAvatar() {
    return CircleAvatar(
      radius: MediaQuery.of(context).size.width / 17,
      backgroundColor: Colors.grey[300],
      child: CircularProgressIndicator(
        color: Theme.of(context).primaryColor,
        strokeWidth: 2.0,
      ),
    );
  }
  
  Widget _buildDefaultAvatar() {
    return CircleAvatar(
      radius: MediaQuery.of(context).size.width / 17,
      backgroundColor: Colors.grey[300],
      child: Icon(
        Icons.person,
        size: MediaQuery.of(context).size.width / 12,
        color: Colors.white,
      ),
    );
  }
  
  Widget _buildErrorAvatar(IconData icon, String message) {
    return Tooltip(
      message: message,
      child: CircleAvatar(
        radius: MediaQuery.of(context).size.width / 17,
        backgroundColor: Colors.grey[300],
        child: Icon(
          icon,
          size: MediaQuery.of(context).size.width / 12,
          color: Colors.red[300],
        ),
      ),
    );
  }
  
  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: MediaQuery.of(context).size.width / 17,
      backgroundColor: Colors.grey[300],
      child: ClipOval(
        child: Image.network(
          _imageUrl!,
          width: MediaQuery.of(context).size.width / 8.5,
          height: MediaQuery.of(context).size.width / 8.5,
          fit: BoxFit.cover,
          // Add cache control to prevent caching issues
          headers: const {
            "Cache-Control": "no-cache",
          },
          // Use cached network image or Flutter's image caching mechanism
          cacheWidth: (MediaQuery.of(context).size.width / 8.5).ceil(),
          cacheHeight: (MediaQuery.of(context).size.width / 8.5).ceil(),
          errorBuilder: (context, error, stackTrace) {
            debugPrint('Error loading profile image: $error');
            return Icon(
              Icons.broken_image,
              size: MediaQuery.of(context).size.width / 12,
              color: Colors.white,
            );
          },
          loadingBuilder: (context, child, loadingProgress) {
            if (loadingProgress == null) return child;
            return Center(
              child: CircularProgressIndicator(
                color: Theme.of(context).primaryColor,
                value: loadingProgress.expectedTotalBytes != null
                    ? loadingProgress.cumulativeBytesLoaded / 
                      loadingProgress.expectedTotalBytes!
                    : null,
                strokeWidth: 2.0,
              ),
            );
          },
        ),
      ),
    );
  }
}

// Utility class to fetch profile images anywhere in the app
class ProfileImageUtil {
  // Use a variable that can be changed for testing different IP addresses/domains
  static String baseApiUrl = 'https://attendance-dci.web.app/api/UploadFile';
  
  /// Test API connectivity and return success status
  static Future<bool> testApiConnection() async {
    try {
      debugPrint('Testing API connection to: $baseApiUrl');
      
      // Use Dio for better error handling and timeout control
      final response = await Dio().get(
        baseApiUrl,
        options: Options(
          validateStatus: (status) => true, // Accept any status code
          receiveTimeout: const Duration(seconds: 3),
          sendTimeout: const Duration(seconds: 3),
        ),
      ).timeout(
        const Duration(seconds: 5),
        onTimeout: () => Response(
          statusCode: 408,
          requestOptions: RequestOptions(path: baseApiUrl),
        ),
      );
      
      debugPrint('API connection test result: ${response.statusCode}');
      
      // Even if we get a 404, it means the server is reachable
      return response.statusCode != 0 && response.statusCode != 408;
    } catch (e) {
      debugPrint('API connection test failed: $e');
      return false;
    }
  }
  
  /// Returns a direct URL to the profile image using the correct path structure
  static Future<String?> fetchProfileImage() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;
    
    // First test the API connection
    bool isConnected = await testApiConnection();
    if (!isConnected) {
      debugPrint('Cannot fetch profile image: API server unreachable');
      profileImageUpdateController.add(null);
      return null;
    }
    
    // Get timestamp for cache busting
    int timestamp;
    try {
      final prefs = await SharedPreferences.getInstance();
      timestamp = prefs.getInt('profile_image_timestamp') ?? DateTime.now().millisecondsSinceEpoch;
    } catch (e) {
      timestamp = DateTime.now().millisecondsSinceEpoch;
      debugPrint('Error getting timestamp, using current time: $e');
    }
    
    // IMPORTANT: Direct matching to the URL format that works in the browser
    final directImageUrl = '$baseApiUrl/profiles/profile_${user.uid}.jpg?t=$timestamp';
    
    debugPrint('Using direct URL format: $directImageUrl');
    
    // Check if the image exists before returning it
    try {
      final response = await Dio().get(
        directImageUrl,
        options: Options(
          validateStatus: (status) => true,
        ),
      ).timeout(const Duration(seconds: 5));

      if (response.statusCode == 200) {
        debugPrint('Image exists at direct URL: $directImageUrl');
        profileImageUpdateController.add(directImageUrl);
        return directImageUrl;
      } else {
        debugPrint('Image not found at direct URL: ${response.statusCode}');
      }
    } catch (e) {
      debugPrint('Error checking direct URL: $e');
    }
    
    // If direct approach fails, try backup approach with multiple extensions
    final extensions = ['jpg', 'jpeg', 'png'];
    for (final ext in extensions) {
      final fallbackUrl = '$baseApiUrl/profiles/profile_${user.uid}.$ext?t=$timestamp';

      try {
        final response = await Dio().get(
          fallbackUrl,
          options: Options(validateStatus: (status) => true),
        ).timeout(const Duration(seconds: 3));

        if (response.statusCode == 200) {
          debugPrint('Found image at fallback URL: $fallbackUrl');
          profileImageUpdateController.add(fallbackUrl);
          return fallbackUrl;
        }
      } catch (e) {
        debugPrint('Error checking fallback URL with $ext: $e');
      }
    }
    
    // Return null if no image is found
    profileImageUpdateController.add(null);
    return null;
  }
}