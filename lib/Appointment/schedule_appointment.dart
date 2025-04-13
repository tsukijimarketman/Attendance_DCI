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
  final TextEditingController agendaController = TextEditingController();
  final TextEditingController departmentController = TextEditingController();
  final TextEditingController scheduleController = TextEditingController();
  final TextEditingController descriptionAgendaController =
      TextEditingController();

  String firstName = "";
  String lastName = "";

  DateTime? selectedScheduleTime; // Store selected date-time

  List<Map<String, dynamic>> selectedGuests = [];
  List<Map<String, dynamic>> selectedUsers = [];

  @override
  void initState() {
    super.initState();
    fetchUserData();
  }

  void clearText() {
    agendaController.clear();
    scheduleController.clear();
    descriptionAgendaController.clear();
    setState(() {
      selectedGuests.clear();
      selectedScheduleTime = null;
    });
  }

  void submitForm() async {
    try {
      String fullName = "$firstName $lastName".trim();
      String agendaText = agendaController.text.trim();
      String scheduleText =
          scheduleController.text.trim(); // Log the schedule value
      String descriptionText = descriptionAgendaController.text.trim();
      // Copy selectedGuests to a local variable to avoid side effects
      List<Map<String, dynamic>> localSelectedGuests =
          List.from(selectedGuests ?? []);

      List<String> guestEmails = localSelectedGuests
          .map((guest) => guest['emailAdd'] as String?)
          .whereType<String>()
          .toList();

      DateTime startDateTime = DateTime.parse(scheduleController.text);
      DateTime endDateTime = startDateTime.add(Duration(hours: 1));

      // 🌟 Retrieve or Authenticate Google Token
      GoogleCalendarService googleCalendarService = GoogleCalendarService();
      String? accessToken = await googleCalendarService.authenticateUser();

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google authentication required!")));
        return;
      }

      // 🌟 Create Google Calendar Event and get the eventId
      String? eventId = await googleCalendarService.createCalendarEvent(
        accessToken,
        agendaText,
        startDateTime,
        endDateTime,
        guestEmails,
      );

      if (eventId == null) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
            content: Text("Failed to create event on Google Calendar")));
        return;
      }

      // Store appointment in Firestore, including the eventId
      await FirebaseFirestore.instance.collection('appointment').add({
        'agenda': agendaText,
        'department': departmentController.text,
        'schedule': scheduleText, // Ensure schedule value is being passed here
        'agendaDescript': descriptionText,
        'guest': localSelectedGuests, // Store local copy of selected guests
        'internal_users': selectedUsers,
        'status': 'Scheduled',
        'createdBy': fullName,
        'googleEventId': eventId, // Store the eventId after creating the event
      });

      await logAuditTrail("Created Appointment",
          "User $fullName scheduled an appointment with agenda: $agendaText");

      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Form submitted successfully!")));

      clearText();
    } catch (e) {
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Error: $e")));
    }
  }

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
          print("No user document found.");
        }
      } catch (e) {
        print("Error fetching user data: $e");
      }
    } else {
      print("No user is logged in.");
    }
  }

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

  void showconfirmdialog() {
    showDialog(
        context: context,
        builder: (BuildContext context) {
          return AlertDialog(
            title: Text("Confirm Appointment"),
            content: Text("Do you want to save this schedule appointment?"),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(color: Colors.red),
                  )),
              TextButton(
                  onPressed: () {
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

  void _showAddGuestDialog() {
    final FirebaseFirestore _firestore = FirebaseFirestore.instance;
    final TextEditingController fullName = TextEditingController();
    final TextEditingController contactNum = TextEditingController();
    final TextEditingController emailAdd = TextEditingController();
    final TextEditingController companyName = TextEditingController();

     void clearAddnewguest(){
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
                  QuerySnapshot duplicateCheck = await _firestore
                      .collection('clients')
                      .where('fullName', isEqualTo: fullName.text)
                      .where('contactNum', isEqualTo: contactNum.text)
                      .where('emailAdd', isEqualTo: emailAdd.text)
                      .where('companyName', isEqualTo: companyName.text)
                      .get();
                
                  if (duplicateCheck.docs.isNotEmpty) {
                    // Show a message if the guest already exists
                        clearAddnewguest();
                
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text("Guest already exists.")),
                    );
                  } else {
                    // Add the new guest
                    await _firestore.collection('clients').add({
                      'fullName': fullName.text,
                      'contactNum': contactNum.text,
                      'emailAdd': emailAdd.text,
                      'companyName': companyName.text,
                    });
                
                        clearAddnewguest();
                    Navigator.pop(context);
                
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
                  child: Text("Add Guest", style: TextStyle(color: Colors.white)),
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
                                            child: Text("Add a new guest", style: TextStyle(color: Colors.white),),
                                          ),
                                        ),
                                      )
                                    ];
                                  }

                                  return filteredGuests.map((guest) {
                                    bool isSelected = selectedGuests.any((g) =>
    g["fullName"] == guest["fullName"] &&
    g["emailAdd"] == guest["emailAdd"] &&
    g["companyName"] == guest["companyName"] &&
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
    g["fullName"] == guest["fullName"] &&
    g["emailAdd"] == guest["emailAdd"] &&
    g["companyName"] == guest["companyName"] &&
    g["contactNum"] == guest["contactNum"]);

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
                                              g["fullName"] == guest["fullName"] &&
    g["emailAdd"] == guest["emailAdd"] &&
    g["companyName"] == guest["companyName"] &&
    g["contactNum"] == guest["contactNum"]);
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
                                              controllerUser.openView();
                                            },
                                          );
                                        },
                                        suggestionsBuilder:
                                            (BuildContext context,
                                                SearchController
                                                    controllerUser) async {
                                          QuerySnapshot querySnapshot =
                                              await FirebaseFirestore.instance
                                                  .collection("users")
                                                  .where('roles',
                                                      isEqualTo: "User")
                                                  .get();

                                          List<Map<String, dynamic>>
                                              allInternalUsers =
                                              querySnapshot.docs.map((doc) {
                                            return {
                                              "fullName":
                                                  "${doc["first_name"] ?? ""} ${doc["last_name"] ?? ""}"
                                                      .trim(),
                                              "email":
                                                  doc["email"] ?? "No Email",
                                              "department": doc["department"] ??
                                                  "No Department",
                                            };
                                          }).toList();

                                          List<Map<String, dynamic>>
                                              filteredUsers = allInternalUsers
                                                  .where((users) => users[
                                                          "fullName"]
                                                      .toString()
                                                      .toLowerCase()
                                                      .contains(controllerUser
                                                          .text
                                                          .toLowerCase()))
                                                  .toList();

                                          return filteredUsers.map((users) {
                                            bool isSelected = selectedUsers.any(
                                                (g) => g["fullName"] == users["fullName"] &&
                                                      g["email"] == users["email"] &&
                                                g["department"] == users["department"]);   

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
                                                    selectedUsers.removeWhere(
                                                        (g) =>
                                                            g["fullName"] ==
                                                            users["fullName"]&&
                                                              g["email"] == users["email"] &&
                                                g["department"] == users["department"]);
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
                                                setState(() {
                                                  selectedUsers.removeWhere(
                                                      (g) =>
                                                         g["fullName"] == users["fullName"] &&
                                                      g["email"] == users["email"] &&
                                                g["department"] == users["department"]);                                    });
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
