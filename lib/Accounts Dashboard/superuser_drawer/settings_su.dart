import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/account_info.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/caddress.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/profile.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/su_address_provider.dart';
import 'package:attendance_app/Animation/loader.dart';
import 'package:attendance_app/Auth/audit_function.dart';
import 'package:attendance_app/edit_mode_provider.dart';
import 'package:attendance_app/hover_extensions.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class SettingsSU extends StatefulWidget {
  const SettingsSU({super.key});

  @override
  State<SettingsSU> createState() => _SettingsSUState();
}

class _SettingsSUState extends State<SettingsSU> {
  bool isEditing = false; //Controls read only state

  // Controllers for TextFields
  final TextEditingController firstNameController = TextEditingController();
  final TextEditingController middleNameController = TextEditingController();
  final TextEditingController lastNameController = TextEditingController();
  final TextEditingController suffixController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController mobileNumberController = TextEditingController();

  String _textContent = "Edit Profile Information";
  Color _buttonColor = Color.fromARGB(255, 11, 55, 99);

  TextEditingController _dateController = TextEditingController();

  bool byBirthChecked = false;
  bool byNaturalizedChecked = false;

  

  List<String> options = ['Male', 'Female'];
  List<String> civilStatus = ['Single', 'Divorced', 'Separated', 'Married'];
  List<String> yon = ['Yes', 'No'];
  String? selectedAnswer;
  String? selectedSex;
  String? selectedCitizenship = "";
  String? selectedCivilStatus;

  final List<String> citizenshipOptions = [
    'Afghan',
    'Albanian',
    'Algerian',
    'Andorran',
    'Angolan',
    'Antiguan and Barbudan',
    'Argentine',
    'Armenian',
    'Australian',
    'Austrian',
    'Azerbaijani',
    'Bahamian',
    'Bahraini',
    'Bangladeshi',
    'Barbadian',
    'Belarusian',
    'Belgian',
    'Belizean',
    'Beninese',
    'Bhutanese',
    'Bolivian',
    'Bosnian and Herzegovinian',
    'Botswanan',
    'Brazilian',
    'Bruneian',
    'Bulgarian',
    'Burkinabe',
    'Burundian',
    'Cabo Verdean',
    'Cambodian',
    'Cameroonian',
    'Canadian',
    'Central African',
    'Chadian',
    'Chilean',
    'Chinese',
    'Colombian',
    'Comorian',
    'Congolese',
    'Costa Rican',
    'Croatian',
    'Cuban',
    'Cypriot',
    'Czech',
    'Danish',
    'Djiboutian',
    'Dominican',
    'Dominican Republic',
    'Ecuadorian',
    'Egyptian',
    'El Salvadoran',
    'Equatorial Guinean',
    'Eritrean',
    'Estonian',
    'Eswatini',
    'Ethiopian',
    'Fijian',
    'Finnish',
    'French',
    'Gabonese',
    'Gambian',
    'Georgian',
    'German',
    'Ghanaian',
    'Greek',
    'Grenadian',
    'Guatemalan',
    'Guinean',
    'Guinea-Bissauan',
    'Guyanese',
    'Haitian',
    'Honduran',
    'Hungarian',
    'Icelander',
    'Indian',
    'Indonesian',
    'Iranian',
    'Iraqi',
    'Irish',
    'Israeli',
    'Italian',
    'Jamaican',
    'Japanese',
    'Jordanian',
    'Kazakhstani',
    'Kenyan',
    'Kiribati',
    'North Korean',
    'South Korean',
    'Kuwaiti',
    'Kyrgyzstani',
    'Laotian',
    'Latvian',
    'Lebanese',
    'Lesothan',
    'Liberian',
    'Libyan',
    'Liechtenstein',
    'Lithuanian',
    'Luxembourgish',
    'Malagasy',
    'Malawian',
    'Malaysian',
    'Maldivian',
    'Malian',
    'Maltese',
    'Marshallese',
    'Mauritanian',
    'Mauritian',
    'Mexican',
    'Micronesian',
    'Moldovan',
    'Monegasque',
    'Mongolian',
    'Montenegrin',
    'Moroccan',
    'Mozambican',
    'Burmese',
    'Namibian',
    'Nauruan',
    'Nepali',
    'Dutch',
    'New Zealand',
    'Nicaraguan',
    'Nigerien',
    'Nigerian',
    'North Macedonian',
    'Norwegian',
    'Omani',
    'Pakistani',
    'Palauan',
    'Panamanian',
    'Papuan New Guinean',
    'Paraguayan',
    'Peruvian',
    'Filipino',
    'Polish',
    'Portuguese',
    'Qatari',
    'Romanian',
    'Russian',
    'Rwandan',
    'Saint Kitts and Nevis',
    'Saint Lucian',
    'Saint Vincentian',
    'Samoan',
    'San Marinese',
    'Sao Tomean',
    'Saudi Arabian',
    'Senegalese',
    'Serbian',
    'Seychellois',
    'Sierra Leonean',
    'Singaporean',
    'Slovak',
    'Slovenian',
    'Solomon Islander',
    'Somali',
    'South African',
    'South Sudanese',
    'Spanish',
    'Sri Lankan',
    'Sudanese',
    'Surinamese',
    'Swedish',
    'Swiss',
    'Syrian',
    'Taiwanese',
    'Tajikistani',
    'Tanzanian',
    'Thai',
    'Timorese',
    'Togolese',
    'Tongan',
    'Trinidadian and Tobagonian',
    'Tunisian',
    'Turkish',
    'Turkmenistani',
    'Tuvaluan',
    'Ugandan',
    'Ukrainian',
    'Emirati',
    'British',
    'American',
    'Uruguayan',
    'Uzbekistani',
    'Vanuatuan',
    'Vatican',
    'Venezuelan',
    'Vietnamese',
    'Yemeni',
    'Zambian',
    'Zimbabwean',
  ];

