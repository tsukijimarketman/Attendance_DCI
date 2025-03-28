import 'package:shared_preferences/shared_preferences.dart';

class WebStorageService {
  // Save access token to SharedPreferences (for Web)
  Future<void> saveAccessToken(String accessToken) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString("access_token", accessToken);
    print("✅ Saved Access Token: $accessToken"); // Debugging
  }

  // Retrieve the stored access token from SharedPreferences
  Future<String?> getStoredAccessToken() async {
    final prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString("access_token");

    if (token == null) {
      print("🔄 No token found, trying to authenticate...");
      return null; // Don't call authenticateUser() here
    }

    print("🔄 Retrieved Access Token: $token"); // Debugging the token retrieval
    return token;
  }
}
