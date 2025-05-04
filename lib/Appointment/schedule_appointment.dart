import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/Calendar/calendar.dart';
import 'package:attendance_app/hover_extensions.dart';
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

  DateTime? selectedScheduleTime;

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
      selectedUsers.clear();
      selectedScheduleTime = null;
    });
  }

  void submitForm() async {
    try {
      String fullName = "$firstName $lastName".trim();
      String agendaText = agendaController.text.trim();
      String scheduleText = scheduleController.text.trim();
      String descriptionText = descriptionAgendaController.text.trim();

      List<Map<String, dynamic>> localSelectedGuests =
          List.from(selectedGuests);

      List<Map<String, dynamic>> localSelectedUsers = List.from(selectedUsers);

      List<String> guestEmails = localSelectedGuests
          .map((guest) => guest['emailAdd'] as String?)
          .whereType<String>()
          .toList();

      DateTime startDateTime = DateTime.parse(scheduleController.text);
      DateTime endDateTime = startDateTime.add(Duration(hours: 1));

      GoogleCalendarService googleCalendarService = GoogleCalendarService();
      String? accessToken = await googleCalendarService.authenticateUser();

      if (accessToken == null) {
        ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Google authentication required!")));
        return;
      }

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

      await FirebaseFirestore.instance.collection('appointment').add({
        'agenda': agendaText,
        'department': departmentController.text,
        'schedule': scheduleText,
        'agendaDescript': descriptionText,
        'guest': localSelectedGuests,
        'internal_users': localSelectedUsers,
        'status': 'Scheduled',
        'createdBy': fullName,
        'googleEventId': eventId,
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
            departmentController.text = userData['department'] ?? "";
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

  void pickScheduleDateTime() async {
    DateTime now = DateTime.now();

    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: now,
      lastDate: DateTime(2100),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color.fromARGB(255, 11, 55, 99),
              onPrimary: Colors.white,
              onSurface: Color.fromARGB(255, 11, 55, 99),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 11, 55, 99),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedDate == null) return;

    TimeOfDay? pickedTime = await showTimePicker(
      context: context,
      initialTime: TimeOfDay.now(),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: Color.fromARGB(255, 11, 55, 99),
              onPrimary: Colors.white,
              onSurface: Color.fromARGB(255, 11, 55, 99),
            ),
            textButtonTheme: TextButtonThemeData(
              style: TextButton.styleFrom(
                foregroundColor: Color.fromARGB(255, 11, 55, 99),
              ),
            ),
          ),
          child: child!,
        );
      },
    );

    if (pickedTime == null) return;

    DateTime fullDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );

    setState(() {
      selectedScheduleTime = fullDateTime;
      scheduleController.text = fullDateTime.toIso8601String();
    });
  }

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
            title: Text(
              "Confirm Appointment",
              style: TextStyle(
                fontFamily: "SB",
                color: Color.fromARGB(255, 11, 55, 99),
              ),
            ),
            content: Text(
              "Do you want to save this schedule appointment?",
              style: TextStyle(
                fontFamily: "R",
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: Text(
                    "Cancel",
                    style: TextStyle(
                      color: Colors.red,
                      fontFamily: "M",
                    ),
                  )),
              TextButton(
                  onPressed: () {
                    submitForm();
                    clearText();
                    Navigator.pop(context);
                  },
                  child: Text(
                    "Save",
                    style: TextStyle(
                      color: Color.fromARGB(255, 11, 55, 99),
                      fontFamily: "M",
                    ),
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
                    QuerySnapshot duplicateCheck = await _firestore
                        .collection('clients')
                        .where('fullName', isEqualTo: fullName.text)
                        .where('contactNum', isEqualTo: contactNum.text)
                        .where('emailAdd', isEqualTo: emailAdd.text)
                        .where('companyName', isEqualTo: companyName.text)
                        .get();

                    if (duplicateCheck.docs.isNotEmpty) {
                      clearAddnewguest();

                      Navigator.pop(context);

                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text("Guest already exists.")),
                      );
                    } else {
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
    // Get screen size for responsive design
    final screenWidth = MediaQuery.of(context).size.width;
    final screenHeight = MediaQuery.of(context).size.height;

    final subtitleSize = screenWidth / 70;
    final bodySize = screenWidth / 90;

    return Padding(
      padding: EdgeInsets.symmetric(
          horizontal: MediaQuery.of(context).size.width / 40,
          vertical: MediaQuery.of(context).size.width / 180),
      child: Column(
        children: [
          SizedBox(height: screenWidth / 100),
          Container(
            width: screenWidth,
            height: screenHeight / 15,
            decoration: BoxDecoration(
                border: Border(
                    bottom: BorderSide(
                        color: Color.fromARGB(255, 11, 55, 99), width: 2))),
            child: Text("Appointment Details",
                style: TextStyle(
                    fontSize: MediaQuery.of(context).size.width / 41,
                    fontFamily: "BL",
                    fontWeight: FontWeight.bold,
                    color: Color.fromARGB(255, 11, 55, 99))),
          ),
          SizedBox(height: screenHeight / 60),
          Expanded(
            child: Row(children: [
              Column(
                children: [
                  Container(
                    width: screenWidth / 3,
                    height: screenWidth / 2.8,
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
                          height: screenWidth / 25,
                          width: screenWidth,
                          child: Center(
                            child: Text(
                              "Schedule an Appointment",
                              style: TextStyle(
                                  fontSize: subtitleSize,
                                  fontFamily: "SB",
                                  color: Colors.white),
                            ),
                          ),
                        ),
                        Expanded(
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                                horizontal: 24, vertical: 5),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  "Agenda",
                                  style: TextStyle(
                                    fontFamily: "M",
                                    fontSize: bodySize,
                                    color: Color.fromARGB(255, 11, 55, 99),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: screenHeight * 0.06,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: agendaController,
                                    style: TextStyle(
                                      fontFamily: "R",
                                      fontSize: bodySize,
                                    ),
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.symmetric(
                                          horizontal: 16),
                                      border: InputBorder.none,
                                      hintText: 'Enter agenda title',
                                      hintStyle: TextStyle(
                                        fontFamily: "R",
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
    
                                // Description field
                                Text(
                                  "Description",
                                  style: TextStyle(
                                    fontFamily: "M",
                                    fontSize: bodySize,
                                    color: Color.fromARGB(255, 11, 55, 99),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: screenHeight / 8.5,
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.white,
                                    border: Border.all(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      width: 1,
                                    ),
                                  ),
                                  child: TextField(
                                    controller: descriptionAgendaController,
                                    style: TextStyle(
                                      fontFamily: "R",
                                      fontSize: bodySize,
                                    ),
                                    maxLines: null,
                                    decoration: InputDecoration(
                                      contentPadding: EdgeInsets.all(16),
                                      border: InputBorder.none,
                                      hintText:
                                          'Describe the purpose of this meeting',
                                      hintStyle: TextStyle(
                                        fontFamily: "R",
                                        color: Colors.grey,
                                      ),
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
    
                                // Department field
                                Text(
                                  "Department",
                                  style: TextStyle(
                                    fontFamily: "M",
                                    fontSize: bodySize,
                                    color: Color.fromARGB(255, 11, 55, 99),
                                  ),
                                ),
                                SizedBox(height: 8),
                                Container(
                                  height: screenHeight * 0.06,
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(8),
                                    color: Colors.grey[100],
                                    border: Border.all(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      width: 1,
                                    ),
                                  ),
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    departmentController.text.isNotEmpty
                                        ? departmentController.text
                                        : "Loading...",
                                    style: TextStyle(
                                      fontSize: bodySize,
                                      fontFamily: "R",
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenHeight * 0.02),
    
                                // Date & Time picker
                                Text(
                                  "Date & Time",
                                  style: TextStyle(
                                    fontFamily: "M",
                                    fontSize: bodySize,
                                    color: Color.fromARGB(255, 11, 55, 99),
                                  ),
                                ),
                                SizedBox(height: 8),
                                GestureDetector(
                                  onTap: pickScheduleDateTime,
                                  child: Container(
                                    height: screenHeight * 0.06,
                                    padding: EdgeInsets.symmetric(
                                        horizontal: 16, vertical: 8),
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(8),
                                      color: Colors.white,
                                      border: Border.all(
                                        color:
                                            Color.fromARGB(255, 11, 55, 99),
                                        width: 1,
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          selectedScheduleTime != null
                                              ? formatDateTime(
                                                  selectedScheduleTime!
                                                      .toLocal())
                                              : "Select Date & Time",
                                          style: TextStyle(
                                            fontSize: bodySize,
                                            fontFamily: "R",
                                            color:
                                                selectedScheduleTime != null
                                                    ? Colors.black87
                                                    : Colors.grey,
                                          ),
                                        ),
                                        Icon(
                                          Icons.calendar_today,
                                          color:
                                              Color.fromARGB(255, 11, 55, 99),
                                          size: bodySize * 1.2,
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                                SizedBox(height: screenWidth / 100),
                                GestureDetector(
                                  onTap: () {
                                    if (selectedScheduleTime == null) {
                                      ScaffoldMessenger.of(context)
                                          .showSnackBar(
                                        SnackBar(
                                          content: Text(
                                              "Please select a date and time."),
                                        ),
                                      );
                                    } else {
                                      showconfirmdialog();
                                    }
                                  },
                                  child: Container(
                                    width: screenWidth,
                                    height: screenWidth / 35,
                                    decoration: BoxDecoration(
                                      color: Color.fromARGB(255, 11, 55, 99),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: Center(
                                      child: Text(
                                        'Create Appointment',
                                        style: TextStyle(
                                          fontSize: screenWidth / 90,
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
                ],
              ),
              SizedBox(width: screenWidth / 80),
              //can you redesign this second expanded card
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
                      // Unified Header
                      Container(
                        color: Color.fromARGB(255, 11, 55, 99),
                        height: MediaQuery.of(context).size.width / 25,
                        width: double.infinity,
                        child: Center(
                          child: Text(
                            "Meeting Participants",
                            style: TextStyle(
                              fontSize:
                                  MediaQuery.of(context).size.width / 70,
                              fontFamily: "SB",
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      // Unified Search Bar
                      Container(
                        height: MediaQuery.of(context).size.width / 25,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SearchAnchor(
                            builder: (BuildContext context,
                                SearchController controller) {
                              return SearchBar(
                                leading: Icon(
                                  Icons.search,
                                  color: Color.fromARGB(255, 11, 55, 99),
                                  size:
                                      MediaQuery.of(context).size.width / 90,
                                ),
                                controller: controller,
                                hintText: "Search participants...",
                                hintStyle: MaterialStateProperty.all(
                                  TextStyle(
                                    fontFamily: "R",
                                    fontSize:
                                        MediaQuery.of(context).size.width /
                                            90,
                                    color: Colors.grey,
                                  ),
                                ),
                                textStyle: MaterialStateProperty.all(
                                  TextStyle(
                                    fontFamily: "R",
                                    fontSize:
                                        MediaQuery.of(context).size.width /
                                            90,
                                  ),
                                ),
                                onChanged: (query) {
                                  controller.openView();
                                },
                              );
                            },
                            suggestionsBuilder: (BuildContext context,
                                SearchController controller) async {
                              // Fetch external guests
                              QuerySnapshot guestSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection("clients")
                                      .get();
    
                              List<Map<String, dynamic>> allGuests =
                                  guestSnapshot.docs.map((doc) {
                                return {
                                  "type": "external",
                                  "fullName": doc["fullName"] ?? "No Name",
                                  "emailAdd": doc["emailAdd"] ?? "No Email",
                                  "companyName":
                                      doc["companyName"] ?? "No Company",
                                  "contactNum":
                                      doc["contactNum"] ?? "No Contact",
                                };
                              }).toList();
    
                              // Fetch internal users
                              QuerySnapshot userSnapshot =
                                  await FirebaseFirestore.instance
                                      .collection("users")
                                      .get();
    
                              List<Map<String, dynamic>> allInternalUsers =
                                  userSnapshot.docs.map((doc) {
                                return {
                                  "type": "internal",
                                  "fullName":
                                      "${doc["first_name"] ?? ""} ${doc["last_name"] ?? ""}"
                                          .trim(),
                                  "email": doc["email"] ?? "No Email",
                                  "department":
                                      doc["department"] ?? "No Department",
                                };
                              }).toList();
    
                              // Combine and filter both lists
                              List<Map<String, dynamic>> allParticipants = [
                                ...allGuests,
                                ...allInternalUsers
                              ];
    
                              List<Map<String, dynamic>>
                                  filteredParticipants = allParticipants
                                      .where((participant) =>
                                          participant["fullName"]
                                              .toString()
                                              .toLowerCase()
                                              .contains(controller.text
                                                  .toLowerCase()) ||
                                          (participant["type"] == "external" &&
                                              participant["companyName"]
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(controller.text
                                                      .toLowerCase())) ||
                                          (participant["type"] == "internal" &&
                                              participant["department"]
                                                  .toString()
                                                  .toLowerCase()
                                                  .contains(
                                                      controller.text.toLowerCase())))
                                      .toList();
    
                              if (filteredParticipants.isEmpty) {
                                return [
                                  ListTile(
                                    title: Text(
                                      "No participants found",
                                      style: TextStyle(
                                        fontFamily: "R",
                                        fontSize: MediaQuery.of(context)
                                                .size
                                                .width /
                                            90,
                                      ),
                                    ),
                                    subtitle: Padding(
                                      padding: const EdgeInsets.all(8.0),
                                      child: ElevatedButton(
                                        onPressed: () {
                                          controller.closeView(null);
                                          _showAddGuestDialog();
                                        },
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor:
                                              Color.fromARGB(255, 11, 55, 99),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(10),
                                          ),
                                        ),
                                        child: Text(
                                          "Add a new guest",
                                          style: TextStyle(
                                            color: Colors.white,
                                            fontFamily: "M",
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                90,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                                ];
                              }
    
                              return filteredParticipants.map((participant) {
                                bool isSelected = false;
    
                                if (participant["type"] == "external") {
                                  isSelected = selectedGuests.any((g) =>
                                      g["fullName"] ==
                                          participant["fullName"] &&
                                      g["emailAdd"] ==
                                          participant["emailAdd"] &&
                                      g["companyName"] ==
                                          participant["companyName"] &&
                                      g["contactNum"] ==
                                          participant["contactNum"]);
                                } else {
                                  isSelected = selectedUsers.any((u) =>
                                      u["fullName"] ==
                                          participant["fullName"] &&
                                      u["email"] == participant["email"] &&
                                      u["department"] ==
                                          participant["department"]);
                                }
    
                                return ListTile(
                                  leading: CircleAvatar(
                                    backgroundColor:
                                        Color.fromARGB(255, 11, 55, 99)
                                            .withOpacity(0.1),
                                    child: Text(
                                      participant["fullName"].isNotEmpty
                                          ? participant["fullName"][0]
                                              .toUpperCase()
                                          : "?",
                                      style: TextStyle(
                                        fontFamily: "B",
                                        fontSize: MediaQuery.of(context)
                                                .size
                                                .width /
                                            110,
                                        color:
                                            Color.fromARGB(255, 11, 55, 99),
                                      ),
                                    ),
                                  ),
                                  title: Row(
                                    children: [
                                      Text(
                                        participant["fullName"],
                                        style: TextStyle(
                                          fontFamily: "M",
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                        ),
                                      ),
                                      SizedBox(width: 8),
                                      Container(
                                        padding: EdgeInsets.symmetric(
                                            horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: participant["type"] ==
                                                  "external"
                                              ? Colors.orange.withOpacity(0.2)
                                              : Colors.green.withOpacity(0.2),
                                          borderRadius:
                                              BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          participant["type"] == "external"
                                              ? "External"
                                              : "Internal",
                                          style: TextStyle(
                                            fontFamily: "R",
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                120,
                                            color: participant["type"] ==
                                                    "external"
                                                ? Colors.orange[800]
                                                : Colors.green[800],
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                  subtitle: Text(
                                    participant["type"] == "external"
                                        ? "${participant["emailAdd"]}\n${participant["companyName"]}"
                                        : "${participant["email"]}\n${participant["department"]}",
                                    style: TextStyle(
                                      fontFamily: "R",
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              100,
                                    ),
                                  ),
                                  isThreeLine: true,
                                  trailing: isSelected
                                      ? Icon(Icons.check_circle,
                                          color: Colors.green)
                                      : null,
                                  onTap: () {
                                    setState(() {
                                      if (participant["type"] == "external") {
                                        if (isSelected) {
                                          selectedGuests.removeWhere((g) =>
                                              g["fullName"] ==
                                                  participant["fullName"] &&
                                              g["emailAdd"] ==
                                                  participant["emailAdd"] &&
                                              g["companyName"] ==
                                                  participant[
                                                      "companyName"] &&
                                              g["contactNum"] ==
                                                  participant["contactNum"]);
                                        } else {
                                          selectedGuests.add({
                                            "fullName":
                                                participant["fullName"],
                                            "emailAdd":
                                                participant["emailAdd"],
                                            "companyName":
                                                participant["companyName"],
                                            "contactNum":
                                                participant["contactNum"],
                                          });
                                        }
                                      } else {
                                        if (isSelected) {
                                          selectedUsers.removeWhere((u) =>
                                              u["fullName"] ==
                                                  participant["fullName"] &&
                                              u["email"] ==
                                                  participant["email"] &&
                                              u["department"] ==
                                                  participant["department"]);
                                        } else {
                                          selectedUsers.add({
                                            "fullName":
                                                participant["fullName"],
                                            "email": participant["email"],
                                            "department":
                                                participant["department"],
                                          });
                                        }
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
                      ),
                      // Participants List Area (Split into two sections)
                      Expanded(
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // External Guests Section
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  border: Border(
                                    right: BorderSide(
                                      color: Colors.grey.withOpacity(0.3),
                                      width: 1,
                                    ),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.width /
                                              29,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            Text(
                                              "External Guests",
                                              style: TextStyle(
                                                fontSize:
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        80,
                                                fontFamily: "SB",
                                                color: Color.fromARGB(
                                                    255, 11, 55, 99),
                                              ),
                                            ),
                                            ElevatedButton.icon(
                                              icon: Icon(
                                                Icons.add,
                                                size: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    100,
                                                color: Colors.white,
                                              ),
                                              label: Text(
                                                "Add Guest",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  fontFamily: "M",
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          100,
                                                ),
                                              ),
                                              onPressed: _showAddGuestDialog,
                                              style: ElevatedButton.styleFrom(
                                                backgroundColor:
                                                    Color.fromARGB(
                                                        255, 11, 55, 99),
                                                padding: EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 4),
                                                shape: RoundedRectangleBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          6),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ),
                                    Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Colors.grey.withOpacity(0.2)),
                                    Expanded(
                                      child: selectedGuests.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.people_outline,
                                                    size:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            40,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    "No external guests selected",
                                                    style: TextStyle(
                                                      fontFamily: "R",
                                                      fontSize: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          90,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : ListView.builder(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              itemCount:
                                                  selectedGuests.length,
                                              itemBuilder: (context, index) {
                                                var guest =
                                                    selectedGuests[index];
                                                return Card(
                                                  margin: EdgeInsets.only(
                                                      bottom: 6),
                                                  elevation: 1,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    side: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 240, 240, 240),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor:
                                                              Color.fromARGB(
                                                                      255,
                                                                      11,
                                                                      55,
                                                                      99)
                                                                  .withOpacity(
                                                                      0.1),
                                                          radius: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              80,
                                                          child: Text(
                                                            guest["fullName"]!
                                                                    .isNotEmpty
                                                                ? guest["fullName"]![
                                                                        0]
                                                                    .toUpperCase()
                                                                : "?",
                                                            style: TextStyle(
                                                              fontFamily: "B",
                                                              fontSize: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  100,
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      11,
                                                                      55,
                                                                      99),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                guest[
                                                                    "fullName"]!,
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      "SB",
                                                                  fontSize: MediaQuery.of(context)
                                                                          .size
                                                                          .width /
                                                                      90,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 2),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .email_outlined,
                                                                    size: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        120,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                  SizedBox(
                                                                      width:
                                                                          2),
                                                                  Expanded(
                                                                    child:
                                                                        Text(
                                                                      guest[
                                                                          "emailAdd"],
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            "R",
                                                                        fontSize:
                                                                            MediaQuery.of(context).size.width / 110,
                                                                        color:
                                                                            Colors.grey[700],
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                  height: 2),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .business_outlined,
                                                                    size: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        120,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                  SizedBox(
                                                                      width:
                                                                          2),
                                                                  Expanded(
                                                                    child:
                                                                        Text(
                                                                      guest[
                                                                          "companyName"],
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            "R",
                                                                        fontSize:
                                                                            MediaQuery.of(context).size.width / 110,
                                                                        color:
                                                                            Colors.grey[700],
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
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
                                                            Icons
                                                                .delete_outline,
                                                            color: Colors
                                                                .red[400],
                                                            size: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                90,
                                                          ),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              BoxConstraints(),
                                                          onPressed: () {
                                                            setState(() {
                                                              selectedGuests.removeWhere((g) =>
                                                                  g["fullName"] == guest["fullName"] &&
                                                                  g["emailAdd"] ==
                                                                      guest[
                                                                          "emailAdd"] &&
                                                                  g["companyName"] ==
                                                                      guest[
                                                                          "companyName"] &&
                                                                  g["contactNum"] ==
                                                                      guest[
                                                                          "contactNum"]);
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
                                                );
                                              },
                                            ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            // Internal Users Section
                            // Internal Users Section
                            Expanded(
                              child: Container(
                                decoration: BoxDecoration(
                                  color: Color.fromARGB(255, 250, 250, 250),
                                ),
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.width /
                                              29,
                                      child: Padding(
                                        padding: const EdgeInsets.all(8.0),
                                        child: Center(
                                          child: Text(
                                            "Internal Team Members",
                                            style: TextStyle(
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  80,
                                              fontFamily: "SB",
                                              color: Color.fromARGB(
                                                  255, 11, 55, 99),
                                            ),
                                          ),
                                        ),
                                      ),
                                    ),
                                    Divider(
                                        height: 1,
                                        thickness: 1,
                                        color: Colors.grey.withOpacity(0.2)),
                                    Expanded(
                                      child: selectedUsers.isEmpty
                                          ? Center(
                                              child: Column(
                                                mainAxisAlignment:
                                                    MainAxisAlignment.center,
                                                children: [
                                                  Icon(
                                                    Icons.group_outlined,
                                                    size:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            40,
                                                    color: Colors.grey,
                                                  ),
                                                  SizedBox(height: 8),
                                                  Text(
                                                    "No internal participants selected",
                                                    style: TextStyle(
                                                      fontFamily: "R",
                                                      fontSize: MediaQuery.of(
                                                                  context)
                                                              .size
                                                              .width /
                                                          90,
                                                      color: Colors.grey,
                                                    ),
                                                  ),
                                                ],
                                              ),
                                            )
                                          : ListView.builder(
                                              padding: EdgeInsets.symmetric(
                                                  horizontal: 8, vertical: 4),
                                              itemCount: selectedUsers.length,
                                              itemBuilder: (context, index) {
                                                var user =
                                                    selectedUsers[index];
                                                return Card(
                                                  margin: EdgeInsets.only(
                                                      bottom: 6),
                                                  elevation: 1,
                                                  shape:
                                                      RoundedRectangleBorder(
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                            8),
                                                    side: BorderSide(
                                                      color: Color.fromARGB(
                                                          255, 240, 240, 240),
                                                      width: 1,
                                                    ),
                                                  ),
                                                  child: Padding(
                                                    padding:
                                                        const EdgeInsets.all(
                                                            8.0),
                                                    child: Row(
                                                      crossAxisAlignment:
                                                          CrossAxisAlignment
                                                              .center,
                                                      children: [
                                                        CircleAvatar(
                                                          backgroundColor:
                                                              Color.fromARGB(
                                                                      255,
                                                                      11,
                                                                      55,
                                                                      99)
                                                                  .withOpacity(
                                                                      0.1),
                                                          radius: MediaQuery.of(
                                                                      context)
                                                                  .size
                                                                  .width /
                                                              80,
                                                          child: Text(
                                                            user["fullName"]!
                                                                    .isNotEmpty
                                                                ? user["fullName"]![
                                                                        0]
                                                                    .toUpperCase()
                                                                : "?",
                                                            style: TextStyle(
                                                              fontFamily: "B",
                                                              fontSize: MediaQuery.of(
                                                                          context)
                                                                      .size
                                                                      .width /
                                                                  100,
                                                              color: Color
                                                                  .fromARGB(
                                                                      255,
                                                                      11,
                                                                      55,
                                                                      99),
                                                            ),
                                                          ),
                                                        ),
                                                        SizedBox(width: 12),
                                                        Expanded(
                                                          child: Column(
                                                            crossAxisAlignment:
                                                                CrossAxisAlignment
                                                                    .start,
                                                            children: [
                                                              Text(
                                                                user[
                                                                    "fullName"]!,
                                                                style:
                                                                    TextStyle(
                                                                  fontFamily:
                                                                      "SB",
                                                                  fontSize: MediaQuery.of(context)
                                                                          .size
                                                                          .width /
                                                                      90,
                                                                ),
                                                              ),
                                                              SizedBox(
                                                                  height: 2),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .email_outlined,
                                                                    size: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        120,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                  SizedBox(
                                                                      width:
                                                                          2),
                                                                  Expanded(
                                                                    child:
                                                                        Text(
                                                                      user[
                                                                          "email"],
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            "R",
                                                                        fontSize:
                                                                            MediaQuery.of(context).size.width / 110,
                                                                        color:
                                                                            Colors.grey[700],
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ],
                                                              ),
                                                              SizedBox(
                                                                  height: 2),
                                                              Row(
                                                                children: [
                                                                  Icon(
                                                                    Icons
                                                                        .business_outlined,
                                                                    size: MediaQuery.of(context)
                                                                            .size
                                                                            .width /
                                                                        120,
                                                                    color: Colors
                                                                        .grey,
                                                                  ),
                                                                  SizedBox(
                                                                      width:
                                                                          2),
                                                                  Expanded(
                                                                    child:
                                                                        Text(
                                                                      user[
                                                                          "department"],
                                                                      style:
                                                                          TextStyle(
                                                                        fontFamily:
                                                                            "R",
                                                                        fontSize:
                                                                            MediaQuery.of(context).size.width / 110,
                                                                        color:
                                                                            Colors.grey[700],
                                                                        overflow:
                                                                            TextOverflow.ellipsis,
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
                                                            Icons
                                                                .delete_outline,
                                                            color: Colors
                                                                .red[400],
                                                            size: MediaQuery.of(
                                                                        context)
                                                                    .size
                                                                    .width /
                                                                90,
                                                          ),
                                                          padding:
                                                              EdgeInsets.zero,
                                                          constraints:
                                                              BoxConstraints(),
                                                          onPressed: () {
                                                            setState(() {
                                                              selectedUsers.removeWhere((u) =>
                                                                  u["fullName"] == user["fullName"] &&
                                                                  u["email"] ==
                                                                      user[
                                                                          "email"] &&
                                                                  u["department"] ==
                                                                      user[
                                                                          "department"]);
                                                            });
                                                          },
                                                        ),
                                                      ],
                                                    ),
                                                  ),
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
                ),
              ),
            ]),
          ),
        ],
      ),
    );
  }
}