  bool textFieldReadOnly = true;
  bool dropDownReadOnly = true;
  bool dropDownSearchReadOnly = true;

  // The _updateUserData function is responsible for updating the user's profile information in Firestore.
// It first retrieves the current user's UID using FirebaseAuth, and then queries the 'users' collection
// in Firestore to find the corresponding document based on the UID. Once the correct document is found,
// it constructs a map of updated user data, including personal details, address information from the AddressProvider,
// and selections from dropdown menus and checkboxes. The function then attempts to update the document
// with the new data. If the update is successful, it disables the editing mode and shows a success message via a SnackBar.
// If an error occurs during the update, an error message is displayed. This method ensures that all relevant user information
// is updated in one go, with validation and feedback to the user for a smooth experience.
  Future<void> _updateUserData() async {
    final addressProvider =
        Provider.of<AddressProvider>(context, listen: false);
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) return;

    // Find the correct document ID
    QuerySnapshot querySnapshot = await FirebaseFirestore.instance
        .collection("users")
        .where("uid", isEqualTo: currentUserUid)
        .limit(1)
        .get();

    if (querySnapshot.docs.isNotEmpty) {
      String docId = querySnapshot.docs.first.id;
      DocumentSnapshot userDoc = querySnapshot.docs.first;

      Map<String, dynamic> currentData = userDoc.data() as Map<String, dynamic>;

      // Create a map of updated values
      Map<String, dynamic> updatedData = {
        "first_name": firstNameController.text,
        "middle_name": middleNameController.text,
        "last_name": lastNameController.text,
        "suffix": suffixController.text,
        "email": emailController.text,
        "mobile_number": mobileNumberController.text,
        // Dropdowns
        "sex": selectedSex,
        "civil_status": selectedCivilStatus,
        
        // Dropdown Search Fields
        "citizenship": selectedCitizenship,
        };

      Map<String, dynamic> changedFields = {};
      updatedData.forEach((key, newValue) {
        var oldValue = currentData[key];
        if (oldValue != newValue) {
          changedFields[key] = {
            "from": oldValue,
            "to": newValue,
          };
        }
      });

      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(docId)
            .update(updatedData);

        if (changedFields.isNotEmpty) {
          await logAuditTrail(
            "Update Profile",
            "Updated fields: ${changedFields.entries.map((e) => "${e.key}: '${e.value['from']}' change to --> '${e.value['to']}'").join(", ")}",
          );
        }

        setState(() {
          isEditing = false; // Disable editing mode after saving
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Profile updated successfully!",
              style: TextStyle(color: Colors.white, fontFamily: "SB"),
            ),
            backgroundColor: Colors.green,
          ),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text("Failed to update profile!",
                style: TextStyle(color: Colors.white, fontFamily: "SB")),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final editModeProvider = Provider.of<EditModeProvider>(context);
    double width = MediaQuery.of(context).size.width;

    // This code retrieves the currently authenticated user's data from Firebase Firestore
// and populates relevant fields in the UI. It first checks if the user is logged in
// by obtaining the user's UID from FirebaseAuth. If the user is not logged in,
// it displays a message indicating that the user is not logged in. If the user is logged in,
// a StreamBuilder is used to listen for real-time updates from the 'users' collection in Firestore.
// When the user data is fetched, it populates form controllers (such as firstNameController, emailController, etc.)
// with the data retrieved from Firestore. It also updates state variables for dropdown fields and checkboxes,
// ensuring that the UI is always in sync with the user's data. In case of no data or loading, a loading indicator (CustomLoader) is shown.
    final String? currentUserUid = FirebaseAuth.instance.currentUser?.uid;
    if (currentUserUid == null) {
      return Center(child: Text("User not logged in"));
    }
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection("users")
          .where("uid", isEqualTo: FirebaseAuth.instance.currentUser?.uid)
          .limit(1)
          .snapshots(), // Real-time Firestore updates
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(child: CustomLoader());
        }

