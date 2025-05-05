import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/maintenance/editable_users_view.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/maintenance/user_details_view.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

class ManageUsers extends StatefulWidget {
  final String searchQuery;

  const ManageUsers({
    super.key,
    this.searchQuery = '',
  });

  @override
  State<ManageUsers> createState() => _ManageUsersState();
}

class _ManageUsersState extends State<ManageUsers> {
  // Primary color theme for the application
  final Color primaryColor = const Color.fromARGB(255, 20, 94, 155);

  // Secondary colors for UI elements
  final Color cardColor = Colors.white;
  final Color dividerColor = Colors.black12;
  final Color textPrimaryColor = Colors.black87;
  final Color rowHoverColor = Colors.grey.shade100;

  // Pagination
  int _currentPage = 1;
  int _itemsPerPage = 10; // Changed from final to regular int
  final TextEditingController _itemsPerPageController =
      TextEditingController(text: '10');

  int _totalUsers = 0;

  // Sorting
  String _sortColumn = 'first_name';
  bool _sortAscending = true;

  // Department abbreviation mappings
  final Map<String, String> _departmentAbbreviations = {
    'Quality Management System': 'QMS',
    'Internal Quality Audit': 'IQA',
    'Project Management Department': 'PMD',
    'Human Resources Admin': 'HRA',
    'Business Development': 'BD',
    'Accounting': 'ACCT',
    'IT Operations': 'ITO',
    'Admin Operations': 'ADM',
    'Technology & Innovations': 'TID',
    'Project Implementation': 'PI',
    'Legal and Compliance': 'LC',
    'Corporate Affairs': 'CA',
    'Customer Service': 'CS',
    'Corporate Planning & Development': 'CPD',
  };

  // Reverse mapping for search functionality
  late Map<String, String> _reverseDepartmentMap;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  @override
  void initState() {
    super.initState();
    // Create reverse mapping for search functionality
    _reverseDepartmentMap = {};
    _departmentAbbreviations.forEach((key, value) {
      _reverseDepartmentMap[value.toLowerCase()] = key.toLowerCase();
    });
    _itemsPerPageController.text = _itemsPerPage.toString();
  }

