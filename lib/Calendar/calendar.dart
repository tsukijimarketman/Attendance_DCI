import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:async'; // Needed for Completer
import 'dart:html' as html; // Only for web (ensure this runs only on web)

/// This Dart file contains a service class for Google Calendar operations
/// such as creating, updating, and deleting events. It also handles OAuth 2.0 authentication
/// to obtain access tokens for API requests. The class is designed to work on both mobile and web platforms.
/// It uses Flutter Secure Storage for mobile and SharedPreferences for web to store access tokens.

// Define a service class for handling Google Calendar operations
class GoogleCalendarService {
  // OAuth 2.0 credentials
  final String clientId =
      "794795546739-gerc0clp04h1qbg5gfphjmsjcvgq6jga.apps.googleusercontent.com";
  final String clientSecret = "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";
  final String redirectUri = "https://attendance-dci.web.app";
  final String scopes = "https://www.googleapis.com/auth/calendar.events";

  // Secure storage instance for mobile (Android/iOS)
  final _secureStorage = FlutterSecureStorage(); // For mobile

  // Save access token for Web platform using SharedPreferences
  Future<void> saveAccessToken(String accessToken) async {
    final prefs =
        await SharedPreferences.getInstance(); // Initialize SharedPreferences
    await prefs.setString(
        "access_token", accessToken); // Save token as a string
  }

  // Retrieve stored access token from SharedPreferences
  Future<String?> getStoredAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token"); // Try fetching token

    if (token == null) {
      return null;
    }
    return token;
  }

  // Authenticate the user via Google OAuth and obtain access token
  Future<String?> authenticateUser() async {
    // Build the Google OAuth URL
    final authUrl = "https://accounts.google.com/o/oauth2/auth"
        "?client_id=$clientId"
        "&redirect_uri=$redirectUri"
        "&response_type=code"
        "&scope=$scopes"
        "&access_type=offline"
        "&prompt=consent";

    try {
      if (kIsWeb) {
        // Open a new window for Google Sign-In (only on web)
        final authWindow = html.window.open(authUrl, "_blank");

        // Create a Completer to wait for OAuth result
        Completer<String?> completer = Completer<String?>();

        // Listen to message from popup
        html.window.onMessage.listen((event) async {
          if (event.data != null && event.data['authCode'] != null) {
            String authCode =
                event.data['authCode']; // Received authorization code

            // Exchange auth code for access token
            String? token = await getAccessToken(authCode);
            if (token != null) {
              await saveAccessToken(token); // Save token
              completer.complete(token); // Return token
            } else {
              completer.complete(null); // Return null if failed
            }
          }
        });

        return completer.future; // Wait until token is received
      } else {
        return null;
      }
    } catch (e) {
      return null;
    }
  }

  // Exchange authorization code for access token
  Future<String?> getAccessToken(String code) async {
    final response = await http.post(
      Uri.parse("https://oauth2.googleapis.com/token"), // Token endpoint
      body: {
        "client_id": clientId,
        "client_secret": clientSecret,
        "code": code,
        "redirect_uri": redirectUri,
        "grant_type": "authorization_code",
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body); // Decode JSON response
      String accessToken = data['access_token']; // Extract access token
      await saveAccessToken(accessToken); // Save token locally
      return accessToken;
    } else {
      return null;
    }
  }

  // Update an existing event in Google Calendar
  Future<void> updateCalendarEvent(
      String accessToken,
      String eventId,
      String title,
      DateTime start,
      DateTime end,
      List<String> attendees) async {
    // Build the URL for updating a specific event
    final url = Uri.parse(
        "https://www.googleapis.com/calendar/v3/calendars/primary/events/$eventId");

    // Build event body
    final event = {
      "summary": title,
      "start": {
        "dateTime": start.toUtc().toIso8601String(),
        "timeZone": "Asia/Manila",
      },
      "end": {
        "dateTime": end.toUtc().toIso8601String(),
        "timeZone": "Asia/Manila",
      },
      "attendees": attendees.map((email) => {"email": email}).toList(),
    };

    // Send PUT request to update event#
    final response = await http.put(
      url,
      headers: {
        "Authorization": "Bearer $accessToken", // Add Bearer token
        "Content-Type": "application/json",
      },
      body: json.encode(event), // Encode event data
    );

    if (response.statusCode == 200) {
      print("✅ Event Updated Successfully!");
    } else {
      print("❌ Failed to update event");
    }
  }

  // Delete existing Google Calendar event
  Future<void> deleteCalendarEvent(String accessToken, String eventId) async {
    final url = Uri.parse(
        "https://www.googleapis.com/calendar/v3/calendars/primary/events/$eventId");

    // Send DELETE request
    final response = await http.delete(
      url,
      headers: {
        "Authorization": "Bearer $accessToken", // Add Bearer token
      },
    );

    if (response.statusCode == 204) {
      // 204 means successful delete
      print("✅ Event Deleted Successfully!");
    } else {
      print("❌ Failed to delete event");
    }
  }

  // Create a new event in Google Calendar
  Future<String?> createCalendarEvent(String accessToken, String title,
      DateTime start, DateTime end, List<String> attendees) async {
    // Build URL for creating new event
    final url = Uri.parse(
        "https://www.googleapis.com/calendar/v3/calendars/primary/events");

    // Build event body
    final event = {
      "summary": title,
      "start": {
        "dateTime": start.toUtc().toIso8601String(),
        "timeZone": "Asia/Manila",
      },
      "end": {
        "dateTime": end.toUtc().toIso8601String(),
        "timeZone": "Asia/Manila",
      },
      "attendees": attendees.map((email) => {"email": email}).toList(),
    };

    // Send POST request to create event
    final response = await http.post(
      url,
      headers: {
        "Authorization": "Bearer $accessToken", // Add Bearer token
        "Content-Type": "application/json",
      },
      body: json.encode(event), // Encode event data
    );

    if (response.statusCode == 200 || response.statusCode == 201) {
      final data = json.decode(response.body); // Decode response
      String eventId = data['id']; // Extract the event ID from the response
      return eventId; // Return the event ID
    } else {
      return null; // Return null if creation fails
    }
  }
}