        var userData = snapshot.data!.docs.first.data() as Map<String, dynamic>;

        // Assign values to controllers & state variables
        firstNameController.text = userData["first_name"] ?? "";
        middleNameController.text = userData["middle_name"] ?? "";
        lastNameController.text = userData["last_name"] ?? "";
        suffixController.text = userData["suffix"] ?? "";
        emailController.text = userData["email"] ?? "";
        mobileNumberController.text = userData["mobile_number"] ?? "";
        
        // Dropdowns
        selectedSex = userData["sex"];
        selectedAnswer = userData["dual_citizen"];
        selectedCivilStatus = userData["civil_status"];
        
        // Dropdown Search Fields
        selectedCitizenship = userData["citizenship"];
        
        // Special Widgets
        _dateController.text = userData["birthdate"] ?? "";

        // Checkboxes
        byBirthChecked = userData["by_birth"] ?? false;
        byNaturalizedChecked = userData["by_naturalized"] ?? false;

        return Container(
          width: MediaQuery.of(context).size.width,
          height: MediaQuery.of(context).size.height,
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(MediaQuery.of(context).size.width / 40),
              child: Container(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 1.328,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            "Personal Information",
                            style: TextStyle(
                                fontSize:
                                    MediaQuery.of(context).size.width / 50,
                                color: Color.fromARGB(255, 11, 55, 99),
                                fontFamily: "BL"),
                          ),
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                                height: MediaQuery.of(context).size.width / 5,
                                width: MediaQuery.of(context).size.width / 5.5,
                                child: Profile()),
                            Container(
                              height: MediaQuery.of(context).size.width / 5,
                              width: MediaQuery.of(context).size.width / 1.75,
                              child: Column(
                                children: [
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 80,
                                  ),
                                  Row(
                                    children: [
                                      Column(
                                        children: [
                                          Text("First Name",
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          90,
                                                  color: Colors.black,
                                                  fontFamily: "R")),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                170,
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                7,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                35,
                                            decoration: BoxDecoration(
                                              color: textFieldReadOnly == true
                                                  ? Colors.grey[300]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          150),
                                            ),
                                            child: TextField(
                                              controller: firstNameController,
                                              keyboardType: TextInputType.text,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'[a-zA-Z]')), // Allows only letters
                                              ],
                                              readOnly: textFieldReadOnly,
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          110,
                                                  color: Colors.black,
                                                  fontFamily: "R"),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        120),
                                                hintText:
                                                    textFieldReadOnly == true
                                                        ? null
                                                        : "First Name",
                                                hintStyle: TextStyle(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            110,
                                                    color: Colors.grey,
                                                    fontFamily: "R"),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              150),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                50,
                                      ),
                                      Column(
                                        children: [
                                          Text("Middle Name",
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          90,
                                                  color: Colors.black,
                                                  fontFamily: "R")),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                170,
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                7,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                35,
                                            decoration: BoxDecoration(
                                              color: textFieldReadOnly == true
                                                  ? Colors.grey[300]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          150),
                                            ),
                                            child: TextField(
                                              controller: middleNameController,
                                              readOnly: textFieldReadOnly,
                                              keyboardType: TextInputType.text,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'[a-zA-Z]')), // Allows only letters
                                              ],
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          110,
                                                  color: Colors.black,
                                                  fontFamily: "R"),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        120),
                                                hintText:
                                                    textFieldReadOnly == true
                                                        ? null
                                                        : "Middle Name",
                                                hintStyle: TextStyle(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            110,
                                                    color: Colors.grey,
                                                    fontFamily: "R"),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              150),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                50,
                                      ),
                                      Column(
                                        children: [
                                          Text("Last Name",
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          90,
                                                  color: Colors.black,
                                                  fontFamily: "R")),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                170,
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                7,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                35,
                                            decoration: BoxDecoration(
                                              color: textFieldReadOnly == true
                                                  ? Colors.grey[300]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          150),
                                            ),
                                            child: TextField(
                                              controller: lastNameController,
                                              keyboardType: TextInputType.text,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'[a-zA-Z]')), // Allows only letters
                                              ],
                                              readOnly: textFieldReadOnly,
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          110,
                                                  color: Colors.black,
                                                  fontFamily: "R"),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        120),
                                                hintText:
                                                    textFieldReadOnly == true
                                                        ? null
                                                        : "Last Name",
                                                hintStyle: TextStyle(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            110,
                                                    color: Colors.grey,
                                                    fontFamily: "R"),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              150),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                50,
                                      ),
                                      Column(
                                        children: [
                                          Text("Suffix",
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          90,
                                                  color: Colors.black,
                                                  fontFamily: "R")),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                170,
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                12.1,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                35,
                                            decoration: BoxDecoration(
                                              color: textFieldReadOnly == true
                                                  ? Colors.grey[300]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          150),
                                            ),
                                            child: TextField(
                                              controller: suffixController,
                                              keyboardType: TextInputType.text,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'[a-zA-Z]')), // Allows only letters
                                              ],
                                              readOnly: textFieldReadOnly,
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          110,
                                                  color: Colors.black,
                                                  fontFamily: "R"),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        120),
                                                hintText:
                                                    textFieldReadOnly == true
                                                        ? null
                                                        : "Suffix",
                                                hintStyle: TextStyle(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            110,
                                                    color: Colors.grey,
                                                    fontFamily: "R"),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              150),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 80,
                                  ),
                                  Row(
                                    children: [
                                      SexDropdown(
                                        selectedSex: selectedSex,
                                        isReadOnly: dropDownReadOnly,
                                        onChanged: (String? newValue) {
                                          selectedSex = newValue;
                                        },
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                50,
                                      ),
                                      CitizenshipDropdown(
                                        initialValue: selectedCitizenship,
                                        enableSearch: dropDownSearchReadOnly,
                                        isReadOnly: dropDownSearchReadOnly,
                                        selectedValue: selectedCitizenship,
                                        citizenshipOptions: citizenshipOptions,
                                        onChanged: (value) {
                                          selectedCitizenship = value;
                                        },
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                50,
                                      ),
                                    ],
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 80,
                                  ),
                                  Row(
                                    children: [
                                      CivilStatusDropdown(
                                        selectedValue: selectedCivilStatus,
                                        isReadOnly: dropDownReadOnly,
                                        onChanged: (String? newValue) {
                                          selectedCivilStatus = newValue;
                                        },
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                50,
                                      ),
                                      Column(
                                        children: [
                                          Text("Mobile Number",
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          90,
                                                  color: Colors.black,
                                                  fontFamily: "R")),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                170,
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                9,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                35,
                                            decoration: BoxDecoration(
                                              color: textFieldReadOnly == true
                                                  ? Colors.grey[300]
                                                  : Colors.white,
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          150),
                                            ),
                                            child: TextField(
                                              controller:
                                                  mobileNumberController,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .digitsOnly, // This ensures only digits are allowed
                                              ],
                                              keyboardType:
                                                  TextInputType.number,
                                              readOnly: textFieldReadOnly,
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          110,
                                                  color: Colors.black,
                                                  fontFamily: "R"),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        120),
                                                hintText:
                                                    textFieldReadOnly == true
                                                        ? null
                                                        : "Mobile Number",
                                                hintStyle: TextStyle(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            110,
                                                    color: Colors.grey,
                                                    fontFamily: "R"),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              150),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                50,
                                      ),
                                      Column(
                                        children: [
                                          Text("Email Address",
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          90,
                                                  color: Colors.black,
                                                  fontFamily: "R")),
                                          SizedBox(
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                170,
                                          ),
                                          Container(
                                            width: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                5.29,
                                            height: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                35,
                                            decoration: BoxDecoration(
                                              color: Colors.grey[300],
                                              borderRadius:
                                                  BorderRadius.circular(
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          150),
                                            ),
                                            child: TextField(
                                              controller: emailController,
                                              readOnly: true,
                                              keyboardType:
                                                  TextInputType.emailAddress,
                                              inputFormatters: [
                                                FilteringTextInputFormatter
                                                    .allow(RegExp(
                                                        r'[a-zA-Z0-9@._-]')), // Allows letters, numbers, @, ., -, and _
                                              ],
                                              style: TextStyle(
                                                  fontSize:
                                                      MediaQuery.of(context)
                                                              .size
                                                              .width /
                                                          110,
                                                  color: Colors.black,
                                                  fontFamily: "R"),
                                              decoration: InputDecoration(
                                                contentPadding: EdgeInsets.all(
                                                    MediaQuery.of(context)
                                                            .size
                                                            .width /
                                                        120),
                                                hintText:
                                                    textFieldReadOnly == true
                                                        ? null
                                                        : "Email Address",
                                                hintStyle: TextStyle(
                                                    fontSize:
                                                        MediaQuery.of(context)
                                                                .size
                                                                .width /
                                                            110,
                                                    color: Colors.grey,
                                                    fontFamily: "R"),
                                                border: OutlineInputBorder(
                                                  borderRadius:
                                                      BorderRadius.circular(
                                                          MediaQuery.of(context)
                                                                  .size
                                                                  .width /
                                                              150),
                                                ),
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        SizedBox(
                          height: MediaQuery.of(context).size.width / 80,
                        ),
                        Container(
                          width: MediaQuery.of(context).size.width / 1.326,
                          padding: EdgeInsets.only(
                              left: MediaQuery.of(context).size.width / 37),
                          child: Column(
                            children: [
                              // GestureDetector triggers onTap event for toggling between edit and save modes.
// Initially, it checks if the user is in edit mode using `editModeProvider.isEditing`.
// If not in edit mode, it enables editing by setting various state variables
// and making input fields (text fields, dropdowns, calendar, etc.) editable.
// The button's color and text content are updated accordingly to reflect the change to edit mode.
// If in edit mode, it triggers saving the updated user data through `_updateUserData` method,
// then switches back to non-edit mode by disabling all input fields and resetting the button's color and text.
// The addressProvider is used to log the selected region name during the save operation.
                              GestureDetector(
                                onTap: () async {
                                  final editModeProvider =
                                      Provider.of<EditModeProvider>(context,
                                          listen: false);
                                  final addressProvider =
                                      Provider.of<AddressProvider>(context,
                                          listen: false);

                                  if (!editModeProvider.isEditing) {
                                    // Enable editing mode
                                    editModeProvider.toggleEditMode();
                                    setState(() {
                                      _buttonColor = Colors.green;
                                      _textContent = "Save Changes";
                                      textFieldReadOnly = false;
                                      dropDownReadOnly = false;
                                      dropDownSearchReadOnly = false;
                                    });
                                  } else {
                                    // Save changes first, then disable editing mode
                                    await _updateUserData();

                                    editModeProvider.toggleEditMode();
                                    setState(() {
                                      _textContent = "Edit Profile Information";
                                      _buttonColor =
                                          Color.fromARGB(255, 11, 55, 99);
                                      textFieldReadOnly = true;
                                      dropDownReadOnly = true;
                                      dropDownSearchReadOnly = true;
                                    });
                                  }
                                },
                                child: Container(
                                    width: MediaQuery.of(context).size.width /
                                        1.328,
                                    height:
                                        MediaQuery.of(context).size.width / 25,
                                    decoration: BoxDecoration(
                                        color: _buttonColor,
                                        borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width /
                                                150)),
                                    child: Center(
                                      child: Text(
                                        "$_textContent",
                                        style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                70,
                                            color: Colors.white,
                                            fontFamily: "SB"),
                                      ),
                                    )),
                              ).showCursorOnHover,
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 50),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Container(
                      width: MediaQuery.of(context).size.width / 1.328,
                      decoration: BoxDecoration(
                        border: Border(bottom: BorderSide(color: Colors.black)),
                      ),
                      child: Text(
                        "Account Information",
                        style: TextStyle(
                            fontSize: MediaQuery.of(context).size.width / 50,
                            color: Color.fromARGB(255, 11, 55, 99),
                            fontFamily: "BL"),
                      ),
                    ),
                    Container(
                        width: MediaQuery.of(context).size.width / 1.328,
                        padding: EdgeInsets.only(
                            left: MediaQuery.of(context).size.width / 37,
                            right: MediaQuery.of(context).size.width / 37),
                        child: AccountInfo()),
                  ],
                ),
              ),
            ),
          ),
        ); // Return the UI after fetching data
      },
    );
  }
}

