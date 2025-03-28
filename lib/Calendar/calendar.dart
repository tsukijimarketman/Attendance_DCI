// import 'dart:convert';
// import 'package:flutter/foundation.dart' show kIsWeb;
// import 'package:flutter_secure_storage/flutter_secure_storage.dart';
// import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';
// import 'package:http/http.dart' as http;
// import 'package:shared_preferences/shared_preferences.dart';
// import 'dart:async'; // Needed for Completer
// import 'dart:html' as html; // Only for web (ensure this runs only on web)


// class GoogleCalendarService {


//   final _secureStorage = FlutterSecureStorage(); // For mobile
//   // You can also use SharedPreferences for web if needed

//    // For web, we can use SharedPreferences.
  
//   // Save access token for web (using SharedPreferences)
//   Future<void> saveAccessToken(String accessToken) async {
//     final prefs = await SharedPreferences.getInstance();
//     await prefs.setString("access_token", accessToken);  // Save token in SharedPreferences
//     print("✅ Saved Access Token: $accessToken");
//   }

//   // Retrieve access token from SharedPreferences
//   Future<String?> getStoredAccessToken() async {
//     final prefs = await SharedPreferences.getInstance();
//     String? token = prefs.getString("access_token");

//     if (token == null) {
//       print("🔄 No token found, please authenticate first.");
//       return null;
//     }

//     print("🔄 Retrieved Access Token from SharedPreferences: $token");
//     return token;
//   }

//   // Authenticate the user and get the access token
//  Future<String?> authenticateUser() async {
//     final authUrl =
//         "https://accounts.google.com/o/oauth2/auth"
//         "?client_id=$clientId"
//         "&redirect_uri=$redirectUri"
//         "&response_type=code"
//         "&scope=$scopes"
//         "&access_type=offline"
//         "&prompt=consent";

//     try {
//       print("🌍 Opening Google Sign-In...");

//       if (kIsWeb) {
//         final authWindow = html.window.open(authUrl, "_blank");

//         Completer<String?> completer = Completer<String?>();

//         html.window.onMessage.listen((event) async {
//           if (event.data != null && event.data['authCode'] != null) {
//             String authCode = event.data['authCode'];
//             print("✅ Received Auth Code: $authCode");

//             String? token = await getAccessToken(authCode);
//             if (token != null) {
//               await saveAccessToken(token);
//               print("✅ Access Token Saved!");
//               completer.complete(token);
//             } else {
//               completer.complete(null);
//             }
//           }
//         });

//         return completer.future;
//       } else {
//         print("❌ Google authentication is only available on the web.");
//         return null;
//       }
//     } catch (e) {
//       print("❌ Authentication failed: $e");
//       return null;
//     }
//   }

//   // Exchange auth code for access token
//   Future<String?> getAccessToken(String code) async {
//   final response = await http.post(
//     Uri.parse("https://oauth2.googleapis.com/token"),
//     body: {
//       "client_id": clientId,
//       "client_secret": clientSecret,
//       "code": code,
//       "redirect_uri": redirectUri,
//       "grant_type": "authorization_code",
//     },
//   );

//   if (response.statusCode == 200) {
//     final data = json.decode(response.body);
//     String accessToken = data['access_token'];
//     await saveAccessToken(accessToken); // Save token
//     print("✅ Access token saved: $accessToken");
//     return accessToken;
//   } else {
//     print("❌ Failed to get access token: ${response.body}");
//     return null;
//   }
// }


//   // Create Google Calendar event
//   Future<void> createCalendarEvent(
//   String accessToken, 
//   String title, 
//   DateTime start, 
//   DateTime end, 
//   List<String> attendees
// ) async {
//   final url = Uri.parse("https://www.googleapis.com/calendar/v3/calendars/primary/events");

//   final event = {
//     "summary": title,
//     "start": {
//       "dateTime": start.toUtc().toIso8601String(),
//       "timeZone": "Asia/Manila",
//     },
//     "end": {
//       "dateTime": end.toUtc().toIso8601String(),
//       "timeZone": "Asia/Manila",
//     },
//     "attendees": attendees.map((email) => {"email": email}).toList(),
//   };

//   final response = await http.post(
//     url,
//     headers: {
//       "Authorization": "Bearer $accessToken",
//       "Content-Type": "application/json",
//     },
//     body: json.encode(event),
//   );

//   if (response.statusCode == 200 || response.statusCode == 201) {
//     print("✅ Event Created Successfully!");
//   } else {
//     print("❌ Failed to create event: ${response.body}");
//   }
// }
// }