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
                            /// This is the add Category Icon Button where you can use this if you want to add new Category on the system
                            /// Just UNCOMMENT this code and the MEthod and you will be having a function for adding a Cateogry
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
                          // This StreamBuilder listens for real-time updates from Firestore for the "categories" collection. 
                          // It handles different states such as showing a loading indicator while waiting for data or displaying 
                          // a message when no categories are available. Once data is available, the list of categories is filtered 
                          // based on the search query provided by the user. If no matching categories are found, a message is shown 
                          // indicating this. The StreamBuilder ensures the UI is automatically updated with the latest data, 
                          // creating a dynamic and responsive user experience. It efficiently handles and displays categories, 
                          // updating the list based on the search query and presenting the results in a ListView.
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
                                  // this is the Icon For Deleting a Category you can UNCOMMENT this to bring the function back
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
                          // This StreamBuilder listens for real-time updates from Firestore for the "references" collection 
                          // under the selected category. It filters out documents where 'isDeleted' is true. When data is 
                          // available, it checks for any search query and filters the list of references based on the 'name' field. 
                          // If no matching data is found, a message is displayed to inform the user. The StreamBuilder ensures 
                          // that the UI is updated automatically when data changes, providing a dynamic experience for the user. 
                          // It handles different states, such as showing a loading indicator while waiting for data, displaying 
                          // a message when there is no data, and rendering a list of filtered results when data is available. 
                          // Additionally, the code checks whether each reference is selected based on the current selection.
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
                                                // Thi will show the Dialog Box for Updating the Data in the Categories
                                                _showEditDialog(
                                                    data.id, data["name"]);
                                              },
                                            ),
                                            IconButton(
                                              icon: Icon(Icons.delete,
                                                  color: Colors.red),
                                              onPressed: () =>
                                                  // This will show the Dialog Box for Deleting a Data in the Categories
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

  // This is a show dialog box for the Editing the Data for the Categories
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
                  onPressed: () => 
                  // This will close the Show Dialog Box
                  Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.white),)),
                ElevatedButton(
                  onPressed: (){
                    // This will triggered the _updateData Method
                _updateData(dataId, _editDataController.text);
                // This will Close the Show Dialog Box
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

  // This function handles the updating of data for a specific reference under the selected category. 
// It ensures that a category is selected, a valid data ID is provided, and the new name is not empty 
// before proceeding. The function then updates the reference document in Firestore with the new name. 
// After the update, an audit trail is logged to track the change. The selected data ID is cleared to 
// indicate the deselection of the updated data. A success notification is shown to the user upon 
// successful update, and an error notification is displayed if any issues occur during the process. 
// This function ensures data consistency while providing feedback to the user.
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

    // This is a Show Dialog box for adding data on the categories
    void _showDialogAddData(BuildContext context) {
      // This will check if the selectedCategoryId is null then it will terminate 
      // but if the selectedCategoryId is not null it will proceed to next step
    if (selectedCategoryId == null) {
      return;
    }
      // This will clear the name Text field
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
                  onPressed: () =>
                   // This will close the Show Dialog Box
                   Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.white),)),
                ElevatedButton(
                  onPressed: (){
                    //This will triggered the _addData Method
                _addData();
                // This will close the ShowDialogBox
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

  // This function is responsible for adding new data under the selected category in Firestore. 
// It first checks if a category is selected. If a category is selected, it creates a new document 
// in the "references" sub-collection under the chosen category with the name provided in the input 
// and a timestamp. After adding the new reference, an audit trail is logged to keep track of the action. 
// A success notification is displayed to the user if the operation is successful. In case of an error, 
// an error notification is shown with the appropriate message. This function performs both data 
// creation and user feedback handling to ensure a smooth experience.
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

  // This is a show Dialog box for deleting a data of the categories
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
                  onPressed: () =>
                  // This will close the Show Dialog Box for deleting the data of the categories
                   Navigator.pop(context), 
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text('Cancel', style: TextStyle(color: Colors.white),)),
                ElevatedButton(
                  onPressed: (){
                  // This will triggered the _deleteData method 
                _deleteData(_selectedDataId!);
                // This will close the Show Dialog Box of the Delete for the data of the Categories
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

  // This Method is for Deleting the Data of the Category
  // 1. it will check if the selectedCategoryId is == null then it will terminate but if the selectedCategoryId is not null it will
  // check the collection of categories inside of that there is the .doc the name would be the selectedCategoryId inside of that there
  // is a sub-collection name references with the doc of if it will update the isDeleted fieldname into true it will not idrectly delete
  // in the firestore it is just deleted in the frontend after that it will show a toastification if the process is success or failed
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


  // This is a Show Dialog Box for Adding a Category this will Trigger the method for Adding a Category
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
              onPressed: () => 
              // This will close the show Dialog Box
              Navigator.pop(context),
              child: Text('Cancel'),
            ),
            TextButton(
              onPressed: () {
                // THis will Triggered the _addCategory
                _addCategory();
                // This will close the ShowDialog box
                Navigator.pop(context);
              },
              child: Text('Save'),
            ),
          ],
        );
      },
    );
  }

  // This will not show in the ui But if you need to add new Category you can use this function for Adding new Category in the references
  // Function to add a new category
  Future<void> _addCategory() async {
    try {
      await _firestore.collection("categories").add({
        "name": _nameController.text,
        "timestamp": FieldValue.serverTimestamp(),
      });
    } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text ("Error: $e")));
        }
  }

  // Function to delete a category
  // This will not show in the ui but if you need to Delete a Category in the reference you can just use this method
  // To Delete Categories
  Future<void> _deleteCategory(String id) async {
    try {
      await _firestore.collection("categories").doc(id).delete();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }
}
