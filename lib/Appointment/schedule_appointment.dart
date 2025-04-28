import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/Calendar/calendar.dart';
import 'package:attendance_app/widget/animated_textfield.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';

class ScheduleAppointment extends StatefulWidget {
  const ScheduleAppointment({super.key});

  @override
  State<ScheduleAppointment> createState() => _ScheduleAppointmentState();
}

class _ScheduleAppointmentState extends State<ScheduleAppointment> {
  // This is the controller for the text fields
  // You can use these controllers to get the text input from the user
  final TextEditingController agendaController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController scheduleController = TextEditingController();
  final TextEditingController descriptionAgendaController =
      TextEditingController();

  String firstName = "";
  String lastName = "";

  DateTime? selectedScheduleTime; // Store selected date-time

  // List to store selected guests and users
  // These lists will be populated when the user selects guests or users
  List<Map<String, dynamic>> selectedGuests = [];
  List<Map<String, dynamic>> selectedUsers = [];

  // This function is called when the widget is first created
  // It initializes the state of the widget
  @override
  void initState() {
    super.initState();
    // Fetch user data when the widget is initialized
    // This is where you can fetch user data from Firestore or any other source
    fetchUserData();
  }

  // This function clears the text fields and resets the selected guests and users
  void clearText() {
    agendaController.clear();
    scheduleController.clear();
    descriptionAgendaController.clear();
    setState(() {
      selectedGuests.clear();
      selectedUsers.clear();
      selectedScheduleTime = null;
    });
  }

