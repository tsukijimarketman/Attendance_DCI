// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:toastification/toastification.dart';

class AddClient extends StatefulWidget {
  const AddClient({super.key});

  @override
  State<AddClient> createState() => _AddClientState();
}

class _AddClientState extends State<AddClient> {
  @override
  Widget build(BuildContext context) {
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
      if (fullName.text.trim().isEmpty ||
          contactNum.text.trim().isEmpty ||
          emailAdd.text.trim().isEmpty ||
          companyName.text.trim().isEmpty) {
        toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('Missing Fields'),
          description: Text('All fields are required.'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      }

      if (contactNum.text.length < 11) {
        toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('Invalid Contact Number'),
          description: Text('Contact number must be 11 digits.'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      }

      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

      if (!emailRegex.hasMatch(emailAdd.text.trim())) {
        toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('Invalid Email'),
          description: Text('Please enter a valid email address.'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      }

      await _firestore.collection('clients').add({
        'fullName': fullName.text,
        'contactNum': contactNum.text,
        'emailAdd': emailAdd.text,
        'companyName': companyName.text,
        'isDeleted': false,
      });

      await logAuditTrail(
        "Added Guest",
        "User added guest ${fullName.text} (Email: ${emailAdd.text})",
      );
      _clearFields();

      toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('Created Successfully'),
          description: Text('Client created successfully'),
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      
    
    }

    void _updateGuest(String docId, String name, String contact, String email,
        String company) async {
         if (fullName.text.trim().isEmpty ||
          contactNum.text.trim().isEmpty ||
          emailAdd.text.trim().isEmpty ||
          companyName.text.trim().isEmpty) {
        toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('Missing Fields'),
          description: Text('All fields are required.'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      }

      if (contactNum.text.length < 11) {
        toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('Invalid Contact Number'),
          description: Text('Contact number must be 11 digits.'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      }

      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

      if (!emailRegex.hasMatch(emailAdd.text.trim())) {
        toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.error, color: Colors.red),
          title: Text('Invalid Email'),
          description: Text('Please enter a valid email address.'),
          type: ToastificationType.error,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      }

      await _firestore.collection('clients').doc(docId).update({
        'fullName': name,
        'contactNum': contact,
        'emailAdd': email,
        'companyName': company,
      });
      await logAuditTrail(
          "Updated Guest", "User updated guest $name (Email: $email)");
      _clearFields();

      toastification.show(
          context: context,
          alignment: Alignment.topRight,
          icon: Icon(Icons.check_circle_outline, color: Colors.green),
          title: Text('Updated Successfully'),
          description: Text('Client updated successfully'),
          type: ToastificationType.info,
          style: ToastificationStyle.flatColored,
          autoCloseDuration: const Duration(seconds: 3),
          animationDuration: const Duration(milliseconds: 300),
        );
        return;
      
    
    }

    void _deleteGuest(String docId, String guestName, String guestEmail) async {
      await _firestore.collection('clients').doc(docId).update({
        'isDeleted': true,
      });

      await logAuditTrail("Deleted Guest",
          "User deleted guest $guestName (Email: $guestEmail)");

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
      
    
    }

    void _showdialogDelete(String docId, String guestName, String guestEmail) {
      showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Delete Client"),
            content: Text("Are you sure you want to delete this client?"),
            actions: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                  ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                    onPressed: () {
                      _deleteGuest(docId, guestName, guestEmail);
                      Navigator.pop(context);
                    },
                    child: Text(
                      "Delete",
                      style: TextStyle(color: Colors.white),
                    ),
                  ),
                ],
              ),
            ],
          );
        },
      );
    }

    void _showdialogUpdate(String docId, Map<String, dynamic> data) {
      TextEditingController updateFullName =
          TextEditingController(text: data['fullName'] ?? '');
      TextEditingController updateContactNum =
          TextEditingController(text: data['contactNum'] ?? '');
      TextEditingController updateEmailAdd =
          TextEditingController(text: data['emailAdd'] ?? '');
      TextEditingController updateCompanyName =
          TextEditingController(text: data['companyName'] ?? '');

      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Update Details"),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    height: 50,
                    width: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: AnimatedTextField(
                      label: "Enter Full Name",
                      controller: updateFullName,
                      suffix: null,
                      readOnly: false,
                      obscureText: false,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 50,
                    width: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: AnimatedTextField(
                      label: "Enter Contact Number",
                      controller: updateContactNum,
                      suffix: null,
                      readOnly: false,
                      obscureText: false,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 50,
                    width: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: AnimatedTextField(
                      label: "Enter Email Address",
                      controller: updateEmailAdd,
                      suffix: null,
                      readOnly: false,
                      obscureText: false,
                    ),
                  ),
                  SizedBox(height: 8),
                  Container(
                    height: 50,
                    width: 400,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(10),
                      color: Colors.grey[200],
                    ),
                    child: AnimatedTextField(
                      label: "Enter Company Name",
                      controller: updateCompanyName,
                      suffix: null,
                      readOnly: false,
                      obscureText: false,
                    ),
                  ),
                  SizedBox(
                    height: 10,
                  )
                ],
              ),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _updateGuest(
                            docId,
                            updateFullName.text,
                            updateContactNum.text,
                            updateEmailAdd.text,
                            updateCompanyName.text);
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Confirm",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            );
          });
    }

    void _showdialogAddGuest() {
      showDialog(
          context: context,
          builder: (BuildContext context) {
            return AlertDialog(
              title: Text("Add Client"),
              content: Text('Are you sure you want to add this client?'),
              actions: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    ElevatedButton(
                      onPressed: () {
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.red,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Cancel",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                    ElevatedButton(
                      onPressed: () {
                        _addGuest();
                        Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: Text(
                        "Add",
                        style: TextStyle(color: Colors.white),
                      ),
                    ),
                  ],
                ),
              ],
            );
          });
    }

    return Center(
        child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [
      Expanded(
        child: Card(
          color: Colors.grey.shade300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Clients Information",
                  style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: Colors.black)),
              SizedBox(
                height: 8,
              ),
              Container(
                height: 50,
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: AnimatedTextField(
                  label: "Enter Full Name",
                  controller: fullName,
                  suffix: null,
                  readOnly: false,
                  obscureText: false,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 50,
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: AnimatedTextField(
                  label: "Enter Contact Number",
                  controller: contactNum,
                  suffix: null,
                  readOnly: false,
                  obscureText: false,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 50,
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: AnimatedTextField(
                  label: "Enter Email Address",
                  controller: emailAdd,
                  suffix: null,
                  readOnly: false,
                  obscureText: false,
                ),
              ),
              SizedBox(height: 8),
              Container(
                height: 50,
                width: 400,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[200],
                ),
                child: AnimatedTextField(
                  label: "Enter Company Name",
                  controller: companyName,
                  suffix: null,
                  readOnly: false,
                  obscureText: false,
                ),
              ),
              SizedBox(height: 8),
              SizedBox(
                height: 50,
                width: 400,
                child: ElevatedButton(
                  onPressed: () => _showdialogAddGuest(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text(
                    'Save',
                    style: TextStyle(color: Colors.white, fontSize: 20),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              )
            ],
          ),
        ),
      ),
      Expanded(
        child: Card(
          color: Colors.grey.shade300,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: _firestore
                      .collection('clients')
                      .where('isDeleted', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      return Center(child: Text("No guests added yet"));
                    }
                    return ListView(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      children: snapshot.data!.docs.map((doc) {
                        var data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            title: Text(data['fullName'] ?? 'No Name'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text("Contact: ${data['contactNum'] ?? 'N/A'}"),
                                Text("Email: ${data['emailAdd'] ?? 'N/A'}"),
                                Text(
                                    "Company: ${data['companyName'] ?? 'N/A'}"),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                IconButton(
                                  icon: Icon(Icons.edit, color: Colors.blue),
                                  onPressed: () =>
                                      _showdialogUpdate(doc.id, data),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showdialogDelete(
                                      doc.id, doc['fullName'], doc['emailAdd']),
                                ),
                              ],
                            ),
                          ),
                        );
                      }).toList(),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      )
    ]));
  }
}
