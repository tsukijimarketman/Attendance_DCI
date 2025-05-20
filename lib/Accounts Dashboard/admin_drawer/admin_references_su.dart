import 'dart:async';
import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class AdminReferences extends StatefulWidget {
  final TextEditingController searchQuery;
  const AdminReferences({super.key, required this.searchQuery});

  @override
  State<AdminReferences> createState() => _AdminReferencesState();
}

class _AdminReferencesState extends State<AdminReferences> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _searchDataController = TextEditingController();

  // Department management
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
              height: screenWidth / 3.1,
              child: Card(
                elevation: 2,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    
                    // Department List
                    Container(
                      height: screenWidth / 3.2,
                      child: StreamBuilder(
                        stream: _firestore
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
                                          contentPadding: EdgeInsets.symmetric(
                                            horizontal: screenWidth * 0.02,
                                            vertical: screenHeight * 0.005,
                                          ),
                                          title: Text(
                                            data["name"],
                                            style: TextStyle(
                                              fontFamily: isSelected
                                                  ? fontSemiBold
                                                  : fontRegular,
                                              fontSize: screenWidth * 0.012 > 18
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
                                          ? () => setState(() => _currentPage--)
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
                                          ? () => setState(() => _currentPage++)
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
                                          ? () => setState(
                                              () => _currentPage = _totalPages)
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
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