class SexDropdown extends StatefulWidget {
  final String? selectedSex;
  final bool isReadOnly;
  final Function(String?) onChanged;

  const SexDropdown({
    Key? key,
    required this.selectedSex,
    required this.isReadOnly,
    required this.onChanged,
  }) : super(key: key);

  @override
  _SexDropdownState createState() => _SexDropdownState();
}

class _SexDropdownState extends State<SexDropdown> {
  String? _selectedValue;

  @override
  void initState() {
    super.initState();
    _selectedValue = widget.selectedSex;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Sex",
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width / 170),
        Container(
          height: MediaQuery.of(context).size.width / 35,
          width: MediaQuery.of(context).size.width / 13,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(
              MediaQuery.of(context).size.width / 150,
            ),
            color: widget.isReadOnly ? Colors.grey[300] : Colors.white,
          ),
          child: DropdownButton<String>(
            value: _selectedValue,
            isExpanded: true,
            dropdownColor: Colors.white,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width / 110,
              color: widget.isReadOnly ? Colors.grey : Colors.black,
              fontFamily: "R",
            ),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width / 120,
            ),
            underline: SizedBox.shrink(),
            icon: Icon(Icons.arrow_drop_down),
            hint: widget.isReadOnly
                ? null
                : Text(
                    'Select',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 110,
                      color: Colors.black,
                      fontFamily: "R",
                    ),
                  ),
            items: ['Male', 'Female'].map<DropdownMenuItem<String>>(
              (String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 4.0),
                    child: Text(value),
                  ),
                );
              },
            ).toList(),
            onChanged: widget.isReadOnly
                ? null
                : (String? newValue) {
                    setState(() {
                      _selectedValue = newValue;
                    });
                    widget.onChanged(newValue);
                  },
          ),
        ),
      ],
    );
  }
}

