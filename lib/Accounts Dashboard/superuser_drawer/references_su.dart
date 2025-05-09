import 'dart:async';
import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class References extends StatefulWidget {
  final TextEditingController searchQuery;
  const References({super.key, required this.searchQuery});

  @override
  State<References> createState() => _ReferencesState();
}

class _ReferencesState extends State<References> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _searchDataController = TextEditingController();
  TextEditingController _editDataController = TextEditingController();

  // Default to the "Department" category
  String? selectedCategoryId;
  String? _selectedDataId;
  String dataSearchQuery = "";

  // Pagination variables
  int _currentPage = 1;
  final int _itemsPerPage = 10;
  List<DocumentSnapshot> _allDepartments = [];
  List<DocumentSnapshot> _filteredDepartments = [];
  Timer? _debounce;

  // Font constants
  static const String fontRegular = "R";
  static const String fontMedium = "M";
  static const String fontSemiBold = "SB";
  static const String fontBold = "B";
  static const String fontBlack = "BL";

  @override
  void initState() {
    super.initState();
    // Fetch the Department category ID on initialization

    // Initialize the search controller with any existing search query
    _searchDataController.text = widget.searchQuery.text;

    // Add listener to local controller
    _searchDataController.addListener(_onSearchChanged);

    // Also listen to widget's search query changes
    widget.searchQuery.addListener(_onExternalSearchChanged);

    // Initial search with any existing query
    dataSearchQuery = _searchDataController.text.toLowerCase();
  }

  @override
  void dispose() {
    _searchDataController.removeListener(_onSearchChanged);
    widget.searchQuery.removeListener(_onExternalSearchChanged);
    _searchDataController.dispose();
    _nameController.dispose();
    _editDataController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  // Search input listener with debounce
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 500), () {
      setState(() {
        dataSearchQuery = _searchDataController.text.toLowerCase();
        _filterDepartments();
        _currentPage = 1; // Reset to first page when search changes
      });
    });
  }

  void _onExternalSearchChanged() {
    if (_searchDataController.text != widget.searchQuery.text) {
      _searchDataController.text = widget.searchQuery.text;
      // No need to call _onSearchChanged, as the listener will trigger it
    }
  }

  // This method filters departments based on search criteria
  void _filterDepartments() {
    if (dataSearchQuery.isEmpty) {
      _filteredDepartments = List.from(_allDepartments);
    } else {
      _filteredDepartments = _allDepartments.where((department) {
        String departmentName = department["name"].toString().toLowerCase();
        return departmentName.contains(dataSearchQuery);
      }).toList();
    }
  }

  // This method returns the items for the current page based on pagination settings
  List<DocumentSnapshot> _getCurrentPageItems() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    if (startIndex >= _filteredDepartments.length) {
      return [];
    }

    if (endIndex > _filteredDepartments.length) {
      return _filteredDepartments.sublist(startIndex);
    }

    return _filteredDepartments.sublist(startIndex, endIndex);
  }

  // This getter calculates the total number of pages needed
  int get _totalPages {
    return (_filteredDepartments.length / _itemsPerPage).ceil();
  }



  @override
  Widget build(BuildContext context) {
    // Get screen dimensions for responsive layout
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        width: screenWidth,
        padding: EdgeInsets.symmetric(
            horizontal: screenWidth * 0.02,
            vertical: screenWidth / 80), // Responsive padding
        child: Column(
          children: [
            Container(
              width: screenWidth,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(12.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          ElevatedButton.icon(
                            icon: Icon(Icons.add, color: Colors.white),
                            label: Text(
                              'Add Department',
                              style: TextStyle(
                                fontFamily: fontMedium,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor:
                                  const Color.fromARGB(255, 11, 55, 99),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(8),
                              ),
                              padding: EdgeInsets.symmetric(
                                horizontal: screenWidth * 0.015,
                                vertical: screenHeight * 0.01,
                              ),
                            ),
                            onPressed: () => _showDialogAddData(context),
                          ),
                        ],
                      ),
                    ),
                    // Department List
                    Container(
                      height: screenWidth / 3.65,
                      child: Container(
                        child: StreamBuilder(
                          stream: 
                               _firestore
                                  .collection("references")
                                  .where('isDeleted', isEqualTo: false)
                                  .snapshots(),
                          builder:
                              (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(
                                child: CircularProgressIndicator(
                                  color: const Color.fromARGB(255, 11, 55, 99),
                                ),
                              );
                            }

                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.folder_open,
                                      size: screenWidth * 0.04,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      "No departments available",
                                      style: TextStyle(
                                        fontFamily: fontMedium,
                                        fontSize: screenWidth * 0.012,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            // Update all departments when data changes
                            _allDepartments = snapshot.data!.docs;

                            // Apply filtering based on search query
                            if (dataSearchQuery.isEmpty) {
                              _filteredDepartments = _allDepartments;
                            } else {
                              _filterDepartments();
                            }

                            // Get current page items
                            final currentPageItems = _getCurrentPageItems();

                            if (_filteredDepartments.isEmpty) {
                              return Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.search_off,
                                      size: screenWidth * 0.04,
                                      color: Colors.grey,
                                    ),
                                    SizedBox(height: screenHeight * 0.01),
                                    Text(
                                      "No departments matching your search",
                                      style: TextStyle(
                                        fontFamily: fontMedium,
                                        fontSize: screenWidth * 0.012,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }

                            return Column(
                              children: [
                                Expanded(
                                  child: Padding(
                                    padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.02,
                                      vertical: screenHeight * 0.01,
                                    ),
                                    child: ListView.separated(
                                      itemCount: currentPageItems.length,
                                      separatorBuilder: (context, index) =>
                                          Divider(
                                        color: Colors.grey.shade300,
                                        height: 1,
                                      ),
                                      itemBuilder: (context, index) {
                                        var data = currentPageItems[index];
                                        bool isSelected =
                                            _selectedDataId == data.id;

                                        return Container(
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? const Color.fromARGB(
                                                        255, 11, 55, 99)
                                                    .withOpacity(0.1)
                                                : Colors.transparent,
                                            borderRadius:
                                                BorderRadius.circular(8),
                                          ),
                                          child: ListTile(
                                            contentPadding:
                                                EdgeInsets.symmetric(
                                              horizontal: screenWidth * 0.02,
                                              vertical: screenHeight * 0.005,
                                            ),
                                            title: Text(
                                              data["name"],
                                              style: TextStyle(
                                                fontFamily: isSelected
                                                    ? fontSemiBold
                                                    : fontRegular,
                                                fontSize: screenWidth * 0.012 >
                                                        18
                                                    ? 18
                                                    : screenWidth * 0.012 < 14
                                                        ? 14
                                                        : screenWidth * 0.012,
                                                color: isSelected
                                                    ? const Color.fromARGB(
                                                        255, 11, 55, 99)
                                                    : Colors.black87,
                                              ),
                                            ),
                                            onTap: () {
                                              setState(() {
                                                _selectedDataId =
                                                    isSelected ? null : data.id;
                                              });
                                            },
                                            trailing: Row(
                                              mainAxisSize: MainAxisSize.min,
                                              children: [
                                                if (isSelected) ...[
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons.edit_rounded,
                                                      color:
                                                          const Color.fromARGB(
                                                              255, 11, 55, 99),
                                                      size: screenWidth *
                                                                  0.012 >
                                                              24
                                                          ? 24
                                                          : screenWidth *
                                                                      0.012 <
                                                                  16
                                                              ? 16
                                                              : screenWidth *
                                                                  0.012,
                                                    ),
                                                    onPressed: () =>
                                                        _showEditDialog(data.id,
                                                            data["name"]),
                                                    tooltip: 'Edit Department',
                                                  ),
                                                  IconButton(
                                                    icon: Icon(
                                                      Icons
                                                          .delete_outline_rounded,
                                                      color: Colors.redAccent,
                                                      size: screenWidth *
                                                                  0.012 >
                                                              24
                                                          ? 24
                                                          : screenWidth *
                                                                      0.012 <
                                                                  16
                                                              ? 16
                                                              : screenWidth *
                                                                  0.012,
                                                    ),
                                                    onPressed: () =>
                                                        _showdialogDeleteData(
                                                            data.id),
                                                    tooltip:
                                                        'Delete Department',
                                                  ),
                                                ] else
                                                  Icon(
                                                    Icons.keyboard_arrow_right,
                                                    color: Colors.grey,
                                                    size: screenWidth * 0.012 >
                                                            24
                                                        ? 24
                                                        : screenWidth * 0.012 <
                                                                16
                                                            ? 16
                                                            : screenWidth *
                                                                0.012,
                                                  ),
                                              ],
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                // Pagination info
                                Padding(
                                  padding: EdgeInsets.symmetric(
                                      horizontal: screenWidth * 0.02),
                                  child: Text(
                                    'Showing ${currentPageItems.length} of ${_filteredDepartments.length} departments',
                                    style: TextStyle(
                                      color: Colors.grey.shade600,
                                      fontSize: screenWidth * 0.01,
                                      fontFamily: fontRegular,
                                    ),
                                  ),
                                ),
                                // Pagination controls
                                Container(
                                  padding: EdgeInsets.symmetric(
                                      vertical: screenHeight * 0.01),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      IconButton(
                                        icon: Icon(Icons.first_page,
                                            color: _currentPage > 1
                                                ? const Color.fromARGB(
                                                    255, 11, 55, 99)
                                                : Colors.grey),
                                        onPressed: _currentPage > 1
                                            ? () =>
                                                setState(() => _currentPage = 1)
                                            : null,
                                        tooltip: 'First Page',
                                        iconSize: screenWidth * 0.01 > 20
                                            ? 20
                                            : screenWidth * 0.01,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.chevron_left,
                                            color: _currentPage > 1
                                                ? const Color.fromARGB(
                                                    255, 11, 55, 99)
                                                : Colors.grey),
                                        onPressed: _currentPage > 1
                                            ? () =>
                                                setState(() => _currentPage--)
                                            : null,
                                        tooltip: 'Previous Page',
                                        iconSize: screenWidth * 0.01 > 20
                                            ? 20
                                            : screenWidth * 0.01,
                                      ),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.01),
                                        child: Text(
                                          'Page $_currentPage of $_totalPages',
                                          style: TextStyle(
                                            fontFamily: fontMedium,
                                            fontSize: screenWidth * 0.01,
                                            color: const Color.fromARGB(
                                                255, 11, 55, 99),
                                          ),
                                        ),
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.chevron_right,
                                            color: _currentPage < _totalPages
                                                ? const Color.fromARGB(
                                                    255, 11, 55, 99)
                                                : Colors.grey),
                                        onPressed: _currentPage < _totalPages
                                            ? () =>
                                                setState(() => _currentPage++)
                                            : null,
                                        tooltip: 'Next Page',
                                        iconSize: screenWidth * 0.01 > 20
                                            ? 20
                                            : screenWidth * 0.01,
                                      ),
                                      IconButton(
                                        icon: Icon(Icons.last_page,
                                            color: _currentPage < _totalPages
                                                ? const Color.fromARGB(
                                                    255, 11, 55, 99)
                                                : Colors.grey),
                                        onPressed: _currentPage < _totalPages
                                            ? () => setState(() =>
                                                _currentPage = _totalPages)
                                            : null,
                                        tooltip: 'Last Page',
                                        iconSize: screenWidth * 0.01 > 20
                                            ? 20
                                            : screenWidth * 0.01,
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Updated _showDialogAddData method with the new design
  void _showDialogAddData(BuildContext context) {
    _nameController.clear();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 8.0,
              child: Container(
                height: MediaQuery.of(context).size.width / 5.5,
                width: MediaQuery.of(context).size.width / 3.5,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF5F9FF)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.business,
                          color: Color(0xFF0e2643),
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Add Department",
                          style: TextStyle(
                            fontFamily: fontSemiBold,
                            color: Color(0xFF0e2643),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    // Content
                    Container(
                      padding: EdgeInsets.all(15),
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
                      child: AnimatedTextField(
                        controller: _nameController,
                        label: "Department Name",
                        suffix: null,
                        readOnly: false,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 8,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 170),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: fontRegular,
                                fontSize:
                                    MediaQuery.of(context).size.width / 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 8,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 170),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () {
                              _addData();
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Confirm",
                              style: TextStyle(
                                fontFamily: fontRegular,
                                fontSize:
                                    MediaQuery.of(context).size.width / 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Updated _showEditDialog method with the new design
  void _showEditDialog(String dataId, String currentName) {
    _editDataController.text = currentName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 8.0,
              child: Container(
                height: MediaQuery.of(context).size.width / 5.5,
                width: MediaQuery.of(context).size.width / 3.5,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF5F9FF)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.edit,
                          color: Color(0xFF0e2643),
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Edit Department",
                          style: TextStyle(
                            fontFamily: fontSemiBold,
                            color: Color(0xFF0e2643),
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    // Content
                    Container(
                      padding: EdgeInsets.all(15),
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
                      child: AnimatedTextField(
                        controller: _editDataController,
                        label: "Department Name",
                        suffix: null,
                        readOnly: false,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 8,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.red,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 170),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: fontRegular,
                                fontSize:
                                    MediaQuery.of(context).size.width / 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 8,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 170),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () {
                              _updateData(dataId, _editDataController.text);
                              Navigator.pop(context);
                            },
                            child: Text(
                              "Confirm",
                              style: TextStyle(
                                fontFamily: fontRegular,
                                fontSize:
                                    MediaQuery.of(context).size.width / 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

// Updated _showdialogDeleteData method with the new design
  void _showdialogDeleteData(String id) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16.0),
              ),
              elevation: 8.0,
              child: Container(
                height: MediaQuery.of(context).size.width / 5.5,
                width: MediaQuery.of(context).size.width / 3.5,
                padding: EdgeInsets.all(20),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16.0),
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [Colors.white, Color(0xFFF5F9FF)],
                  ),
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.delete_forever,
                          color: Colors.red[700],
                          size: 28,
                        ),
                        SizedBox(width: 10),
                        Text(
                          "Delete Department",
                          style: TextStyle(
                            fontFamily: fontSemiBold,
                            color: Colors.red[700],
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 15),
                    // Content
                    Container(
                      padding: EdgeInsets.all(15),
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
                      child: Text(
                        "Are you sure you want to delete this department? This action cannot be undone.",
                        style: TextStyle(
                          fontFamily: fontRegular,
                          fontSize: MediaQuery.of(context).size.width / 90,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    SizedBox(height: 20),
                    // Buttons
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        Container(
                          width: MediaQuery.of(context).size.width / 8,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.grey[400],
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 170),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: Text(
                              "Cancel",
                              style: TextStyle(
                                fontFamily: fontRegular,
                                fontSize:
                                    MediaQuery.of(context).size.width / 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 8,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.red[700],
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 170),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextButton(
                            onPressed: () {
   _deleteData(_selectedDataId!); // Let the function decide whether to close the dialog
Navigator.pop(context);
                            },
                            child: Text(
                              "Delete",
                              style: TextStyle(
                                fontFamily: fontRegular,
                                fontSize:
                                    MediaQuery.of(context).size.width / 100,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

Future<void> _updateData(String dataId, String newName) async {
  if (dataId.isEmpty || newName.trim().isEmpty) return;

  try {
    await _firestore.collection("references").doc(dataId).update({
      "name": newName.trim(),
    });

    await logAuditTrail(
        "Department Updated", "Updated department '$dataId' with new name: $newName");

    setState(() => _selectedDataId = null);
    _showSuccessToast('Department updated successfully');
  } catch (e) {
    _showErrorToast('Error updating department: $e');
  }
}


Future<void> _addData() async {
  if (_nameController.text.trim().isEmpty) return;

  try {
    final referencesRef = _firestore.collection("references");

    // Get the highest current deptID
    final snapshot = await referencesRef
        .orderBy("deptID", descending: true)
        .limit(1)
        .get();

    String nextDeptID = "1";  // Start with "1" as the initial department ID (string)
    if (snapshot.docs.isNotEmpty) {
      final currentMax = snapshot.docs.first.data()['deptID'];
      if (currentMax != null) {
        // If currentMax is already a string, parse and increment
        if (currentMax is String) {
          nextDeptID = (int.tryParse(currentMax) ?? 0 + 1).toString();
        }
        // If currentMax is an integer, increment and convert to string
        else if (currentMax is int) {
          nextDeptID = (currentMax + 1).toString();
        }
      }
    }

    final docRef = await referencesRef.add({
      "deptID": nextDeptID,  // Save deptID as a string
      "name": _nameController.text.trim(),
      "timestamp": FieldValue.serverTimestamp(),
      "isDeleted": false,
    });

    await logAuditTrail("Department Added",
        "Added new department '${docRef.id}' with deptID: $nextDeptID and name: ${_nameController.text}");

    _showSuccessToast('Department added successfully');
  } catch (e) {
    _showErrorToast('Error adding department: $e');
  }
}



Future<void> _deleteData(String id) async {
  if (id.isEmpty) return;

  try {
    DocumentSnapshot docSnapshot =
        await _firestore.collection("references").doc(id).get();

    if (!docSnapshot.exists || docSnapshot.data() == null) {
      _showErrorToast('Department not found');
      return;
    }

    final data = docSnapshot.data() as Map<String, dynamic>;
    String name = data['name'] ?? 'Unknown';
    String deptID = data['deptID'] ?? id;

    List<String> blockingSources = [];

    // Check users
    final usersSnapshot = await _firestore
        .collection("users")
        .where("deptID", isEqualTo: deptID)
        .limit(1)
        .get();

    if (usersSnapshot.docs.isNotEmpty) blockingSources.add("Users");

    // Check appointments
    final appointmentsSnapshot = await _firestore
        .collection("appointment")
        .where("deptID", isEqualTo: deptID)
        .limit(1)
        .get();

    if (appointmentsSnapshot.docs.isNotEmpty) blockingSources.add("Appointments");

    if (blockingSources.isNotEmpty) {
      _showBlockedDeletionDialog(blockingSources);
      return;
    }

    // Proceed with soft delete
    await _firestore.collection("references").doc(id).update({
      "isDeleted": true,
    });

    await logAuditTrail(
        "Department Deleted", "Deleted department '$id' with name: $name");

    setState(() => _selectedDataId = null);
    _showSuccessToast('Department deleted successfully');
  } catch (e) {
    _showErrorToast('Error deleting department: $e');
  }
}


void _showBlockedDeletionDialog(List<String> sources) {
  showDialog(
    context: context,
    builder: (BuildContext context) {
      return Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        elevation: 8.0,
        child: Container(
          width: MediaQuery.of(context).size.width / 3.5,
          padding: EdgeInsets.all(20),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16.0),
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Colors.white, Color(0xFFFFF3F3)],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.warning_amber_rounded, color: Colors.orange[700], size: 28),
                  SizedBox(width: 10),
                  Text(
                    "Deletion Blocked",
                    style: TextStyle(
                      fontFamily: fontSemiBold,
                      color: Colors.orange[700],
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 15),
              Text(
                "This department cannot be deleted because it is currently linked to existing records in:\n\n• ${sources.join('\n• ')}",
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: fontRegular,
                  fontSize: MediaQuery.of(context).size.width / 100,
                  color: Colors.black87,
                ),
              ),
              SizedBox(height: 20),
               Container(
                          width: MediaQuery.of(context).size.width / 8,
                          height: MediaQuery.of(context).size.width / 35,
                          decoration: BoxDecoration(
                            color: Colors.blue[700],
                            borderRadius: BorderRadius.circular(
                                MediaQuery.of(context).size.width / 170),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.black.withOpacity(0.05),
                                blurRadius: 10,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  "OK",
                  style: TextStyle(
                    fontFamily: fontRegular,
                    fontSize: MediaQuery.of(context).size.width / 100,
                    color: Colors.white,
                  ),
                ),
              ),
               )
            ],
          ),
        ),
      );
    },
  );
}


  // Toast notifications
  void _showSuccessToast(String message) {
    toastification.show(
      context: context,
      alignment: Alignment.topRight,
      icon: Icon(Icons.check_circle_outline, color: Colors.green),
      title: Text(
        'Success',
        style: TextStyle(fontFamily: fontBold),
      ),
      description: Text(
        message,
        style: TextStyle(fontFamily: fontRegular),
      ),
      type: ToastificationType.success,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
    );
  }

  void _showErrorToast(String message) {
    toastification.show(
      context: context,
      alignment: Alignment.topRight,
      icon: Icon(Icons.error_outline, color: Colors.white),
      title: Text(
        'Error',
        style: TextStyle(fontFamily: fontBold, color: Colors.white),
      ),
      description: Text(
        message,
        style: TextStyle(fontFamily: fontRegular, color: Colors.white),
      ),
      type: ToastificationType.error,
      style: ToastificationStyle.flatColored,
      autoCloseDuration: const Duration(seconds: 3),
      animationDuration: const Duration(milliseconds: 300),
    );
  }
}
