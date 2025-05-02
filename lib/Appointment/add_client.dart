import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

class AddClient extends StatefulWidget {
  const AddClient({super.key});

  @override
  State<AddClient> createState() => _AddClientState();
}

class _AddClientState extends State<AddClient> {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final TextEditingController fullName = TextEditingController();
  final TextEditingController contactNum = TextEditingController();
  final TextEditingController emailAdd = TextEditingController();
  final TextEditingController companyName = TextEditingController();

  void _clearFields() {
    fullName.clear();
    contactNum.clear();
    emailAdd.clear();
    companyName.clear();
  }

  void _addGuest() async {
    if (fullName.text.isEmpty ||
        contactNum.text.isEmpty ||
        emailAdd.text.isEmpty ||
        companyName.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Please fill in all fields."),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      await _firestore.collection('clients').add({
        'fullName': fullName.text,
        'contactNum': contactNum.text,
        'emailAdd': emailAdd.text,
        'companyName': companyName.text,
        'isDeleted': false,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Client added successfully."),
          backgroundColor: Colors.green,
        ),
      );
    await logAuditTrail("Client Added", "Client Added with a name of ${fullName.text} Contact No: ${contactNum.text} Email Address: ${emailAdd.text} and Company of: ${companyName.text}");
      _clearFields();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Failed to add client: $e"),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