class CivilStatusDropdown extends StatefulWidget {
  final String? selectedValue;
  final bool isReadOnly;
  final ValueChanged<String?>? onChanged;

  const CivilStatusDropdown({
    Key? key,
    this.selectedValue,
    required this.isReadOnly,
    this.onChanged,
  }) : super(key: key);

  @override
  _CivilStatusDropdownState createState() => _CivilStatusDropdownState();
}

class _CivilStatusDropdownState extends State<CivilStatusDropdown> {
  String? localSelectedValue;

  @override
  void initState() {
    super.initState();
    localSelectedValue = widget.selectedValue; // Initialize with provided value
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          "Civil Status",
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width / 170),
        Container(
          height: MediaQuery.of(context).size.width / 35,
          width: MediaQuery.of(context).size.width / 10,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius:
                BorderRadius.circular(MediaQuery.of(context).size.width / 150),
            color: widget.isReadOnly ? Colors.grey[300] : Colors.white,
          ),
          child: DropdownButton<String>(
            value: localSelectedValue,
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width / 110,
              color: widget.isReadOnly ? Colors.grey : Colors.black,
              fontFamily: "R",
            ),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width / 120,
            ),
            hint: widget.isReadOnly
                ? null
                : Text(
                    'Select',
                    style: TextStyle(
                      fontSize: MediaQuery.of(context).size.width / 110,
                      color: Colors.black,
                      fontFamily: "R",
                    ),
                  ),
            onChanged: widget.isReadOnly
                ? null
                : (String? newValue) {
                    setState(() {
                      localSelectedValue = newValue;
                    });
                    widget.onChanged?.call(newValue);
                  },
            items: ['Single', 'Married', 'Divorced', 'Separated']
                .map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Padding(
                  padding: EdgeInsets.symmetric(vertical: 4.0),
                  child: Text(value),
                ),
              );
            }).toList(),
            underline: SizedBox.shrink(),
            isExpanded: true,
            dropdownColor: Colors.white,
            icon: Icon(Icons.arrow_drop_down),
          ),
        ),
      ],
    );
  }
}

