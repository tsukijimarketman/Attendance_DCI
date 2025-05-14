import 'package:shared_preferences/shared_preferences.dart';

// This class is responsible for managing web storage operations using SharedPreferences.
// SharedPreferences is used here to save and retrieve the access token in the browser's local storage.
// It is specifically useful for web applications where local storage is required to maintain user sessions across page reloads.
class WebStorageService {
  // This method saves the access token to SharedPreferences (local storage for web).
  // It is called when the user successfully logs in and receives an access token from the server.
  // This allows the user to remain authenticated even if they reload the page or return to the app later.
  Future<void> saveAccessToken(String accessToken) async {
    // Retrieves the instance of SharedPreferences to store data locally.
    final prefs = await SharedPreferences.getInstance();

    // Saves the access token as a string in SharedPreferences under the key "access_token".#
    await prefs.setString("access_token", accessToken);
  }

  // This method retrieves the stored access token from SharedPreferences.
  // It checks if an access token is available, which can be used for subsequent requests to authenticate the user.
  // If no token is found, the method returns null, indicating the user is not authenticated.
  Future<String?> getStoredAccessToken() async {
    // Retrieves the instance of SharedPreferences to access saved data.
    final prefs = await SharedPreferences.getInstance();

    // Retrieves the stored access token from SharedPreferences using the key "access_token".
    String? token = prefs.getString("access_token");

    // If the token doesn't exist, return null, indicating no valid session.
    if (token == null) {
      return null; // No token found, so the user might need to authenticate.
    }

    // If a token is found, return it for use in API requests or checking authentication status.
    return token;
  }
}