  @override
  void dispose() {
    _itemsPerPageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(16.0),
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildTableHeader(),
            const SizedBox(height: 12),
            _buildTable(),
            const SizedBox(height: 20),
            _buildPagination(),
          ],
        ),
      ),
    );
  }

  /// Builds the table header with title and counts
  Widget _buildTableHeader() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Text(
              'Items per page:',
              style: TextStyle(
                fontFamily: "M",
                fontSize: 14,
                color: textPrimaryColor,
              ),
            ),
            const SizedBox(width: 8),
            SizedBox(
              width: 60,
              child: TextField(
                controller: _itemsPerPageController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(4),
                    borderSide: BorderSide(color: primaryColor),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () {
                int? newValue = int.tryParse(_itemsPerPageController.text);
                if (newValue != null && newValue > 0) {
                  setState(() {
                    _itemsPerPage = newValue;
                    _currentPage = 1; // Reset to first page
                  });
                } else {
                  _itemsPerPageController.text = _itemsPerPage.toString();
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: primaryColor,
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
              child: const Text('Apply', style: TextStyle(color: Colors.white)),
            ),
          ],
        ),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
          .collection('users')        
          .where('isDeleted', isEqualTo: false)
          .snapshots(),

          builder: (context, snapshot) {
            int count = snapshot.hasData ? snapshot.data!.docs.length : 0;
            _totalUsers = count;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: primaryColor.withOpacity(0.1),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                'Total Users: $count',
                style: TextStyle(
                  fontFamily: "B",
                  color: primaryColor,
                  fontSize: 14,
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  /// Get department abbreviation from full name
  String _getDepartmentAbbreviation(String? fullDepartment) {
    if (fullDepartment == null) return 'N/A';
    return _departmentAbbreviations[fullDepartment] ?? fullDepartment;
  }

  /// Builds the main table content
  Widget _buildTable() {
    return Expanded(
      child: StreamBuilder<QuerySnapshot>(
        stream: _getUsersStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return Center(
              child: Text(
                "No users found",
                style: TextStyle(
                  fontFamily: "M",
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            );
          }

          var users = snapshot.data!.docs;
            print("Users data: ${users.length}"); // Add this line to debug


          // Filter users based on search query
          if (widget.searchQuery.isNotEmpty) {
            users = users.where((doc) {
              var userData = doc.data() as Map<String, dynamic>;
              String name =
                  "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}"
                      .toLowerCase();
              String email = (userData['email'] ?? '').toLowerCase();
              String departmentFull =
                  (userData['department'] ?? '').toLowerCase();
              String departmentAbbr =
                  _getDepartmentAbbreviation(userData['department'])
                      .toLowerCase();
              String role = (userData['roles'] ?? '').toLowerCase();
              String status = (userData['status'] ?? '').toLowerCase();

              String searchLower = widget.searchQuery.toLowerCase();

              // Check if search is for abbreviation and match it with full department name
              bool departmentMatch = departmentFull.contains(searchLower) ||
                  departmentAbbr.contains(searchLower);

              // Check if search is for full department name when user types an abbreviation
              if (_reverseDepartmentMap.containsKey(searchLower)) {
                departmentMatch = departmentMatch ||
                    departmentFull
                        .contains(_reverseDepartmentMap[searchLower]!);
              }

              return name.contains(searchLower) ||
                  email.contains(searchLower) ||
                  departmentMatch ||
                  role.contains(searchLower) ||
                  status.contains(searchLower);
            }).toList();
          }

          // Calculate pagination
          final int startIndex = (_currentPage - 1) * _itemsPerPage;
          final int endIndex = startIndex + _itemsPerPage > users.length
              ? users.length
              : startIndex + _itemsPerPage;

          // No users found after filtering
          if (users.isEmpty) {
            return Center(
              child: Text(
                "No matching users found",
                style: TextStyle(
                  fontFamily: "M",
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            );
          }

          // Slice users for current page
          final displayUsers = users.sublist(startIndex, endIndex);
          print("Displaying users: ${displayUsers.length}");  // Check how many users are being displayed

          return SingleChildScrollView(
            scrollDirection: Axis.vertical,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: MediaQuery.of(context).size.width -
                    100, // Adjust based on your padding
              ),
              child: DataTable(
                headingRowColor: MaterialStateProperty.all(Colors.grey.shade50),
                dataRowMinHeight: 60,
                dataRowMaxHeight: 60,
                headingRowHeight: 56,
                columnSpacing: 24,
                horizontalMargin: 8,
                showCheckboxColumn: false,
                dividerThickness: 1,
                columns: [
                  _buildDataColumn(
                      'Name',
                      (user) => "${user['first_name']} ${user['last_name']}",
                      'first_name'),
                  _buildDataColumn(
                      'Dept',
                      (user) => _getDepartmentAbbreviation(user['department']),
                      'department'),
                  _buildDataColumn(
                      'Role', (user) => user['roles'] ?? 'N/A', 'roles'),
                  _buildDataColumn(
                      'Email', (user) => user['email'] ?? 'N/A', 'email'),
                  _buildDataColumn(
                      'Status', (user) => user['status'] ?? 'N/A', 'status'),
                  DataColumn(
                    label: Text(
                      'Actions',
                      style: TextStyle(
                        fontFamily: "B",
                        fontSize: 14,
                        color: primaryColor,
                      ),
                    ),
                  ),
                ],
                rows: List<DataRow>.generate(
                  displayUsers.length,
                  (index) {
                    var userData =
                        displayUsers[index].data() as Map<String, dynamic>;
                    String firstName = userData['first_name'] ?? '';
                    String lastName = userData['last_name'] ?? '';
                    String fullName = "$firstName $lastName".trim();
                    String department =
                        _getDepartmentAbbreviation(userData['department']);
                    String role = userData['roles'] ?? 'N/A';
                    String email = userData['email'] ?? 'N/A';
                    String status = userData['status'] ?? 'inactive';
                    String userId = displayUsers[index].id;

                    return DataRow(
                      cells: [
                        DataCell(
                          Row(
                            children: [
                              _buildUserAvatar(firstName, lastName),
                              const SizedBox(width: 12),
                              Text(
                                fullName,
                                style: TextStyle(
                                  fontFamily: "M",
                                  fontSize: 14,
                                  color: textPrimaryColor,
                                ),
                              ),
                            ],
                          ),
                        ),
                        DataCell(
                          Tooltip(
                            message:
                                userData['department'] ?? 'Unknown Department',
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                department,
                                style: TextStyle(
                                  fontFamily: "M",
                                  fontSize: 14,
                                  color: primaryColor,
                                ),
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _getRoleColor(role).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              role,
                              style: TextStyle(
                                fontFamily: "M",
                                fontSize: 14,
                                color: _getRoleColor(role),
                              ),
                            ),
                          ),
                        ),
                        DataCell(Text(
                          email,
                          style: TextStyle(
                            fontFamily: "R",
                            fontSize: 14,
                            color: textPrimaryColor,
                          ),
                        )),
                        DataCell(
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'active'
                                  ? Colors.green.withOpacity(0.1)
                                  : Colors.red.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              status,
                              style: TextStyle(
                                fontFamily: "M",
                                fontSize: 14,
                                color: status == 'active'
                                    ? Colors.green
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),
                        DataCell(
                          Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              _buildActionButton(
                                icon: Icons.visibility,
                                color: Colors.blue,
                                onPressed: () {
                                  // View user details
                                  _viewUser(userId);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.edit,
                                color: Colors.orange,
                                onPressed: () {
                                  // Edit user
                                  _editUser(userId);
                                },
                              ),
                              const SizedBox(width: 8),
                              _buildActionButton(
                                icon: Icons.delete,
                                color: Colors.red,
                                onPressed: () {
                                  // Delete/deactivate user
                                  _deleteUser(userId);
                                },
                              ),
                            ],
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Build a data column with sorting capability
  DataColumn _buildDataColumn(String label,
      dynamic Function(Map<String, dynamic>) getValue, String field) {
    return DataColumn(
      label: InkWell(
        onTap: () {
          setState(() {
            if (_sortColumn == field) {
              _sortAscending = !_sortAscending;
            } else {
              _sortColumn = field;
              _sortAscending = true;
            }
          });
        },
        child: Row(
          children: [
            Text(
              label,
              style: TextStyle(
                fontFamily: "B",
                fontSize: 14,
                color: primaryColor,
              ),
            ),
            const SizedBox(width: 4),
            if (_sortColumn == field)
              Icon(
                _sortAscending ? Icons.arrow_upward : Icons.arrow_downward,
                size: 14,
                color: primaryColor,
              ),
          ],
        ),
      ),
    );
  }

  /// Builds the pagination controls
  Widget _buildPagination() {
    // Calculate total pages
    final int totalPages = (_totalUsers / _itemsPerPage).ceil();

    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.first_page),
          onPressed:
              _currentPage > 1 ? () => setState(() => _currentPage = 1) : null,
          color: primaryColor,
        ),
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed:
              _currentPage > 1 ? () => setState(() => _currentPage--) : null,
          color: primaryColor,
        ),
        const SizedBox(width: 8),
        Text(
          'Page $_currentPage of $totalPages',
          style: TextStyle(
            fontFamily: "M",
            fontSize: 14,
            color: textPrimaryColor,
          ),
        ),
        const SizedBox(width: 8),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: _currentPage < totalPages
              ? () => setState(() => _currentPage++)
              : null,
          color: primaryColor,
        ),
        IconButton(
          icon: const Icon(Icons.last_page),
          onPressed: _currentPage < totalPages
              ? () => setState(() => _currentPage = totalPages)
              : null,
          color: primaryColor,
        ),
      ],
    );
  }

  /// Creates a circular avatar with initials for the user
  Widget _buildUserAvatar(String firstName, String lastName) {
    String avatarLetter = (firstName.isNotEmpty)
        ? firstName[0].toUpperCase()
        : (lastName.isNotEmpty)
            ? lastName[0].toUpperCase()
            : '?';

    // Generate a color based on the avatar letter
    final int colorValue =
        avatarLetter.codeUnitAt(0) * 10 % Colors.primaries.length;
    final Color avatarColor = Colors.primaries[colorValue];

    return CircleAvatar(
      backgroundColor: avatarColor,
      radius: 16,
      child: Text(
        avatarLetter,
        style: const TextStyle(
          fontFamily: "B",
          color: Colors.white,
          fontSize: 14,
        ),
      ),
    );
  }

  /// Builds action buttons for table rows
  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(4),
      ),
      child: IconButton(
        icon: Icon(icon, size: 18, color: color),
        onPressed: onPressed,
        constraints: const BoxConstraints(
          minHeight: 30,
          minWidth: 30,
        ),
        padding: const EdgeInsets.all(4),
        splashRadius: 20,
      ),
    );
  }

  /// Get color for different user roles
  Color _getRoleColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.purple;
      case 'superuser':
        return Colors.red;
      case 'manager':
        return Colors.green;
      case 'departmenthead':
        return Colors.blue;
      default:
        return Colors.teal;
    }
  }

  /// Get users stream with sorting
Stream<QuerySnapshot> _getUsersStream() {
  return FirebaseFirestore.instance
      .collection('users')
      .where('isDeleted', isEqualTo: false)  // Ensure no extra spaces
      .orderBy(_sortColumn, descending: !_sortAscending)  // Ensure _sortColumn is a valid field
      .snapshots();
}

  /// View user details (placeholder)
  void _viewUser(String userId) {
    // Show loading indicator
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
                Text("Loading user details...")
              ],
            ),
          ),
        );
      },
    );

    // Fetch and show user details
    FirebaseFirestore.instance.collection('users').doc(userId).get().then(
      (DocumentSnapshot document) {
        // Close loading dialog
        Navigator.of(context).pop();

        if (document.exists) {
          final userData = document.data() as Map<String, dynamic>;
          final firestoreUid = userData['uid']; // Fetch the correct stored UID
          final profileImageUrl = "$firestoreUid";

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: UserDetailsView(
                    userData: userData,
                    userId: userId,
                    profileImageUrl: profileImageUrl, // Ensure this is used
                  ),
                ),
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User not found or details unavailable')),
          );
        }
      },
      onError: (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user details: $e')),
        );
      },
    );
  }

  /// Edit user (placeholder)
  void _editUser(String userId) {
    // Show loading indicator
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
                Text("Loading user details...")
              ],
            ),
          ),
        );
      },
    );

    // Fetch and show user details
    FirebaseFirestore.instance.collection('users').doc(userId).get().then(
      (DocumentSnapshot document) {
        // Close loading dialog
        Navigator.of(context).pop();

        if (document.exists) {
          final userData = document.data() as Map<String, dynamic>;
          final firestoreUid = userData['uid']; // Fetch the correct stored UID
          final profileImageUrl = "$firestoreUid";

          showDialog(
            context: context,
            builder: (BuildContext context) {
              return Dialog(
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16.0)),
                child: ConstrainedBox(
                  constraints: BoxConstraints(
                    maxWidth: MediaQuery.of(context).size.width * 0.7,
                    maxHeight: MediaQuery.of(context).size.height * 0.8,
                  ),
                  child: EditableUserDetailsView(
                    userData: userData,
                    userId: userId,
                    profileImageUrl: profileImageUrl,
                  ),
                ),
              );
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
                content: Text('User not found or details unavailable')),
          );
        }
      },
      onError: (e) {
        Navigator.of(context).pop();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading user details: $e')),
        );
      },
    );
  }

  /// Delete/deactivate user (placeholder)
  void _deleteUser(String userId) {
    // Show confirmation dialog
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirm Action'),
          content: const Text('Are you sure you want to deactivate this user?'),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancel'),
              onPressed: () {
                Navigator.of(context).pop();
              },
            ),
            TextButton(
              child:
                  const Text('Deactivate', style: TextStyle(color: Colors.red)),
              onPressed: () async {
              Navigator.of(context).pop();

              try {
                await _firestore.collection("users").doc(userId).update({
                  "isDeleted": true,
                  "status": "inactive",
                  "deletedAt": FieldValue.serverTimestamp(),
                });

                print('User $userId marked as deleted.');
              } catch (e) {
                print('Error marking user as deleted: $e');
              }
              }
            ),
          ],
        );
      },
    );
  }
}