 void _updateGuest(String docId, String fullName, String contactNum,
    String emailAdd, String companyName) async {
  try {
    // Step 1: Fetch the existing document
    DocumentSnapshot doc = await _firestore.collection('clients').doc(docId).get();

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Client not found."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Map<String, dynamic> oldData = doc.data() as Map<String, dynamic>;

    // Step 2: Prepare new data
    Map<String, dynamic> newData = {
      'fullName': fullName,
      'contactNum': contactNum,
      'emailAdd': emailAdd,
      'companyName': companyName,
    };

    // Step 3: Compare and build a list of changes
    List<String> changes = [];
    newData.forEach((key, newValue) {
      var oldValue = oldData[key] ?? '';
      if (oldValue != newValue) {
        changes.add("$key: '$oldValue' → '$newValue'");
      }
    });

    // Step 4: Perform the update
    await _firestore.collection('clients').doc(docId).update(newData);

    // Step 5: Log the audit trail only if there are changes
    if (changes.isNotEmpty) {
      await logAuditTrail(
        "Client Updated",
        "Updated client '$docId' with changes: ${changes.join(', ')}",
      );
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Client updated successfully."),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to update client: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}

 void _deleteGuest(String docId) async {
  try {
    // Step 1: Fetch the full client document
    DocumentSnapshot doc = await _firestore.collection('clients').doc(docId).get();

    if (!doc.exists) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Client not found."),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;

    // Step 2: Soft delete the document
    await _firestore.collection('clients').doc(docId).update({
      'isDeleted': true,
    });

    // Step 3: Log with actual data from the document
    await logAuditTrail(
      "Client Deleted",
      "Client deleted with Name: ${data['fullName'] ?? 'N/A'}, Contact No: ${data['contactNum'] ?? 'N/A'}, "
      "Email: ${data['emailAdd'] ?? 'N/A'}, Company: ${data['companyName'] ?? 'N/A'}",
    );

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Client deleted successfully."),
        backgroundColor: Colors.green,
      ),
    );
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Failed to delete client: $e"),
        backgroundColor: Colors.red,
      ),
    );
  }
}


  void _showdialogDelete(String docId, String guestName, String guestEmail) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Delete Client"),
          content: Text("Are you sure you want to delete $guestName?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _deleteGuest(docId);
                Navigator.pop(context);
              },
              child: Text("Delete"),
            ),
          ],
        );
      },
    );
  }

  void _showdialogUpdate(String docId, Map<String, dynamic> data) {
    final TextEditingController updateFullName =
        TextEditingController(text: data['fullName']);
    final TextEditingController updateContactNum =
        TextEditingController(text: data['contactNum']);
    final TextEditingController updateEmailAdd =
        TextEditingController(text: data['emailAdd']);
    final TextEditingController updateCompanyName =
        TextEditingController(text: data['companyName']);

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text("Update Client"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: updateFullName,
                decoration: InputDecoration(labelText: "Full Name"),
              ),
              TextField(
                controller: updateContactNum,
                decoration: InputDecoration(labelText: "Contact Number"),
              ),
              TextField(
                controller: updateEmailAdd,
                decoration: InputDecoration(labelText: "Email Address"),
              ),
              TextField(
                controller: updateCompanyName,
                decoration: InputDecoration(labelText: "Company Name"),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                _updateGuest(
                  docId,
                  updateFullName.text,
                  updateContactNum.text,
                  updateEmailAdd.text,
                  updateCompanyName.text,
                );
                Navigator.pop(context);
              },
              child: Text("Update"),
            ),
          ],
        );
      },
    );
  }

  void _showdialogAddGuest() {
    _addGuest();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
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
            child: Text("Client Management",
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width / 41,
                    fontFamily: "BL",
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 11, 55, 99))),
          ),
          SizedBox(height: MediaQuery.of(context).size.height / 60),
          Expanded(
            child: Row(
              children: [
                // Left Section: Add Client Form
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          color: Color.fromARGB(255, 11, 55, 99),
                          height: MediaQuery.of(context).size.width / 25,
                          width: MediaQuery.of(context).size.width,
                          child: Center(
                            child: Text(
                              "Add New Client",
                              style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 70,
                                  fontFamily: "SB",
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Full Name",
                                  style: TextStyle(
                                    fontFamily: "M",
                                    fontSize:
                                        MediaQuery.of(context).size.width /
                                            90,
                                    color: Color.fromARGB(255, 11, 55, 99),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: MediaQuery.of(context).size.height *
                                      0.06,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: fullName,
                                    style: TextStyle(
                                      fontFamily: "R",
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16),
                                      border: InputBorder.none,
                                      hintText: 'Enter full name',
                                      hintStyle: TextStyle(
                                        fontFamily: "R",
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Contact Number",
                                  style: TextStyle(
                                    fontFamily: "M",
                                    fontSize:
                                        MediaQuery.of(context).size.width /
                                            90,
                                    color: Color.fromARGB(255, 11, 55, 99),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: MediaQuery.of(context).size.height *
                                      0.06,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: contactNum,
                                    keyboardType: TextInputType.phone,
                                    inputFormatters: [
                                      FilteringTextInputFormatter.digitsOnly,
                                      LengthLimitingTextInputFormatter(11),
                                    ],
                                    style: TextStyle(
                                      fontFamily: "R",
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16),
                                      border: InputBorder.none,
                                      hintText: 'Enter contact number',
                                      hintStyle: TextStyle(
                                        fontFamily: "R",
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Email Address",
                                  style: TextStyle(
                                    fontFamily: "M",
                                    fontSize:
                                        MediaQuery.of(context).size.width /
                                            90,
                                    color: Color.fromARGB(255, 11, 55, 99),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: MediaQuery.of(context).size.height *
                                      0.06,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: emailAdd,
                                    style: TextStyle(
                                      fontFamily: "R",
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16),
                                      border: InputBorder.none,
                                      hintText: 'Enter email address',
                                      hintStyle: TextStyle(
                                        fontFamily: "R",
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 16),
                                Text(
                                  "Company Name",
                                  style: TextStyle(
                                    fontFamily: "M",
                                    fontSize:
                                        MediaQuery.of(context).size.width /
                                            90,
                                    color: Color.fromARGB(255, 11, 55, 99),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: MediaQuery.of(context).size.height *
                                      0.06,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: companyName,
                                    style: TextStyle(
                                      fontFamily: "R",
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16),
                                      border: InputBorder.none,
                                      hintText: 'Enter company name',
                                      hintStyle: TextStyle(
                                        fontFamily: "R",
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: 24),
                                GestureDetector(
                                  onTap: _showdialogAddGuest,
                                  child: Container(
                                    width: MediaQuery.of(context).size.width,
                                    height:
                                        MediaQuery.of(context).size.width /
                                            35,
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Save Client',
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          fontFamily: "SB",
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                  ),
                                ).showCursorOnHover,
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(width: MediaQuery.of(context).size.width / 80),
                // Right Section: Client List
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 8,
                          offset: Offset(0, 3),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          color: Color.fromARGB(255, 11, 55, 99),
                          height: MediaQuery.of(context).size.width / 25,
                          width: double.infinity,
                          child: Center(
                            child: Text(
                              "Client List",
                              style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width / 70,
                                fontFamily: "SB",
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: StreamBuilder<QuerySnapshot>(
                            stream: _firestore
                                .collection('clients')
                                .where('isDeleted', isEqualTo: false)
                                .snapshots(),
                            builder: (context, snapshot) {
                              if (snapshot.connectionState ==
                                  ConnectionState.waiting) {
                                return Center(
                                  child: CircularProgressIndicator(
                                    color: Color.fromARGB(255, 11, 55, 99),
                                  ),
                                );
                              }
                              if (!snapshot.hasData ||
                                  snapshot.data!.docs.isEmpty) {
                                return Center(
                                  child: Column(
                                    mainAxisAlignment:
                                        MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.people_outline,
                                        size: MediaQuery.of(context)
                                                .size
                                                .width /
                                            40,
                                        color: Colors.grey,
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        "No clients added yet",
                                        style: TextStyle(
                                          fontFamily: "R",
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }
                              return ListView.builder(
                                padding: EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                itemCount: snapshot.data!.docs.length,
                                itemBuilder: (context, index) {
                                  var doc = snapshot.data!.docs[index];
                                  var data =
                                      doc.data() as Map<String, dynamic>;
                                  return Card(
                                    margin: EdgeInsets.only(bottom: 6),
                                    elevation: 1,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                      side: BorderSide(
                                        color: Color.fromARGB(
                                            255, 240, 240, 240),
                                        width: 1,
                                      ),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: Row(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.center,
                                        children: [
                                          CircleAvatar(
                                            backgroundColor: Color.fromARGB(
                                                    255, 11, 55, 99)
                                                .withOpacity(0.1),
                                            radius: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                80,
                                            child: Text(
                                              data["fullName"]!.isNotEmpty
                                                  ? data["fullName"]![0]
                                                      .toUpperCase()
                                                  : "?",
                                              style: TextStyle(
                                                fontFamily: "B",
                                                fontSize:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        100,
                                                color: Color.fromARGB(
                                                    255, 11, 55, 99),
                                              ),
                                            ),
                                          ),
                                          SizedBox(width: 12),
                                          Expanded(
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  data["fullName"]!,
                                                  style: TextStyle(
                                                    fontFamily: "SB",
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            90,
                                                  ),
                                                ),
                                                SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.email_outlined,
                                                      size: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          120,
                                                      color: Colors.grey,
                                                    ),
                                                    SizedBox(width: 2),
                                                    Expanded(
                                                      child: Text(
                                                        data["emailAdd"],
                                                        style: TextStyle(
                                                          fontFamily: "R",
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              110,
                                                          color: Colors
                                                              .grey[700],
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                                SizedBox(height: 2),
                                                Row(
                                                  children: [
                                                    Icon(
                                                      Icons.business_outlined,
                                                      size: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          120,
                                                      color: Colors.grey,
                                                    ),
                                                    SizedBox(width: 2),
                                                    Expanded(
                                                      child: Text(
                                                        data["companyName"],
                                                        style: TextStyle(
                                                          fontFamily: "R",
                                                          fontSize: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              110,
                                                          color: Colors
                                                              .grey[700],
                                                          overflow:
                                                              TextOverflow
                                                                  .ellipsis,
                                                        ),
                                                      ),
                                                    ),
                                                  ],
                                                ),
                                              ],
                                            ),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.edit_outlined,
                                              color: Colors.blue,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  90,
                                            ),
                                            onPressed: () =>
                                                _showdialogUpdate(
                                                    doc.id, data),
                                          ),
                                          IconButton(
                                            icon: Icon(
                                              Icons.delete_outline,
                                              color: Colors.red,
                                              size: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  90,
                                            ),
                                            onPressed: () =>
                                                _showdialogDelete(
                                                    doc.id,
                                                    data["fullName"],
                                                    data["emailAdd"]),
                                          ),
                                        ],
                                      ),
                                    ),
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
              ],
            ),
          ),
          ],
      ),
    );
  }
}