  /// This function is called when the user submits the form
  /// It retrieves the values from the text fields and selected guests/users,
  /// It creates a Google Calendar event and stores the appointment in Firestore
  /// It also logs the action in the audit trail
  /// It shows a success or error message based on the outcome
  void submitForm() async {
    try {
      // Validate the form fields
      String fullName = "$firstName $lastName".trim();
      String agendaText = agendaController.text.trim();
      String scheduleText =
          scheduleController.text.trim(); // Log the schedule value
      String descriptionText = descriptionAgendaController.text.trim();
      // Copy selectedGuests to a local variable to avoid side effects
      // This is to ensure that the original list is not modified
      List<Map<String, dynamic>> localSelectedGuests =
          List.from(selectedGuests);
      // Copy selectedUsers to a local variable to avoid side effects
      // This is to ensure that the original list is not modified
      List<Map<String, dynamic>> localSelectedUsers = List.from(selectedUsers);

      // Extract email addresses from selected guests
      // This is done to create the Google Calendar event
      List<String> guestEmails = localSelectedGuests
          .map((guest) => guest['emailAdd'] as String?)
          .whereType<String>()
          .toList();

      DateTime startDateTime = DateTime.parse(scheduleController.text);
      DateTime endDateTime = startDateTime.add(Duration(hours: 1));

      // 🌟 Retrieve or Authenticate Google Token
      GoogleCalendarService googleCalendarService = GoogleCalendarService();
      String? accessToken = await googleCalendarService.authenticateUser();

      // Check if accessToken is null, which means authentication failed
      // If authentication fails, show a message to the user
      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google authentication required!")));
        return;
      }

      // 🌟 Create Google Calendar Event and get the eventId
      // This is where the Google Calendar event is created
      // The eventId is used to link the appointment in Firestore with the Google Calendar event
      String? eventId = await googleCalendarService.createCalendarEvent(
        // Pass the access token and other event details
        accessToken,
        agendaText,
        startDateTime,
        endDateTime,
        guestEmails,
      );

      // Check if eventId is null, which means event creation failed
      // If event creation fails, show a message to the user
      if (eventId == null) {
        // Show a message to the user indicating that the event creation failed
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Failed to create event on Google Calendar")));
        return;
      }

      // This is where the appointment is stored in Firestore
      // The eventId is used to link the appointment with the Google Calendar event
      // The appointment is stored in the 'appointment' collection
      // The appointment includes the agenda, department, schedule, description,
      // selected guests, internal users, status, createdBy, and eventId
      // The status is set to 'Scheduled' initially
      await FirebaseFirestore.instance.collection('appointment').add({
        'agenda': agendaText,
        'department': departmentController.text,
        'schedule': scheduleText, // Ensure schedule value is being passed here
        'agendaDescript': descriptionText,
        'guest': localSelectedGuests, // Store local copy of selected guests
        'internal_users': localSelectedUsers,
        'status': 'Scheduled',
        'createdBy': fullName,
        'googleEventId': eventId, // Store the eventId after creating the event
      });

      // Log the action in the audit trail
      await logAuditTrail("Created Appointment",
          "User $fullName scheduled an appointment with agenda: $agendaText");

      // Show a success message to the user
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Form submitted successfully!")));

      // Trigger the clearText function to clear the text fields and reset the state
      clearText();
    } catch (e) {
      // If an error occurs, show an error message to the user
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

  // This function fetches user data from Firestore
  // It retrieves the user's first name, last name, and department
  // It sets the values in the text fields and updates the state
  // It also handles errors if the user is not logged in or if there is an error fetching data
  // It uses the FirebaseAuth instance to get the current user
  // It uses the FirebaseFirestore instance to query the 'users' collection
  // It uses the where clause to filter the documents based on the user's UID
  // It uses the limit clause to limit the results to one document
  // It uses the setState method to update the UI with the fetched data
  Future<void> fetchUserData() async {
    User? user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        QuerySnapshot querySnapshot = await FirebaseFirestore.instance
            .collection('users')
            .where('uid', isEqualTo: user.uid)
            .limit(1)
            .get();

        if (querySnapshot.docs.isNotEmpty) {
          var userData =
              querySnapshot.docs.first.data() as Map<String, dynamic>;

          setState(() {
            firstName = userData['first_name'] ?? "N/A";
            lastName = userData['last_name'] ?? "N/A";
            departmentController.text =
                userData['department'] ?? ""; // Set department field
          });
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("User data not found.")));
        }
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Error fetching user data: $e")));
      }
    } else {
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("User not logged in.")));
    }
  }

  // This function is called when the user taps on the date and time picker
  // It shows a date picker and a time picker to the user
  // It combines the selected date and time into a single DateTime object
  // It updates the selectedScheduleTime variable and the scheduleController text field
  // It uses the showDatePicker and showTimePicker functions to display the pickers
  // It uses the setState method to update the UI with the selected date and time
  void pickScheduleDateTime() async {
    DateTime now = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
    );

    if (pickedTime == null) return;

    // Combine Date and Time
    DateTime fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      selectedScheduleTime = fullDateTime;
      scheduleController.text =
          fullDateTime.toIso8601String(); // Store in ISO format
    });
  }