class CitizenshipDropdown extends StatefulWidget {
  final String? initialValue;
  final bool enableSearch;
  final bool isReadOnly;
  final String? selectedValue;
  final List<String> citizenshipOptions;
  final Function(String?) onChanged;

  const CitizenshipDropdown({
    Key? key,
    required this.initialValue,
    required this.enableSearch,
    required this.isReadOnly,
    required this.selectedValue,
    required this.citizenshipOptions,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CitizenshipDropdownState createState() => _CitizenshipDropdownState();
}

class _CitizenshipDropdownState extends State<CitizenshipDropdown> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Text(
          "Citizenship",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          height: width / 35,
          width: width / 10,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(width / 150),
            color: widget.isReadOnly ? Colors.grey[300] : Colors.white,
          ),
          child: DropDownTextField(
            onChanged: (selected) {
              setState(() {
                widget.onChanged(selected?.value);
              });
            },
            readOnly: widget.isReadOnly,
            enableSearch: widget.enableSearch,
            searchTextStyle: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            initialValue: widget.initialValue,
            searchKeyboardType: TextInputType.text,
            searchDecoration: InputDecoration(
              hintText: widget.isReadOnly ? null : "Search",
              hintStyle: TextStyle(
                fontSize: width / 140,
                color: Colors.black,
                fontFamily: "R",
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(width / 150),
              ),
            ),
            clearOption: true,
            listTextStyle: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            textStyle: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            validator: (value) => value == null ? "Required field" : null,
            dropDownItemCount: 6,
            listPadding: ListPadding(top: 0, bottom: 0),
            dropDownList: widget.isReadOnly
                ? []
                : widget.citizenshipOptions
                    .map((option) => DropDownValueModel(
                          name: option,
                          value: option,
                        ))
                    .toList(),
          ),
        ),
      ],
    );
  }
}
