import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

class EditableUserDetailsView extends StatefulWidget {
  final String profileImageUrl;
  final Map<String, dynamic> userData;
  final String userId;

  const EditableUserDetailsView({
    super.key,
    required this.userData,
    required this.userId,
    required this.profileImageUrl,
  });

  @override
  State<EditableUserDetailsView> createState() =>
      _EditableUserDetailsViewState();
}

class _EditableUserDetailsViewState extends State<EditableUserDetailsView> {
  final supabase = Supabase.instance.client;
  String? _profileImageUrl;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Status, department and role selection
  String _selectedStatus = 'inactive';
  String? _selectedDepartment;
  String? _selectedRole;

  // Lists of available departments (will be fetched) and roles
List<Map<String, String>> _departmentList = [];

  // Role mapping as provided
  final Map<String, String> _rolesMap = {
    '---': '',
    'Super User': 'Superuser',
    'Manager': 'Manager',
    'Department Head': 'DepartmentHead',
    'Admin': 'Admin',
    'User': 'User'
  };

  // Track if we've made changes
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    // Initialize data safely
    _safeInitializeUserData();
    // Fetch departments in background
    _fetchDepartments();
    // Fix: Delay profile image loading to prevent UI issues
    Future.delayed(Duration.zero, () {
      _fetchProfileImage();
    });
  }

  void _safeInitializeUserData() {
    // Set default values to prevent null issues
    setState(() {
      // Handle status with default
      _selectedStatus = widget.userData['status'] ?? 'inactive';

      // Handle department with validation
      String? department = widget.userData['department'];
      if (department != null && department.isNotEmpty) {
        _selectedDepartment = department;
      } else {
        _selectedDepartment = null;
      }

      // Handle role with validation against known roles
      String? role = widget.userData['roles'];
      if (role != null && role.isNotEmpty) {
        bool isKnownRole = _rolesMap.values.contains(role);
        if (isKnownRole) {
          _selectedRole = role;
        } else {
          // If it's not a known role but not null, still keep it
          _selectedRole = role;
        }
      } else {
        _selectedRole = null;
      }
    });

    // Debug output to confirm values
    print("Initialized Status: $_selectedStatus");
    print("Initialized Department: $_selectedDepartment");
    print("Initialized Role: $_selectedRole");
  }

  // Initialize the dropdowns with current values from userData
  void _initializeUserData() {
    // Set default values to prevent null issues
    setState(() {
      _selectedStatus = widget.userData['status'] ?? 'inactive';
      _selectedDepartment = widget.userData['department'];
      _selectedRole = widget.userData['roles'];
    });
  }

  // Fetch departments from Firestore
 Future<void> _fetchDepartments() async {
  try {
    QuerySnapshot referencesSnapshot = await FirebaseFirestore.instance
        .collection("references")
        .where('isDeleted', isEqualTo: false)
        .get();

    if (mounted) {
      setState(() {
        _departmentList = referencesSnapshot.docs
            .map((doc) => {
              'deptID': doc["deptID"] as String,
              'name': doc["name"] as String,
            })
            .toList();

        // Add an empty selection option if needed
        if (!_departmentList.any((department) => department['name'] == '---')) {
          _departmentList.insert(0, {'deptID': '', 'name': '---'});
        }
      });

      // Debug output
      print("Fetched departments: $_departmentList");
    }
  } catch (e) {
    print("Error fetching departments: $e");
  }
}


  /// Fetch user's profile image from Supabase
  Future<void> _fetchProfileImage() async {
    try {
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
    } catch (e) {
      print("Error in _fetchProfileImage: $e");
      // Don't set state here to avoid UI issues
    }
  }

  Future<void> _tryFetchWithUserId(String userId) async {
    if (!mounted) return;

    try {
      final filePrefix = 'profile_$userId';
      print("Trying to fetch profile image with prefix: $filePrefix");

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
        if (mounted) {
          setState(() {
            _profileImageUrl = imageUrl;
          });
        }
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
          if (mounted) {
            setState(() {
              _profileImageUrl = imageUrl;
            });
          }
        } catch (e) {
          print("Error getting public URL: $e");
        }
      } else {
        print("No matching file found with prefix: $filePrefix");
      }
    } catch (e) {
      print("Error in _tryFetchWithUserId: $e");
    }
  }

  // Save changes to Firestore
  Future<void> _saveChanges() async {
  try {
    // Show loading indicator
    _showLoadingDialog(context);

    // Create an update map with only the fields that need updating
    Map<String, dynamic> updateData = {};

    // Only add fields that were actually changed
    if (_selectedStatus != widget.userData['status']) {
      updateData['status'] = _selectedStatus;
    }

    if (_selectedDepartment != widget.userData['deptID']) {
      updateData['deptID'] = _selectedDepartment;  // Save deptID, not name
    }

    if (_selectedRole != widget.userData['roles']) {
      updateData['roles'] = _selectedRole;
    }

    // Only update if there are changes
    if (updateData.isNotEmpty) {
      await _firestore
          .collection('users')
          .doc(widget.userId)
          .update(updateData);
    }

    // Dismiss loading dialog
    if (context.mounted) Navigator.of(context).pop();

    // Show success message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('User details updated successfully'),
          backgroundColor: Colors.green,
        ),
      );

      setState(() {
        _hasChanges = false;
      });

      // Close the details view
      Navigator.of(context).pop();
    }
  } catch (e) {
    // Dismiss loading dialog
    if (context.mounted) Navigator.of(context).pop();

    // Show error message
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error updating user details: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}


  // Show loading dialog while saving changes
  void _showLoadingDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return const Dialog(
          child: Padding(
            padding: EdgeInsets.all(20.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                CircularProgressIndicator(),
                SizedBox(width: 20),
                Text("Saving changes..."),
              ],
            ),
          ),
        );
      },
    );
  }

  // Show confirmation dialog before saving changes
  void _showConfirmationDialog() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Changes'),
          content: const Text(
              'Are you sure you want to update this user\'s details?'),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop();
                _saveChanges();
              },
              child: const Text('Save'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    // Debug output to confirm state values
    print("Current status: $_selectedStatus");
    print("Current department: $_selectedDepartment");
    print("Current role: $_selectedRole");
    print("Has changes: $_hasChanges");
    print("Department list size: ${_departmentList.length}");

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
                'Edit User Details',
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
                        _buildEditableStatusBadge(),
                        const SizedBox(height: 24),
                      ],
                    ),
                  ),

                  // Editable Section
                  _buildEditableSection('Edit User Settings', [
                    _buildDepartmentDropdown(),
                    _buildRoleDropdown(),
                  ]),
                  const SizedBox(height: 24),

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
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(),
                child: const Text('Cancel'),
              ),
              const SizedBox(width: 16),
              ElevatedButton(
                // Force enable the button for testing
                onPressed: _hasChanges ? () => _showConfirmationDialog() : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: primaryColor,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  disabledBackgroundColor: Colors.grey,
                ),
                child: const Text('Save Changes',
                    style: TextStyle(color: Colors.white)),
              ),
            ],
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
      // Only provide error handler when backgroundImage is not null
      onBackgroundImageError: _profileImageUrl != null
          ? (exception, stackTrace) {
              print("Error loading profile image: $exception");
              // Use Future.microtask to avoid setState during build
              Future.microtask(() {
                if (mounted) {
                  setState(() {
                    _profileImageUrl = null;
                  });
                }
              });
            }
          : null,
      child: _profileImageUrl == null
          ? Icon(Icons.person, size: 60, color: Colors.grey.shade700)
          : null,
    );
  }

  Widget _buildEditableSection(String title, List<Widget> content) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontFamily: "B",
              fontSize: 18,
              color: Color.fromARGB(255, 20, 94, 155),
            ),
          ),
          const SizedBox(height: 16),
          ...content,
        ],
      ),
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

  /// Build editable status badge
  Widget _buildEditableStatusBadge() {
    return GestureDetector(
      onTap: () {
        // Toggle between active and inactive only
        setState(() {
          _selectedStatus = _selectedStatus == 'active' ? 'inactive' : 'active';
          _hasChanges = true;
          print("Status changed to: $_selectedStatus");
        });
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        decoration: BoxDecoration(
          color: _getStatusColor(_selectedStatus).withOpacity(0.1),
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: _getStatusColor(_selectedStatus), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              _selectedStatus.toUpperCase(),
              style: TextStyle(
                fontFamily: "M",
                fontSize: 12,
                color: _getStatusColor(_selectedStatus),
              ),
            ),
            const SizedBox(width: 6),
            Icon(
              Icons.edit,
              size: 14,
              color: _getStatusColor(_selectedStatus),
            ),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'active':
        return Colors.green;
      case 'inactive':
        return Colors.red;
      case 'pending':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  Widget _buildDepartmentDropdown() {
  return Padding(
    padding: const EdgeInsets.only(bottom: 16.0),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Department',
          style: TextStyle(
            fontFamily: "M",
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: FutureBuilder<List<Map<String, String>>>(
            // Use FutureBuilder to ensure departments are fully loaded
            future: _getDepartmentsList(),
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 12.0, horizontal: 16.0),
                  child: Text("Loading departments..."),
                );
              }

              // Get the list of departments
              final departmentList = snapshot.data ?? [];

              // Ensure the selected department is in the list
              bool hasSelectedDepartment = false;
              if (_selectedDepartment != null) {
                hasSelectedDepartment = departmentList.any((department) =>
                    department['deptID'] == _selectedDepartment);
                if (!hasSelectedDepartment) {
                  // If the department isn't in the list, add it temporarily
                  departmentList.add({'deptID': _selectedDepartment!, 'name': _selectedDepartment!});
                }
              }

              return DropdownButtonFormField<String>(
                value: _selectedDepartment,
                decoration: const InputDecoration(
                  contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  border: InputBorder.none,
                ),
                hint: const Text("Select Department"),
                isExpanded: true,
                onChanged: (newValue) {
                  setState(() {
                    _selectedDepartment = newValue;
                    _hasChanges = true;
                    print("Department changed to: $newValue");
                  });
                },
                items: departmentList.map<DropdownMenuItem<String>>((department) {
                  return DropdownMenuItem<String>(
                    value: department['deptID'],  // Store deptID in the value
                    child: Text(department['name'] ?? '',
                        style: const TextStyle(fontSize: 16)),
                  );
                }).toList(),
              );
            },
          ),
        ),
      ],
    ),
  );
}

 Future<List<Map<String, String>>> _getDepartmentsList() async {
  // If we already have the list, return it
  if (_departmentList.isNotEmpty) {
    return _departmentList;
  }

  try {
    // Fetch the references directly
    QuerySnapshot referencesSnapshot = await FirebaseFirestore.instance
        .collection("references")
        .where('isDeleted', isEqualTo: false)
        .get();

    List<Map<String, String>> departments = referencesSnapshot.docs
        .map((doc) => {
          'deptID': doc["deptID"] as String,  // Save deptID as string
          'name': doc["name"] as String,      // Save name
        })
        .toList();

    // Add an empty selection option if needed
    if (!departments.any((department) => department['name'] == '---')) {
      departments.insert(0, {'deptID': '', 'name': '---'});  // Add empty selection option
    }

    // Cache the result
    _departmentList = departments;
    return departments;
  } catch (e) {
    print("Error fetching departments: $e");
  }

  // Return a minimal list with at least the selected department if any
  List<Map<String, String>> fallback = [{'deptID': '', 'name': '---'}];
  if (_selectedDepartment != null && _selectedDepartment != '---') {
    fallback.add({'deptID': _selectedDepartment!, 'name': _selectedDepartment!});
  }
  return fallback;
}



  Widget _buildRoleDropdown() {
    // Create a list of role items
    List<DropdownMenuItem<String>> roleItems = [];

    // Ensure the currently selected role is valid
    bool selectedRoleExists = false;

    // Check if the selected role is in our map
    if (_selectedRole != null) {
      selectedRoleExists = _rolesMap.values.contains(_selectedRole);
    }

    // Build the dropdown items
    _rolesMap.forEach((display, value) {
      roleItems.add(DropdownMenuItem<String>(
        value: value.isEmpty ? null : value,
        child: Text(display, style: const TextStyle(fontSize: 16)),
      ));
    });

    // If the selected role doesn't exist in our map but is not null, add it temporarily
    if (_selectedRole != null && !selectedRoleExists) {
      // Find a display name or use the value itself
      String displayName = _selectedRole!;
      _rolesMap.forEach((key, value) {
        if (value == _selectedRole) {
          displayName = key;
        }
      });

      // Add the missing role temporarily
      roleItems.add(DropdownMenuItem<String>(
        value: _selectedRole,
        child:
            Text("$displayName (Legacy)", style: const TextStyle(fontSize: 16)),
      ));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Role',
          style: TextStyle(
            fontFamily: "M",
            fontSize: 14,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            border: Border.all(color: Colors.grey.shade300),
            borderRadius: BorderRadius.circular(8),
          ),
          child: DropdownButtonFormField<String>(
            value: _selectedRole,
            decoration: const InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              border: InputBorder.none,
            ),
            hint: const Text("Select Role"),
            isExpanded: true,
            onChanged: (newValue) {
              setState(() {
                _selectedRole = newValue;
                _hasChanges = true;
                print("Role changed to: $newValue");
              });
            },
            items: roleItems,
          ),
        ),
      ],
    );
  }
}

/// Function to open the editable user details dialog
void showEditableUserDetails(BuildContext context, String userId) {
  // Fetch the user data from Firestore
  FirebaseFirestore.instance.collection('users').doc(userId).get().then(
    (DocumentSnapshot document) {
      if (document.exists) {
        final userData = document.data() as Map<String, dynamic>;
        _showEditableUserDetailsDialog(context, userData, userId);
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

/// Shows a dialog with editable user details
void _showEditableUserDetailsDialog(
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
          child: EditableUserDetailsView(
            userData: userData,
            userId: userId,
            profileImageUrl: userData['uid'] ??
                '', // Use the stored UID as profile image prefix
          ),
        ),
      );
    },
  );
}
