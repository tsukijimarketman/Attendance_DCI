import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class UserDetailsView extends StatefulWidget {
  final String profileImageUrl;
  final Map<String, dynamic> userData;
  final String userId;

  const UserDetailsView({
    super.key,
    required this.userData,
    required this.userId,
    required this.profileImageUrl,
  });

  @override
  State<UserDetailsView> createState() => _UserDetailsViewState();
}

class _UserDetailsViewState extends State<UserDetailsView> {
  final supabase = Supabase.instance.client;
  String? _profileImageUrl;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  @override
  void initState() {
    super.initState();
    _fetchProfileImage();
  }

  /// Fetch user's profile image from Supabase
  Future<void> _fetchProfileImage() async {
    // Get current authenticated user
    final firebase_auth.User? currentUser = _auth.currentUser;

    if (currentUser == null) {
      print("No authenticated user found");
      return;
    }

    print("Current Auth UID: ${currentUser.uid}");
    print("Firestore User ID: ${widget.userId}");

    // First, try with the widget's userId (from Firestore)
    await _tryFetchWithUserId(widget.profileImageUrl);

    // If that didn't work and we're looking at our own profile, try with Auth UID
    if (_profileImageUrl == null && currentUser.uid != widget.userId) {
      print("First attempt failed. Trying with current user's Auth UID");
      await _tryFetchWithUserId(currentUser.uid);
    }
  }

