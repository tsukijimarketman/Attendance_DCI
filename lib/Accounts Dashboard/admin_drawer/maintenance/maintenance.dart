import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_references_su.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/maintenance/appointmentconfig.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/maintenance/manage_users.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'dart:async';
import 'dart:ui';
import 'package:flutter/rendering.dart';

/// UserMasterlist - A comprehensive view of all users organized by roles and departments
///
/// This widget provides a unified view of the organization's user structure with two main tabs:
/// 1. Role-based view - Shows users grouped by their roles (Admin, Manager, etc.)
/// 2. Department-based view - Shows users grouped by their departments
class Maintenance extends StatefulWidget {
  const Maintenance({super.key});

  @override
  State<Maintenance> createState() => _MaintenanceState();
}

class _MaintenanceState extends State<Maintenance>
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

  bool _showRoleView = true;

  // State management variables
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

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
              child: Text("Maintenance",
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
                  _buildSortedUsersContent(),
                  ManageUsers(
                    searchQuery: _searchQuery,
                  ),
                  AdminReferences(searchQuery: _searchController),
                  Appointmentconfig(searchQuery: _searchQuery)
                ],
              ),
            ),
          ],
        ),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        mainAxisSize: MainAxisSize.max,
        children: [
          // Search Bar
          Container(
            height: 40,
            width: 500,
            decoration: BoxDecoration(
              color: Colors.grey.shade100,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search....',
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

          // Tabs
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            mainAxisSize: MainAxisSize.min,
            children: [
              _buildTabButton(0, 'Sort Users', Icons.people_outline),
              _buildTabButton(1, 'Manage Users', Icons.settings),
              _buildTabButton(2, 'Manage Departments', Icons.workspaces),
              _buildTabButton(3, 'Appointment Configuration',  Icons.settings_applications)

            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSortedUsersContent() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 24.0),
      child: Column(
        children: [
          // Toggle switch at the top
          Container(
            margin: const EdgeInsets.only(bottom: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // By Roles button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showRoleView = true;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        _showRoleView ? primaryColor : Colors.grey.shade200,
                    foregroundColor:
                        _showRoleView ? Colors.white : Colors.black87,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.circular(8),
                        right: Radius.zero,
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      'By Roles',
                      style: TextStyle(
                        fontFamily: _showRoleView ? "B" : "M",
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),

                // By Departments button
                ElevatedButton(
                  onPressed: () {
                    setState(() {
                      _showRoleView = false;
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor:
                        !_showRoleView ? primaryColor : Colors.grey.shade200,
                    foregroundColor:
                        !_showRoleView ? Colors.white : Colors.black87,
                    shape: const RoundedRectangleBorder(
                      borderRadius: BorderRadius.horizontal(
                        left: Radius.zero,
                        right: Radius.circular(8),
                      ),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 16, vertical: 12),
                    child: Text(
                      'By Departments',
                      style: TextStyle(
                        fontFamily: !_showRoleView ? "B" : "M",
                        fontSize: 14,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),

          // Show the appropriate content based on toggle state with scrollbar
          Expanded(
            child: Container(
              color: Colors.blueGrey[100],
              child: _showRoleView
                  ? _buildScrollableRoleView()
                  : _buildScrollableDepartmentView(),
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
  Widget _buildScrollableRoleView() {
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
      child: Theme(
        // This ensures the scrollbar has the right colors
        data: Theme.of(context).copyWith(
          scrollbarTheme: ScrollbarThemeData(
            thumbColor:
                MaterialStateProperty.all(primaryColor.withOpacity(0.7)),
            trackColor: MaterialStateProperty.all(Colors.grey.withOpacity(0.2)),
            thickness: MaterialStateProperty.all(10.0),
            radius: const Radius.circular(10.0),
            thumbVisibility: MaterialStateProperty.all(true),
            trackVisibility: MaterialStateProperty.all(true),
            trackBorderColor:
                MaterialStateProperty.all(Colors.grey.withOpacity(0.5)),
          ),
        ),
        child: ScrollConfiguration(
          // This enables scrollbars on all platforms
          behavior: ScrollConfiguration.of(context).copyWith(
            dragDevices: {
              PointerDeviceKind.touch,
              PointerDeviceKind.mouse,
            },
          ),
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            physics: const AlwaysScrollableScrollPhysics(),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: roleCategories.map((category) {
                return Container(
                  width: 320, // Fixed width for each card
                  margin: const EdgeInsets.only(right: 16),
                  child: _buildRoleCard(
                    category["title"]!,
                    category["role"]!,
                  ),
                );
              }).toList(),
            ),
          ),
        ),
      ),
    );
  }

  /// Builds the content for the department-based masterlist tab
  // Similarly, modify _buildDepartmentMasterlistContent
  Widget _buildScrollableDepartmentView() {
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

          return Theme(
            // This ensures the scrollbar has the right colors
            data: Theme.of(context).copyWith(
              scrollbarTheme: ScrollbarThemeData(
                thumbColor:
                    MaterialStateProperty.all(primaryColor.withOpacity(0.7)),
                trackColor:
                    MaterialStateProperty.all(Colors.grey.withOpacity(0.2)),
                thickness: MaterialStateProperty.all(10.0),
                radius: const Radius.circular(10.0),
                thumbVisibility: MaterialStateProperty.all(true),
                trackVisibility: MaterialStateProperty.all(true),
                trackBorderColor:
                    MaterialStateProperty.all(Colors.grey.withOpacity(0.5)),
              ),
            ),
            child: ScrollConfiguration(
              // This enables scrollbars on all platforms
              behavior: ScrollConfiguration.of(context).copyWith(
                dragDevices: {
                  PointerDeviceKind.touch,
                  PointerDeviceKind.mouse,
                },
              ),
              child: SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                physics: const AlwaysScrollableScrollPhysics(),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: departments.map((entry) {
                    final department = entry.key;
                    final users = entry.value;

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

                    return Container(
                      width: 320, // Fixed width for each card
                      margin: const EdgeInsets.only(right: 16),
                      child: _buildDepartmentCard(department, filteredUsers),
                    );
                  }).toList(),
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Builds a card for a specific role category
  Widget _buildRoleCard(String title, String role) {
     return FutureBuilder<Map<String, String>>(
    future: _fetchDepartmentNames(),
    builder: (context, deptSnapshot) {
      if (!deptSnapshot.hasData) {
        return const Center(child: CircularProgressIndicator());
      }

      final deptMap = deptSnapshot.data!;
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
    String deptID = userData['deptID'] ?? '';

                     String department =
                            deptMap[deptID] ?? 'Unknown Department';
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
   Future<Map<String, List<Map<String, dynamic>>>> _fetchUsersGroupedByDepartment() async {

final deptSnapshot = await FirebaseFirestore.instance
      .collection('references')
      .where('isDeleted', isEqualTo: false)
      .get();

  // Create a map of deptID -> name
  final Map<String, String> deptMap = {
    for (var doc in deptSnapshot.docs)
      if (doc.data().containsKey('deptID') && doc.data().containsKey('name'))
        doc['deptID']: doc['name']
  };

  // Fetch active users
  final userSnapshot = await FirebaseFirestore.instance
      .collection('users')
      .where('status', isEqualTo: 'active')
      .get();

  final Map<String, List<Map<String, dynamic>>> groupedUsers = {};

  for (var doc in userSnapshot.docs) {
    final userData = doc.data();

    final deptID = userData['deptID'];
    final deptName = deptMap[deptID] ?? 'Unknown Department';

    if (!groupedUsers.containsKey(deptName)) {
      groupedUsers[deptName] = [];
    }

    groupedUsers[deptName]!.add(userData);
  }

   return groupedUsers;
}
    }

 Future<Map<String, String>> _fetchDepartmentNames() async {
  final snapshot = await FirebaseFirestore.instance
      .collection('references')
      .where('isDeleted', isEqualTo: false)
      .get();

  Map<String, String> deptMap = {};
  for (var doc in snapshot.docs) {
    final data = doc.data();
    if (data.containsKey('deptID') && data.containsKey('name')) {
      deptMap[data['deptID']] = data['name'];
    }
  }

     return deptMap;
}


    
