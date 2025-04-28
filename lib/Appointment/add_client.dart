// ignore_for_file: no_leading_underscores_for_local_identifiers

import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:toastification/toastification.dart';

// This is the AddClient widget that allows users to add, update, and delete client information.
// It uses Firebase Firestore to store client data and provides a user interface for managing clients.
class AddClient extends StatefulWidget {
  const AddClient({super.key});

  @override
  State<AddClient> createState() => _AddClientState();
}

class _AddClientState extends State<AddClient> {
  @override
  Widget build(BuildContext context) {
    // This is all the Variables and controllers needed for the widget.
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final TextEditingController fullName = TextEditingController();
    final TextEditingController contactNum = TextEditingController();
    final TextEditingController emailAdd = TextEditingController();
    final TextEditingController companyName = TextEditingController();

    // This is for clearing the fields after adding, updating a client.
    void _clearFields() {
      fullName.clear();
      contactNum.clear();
      emailAdd.clear();
      companyName.clear();
    }

    // This is the function for adding a client to the database.
    void _addGuest() async {
      // Check if any of the fields are empty and show a toast message if they are.
      if (fullName.text.trim().isEmpty ||
          contactNum.text.trim().isEmpty ||
          emailAdd.text.trim().isEmpty ||
          companyName.text.trim().isEmpty) {
        // Show a toast message if any field is empty
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
        // Return early if any field is empty
        return;
      }

      // Check if the contact number is less than 11 digits and show a toast message if it is.
      // This is a simple validation for the contact number.
      if (contactNum.text.length < 11) {
        // Show a toast message if the contact number is invalid
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
        // Return early if the contact number is invalid
        return;
      }

      // Regular expression for validating email format
      // This regex checks if the email address is in a valid format.
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");

      // Check if the email address is valid and show a toast message if it is not.
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
        // Return early if the email address is invalid
        return;
      }

      // Add the client information to the Firestore database.
      await _firestore.collection('clients').add({
        'fullName': fullName.text,
        'contactNum': contactNum.text,
        'emailAdd': emailAdd.text,
        'companyName': companyName.text,
        'isDeleted': false,
      });

      // Log the action in the audit trail.
      await logAuditTrail(
        "Added Guest",
        "User added guest ${fullName.text} (Email: ${emailAdd.text})",
      );
      // Clear the input fields after adding the client.
      _clearFields();

      // Show a success toast message after adding the client.
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
      // Return early after showing the success message
      return;
    }

    // This is the function for updating a client in the database.
    // It takes the document ID and the new values for the client information.
    void _updateGuest(String docId, String fullName, String contactNum,
        String emailAdd, String companyName) async {
      //
      final trimmedName = fullName.trim();
      final trimmedContact = contactNum.trim();
      final trimmedEmail = emailAdd.trim();
      final trimmedCompany = companyName.trim();

      // OPTIONAL: Only validate fields that have values
      // Check if any of the fields are empty and show a toast message if they are.
      if (trimmedContact.isNotEmpty && trimmedContact.length < 11) {
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

      // Regular expression for validating email format
      // This regex checks if the email address is in a valid format.
      final emailRegex = RegExp(r"^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$");
      if (trimmedEmail.isNotEmpty && !emailRegex.hasMatch(trimmedEmail)) {
        // Show a toast message if the email address is invalid
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
        // Return early if the email address is invalid
        return;
      }

      /// Update the client information in the Firestore database.
      /// The document ID is used to identify the specific client to update.
      await _firestore.collection('clients').doc(docId).update({
        'fullName': trimmedName,
        'contactNum': trimmedContact,
        'emailAdd': trimmedEmail,
        'companyName': trimmedCompany,
      });

      // Log the action in the audit trail.
      /// This logs the action of updating a guest with the new values.
      await logAuditTrail("Updated Guest",
          "User updated guest $trimmedName (Email: $trimmedEmail)");
      // Clear the input fields after updating the client.
      _clearFields();
      // Show a success toast message after updating the client.
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
    }

    // This is the function for deleting a client from the database.
    // It takes the document ID and the client information to be deleted.
    void _deleteGuest(String docId, String guestName, String guestEmail) async {
      await _firestore.collection('clients').doc(docId).update({
        // Mark the client as deleted instead of actually deleting it
        'isDeleted': true,
      });

      // Log the action in the audit trail.
      /// This logs the action of deleting a guest with the name and email.
      await logAuditTrail("Deleted Guest",
          "User deleted guest $guestName (Email: $guestEmail)");
      // Show a success toast message after deleting the client.
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
      // Return early after showing the success message
      return;
    }

    // This is the function for showing a dialog to confirm the deletion of a client.
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
                      // Close the dialog without doing anything
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
                    // This button will call the _deleteGuest function to delete the client
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

    // This is the function for showing a dialog to update the client information.
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
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(11),
                      ],
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
                      // This button will close the dialog without doing anything
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
                      // This button will call the _updateGuest function to update the client
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

    // This is the function for showing a dialog to confirm adding a client.
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
                        // Close the dialog without doing anything
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
                        // Call the _addGuest function to add the client
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
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(11),
                  ],
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
                  // This button will call the _showdialogAddGuest function to show the confirmation dialog
                  onPressed: () => _showdialogAddGuest(),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color.fromARGB(255, 11, 55, 99),
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
                // This is the StreamBuilder that listens to the Firestore collection 'clients'
                child: StreamBuilder<QuerySnapshot>(
                  // This stream listens to the 'clients' collection and filters out deleted clients
                  stream: _firestore
                      .collection('clients')
                      .where('isDeleted', isEqualTo: false)
                      .snapshots(),
                  builder: (context, snapshot) {
                    // Check the connection state of the snapshot
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      // Show a loading indicator while waiting for data
                      return Center(child: CircularProgressIndicator());
                    }
                    if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                      // Show a message if there are no clients in the collection
                      return Center(child: Text("No guests added yet"));
                    }
                    // Map through the documents in the snapshot and create a list of cards for each client
                    return ListView(
                      shrinkWrap: true,
                      physics: BouncingScrollPhysics(),
                      children: snapshot.data!.docs.map((doc) {
                        // Get the data from the document
                        // This is the data for each client
                        var data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: EdgeInsets.all(8),
                          child: ListTile(
                            // This is the title of the card, showing the client's full name
                            title: Text(data['fullName'] ?? 'No Name'),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                // This is the subtitle of the card, showing the client's contact number, email address, and company name
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
                                      // This button will call the _showdialogUpdate function to show the update dialog
                                      _showdialogUpdate(doc.id, data),
                                ),
                                IconButton(
                                  icon: Icon(Icons.delete, color: Colors.red),
                                  onPressed: () => _showdialogDelete(
                                      // This button will call the _showdialogDelete function to show the delete confirmation dialog
                                      doc.id,
                                      doc['fullName'],
                                      doc['emailAdd']),
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