  Future<void> _tryFetchWithUserId(String userId) async {
    final filePrefix = 'profile_$userId';
    print("Trying to fetch profile image with prefix: $filePrefix");

    try {
      // List all files in storage
      final response = await supabase.storage.from('profile-pictures').list();

      // Try to find an exact match first
      final exactFilename = '$filePrefix.jpg';
      print("Looking for exact filename: $exactFilename");

      // Check if there's a direct match first
      try {
        String imageUrl = supabase.storage
            .from('profile-pictures')
            .getPublicUrl(exactFilename);
        final timestamp = DateTime.now().millisecondsSinceEpoch;
        imageUrl = "$imageUrl?t=$timestamp";

        print("Found exact match, URL: $imageUrl");
        setState(() {
          _profileImageUrl = imageUrl;
        });
        return;
      } catch (e) {
        print("Exact match not found: $e");
      }

      // If no direct match, look through all files
      print("Searching through ${response.length} files...");
      FileObject? userFile;

      for (var file in response) {
        print("Checking file: ${file.name}");
        if (file.name.startsWith(filePrefix)) {
          userFile = file;
          print("Found matching file: ${file.name}");
          break;
        }
      }

      if (userFile != null) {
        try {
          String imageUrl = supabase.storage
              .from('profile-pictures')
              .getPublicUrl(userFile.name);

          // Ensure URL doesn't contain an extra ":http:"
          if (imageUrl.contains(':http:')) {
            imageUrl = imageUrl.replaceAll(':http:', '');
          }

          // Add timestamp to force refresh
          final timestamp = DateTime.now().millisecondsSinceEpoch;
          imageUrl = "$imageUrl?t=$timestamp";

          print("Final image URL: $imageUrl");
          setState(() {
            _profileImageUrl = imageUrl;
          });
        } catch (e) {
          print("Error getting public URL: $e");
        }
      } else {
        print("No matching file found with prefix: $filePrefix");
      }
    } catch (e) {
      print("Error listing files: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    // Primary color theme for the application
    final Color primaryColor = const Color.fromARGB(255, 20, 94, 155);

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'User Details',
                style: TextStyle(
                  fontFamily: "B",
                  fontSize: 22,
                  color: primaryColor,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const Divider(height: 24),
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Profile section
                  Center(
                    child: Column(
                      children: [
                        _buildProfileAvatar(),
                        const SizedBox(height: 16),
                        Text(
                          '${widget.userData['first_name'] ?? ''} ${widget.userData['last_name'] ?? ''}'
                              .trim(),
                          style: const TextStyle(
                            fontFamily: "B",
                            fontSize: 24,
                          ),
                        ),
                        const SizedBox(height: 8),
                        _buildStatusBadge(
                            widget.userData['status'] ?? 'inactive'),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Information sections
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Personal Information
                      Expanded(
                        child: _buildInfoSection(
                          'Personal Information',
                          [
                            _buildInfoRow(
                                'First Name', widget.userData['first_name']),
                            _buildInfoRow(
                                'Middle Name', widget.userData['middle_name']),
                            _buildInfoRow(
                                'Last Name', widget.userData['last_name']),
                            _buildInfoRow('Suffix', widget.userData['suffix']),
                            _buildInfoRow(
                                'Birthdate', widget.userData['birthdate']),
                            _buildInfoRow('Sex', widget.userData['sex']),
                            _buildInfoRow('Civil Status',
                                widget.userData['civil_status']),
                            _buildInfoRow(
                                'Height (cm)', widget.userData['height']),
                            _buildInfoRow(
                                'Weight (kg)', widget.userData['weight']),
                            _buildInfoRow(
                                'Blood Type', widget.userData['blood_type']),
                            _buildInfoRow(
                                'Religion', widget.userData['religion']),
                          ],
                        ),
                      ),
                      const SizedBox(width: 32),
                      // Professional Information
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildInfoSection(
                              'Professional Information',
                              [
                                _buildInfoRow('Department',
                                    widget.userData['department']),
                                _buildInfoRow('Role', widget.userData['roles']),
                                _buildInfoRow(
                                    'Email', widget.userData['email']),
                                _buildInfoRow('Mobile Number',
                                    widget.userData['mobile_number']),
                                _buildInfoRow('Telephone',
                                    widget.userData['telephone_number']),
                              ],
                            ),
                            const SizedBox(height: 24),
                            _buildInfoSection(
                              'Citizenship Information',
                              [
                                _buildInfoRow('Citizenship',
                                    widget.userData['citizenship']),
                                _buildInfoRow('Dual Citizen',
                                    widget.userData['dual_citizen']),
                                _buildInfoRow(
                                    'By Birth',
                                    _formatBoolean(
                                        widget.userData['by_birth'])),
                                _buildInfoRow(
                                    'By Naturalized',
                                    _formatBoolean(
                                        widget.userData['by_naturalized'])),
                                _buildInfoRow('Place of Birth',
                                    widget.userData['place_of_birth']),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // Address Information
                  _buildInfoSection(
                    'Address Information',
                    [
                      _buildInfoRow(
                          'House Number', widget.userData['house_number']),
                      _buildInfoRow('Street', widget.userData['street']),
                      _buildInfoRow(
                          'Subdivision', widget.userData['subdivision']),
                      _buildInfoRow('Barangay', widget.userData['barangay']),
                      _buildInfoRow(
                          'Municipality', widget.userData['municipality']),
                      _buildInfoRow('City', widget.userData['city']),
                      _buildInfoRow('Province', widget.userData['province']),
                      _buildInfoRow('Region', widget.userData['region']),
                      _buildInfoRow('Country', widget.userData['country']),
                      _buildInfoRow('Zip Code', widget.userData['zip_code']),
                    ],
                  ),
                  const SizedBox(height: 24),
                  // System Information
                  _buildInfoSection(
                    'System Information',
                    [
                      _buildInfoRow(
                          'IP Address', widget.userData['ip_address']),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 24),
          Align(
            alignment: Alignment.centerRight,
            child: ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: const Text('Close', style: TextStyle(color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProfileAvatar() {
    return CircleAvatar(
      radius: 60,
      backgroundColor: Colors.grey.shade200,
      backgroundImage:
          _profileImageUrl != null ? NetworkImage(_profileImageUrl!) : null,
      onBackgroundImageError: _profileImageUrl != null
          ? (exception, stackTrace) {
              print("Error loading profile image: $exception");
              setState(() {
                _profileImageUrl = null;
              });
            }
          : null,
      child: _profileImageUrl == null
          ? Icon(Icons.person, size: 60, color: Colors.grey.shade700)
          : null,
    );
  }

  Widget _buildInfoSection(String title, List<Widget> rows) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: const Color.fromARGB(255, 20, 94, 155).withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(
            title,
            style: const TextStyle(
              fontFamily: "B",
              fontSize: 16,
              color: Color.fromARGB(255, 20, 94, 155),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...rows,
        const SizedBox(height: 8),
      ],
    );
  }

  /// Build a row of information with label and value
  Widget _buildInfoRow(String label, dynamic value) {
    String displayValue = 'N/A';

    if (value != null) {
      if (value is String && value.isNotEmpty) {
        displayValue = value;
      } else if (!(value is String) && value.toString().isNotEmpty) {
        displayValue = value.toString();
      }
    }

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 140,
            child: Text(
              '$label:',
              style: TextStyle(
                fontFamily: "M",
                fontSize: 14,
                color: Colors.grey[700],
              ),
            ),
          ),
          Expanded(
            child: Text(
              displayValue,
              style: const TextStyle(
                fontFamily: "R",
                fontSize: 14,
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Format boolean values for display
  String _formatBoolean(dynamic value) {
    if (value == null) return 'N/A';
    return value == true ? 'Yes' : 'No';
  }

  /// Build status badge
  Widget _buildStatusBadge(String status) {
    final Color badgeColor =
        status.toLowerCase() == 'active' ? Colors.green : Colors.red;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: badgeColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: badgeColor, width: 1),
      ),
      child: Text(
        status.toUpperCase(),
        style: TextStyle(
          fontFamily: "M",
          fontSize: 12,
          color: badgeColor,
        ),
      ),
    );
  }

  /// Function to view user details - call this from your main widget
  void showUserDetails(BuildContext context, String userId) {
    // Fetch the user data from Firestore
    FirebaseFirestore.instance.collection('users').doc(userId).get().then(
      (DocumentSnapshot document) {
        if (document.exists) {
          final userData = document.data() as Map<String, dynamic>;
          _showUserDetailsDialog(context, userData, userId);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('User not found')),
          );
        }
      },
      onError: (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user details: $e')),
        );
      },
    );
  }

  /// Shows a dialog with user details
  void _showUserDetailsDialog(
      BuildContext context, Map<String, dynamic> userData, String userId) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return Dialog(
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(16.0)),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
              maxHeight: MediaQuery.of(context).size.height * 0.8,
            ),
            child: UserDetailsView(
              userData: userData,
              userId: userId,
              profileImageUrl: widget.profileImageUrl,
            ),
          ),
        );
      },
    );
  }
}
