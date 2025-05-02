import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';

/// UserMasterlist - A comprehensive view of all users organized by roles and departments
///
/// This widget provides a unified view of the organization's user structure with two main tabs:
/// 1. Role-based view - Shows users grouped by their roles (Admin, Manager, etc.)
/// 2. Department-based view - Shows users grouped by their departments
class UserMasterlist extends StatefulWidget {
  const UserMasterlist({super.key});

  @override
  State<UserMasterlist> createState() => _UserMasterlistState();
}

class _UserMasterlistState extends State<UserMasterlist>
    with SingleTickerProviderStateMixin {
  // Primary color theme for the application
  final Color primaryColor = const Color.fromARGB(255, 20, 94, 155);

  // Secondary colors for UI elements
  final Color cardColor = Colors.white;
  final Color dividerColor = Colors.black12;
  final Color textPrimaryColor = Colors.black87;
  final Color cardHighlightColor = Colors.grey.shade100;

  // Tab controller for managing the two view types
  late TabController _tabController;

  // Search functionality
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _debounce;

  // State management variables
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    // Add listener to search controller with debounce
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Search with debounce to avoid rapid UI updates
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();
    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        _searchQuery = _searchController.text.toLowerCase();
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 40,
          vertical: MediaQuery.of(context).size.width / 180,
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).size.width / 100),
            Container(
              width: MediaQuery.of(context).size.width,
              height: MediaQuery.of(context).size.height / 15,
              decoration: BoxDecoration(
                  border: Border(
                      bottom: BorderSide(
                          color: Color.fromARGB(255, 11, 55, 99), width: 2))),
              child: Text("Users Masterlist",
                  style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 41,
                      fontFamily: "BL",
                      fontWeight: FontWeight.bold,
                      color: Color.fromARGB(255, 11, 55, 99))),
            ),

            // Search and Tab Bar Row
            _buildSearchAndTabsRow(),

            // Main Content Area
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildRoleMasterlistContent(),
                  _buildDepartmentMasterlistContent(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the header section with title and any additional UI elements
  Widget _buildHeaderSection() {
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'User Directory',
            style: TextStyle(
              fontFamily: "BL",
              fontSize: 28,
              color: primaryColor,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Manage and view all users organized by roles and departments',
            style: TextStyle(
              fontFamily: "R",
              fontSize: 16,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  /// Builds the search bar and tab bar row
  Widget _buildSearchAndTabsRow() {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(
            color: dividerColor,
            width: 1,
          ),
        ),
      ),
      child: Row(
        children: [
          // Search Bar
          Expanded(
            flex: 2,
            child: Container(
              height: 40,
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: 'Search users...',
                  hintStyle: TextStyle(
                    fontFamily: "R",
                    fontSize: 14,
                    color: Colors.grey[500],
                  ),
                  prefixIcon: Icon(Icons.search, color: Colors.grey[500]),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(vertical: 8),
                ),
                style: TextStyle(
                  fontFamily: "M",
                  fontSize: 14,
                ),
              ),
            ),
          ),

          // Space between search and tabs
          const SizedBox(width: 24),

          // Tabs
          Expanded(
            flex: 3,
            child: Row(
              children: [
                _buildTabButton(0, 'By Roles', Icons.people_outline),
                const SizedBox(width: 24),
                _buildTabButton(1, 'By Departments', Icons.business),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Builds a single tab button
  Widget _buildTabButton(int index, String label, IconData icon) {
    bool isSelected = _tabController.index == index;

    return InkWell(
      onTap: () => setState(() => _tabController.animateTo(index)),
      borderRadius: BorderRadius.circular(4),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: isSelected ? primaryColor : Colors.transparent,
              width: 3,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(
              icon,
              color: isSelected ? primaryColor : Colors.grey,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: isSelected ? "B" : "M",
                color: isSelected ? primaryColor : Colors.grey,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds the content for the role-based masterlist tab
  Widget _buildRoleMasterlistContent() {
    // Predefined role categories
    final List<Map<String, String>> roleCategories = [
      {"title": "Internal Users", "role": "User"},
      {"title": "Managers", "role": "Manager"},
      {"title": "Department Heads", "role": "DepartmentHead"},
      {"title": "Administrators", "role": "Admin"},
      {"title": "Super Users", "role": "Superuser"},
    ];

    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          childAspectRatio: 1.2,
        ),
        itemCount: roleCategories.length,
        itemBuilder: (context, index) {
          return _buildRoleCard(
            roleCategories[index]["title"]!,
            roleCategories[index]["role"]!,
          );
        },
      ),
    );
  }

  /// Builds the content for the department-based masterlist tab
  Widget _buildDepartmentMasterlistContent() {
    return Padding(
      padding: const EdgeInsets.all(24.0),
      child: FutureBuilder<Map<String, List<Map<String, dynamic>>>>(
        future: _fetchUsersGroupedByDepartment(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return Center(
              child: Text(
                "No departments or active users found",
                style: TextStyle(
                  fontFamily: "M",
                  color: Colors.grey[600],
                  fontSize: 16,
                ),
              ),
            );
          }

          final grouped = snapshot.data!;
          final departments = grouped.entries.toList();

          return GridView.builder(
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 1.2,
            ),
            itemCount: departments.length,
            itemBuilder: (context, index) {
              final department = departments[index].key;
              final users = departments[index].value;

              // Filter users based on search query
              final filteredUsers = _searchQuery.isEmpty
                  ? users
                  : users.where((user) {
                      final name =
                          "${user['first_name'] ?? ''} ${user['last_name'] ?? ''}"
                              .toLowerCase();
                      final email = (user['email'] ?? '').toLowerCase();
                      return name.contains(_searchQuery) ||
                          email.contains(_searchQuery);
                    }).toList();

              return _buildDepartmentCard(department, filteredUsers);
            },
          );
        },
      ),
    );
  }

  /// Builds a card for a specific role category
  Widget _buildRoleCard(String title, String role) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    title,
                    style: TextStyle(
                      fontFamily: "SB",
                      fontSize: 18,
                      color: primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StreamBuilder<QuerySnapshot>(
                    stream: FirebaseFirestore.instance
                        .collection('users')
                        .where('status', isEqualTo: 'active')
                        .where('roles', isEqualTo: role)
                        .snapshots(),
                    builder: (context, snapshot) {
                      int count =
                          snapshot.hasData ? snapshot.data!.docs.length : 0;
                      return Text(
                        '$count',
                        style: TextStyle(
                          fontFamily: "B",
                          color: primaryColor,
                          fontSize: 14,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, thickness: 1, color: dividerColor),
            const SizedBox(height: 8),
            Expanded(
              child: StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance
                    .collection('users')
                    .where('status', isEqualTo: 'active')
                    .where('roles', isEqualTo: role)
                    .snapshots(),
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
                        ),
                      ),
                    );
                  }

                  var users = snapshot.data!.docs;

                  // Filter users based on search query
                  if (_searchQuery.isNotEmpty) {
                    users = users.where((doc) {
                      var userData = doc.data() as Map<String, dynamic>;
                      String name =
                          "${userData['first_name'] ?? ''} ${userData['last_name'] ?? ''}"
                              .toLowerCase();
                      String email = (userData['email'] ?? '').toLowerCase();
                      return name.contains(_searchQuery) ||
                          email.contains(_searchQuery);
                    }).toList();
                  }

                  if (users.isEmpty) {
                    return Center(
                      child: Text(
                        "No matching users found",
                        style: TextStyle(
                          fontFamily: "M",
                          color: Colors.grey[600],
                        ),
                      ),
                    );
                  }

                  return ListView.separated(
                    itemCount: users.length,
                    separatorBuilder: (context, index) =>
                        const SizedBox(height: 8),
                    itemBuilder: (context, index) {
                      var userData =
                          users[index].data() as Map<String, dynamic>;
                      String firstName = userData['first_name'] ?? '';
                      String lastName = userData['last_name'] ?? '';
                      String name = "$firstName $lastName".trim();
                      String email = userData['email'] ?? 'No email';
                      String department = userData['department'] ?? 'N/A';

                      // Get first letter for avatar
                      String avatarLetter = (firstName.isNotEmpty)
                          ? firstName[0].toUpperCase()
                          : (lastName.isNotEmpty)
                              ? lastName[0].toUpperCase()
                              : '?';

                      return _buildUserTile(
                          name, email, department, avatarLetter);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a card for a specific department
  Widget _buildDepartmentCard(
      String department, List<Map<String, dynamic>> users) {
    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      color: cardColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(
                    department,
                    style: TextStyle(
                      fontFamily: "SB",
                      fontSize: 18,
                      color: primaryColor,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: primaryColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${users.length}',
                    style: TextStyle(
                      fontFamily: "B",
                      color: primaryColor,
                      fontSize: 14,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(height: 1, thickness: 1, color: dividerColor),
            const SizedBox(height: 8),
            Expanded(
              child: users.isEmpty
                  ? Center(
                      child: Text(
                        "No matching users found",
                        style: TextStyle(
                          fontFamily: "M",
                          color: Colors.grey[600],
                        ),
                      ),
                    )
                  : ListView.separated(
                      itemCount: users.length,
                      separatorBuilder: (context, index) =>
                          const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        final user = users[index];
                        final firstName = user['first_name'] ?? '';
                        final lastName = user['last_name'] ?? '';
                        final name = "$firstName $lastName".trim();
                        final email = user['email'] ?? 'No Email';
                        final role = user['roles'] ?? 'No Role';

                        // Get first letter for avatar
                        String avatarLetter = (firstName.isNotEmpty)
                            ? firstName[0].toUpperCase()
                            : (lastName.isNotEmpty)
                                ? lastName[0].toUpperCase()
                                : '?';

                        return _buildUserTile(name, email, role, avatarLetter);
                      },
                    ),
            ),
          ],
        ),
      ),
    );
  }

  /// Builds a consistent user list tile with avatar
  Widget _buildUserTile(
      String name, String email, String detail, String avatarLetter) {
    // Generate a color based on the avatar letter (for consistent colors per user)
    final int colorValue =
        avatarLetter.codeUnitAt(0) * 10 % Colors.primaries.length;
    final Color avatarColor = Colors.primaries[colorValue];

    return Container(
      decoration: BoxDecoration(
        color: cardHighlightColor,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      child: Row(
        children: [
          // Circle Avatar with first letter
          CircleAvatar(
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
          ),
          const SizedBox(width: 12),

          // User details
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontFamily: "B",
                    fontSize: 14,
                    color: textPrimaryColor,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  email,
                  style: TextStyle(
                    fontFamily: "R",
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Text(
                  detail,
                  style: TextStyle(
                    fontFamily: "M",
                    fontSize: 12,
                    color: primaryColor,
                    fontStyle: FontStyle.italic,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Fetches and groups users by department
  Future<Map<String, List<Map<String, dynamic>>>>
      _fetchUsersGroupedByDepartment() async {
    QuerySnapshot userSnapshot = await FirebaseFirestore.instance
        .collection('users')
        .where('status', isEqualTo: 'active')
        .get();

    Map<String, List<Map<String, dynamic>>> grouped = {};

    for (var doc in userSnapshot.docs) {
      var data = doc.data() as Map<String, dynamic>;
      String department = data['department'] ?? 'Unknown Department';

      if (!grouped.containsKey(department)) {
        grouped[department] = [];
      }

      grouped[department]!.add(data);
    }

    return grouped;
  }
}