// Function to format date-time
  String formatDateTime(DateTime dateTime) {
    return "${_monthName(dateTime.month)} ${dateTime.day} ${dateTime.year} at "
        "${_formatHour(dateTime.hour)}:${_formatMinute(dateTime.minute)} "
        "${dateTime.hour >= 12 ? 'PM' : 'AM'}";
  }

  // Helper functions to format month name, hour, and minute
  String _monthName(int month) {
    List<String> months = [
      "",
      "January",
      "February",
      "March",
      "April",
      "May",
      "June",
      "July",
      "August",
      "September",
      "October",
      "November",
      "December"
    ];
    return months[month];
  }

  String _formatHour(int hour) {
    int formattedHour = hour % 12 == 0 ? 12 : hour % 12;
    return formattedHour.toString();
  }

  String _formatMinute(int minute) {
    return minute.toString().padLeft(2, '0');
  }

  // Function to show confirmation dialog before saving the appointment
  void showconfirmdialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm Appointment"),
            content: Text("Do you want to save this schedule appointment?"),
            actions: [
              TextButton(
                  onPressed: () =>
                      // Close the dialog without saving
                      Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () {
                    // This will trigger the SubmitForm function to save the appointment
                    // and trigger the clearText function to reset the form
                    // and close the dialog
                    submitForm();
                    clearText(); // Ensure UI updates after clearing the form
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Save",
                    style: TextStyle(color: Colors.blue),
                  ))
            ],
          );
        });
  }

  // Function to show the dialog for adding a new guest
  // This function is called when the user search an existing guest and the guest is not found
  // It allows the user to enter the details of a new guest
  // It uses the FirebaseFirestore instance to add the new guest to the 'clients' collection
  // It uses the TextEditingController instances to get the input from the user
  void _showAddGuestDialog() {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final TextEditingController fullName = TextEditingController();
    final TextEditingController contactNum = TextEditingController();
    final TextEditingController emailAdd = TextEditingController();
    final TextEditingController companyName = TextEditingController();

    // Function to clear the text fields after adding a new guest
    void clearAddnewguest() {
      fullName.clear();
      contactNum.clear();
      emailAdd.clear();
      companyName.clear();
    }

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Add New Guest"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
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
            ],
          ),
          actions: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton(
                  onPressed: () {
                    // Close the dialog without saving
                    Navigator.of(context).pop();
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.red,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child: Text("Cancel", style: TextStyle(color: Colors.white)),
                ),
                ElevatedButton(
                  onPressed: () async {
                    // Check if the guest already exists
                    // This is done to prevent duplicate entries in the Firestore database
                    // This is where the duplicate check is performed
                    // It uses the FirebaseFirestore instance to query the 'clients' collection
                    // It uses the where clause to filter the documents based on the input values
                    QuerySnapshot duplicateCheck = await _firestore
                        .collection('clients')
                        .where('fullName', isEqualTo: fullName.text)
                        .where('contactNum', isEqualTo: contactNum.text)
                        .where('emailAdd', isEqualTo: emailAdd.text)
                        .where('companyName', isEqualTo: companyName.text)
                        .get();

                    // Check if the duplicateCheck contains any documents
                    if (duplicateCheck.docs.isNotEmpty) {
                      // Show a message if the guest already exists
                      // clear the text fields to allow the user to enter new values
                      clearAddnewguest();

                      // Close the dialog
                      Navigator.pop(context);
                      // Show a message to the user indicating that the guest already exists
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Guest already exists.")),
                      );
                    } else {
                      // Add the new guest
                      // This is where the new guest is added to the Firestore database
                      await _firestore.collection('clients').add({
                        'fullName': fullName.text,
                        'contactNum': contactNum.text,
                        'emailAdd': emailAdd.text,
                        'companyName': companyName.text,
                      });
                      // clear the text fields to allow the user to enter new values
                      clearAddnewguest();
                      // Close the dialog
                      Navigator.pop(context);
                      // Show a message to the user indicating that the guest was added successfully
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Guest added successfully.")),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                  child:
                      Text("Add Guest", style: TextStyle(color: Colors.white)),
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Center(
        child: Row(children: [
      Expanded(
        child: Card(
          color: Colors.grey.shade300,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text("Schedule an Appointment"),
              SizedBox(
                height: 5,
              ),
              Container(
                height: 50,
                width: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 1),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[
                      200], // Light grey background to indicate it's non-editable
                ),
                child: CupertinoTextField(
                  controller: agendaController,
                  placeholder: 'Agenda',
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 90,
                width: 400,
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 1),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[
                      200], // Light grey background to indicate it's non-editable
                ),
                child: CupertinoTextField(
                  controller: descriptionAgendaController,
                  maxLines: null,
                  placeholder: 'Description of Agenda',
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              Container(
                height: 50,
                width: 400,
                padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.amber, width: 1),
                  borderRadius: BorderRadius.circular(10),
                  color: Colors.grey[
                      200], // Light grey background to indicate it's non-editable
                ),
                child: Text(
                  departmentController.text.isNotEmpty
                      ? departmentController.text
                      : "Loading...",
                  style: TextStyle(fontSize: 16, color: Colors.black),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              // this is the date and time picker
              GestureDetector(
                onTap: pickScheduleDateTime,
                child: Container(
                  height: 50,
                  width: 400,
                  padding: EdgeInsets.symmetric(horizontal: 10, vertical: 12),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.amber, width: 1),
                    borderRadius: BorderRadius.circular(10),
                    color: Colors.grey[200], // Non-editable look
                  ),
                  child: Text(
                    selectedScheduleTime != null
                        ? formatDateTime(selectedScheduleTime!
                            .toLocal()) // Correct function usage
                        : "Select Date & Time For Appointment",
                    style: TextStyle(fontSize: 16, color: Colors.black),
                  ),
                ),
              ),
              SizedBox(
                height: 10,
              ),
              ElevatedButton(
                  // this will trigger the showconfirmdialog function to show the confirmation dialog
                  onPressed: showconfirmdialog,
                  child: Text('Make an Appointment'))
            ],
          ),
        ),
      ),
      // External Guest
      Expanded(
          child: Card(
              color: Colors.grey.shade300,
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(10),
                      child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text("Pre-Invited Guests",
                                style: TextStyle(
                                    fontSize: 18, fontWeight: FontWeight.bold)),
                            SizedBox(
                              height: 40,
                              width: 450,
                              child: SearchAnchor(
                                builder: (BuildContext context,
                                    SearchController controller) {
                                  return SearchBar(
                                    leading: Icon(Icons.search),
                                    controller: controller,
                                    hintText: "Search Guest...",
                                    onChanged: (query) {
                                      controller.openView();
                                    },
                                  );
                                },
                                suggestionsBuilder: (BuildContext context,
                                    SearchController controller) async {
                                  QuerySnapshot querySnapshot =
                                      await FirebaseFirestore.instance
                                          .collection("clients")
                                          .get();

                                  List<Map<String, dynamic>> allGuests =
                                      querySnapshot.docs.map((doc) {
                                    return {
                                      "fullName": doc["fullName"] ?? "No Name",
                                      "emailAdd": doc["emailAdd"] ?? "No Email",
                                      "companyName":
                                          doc["companyName"] ?? "No Company",
                                      "contactNum":
                                          doc["contactNum"] ?? "No Contact",
                                    };
                                  }).toList();

                                  List<Map<String, dynamic>> filteredGuests =
                                      allGuests
                                          .where((guest) => guest["fullName"]
                                              .toString()
                                              .toLowerCase()
                                              .contains(controller.text
                                                  .toLowerCase()))
                                          .toList();

                                  if (filteredGuests.isEmpty) {
                                    return [
                                      ListTile(
                                        title: Text("No guests found"),
                                        subtitle: Padding(
                                          padding: const EdgeInsets.all(8.0),
                                          child: ElevatedButton(
                                            onPressed: () {
                                              // Close the search view and show the add guest dialog
                                              // This is where the add guest dialog is shown
                                              controller.closeView(null);
                                              _showAddGuestDialog();
                                            },
                                            style: ElevatedButton.styleFrom(
                                              backgroundColor: Colors.blue,
                                              shape: RoundedRectangleBorder(
                                                borderRadius:
                                                    BorderRadius.circular(10),
                                              ),
                                            ),
                                            child: Text(
                                              "Add a new guest",
                                              style: TextStyle(
                                                  color: Colors.white),
                                            ),
                                          ),
                                        ),
                                      )
                                    ];
                                  }

                                  return filteredGuests.map((guest) {
                                    bool isSelected = selectedGuests.any((g) =>
                                        g["fullName"] == guest["fullName"] &&
                                        g["emailAdd"] == guest["emailAdd"] &&
                                        g["companyName"] ==
                                            guest["companyName"] &&
                                        g["contactNum"] == guest["contactNum"]);

                                    return ListTile(
                                      title: Text(guest["fullName"]),
                                      subtitle: Text(
                                          "${guest["emailAdd"]}\n${guest["companyName"]}"),
                                      isThreeLine: true,
                                      trailing: isSelected
                                          ? Icon(Icons.check_circle,
                                              color: Colors.green)
                                          : null,
                                      onTap: () {
                                        setState(() {
                                          if (isSelected) {
                                            selectedGuests.removeWhere((g) =>
                                                g["fullName"] ==
                                                    guest["fullName"] &&
                                                g["emailAdd"] ==
                                                    guest["emailAdd"] &&
                                                g["companyName"] ==
                                                    guest["companyName"] &&
                                                g["contactNum"] ==
                                                    guest["contactNum"]);
                                          } else {
                                            selectedGuests.add(guest);
                                          }
                                        });
                                        controller.closeView(null);
                                        controller.clear();
                                      },
                                    );
                                  }).toList();
                                },
                              ),
                            ),
                          ]),
                    ),
                    Divider(
                      height: 2,
                      thickness: 1,
                      color: Colors.black,
                    ),
                    // Display selected guests
                    Expanded(
                      child: selectedGuests.isEmpty
                          ? Center(child: Text("No guests selected"))
                          : ListView.builder(
                              itemCount: selectedGuests.length,
                              itemBuilder: (context, index) {
                                var guest = selectedGuests[index];

                                return Card(
                                  margin: EdgeInsets.symmetric(
                                      vertical: 5, horizontal: 10),
                                  child: ListTile(
                                    title: Text(guest["fullName"]!,
                                        style: TextStyle(
                                            fontWeight: FontWeight.bold)),
                                    subtitle: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                            "📞 Contact: ${guest["contactNum"]}"),
                                        Text("✉️ Email: ${guest["emailAdd"]}"),
                                        Text(
                                            "🏢 Company: ${guest["companyName"]}"),
                                      ],
                                    ),
                                    trailing: IconButton(
                                      icon: Icon(Icons.remove_circle,
                                          color: Colors.red),
                                      onPressed: () {
                                        setState(() {
                                          selectedGuests.removeWhere((g) =>
                                              g["fullName"] ==
                                                  guest["fullName"] &&
                                              g["emailAdd"] ==
                                                  guest["emailAdd"] &&
                                              g["companyName"] ==
                                                  guest["companyName"] &&
                                              g["contactNum"] ==
                                                  guest["contactNum"]);
                                        });
                                      },
                                    ),
                                  ),
                                );
                              },
                            ),
                    ),
                    // Internal Users
                    Expanded(
                      child: Card(
                        color: Colors.grey.shade300,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Padding(
                              padding: const EdgeInsets.all(10),
                              child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text("Internal Users",
                                        style: TextStyle(
                                            fontSize: 18,
                                            fontWeight: FontWeight.bold)),
                                    SizedBox(
                                      height: 40,
                                      width: 450,
                                      child: SearchAnchor(
                                        builder: (BuildContext context,
                                            SearchController controllerUser) {
                                          return SearchBar(
                                            leading: Icon(Icons.search),
                                            controller: controllerUser,
                                            hintText:
                                                "Search Internal Users...",
                                            onChanged: (query) {
                                              // Open the search view when the user types
                                              controllerUser.openView();
                                            },
                                          );
                                        },
                                        suggestionsBuilder:
                                            (BuildContext context,
                                                SearchController
                                                    controllerUser) async {
                                          // Fetch all internal users from Firestore
                                          QuerySnapshot querySnapshot =
                                              await FirebaseFirestore.instance
                                                  .collection("users")
                                                  .where('roles',
                                                      isEqualTo: "User")
                                                  .get();
                                          // Map the documents to a list of maps
                                          List<Map<String, dynamic>>
                                              allInternalUsers =
                                              querySnapshot.docs.map((doc) {
                                            // Extract relevant fields from each document
                                            return {
                                              "fullName":
                                                  "${doc["first_name"] ?? ""} ${doc["last_name"] ?? ""}"
                                                      .trim(),
                                              "email":
                                                  doc["email"] ?? "No Email",
                                              "department": doc["department"] ??
                                                  "No Department",
                                            };
                                            // Return the mapped data as a list of maps
                                          }).toList();
                                          // Filter the list based on the search query
                                          // This is where the filtering happens
                                          List<Map<String, dynamic>>
                                              filteredUsers = allInternalUsers
                                                  .where((users) => users[
                                                          // Filter by fullName
                                                          "fullName"]
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains(controllerUser
                                                          .text
                                                          .toLowerCase()))
                                                  .toList();

                                          return filteredUsers.map((users) {
                                            bool isSelected = selectedUsers.any(
                                                (g) =>
                                                    g["fullName"] ==
                                                        users["fullName"] &&
                                                    g["email"] ==
                                                        users["email"] &&
                                                    g["department"] ==
                                                        users["department"]);

                                            return ListTile(
                                              title: Text(users["fullName"]),
                                              subtitle: Text(
                                                  "${users["email"]}\n${users["department"]}"),
                                              isThreeLine: true,
                                              trailing: isSelected
                                                  ? Icon(Icons.check_circle,
                                                      color: Colors.green)
                                                  : null,
                                              onTap: () {
                                                setState(() {
                                                  if (isSelected) {
                                                    selectedUsers.removeWhere((g) =>
                                                        g["fullName"] ==
                                                            users["fullName"] &&
                                                        g["email"] ==
                                                            users["email"] &&
                                                        g["department"] ==
                                                            users[
                                                                "department"]);
                                                  } else {
                                                    selectedUsers.add(users);
                                                  }
                                                });
                                                controllerUser.closeView(null);
                                                controllerUser.clear();
                                              },
                                            );
                                          }).toList();
                                        },
                                      ),
                                    ),
                                  ]),
                            ),
                            Divider(
                              height: 2,
                              thickness: 1,
                              color: Colors.black,
                            ),
                            // Display selected guests
                            Expanded(
                              child: selectedUsers.isEmpty
                                  ? Center(child: Text("No guests selected"))
                                  : ListView.builder(
                                      itemCount: selectedUsers.length,
                                      itemBuilder: (context, index) {
                                        var users = selectedUsers[index];

                                        return Card(
                                          margin: EdgeInsets.symmetric(
                                              vertical: 5, horizontal: 10),
                                          child: ListTile(
                                            title: Text(users["fullName"]!,
                                                style: TextStyle(
                                                    fontWeight:
                                                        FontWeight.bold)),
                                            subtitle: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                    "✉️ Email: ${users["email"]}"),
                                                Text(
                                                    "🏢 Department: ${users["department"]}"),
                                              ],
                                            ),
                                            trailing: IconButton(
                                              icon: Icon(Icons.remove_circle,
                                                  color: Colors.red),
                                              onPressed: () {
                                                // Remove the user from the selected list
                                                // This is where the user is removed from the selected list
                                                // This is done to allow the user to select other users
                                                // and to prevent duplicate entries in the Firestore database
                                                setState(() {
                                                  selectedUsers.removeWhere(
                                                      (g) =>
                                                          g["fullName"] ==
                                                              users[
                                                                  "fullName"] &&
                                                          g["email"] ==
                                                              users["email"] &&
                                                          g["department"] ==
                                                              users[
                                                                  "department"]);
                                                });
                                              },
                                            ),
                                          ),
                                        );
                                      },
                                    ),
                            )
                          ],
                        ),
                      ),
                    )
                  ])))
    ]));
  }
}
