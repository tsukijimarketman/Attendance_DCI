import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:image_picker/image_picker.dart';

class GDriveService {
  static const String baseUrl =
      'https://gdrive-8066bw2nb-devs-projects-9ca9c626.vercel.app';

  // Upload profile image
  static Future<String> uploadProfileImage(XFile file, String userId) async {
    try {
      print('Starting file upload to Google Drive...');
      print('File path: ${file.path}');
      print('File name: ${file.name}');

      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload'),
      );

      // Add file to request
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      print('File size: $fileLength bytes');

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: 'profile_$userId.${file.path.split('.').last}',
      );

      request.files.add(multipartFile);

      print('Sending request...');
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return responseData['link'] as String;
      } else {
        throw Exception(
            'Failed to upload profile image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in uploadProfileImage: $e');
      throw Exception('Error uploading profile image: $e');
    }
  }

  // Get profile image URL
  static Future<String?> getProfileImageUrl(String userId) async {
    try {
      print('Fetching profile image URL for user: $userId');

      final response = await http.get(
        Uri.parse('$baseUrl/list'),
        headers: {
          'Accept': 'application/json',
          'Content-Type': 'application/json',
        },
      );

      print('Response status code: ${response.statusCode}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> files =
            json.decode(response.body)['files'] as List<dynamic>;
        print('Files found: ${files.length}');

        final userFile = files.firstWhere(
          (file) => file['name'].toString().startsWith('profile_$userId'),
          orElse: () => null,
        );

        if (userFile != null) {
          print('Found user file: ${userFile['webViewLink']}');
          return userFile['webViewLink'];
        }
        print('No file found for user: $userId');
        return null;
      } else {
        throw Exception(
            'Failed to fetch profile image: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      print('Error in getProfileImageUrl: $e');
      throw Exception('Error fetching profile image: $e');
    }
  }
}
