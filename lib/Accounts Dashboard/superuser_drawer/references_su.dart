// ignore_for_file: unused_element

import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class References extends StatefulWidget {
  const References({super.key});

  @override
  State<References> createState() => _ReferencesState();
}

class _ReferencesState extends State<References> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  TextEditingController _nameController = TextEditingController();
  TextEditingController _searchCategoryController = TextEditingController();
  TextEditingController _searchDataController = TextEditingController();
  TextEditingController _editDataController =
      TextEditingController(); // Controller for editing data

  // Store selected category
  String? selectedCategoryId;
  String? _selectedDataId; // Track selected data entry
  String selectedCategoryName = "Select Category";
  String categorySearchQuery = "";
  String dataSearchQuery = "";

  @override
  Widget build(BuildContext context) {
    double screenWidth = MediaQuery.of(context).size.width;
    double screenHeight = MediaQuery.of(context).size.height;

    return SafeArea(
      child: Container(
        padding: EdgeInsets.all(10),
        child: Row(
          children: [
            // Category List Section
            Expanded(
              child: SizedBox(
                width: screenWidth / 2.2,
                height: screenHeight / 1.1,
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Category List',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            // TextButton(
                            //   style: ButtonStyle(
                            //     backgroundColor:
                            //         MaterialStateProperty.all(Colors.amber),
                            //     shape: MaterialStateProperty.all(
                            //         RoundedRectangleBorder(
                            //       borderRadius: BorderRadius.circular(10),
                            //     )),
                            //   ),
                            //   onPressed: () => _showDialogAddCategory(context),
                            //   child: Text(
                            //     'Add Category',
                            //     style: TextStyle(
                            //         fontSize: 12, color: Colors.black),
                            //   ),
                            // ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: CupertinoTextField(
                          controller: _searchCategoryController,
                          placeholder: 'Search Categories',
                          prefix: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(Icons.search, color: Colors.grey),
                          ),
                          onChanged: (value) {
                            setState(() {
                              categorySearchQuery = value.toLowerCase();
                            });
                          },
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder(
                          stream:
                              _firestore.collection("categories").snapshots(),
                          builder:
                              (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(
                                  child: Text("No categories available."));
                            }

                            var filteredCategories =
                                snapshot.data!.docs.where((doc) {
                              var categoryName =
                                  doc["name"].toString().toLowerCase();
                              return categoryName.contains(categorySearchQuery);
                            }).toList();

                            if (filteredCategories.isEmpty) {
                              return Center(
                                  child: Text("No matching categories."));
                            }

                            return ListView.builder(
                              itemCount: filteredCategories.length,
                              itemBuilder: (context, index) {
                                var category = filteredCategories[index];
                                return ListTile(
                                  title: Text(category["name"]),
                                  tileColor: selectedCategoryId == category.id
                                      ? Colors.grey[300]
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      selectedCategoryId = category.id;
                                      selectedCategoryName = category["name"];
                                    });
                                  },
                                  // trailing: IconButton(
                                  //   icon: Icon(Icons.delete, color: Colors.red),
                                  //   onPressed: () =>
                                  //       _deleteCategory(category.id),
                                  // ),
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),

            // Data List Section
            Expanded(
              child: SizedBox(
                width: screenWidth / 2.2,
                height: screenHeight / 1.1,
                child: Card(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text(
                              'Data List (${selectedCategoryName})',
                              style: TextStyle(
                                  fontSize: 18, fontWeight: FontWeight.w600),
                            ),
                            TextButton(
                              style: ButtonStyle(
                                backgroundColor:
                                    MaterialStateProperty.all(const Color.fromARGB(255, 11, 55, 99),),
                                shape: MaterialStateProperty.all(
                                    RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(10),
                                )),
                              ),
                              onPressed: () => _showDialogAddData(context),
                              child: Text(
                                'Add Data',
                                style: TextStyle(
                                    fontSize: 12, color: Colors.white),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 10),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 15),
                        child: CupertinoTextField(
                          controller: _searchDataController,
                          placeholder: 'Search Data',
                          prefix: Padding(
                            padding: EdgeInsets.only(left: 10),
                            child: Icon(Icons.search, color: Colors.grey),
                          ),
                          onChanged: (value) {
                            setState(() {
                              dataSearchQuery = value.toLowerCase();
                            });
                          },
                          decoration: BoxDecoration(
                            color: Colors.grey[200],
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ),
                      Expanded(
                        child: StreamBuilder(
                          stream: selectedCategoryId != null
                              ? _firestore
                                  .collection("categories")
                                  .doc(selectedCategoryId)
                                  .collection("references")
                                  .where('isDeleted', isEqualTo: false)
                                  .snapshots()
                              : null,
                          builder:
                              (context, AsyncSnapshot<QuerySnapshot> snapshot) {
                            if (snapshot.connectionState ==
                                ConnectionState.waiting) {
                              return Center(child: CircularProgressIndicator());
                            }
                            if (!snapshot.hasData ||
                                snapshot.data!.docs.isEmpty) {
                              return Center(child: Text("No data available."));
                            }

                            // Filter data based on the search query
                            var filteredData = snapshot.data!.docs.where((doc) {
                              var dataName =
                                  doc["name"].toString().toLowerCase();
                              return dataName.contains(dataSearchQuery);
                            }).toList();

                            if (filteredData.isEmpty) {
                              return Center(child: Text("No matching data."));
                            }

                            return ListView.builder(
                              itemCount: filteredData.length,
                              itemBuilder: (context, index) {
                                var data = filteredData[index];
                                bool isSelected = _selectedDataId == data.id;

                                return ListTile(
                                  title: Text(
                                    data["name"],
                                    style: TextStyle(
                                      fontWeight: isSelected
                                          ? FontWeight.bold
                                          : FontWeight.normal,
                                      color: isSelected
                                          ? Colors.black
                                          : Colors.black, // Highlight color
                                    ),
                                  ),
                                  tileColor: isSelected
                                      ? Colors.grey.withOpacity(0.2)
                                      : null, // Light background for selected
                                  onTap: () {
                                    setState(() {
                                      _selectedDataId =
                                          isSelected ? null : data.id;
                                    });
                                  },
                                  trailing: isSelected
                                      ? Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: Icon(Icons.edit,
                                                  color: Colors.blue),
                                              onPressed: () {
                                                _showEditDialog(
                                                    data.id, data["name"]);
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  _showdialogDeleteData(data.id),
                                            ),
                                          ],
                                        )
                                      : null, // Show icons only when selected
                                );
                              },
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showEditDialog(String dataId, String currentName) {
    _editDataController.text = currentName;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Edit Data List"),
          
          content: AnimatedTextField(
            controller: _editDataController,
            label: "Update Name",
            suffix: null,
            readOnly: false,
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.white),)),
                ElevatedButton(
                  onPressed: (){
                _updateData(dataId, _editDataController.text);
                Navigator.pop(context);},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ), 
                  ),
                  child: Text('Confirm', style: TextStyle(color: Colors.white),),
                )
              ],
            ),
          ],
        );
      },
    );
  }

  Future<void> _updateData(String dataId, String newName) async {
    if (selectedCategoryId == null || dataId.isEmpty || newName.trim().isEmpty)
      return;

    try {
      await _firestore
          .collection("categories")
          .doc(selectedCategoryId)
          .collection("references")
          .doc(dataId)
          .update({"name": newName});

       await logAuditTrail(
      "Data Updated",
      "Updated reference '$dataId' under category '$selectedCategoryId' with new name: $newName"
    );

      setState(() => _selectedDataId = null); // Deselect after editing

      toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('Updated Successfully'),
          description: Text('Data updated successfully'),
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      
    
    } catch (e) {
      toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('Error'),
          description: Text('Error updating data: $e'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      }
  }

  // Function to show Add Data dialog
  void _showDialogAddData(BuildContext context) {
    if (selectedCategoryId == null) {
      print("No category selected.");
      return;
    }

    _nameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Data to $selectedCategoryName'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedTextField(
                controller: _nameController,
                label: "Enter Name",
                suffix: null,
                readOnly: false,
              ),
            ],
          ),
          actions: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.white),)),
                ElevatedButton(
                  onPressed: (){
                _addData();
                Navigator.pop(context);},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ), 
                  ),
                  child: Text('Confirm', style: TextStyle(color: Colors.white),),
                )
              ],
            ),
          ],
        );
      },
    );
  }

  // Function to add new data under the selected category
  Future<void> _addData() async {
    if (selectedCategoryId == null) return;

   try {
    // Add new document and capture the reference
    DocumentReference docRef = await _firestore
        .collection("categories")
        .doc(selectedCategoryId)
        .collection("references")
        .add({
      "name": _nameController.text,
      "timestamp": FieldValue.serverTimestamp(),
      'isDeleted': false,
    });

    // ✅ Now docRef is defined, so we can use it in the log
    await logAuditTrail(
      "Data Added",
      "Added new reference '${docRef.id}' under category '$selectedCategoryId' with name: ${_nameController.text}"
    );

    toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('Created Successfully'),
          description: Text('Data created successfully'),
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      
    

    } catch (e) {
      toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('Error'),
          description: Text('Error updating data: $e'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
    }
  }

  void _showdialogDeleteData(String id){
    showDialog(
      context: context, 
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Delete Data"),
          content: Text("Are you sure you want to delete this data?"),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () => Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.white),)),
                ElevatedButton(
                  onPressed: (){
                _deleteData(_selectedDataId!);
                Navigator.pop(context);},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ), 
                  ),
                  child: Text('Confirm', style: TextStyle(color: Colors.white),),
                )
              ],
            ),
          ],
        );
      },
    );
  }

  // Function to delete a data entry
  Future<void> _deleteData(String id) async {
    if (selectedCategoryId == null) return;

    try {
      await _firestore
          .collection("categories")
          .doc(selectedCategoryId)
          .collection("references")
          .doc(id)
          .update({
            "isDeleted": true,
          });

           await logAuditTrail(
      "Data Deleted",
      "Deleted reference '$id' under category '$selectedCategoryId'"
    );

      toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('Deleted Successfully'),
          description: Text('Data deleted successfully'),
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      
    

    } catch (e) {
      toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('Error'),
          description: Text('Error updating data: $e'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      }
    
  }

  // Function to show Add Category dialog
  void _showDialogAddCategory(BuildContext context) {
    _nameController.clear();
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text('Add Category'),
          content: TextField(
            controller: _nameController,
            decoration: InputDecoration(labelText: "Enter Name"),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                _addCategory();
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // Function to add a new category
  Future<void> _addCategory() async {
    try {
      await _firestore.collection("categories").add({
        "name": _nameController.text,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
      print("Error adding category: $e");
    }
  }

  // Function to delete a category
  Future<void> _deleteCategory(String id) async {
    try {
      await _firestore.collection("categories").doc(id).delete();
    } catch (e) {
      print("Error deleting category: $e");
    }
  }
}
