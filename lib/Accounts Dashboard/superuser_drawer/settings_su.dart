import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/account_info.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/caddress.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/profile.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/su_address_provider.dart';
import 'package:attendance_app/Animation/loader.dart';
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
  final TextEditingController telephoneNumberController =
      TextEditingController();
  final TextEditingController placeOfBirthController = TextEditingController();
  final TextEditingController heightController = TextEditingController();
  final TextEditingController weightController = TextEditingController();

  String _textContent = "Edit Profile Information";
  Color _buttonColor = Color.fromARGB(255, 11, 55, 99);

  DateTime? _selectedDate;
  TextEditingController _dateController = TextEditingController();

  bool byBirthChecked = false;
  bool byNaturalizedChecked = false;

  void _onCheckboxChanged(String type) {
    setState(() {
      if (type == 'birth') {
        byBirthChecked = true;
        byNaturalizedChecked = false;
      } else {
        byBirthChecked = false;
        byNaturalizedChecked = true;
      }
    });
  }

  List<String> options = ['Male', 'Female'];
  List<String> civilStatus = ['Single', 'Divorced', 'Separated', 'Married'];
  List<String> yon = ['Yes', 'No'];
  String? selectedAnswer;
  String? selectedSex;
  String? selectedCitizenship = "";
  String? selectedCountry;
  String? selectedReligion;
  String? selectedCivilStatus;
  String? selectedBloodType;
  List<String> bloodTypes = ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-'];
  List<String> religion = [
    'Iglesia Ni Cristo',
    'Roman Catholic',
    'Jehovah\'s Witness',
    'Christianity',
    'Islam',
    'Hinduism',
    'Buddhism',
    'Judaism',
    'Sikhism',
    'Taoism',
    'Shinto',
    'Confucianism',
    'Zoroastrianism',
    'Jainism',
    'Bahá\'í Faith',
    'Shamanism',
    'Paganism',
    'Atheism',
    'Agnosticism',
    'Spiritualism',
    'Unitarian Universalism',
    'Wicca',
    'Zoroastrianism',
    'Rastafari',
    'New Age',
    'Scientology',
    'Church of the Flying Spaghetti Monster',
    'Pastafarianism',
    'Satanism',
    'Druidism',
    'Animism',
    'Falun Gong',
    'Cao Dai',
    'Tenrikyo',
    'Seventh-day Adventist',
    'Mormonism',
    'Hare Krishna',
    'Native American Religion',
    'African Traditional Religions',
    'Santería',
    'Vodou',
    'Candomblé',
    'Native Hawaiian Religion',
    'Mormonism',
    'Confucianism',
    'Bahá\'í Faith',
    'Zoroastrianism',
    'Tengrism',
    'Unitarianism'
  ];

  List<String> countries = [
    'Afghanistan',
    'Albania',
    'Algeria',
    'Andorra',
    'Angola',
    'Antigua and Barbuda',
    'Argentina',
    'Armenia',
    'Australia',
    'Austria',
    'Azerbaijan',
    'Bahamas',
    'Bahrain',
    'Bangladesh',
    'Barbados',
    'Belarus',
    'Belgium',
    'Belize',
    'Benin',
    'Bhutan',
    'Bolivia',
    'Bosnia and Herzegovina',
    'Botswana',
    'Brazil',
    'Brunei',
    'Bulgaria',
    'Burkina Faso',
    'Burundi',
    'Cabo Verde',
    'Cambodia',
    'Cameroon',
    'Canada',
    'Central African Republic',
    'Chad',
    'Chile',
    'China',
    'Colombia',
    'Comoros',
    'Congo',
    'Costa Rica',
    'Croatia',
    'Cuba',
    'Cyprus',
    'Czech Republic',
    'Denmark',
    'Djibouti',
    'Dominica',
    'Dominican Republic',
    'Ecuador',
    'Egypt',
    'El Salvador',
    'Equatorial Guinea',
    'Eritrea',
    'Estonia',
    'Eswatini',
    'Ethiopia',
    'Fiji',
    'Finland',
    'France',
    'Gabon',
    'Gambia',
    'Georgia',
    'Germany',
    'Ghana',
    'Greece',
    'Grenada',
    'Guatemala',
    'Guinea',
    'Guinea-Bissau',
    'Guyana',
    'Haiti',
    'Honduras',
    'Hungary',
    'Iceland',
    'India',
    'Indonesia',
    'Iran',
    'Iraq',
    'Ireland',
    'Israel',
    'Italy',
    'Jamaica',
    'Japan',
    'Jordan',
    'Kazakhstan',
    'Kenya',
    'Kiribati',
    'Korea, North',
    'Korea, South',
    'Kuwait',
    'Kyrgyzstan',
    'Laos',
    'Latvia',
    'Lebanon',
    'Lesotho',
    'Liberia',
    'Libya',
    'Liechtenstein',
    'Lithuania',
    'Luxembourg',
    'Madagascar',
    'Malawi',
    'Malaysia',
    'Maldives',
    'Mali',
    'Malta',
    'Marshall Islands',
    'Mauritania',
    'Mauritius',
    'Mexico',
    'Micronesia',
    'Moldova',
    'Monaco',
    'Mongolia',
    'Montenegro',
    'Morocco',
    'Mozambique',
    'Myanmar',
    'Namibia',
    'Nauru',
    'Nepal',
    'Netherlands',
    'New Zealand',
    'Nicaragua',
    'Niger',
    'Nigeria',
    'North Macedonia',
    'Norway',
    'Oman',
    'Pakistan',
    'Palau',
    'Panama',
    'Papua New Guinea',
    'Paraguay',
    'Peru',
    'Philippines',
    'Poland',
    'Portugal',
    'Qatar',
    'Romania',
    'Russia',
    'Rwanda',
    'Saint Kitts and Nevis',
    'Saint Lucia',
    'Saint Vincent and the Grenadines',
    'Samoa',
    'San Marino',
    'Sao Tome and Principe',
    'Saudi Arabia',
    'Senegal',
    'Serbia',
    'Seychelles',
    'Sierra Leone',
    'Singapore',
    'Slovakia',
    'Slovenia',
    'Solomon Islands',
    'Somalia',
    'South Africa',
    'South Sudan',
    'Spain',
    'Sri Lanka',
    'Sudan',
    'Suriname',
    'Sweden',
    'Switzerland',
    'Syria',
    'Taiwan',
    'Tajikistan',
    'Tanzania',
    'Thailand',
    'Timor-Leste',
    'Togo',
    'Tonga',
    'Trinidad and Tobago',
    'Tunisia',
    'Turkey',
    'Turkmenistan',
    'Tuvalu',
    'Uganda',
    'Ukraine',
    'United Arab Emirates',
    'United Kingdom',
    'United States',
    'Uruguay',
    'Uzbekistan',
    'Vanuatu',
    'Vatican City',
    'Venezuela',
    'Vietnam',
    'Yemen',
    'Zambia',
    'Zimbabwe'
  ];
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
  bool calendarReadOnly = true;
  String? selectedCity;
  String? selectedMunicipality;
  String? selectedRegion;
  String? selectedProvince;
  String? selectedCityOrMunicipality;
  String? selectedBarangay;

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
      String docId = querySnapshot.docs.first.id; // Get Firestore document ID

      // Create a map of updated values
      Map<String, dynamic> updatedData = {
        "first_name": firstNameController.text,
        "middle_name": middleNameController.text,
        "last_name": lastNameController.text,
        "suffix": suffixController.text,
        "email": emailController.text,
        "mobile_number": mobileNumberController.text,
        "telephone_number": telephoneNumberController.text,
        "place_of_birth": placeOfBirthController.text,
        "height": heightController.text,
        "weight": weightController.text,
        "house_number": addressProvider.houseNumber,
        "street": addressProvider.street,
        "subdivision": addressProvider.subdivision,
        "zip_code": addressProvider.zipcode,

        // Dropdowns
        "sex": selectedSex,
        "dual_citizen": selectedAnswer,
        "civil_status": selectedCivilStatus,
        "blood_type": selectedBloodType,

        // Dropdown Search Fields
        "citizenship": selectedCitizenship,
        "country": selectedCountry,
        "religion": selectedReligion,
        "region": addressProvider.selectedRegionName ?? "",
        "province": addressProvider.selectedProvinceName ?? "",
        "city": addressProvider.selectedCityName ?? "",
        "municipality": addressProvider.selectedMunicipalityName ?? "",
        "barangay": addressProvider.selectedBarangayName ?? "",

        // Special Widgets
        "birthdate": _dateController.text,

        // Checkboxes
        "by_birth": byBirthChecked,
        "by_naturalized": byNaturalizedChecked,
      };

      try {
        await FirebaseFirestore.instance
            .collection("users")
            .doc(docId)
            .update(updatedData);

        setState(() {
          isEditing = false; // Disable editing mode after saving
        });

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile updated successfully!", style: TextStyle(color: Colors.white, fontFamily: "SB"),), backgroundColor: Colors.green,),
        );
      } catch (e) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Failed to update profile!", style: TextStyle(color: Colors.white, fontFamily: "SB")), backgroundColor: Colors.red,),
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
        telephoneNumberController.text = userData["telephone_number"] ?? "";
        placeOfBirthController.text = userData["place_of_birth"] ?? "";
        heightController.text = userData["height"] ?? "";
        weightController.text = userData["weight"] ?? "";

        // Dropdowns
        selectedSex = userData["sex"];
        selectedAnswer = userData["dual_citizen"];
        selectedCivilStatus = userData["civil_status"];
        selectedBloodType = userData["blood_type"];

        // Dropdown Search Fields
        selectedCitizenship = userData["citizenship"];
        selectedCountry = userData["country"];
        selectedReligion = userData["religion"];

        // Special Widgets
        _dateController.text = userData["birthdate"] ?? "";

        // Checkboxes
        byBirthChecked = userData["by_birth"] ?? false;
        byNaturalizedChecked = userData["by_naturalized"] ?? false;

        return Expanded(
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
                              height: MediaQuery.of(context).size.width/5,
                              width: MediaQuery.of(context).size.width/5.5,
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
                                      DualCitizenDropdown(
                                        selectedValue: selectedAnswer,
                                        isReadOnly: dropDownReadOnly,
                                        onChanged: (String? newValue) {
                                          selectedAnswer = newValue;
                                        },
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                50,
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                8.55,
                                        height:
                                            MediaQuery.of(context).size.width /
                                                20,
                                        child: CitizenshipCheckbox(
                                          byBirthChecked: byBirthChecked,
                                          byNaturalizedChecked:
                                              byNaturalizedChecked,
                                          onChanged:
                                              (bool birth, bool naturalized) {
                                            byBirthChecked = birth;
                                            byNaturalizedChecked = naturalized;
                                          },
                                        ),
                                      ),
                                      SizedBox(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                50,
                                      ),
                                      SpecifyCountryDropdown(
                                        initialValue:
                                            selectedCountry, // The initial value to be displayed
                                        enableSearch:
                                            dropDownSearchReadOnly, // Enable search if not readonly
                                        isReadOnly:
                                            dropDownSearchReadOnly, // Control readonly state
                                        selectedValue:
                                            selectedCountry, // Bind selected value
                                        countries:
                                            countries, // Pass country list
                                        onChanged: (value) {
                                          // Handle value changes
                                          selectedCountry = value;
                                        },
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
                                          Text("Telephone Number",
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
                                                  telephoneNumberController,
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
                                                        : "Telephone Number",
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
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  BirthDatePicker(
                                    initialDate: _dateController
                                        .text, // Pass stored date
                                    isReadOnly: calendarReadOnly,
                                    onDateSelected: (String selectedDate) {
                                      _dateController.text = selectedDate;
                                    },
                                  ),
                                  Column(
                                    children: [
                                      Text("Place of Birth",
                                          style: TextStyle(
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  90,
                                              color: Colors.black,
                                              fontFamily: "R")),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                170,
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                5.52,
                                        height:
                                            MediaQuery.of(context).size.width /
                                                35,
                                        decoration: BoxDecoration(
                                          color: textFieldReadOnly == true
                                              ? Colors.grey[300]
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                        child: TextField(
                                          controller: placeOfBirthController,
                                          keyboardType: TextInputType.text,
                                          inputFormatters: [
                                            FilteringTextInputFormatter.allow(
                                                RegExp(
                                                    r'[a-zA-Z ]')), // Allows letters and spaces only
                                          ],
                                          readOnly: textFieldReadOnly,
                                          style: TextStyle(
                                              fontSize: MediaQuery.of(context)
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
                                            hintText: textFieldReadOnly == true
                                                ? null
                                                : "Place of Birth",
                                            hintStyle: TextStyle(
                                                fontSize: MediaQuery.of(context)
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
                                  Column(
                                    children: [
                                      Text("Height",
                                          style: TextStyle(
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  90,
                                              color: Colors.black,
                                              fontFamily: "R")),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                170,
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                15,
                                        height:
                                            MediaQuery.of(context).size.width /
                                                35,
                                        decoration: BoxDecoration(
                                          color: textFieldReadOnly == true
                                              ? Colors.grey[300]
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                        child: TextField(
                                          controller: heightController,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly, // This ensures only digits are allowed
                                          ],
                                          keyboardType: TextInputType.number,
                                          readOnly: textFieldReadOnly,
                                          style: TextStyle(
                                              fontSize: MediaQuery.of(context)
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
                                            hintText: textFieldReadOnly == true
                                                ? null
                                                : "in cm",
                                            hintStyle: TextStyle(
                                                fontSize: MediaQuery.of(context)
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
                                  Column(
                                    children: [
                                      Text("Weight",
                                          style: TextStyle(
                                              fontSize: MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  90,
                                              color: Colors.black,
                                              fontFamily: "R")),
                                      SizedBox(
                                        height:
                                            MediaQuery.of(context).size.width /
                                                170,
                                      ),
                                      Container(
                                        width:
                                            MediaQuery.of(context).size.width /
                                                15,
                                        height:
                                            MediaQuery.of(context).size.width /
                                                35,
                                        decoration: BoxDecoration(
                                          color: textFieldReadOnly == true
                                              ? Colors.grey[300]
                                              : Colors.white,
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                        child: TextField(
                                          controller: weightController,
                                          inputFormatters: [
                                            FilteringTextInputFormatter
                                                .digitsOnly, // This ensures only digits are allowed
                                          ],
                                          keyboardType: TextInputType.number,
                                          readOnly: textFieldReadOnly,
                                          style: TextStyle(
                                              fontSize: MediaQuery.of(context)
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
                                            hintText: textFieldReadOnly == true
                                                ? null
                                                : "in kg",
                                            hintStyle: TextStyle(
                                                fontSize: MediaQuery.of(context)
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
                                  BloodTypeDropdown(
                                    selectedValue: selectedBloodType,
                                    isReadOnly: dropDownReadOnly,
                                    onChanged: (String? newValue) {
                                      selectedBloodType = newValue;
                                    },
                                  ),
                                  ReligionDropdown(
                                    initialValue:
                                        selectedReligion, // The initial value to be displayed
                                    enableSearch:
                                        dropDownSearchReadOnly, // Enable search if not readonly
                                    isReadOnly:
                                        dropDownSearchReadOnly, // Control readonly state
                                    selectedValue:
                                        selectedReligion, // Bind selected value
                                    religionOptions:
                                        religion, // Pass religion list
                                    onChanged: (value) {
                                      // Handle value changes
                                      selectedReligion = value;
                                    },
                                  ),
                                ],
                              ),
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width / 80),
                              Container(
                                width:
                                    MediaQuery.of(context).size.width / 1.328,
                                decoration: BoxDecoration(
                                  border: Border(
                                      bottom: BorderSide(color: Colors.grey)),
                                ),
                                child: Text(
                                  "Current Address",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              70,
                                      color: Colors.black,
                                      fontFamily: "SB"),
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 100,
                              ),
                              Container(
                                  width:
                                      MediaQuery.of(context).size.width / 1.328,
                                  height: MediaQuery.of(context).size.width / 8,
                                  child: CurrentAddressPick()),
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.height / 50),
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
                                      calendarReadOnly = false;
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
                                      calendarReadOnly = true;
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

class DualCitizenDropdown extends StatefulWidget {
  final String? selectedValue;
  final bool isReadOnly;
  final ValueChanged<String?>? onChanged;

  const DualCitizenDropdown({
    Key? key,
    this.selectedValue,
    required this.isReadOnly,
    this.onChanged,
  }) : super(key: key);

  @override
  _DualCitizenDropdownState createState() => _DualCitizenDropdownState();
}

class _DualCitizenDropdownState extends State<DualCitizenDropdown> {
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
          "Dual Citizen",
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
            borderRadius:
                BorderRadius.circular(MediaQuery.of(context).size.width / 150),
            color: widget.isReadOnly ? Colors.grey[300] : Colors.white,
          ),
          child: DropdownButton<String>(
            style: TextStyle(
              fontSize: MediaQuery.of(context).size.width / 110,
              color: widget.isReadOnly ? Colors.grey : Colors.black,
              fontFamily: "R",
            ),
            padding: EdgeInsets.symmetric(
              horizontal: MediaQuery.of(context).size.width / 120,
            ),
            value: localSelectedValue,
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
            items: ['Yes', 'No'].map<DropdownMenuItem<String>>((String value) {
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

class BloodTypeDropdown extends StatefulWidget {
  final String? selectedValue;
  final bool isReadOnly;
  final ValueChanged<String?>? onChanged;

  const BloodTypeDropdown({
    Key? key,
    this.selectedValue,
    required this.isReadOnly,
    this.onChanged,
  }) : super(key: key);

  @override
  _BloodTypeDropdownState createState() => _BloodTypeDropdownState();
}

class _BloodTypeDropdownState extends State<BloodTypeDropdown> {
  String? localSelectedValue;

  final List<String> bloodTypes = [
    'A+',
    'A-',
    'B+',
    'B-',
    'AB+',
    'AB-',
    'O+',
    'O-'
  ];

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
          "Blood Type",
          style: TextStyle(
            fontSize: MediaQuery.of(context).size.width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: MediaQuery.of(context).size.width / 170),
        Container(
          height: MediaQuery.of(context).size.width / 35,
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
              vertical: MediaQuery.of(context).size.width / 150,
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
            items: bloodTypes.map<DropdownMenuItem<String>>((String value) {
              return DropdownMenuItem<String>(
                value: value,
                child: Text(value),
              );
            }).toList(),
            underline: SizedBox.shrink(),
            isExpanded: false,
            dropdownColor: Colors.white,
            icon: Icon(Icons.arrow_drop_down),
            isDense: true,
            selectedItemBuilder: (BuildContext context) {
              return bloodTypes.map<Widget>((String value) {
                return Text(value);
              }).toList();
            },
            menuMaxHeight: MediaQuery.of(context).size.width / 7,
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

class SpecifyCountryDropdown extends StatefulWidget {
  final String? initialValue;
  final bool enableSearch;
  final bool isReadOnly;
  final String? selectedValue;
  final List<String> countries;
  final Function(String?) onChanged;

  const SpecifyCountryDropdown({
    Key? key,
    required this.initialValue,
    required this.enableSearch,
    required this.isReadOnly,
    required this.selectedValue,
    required this.countries,
    required this.onChanged,
  }) : super(key: key);

  @override
  _SpecifyCountryDropdownState createState() => _SpecifyCountryDropdownState();
}

class _SpecifyCountryDropdownState extends State<SpecifyCountryDropdown> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Column(
      children: [
        Text(
          "Specify Country",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          height: width / 35,
          width: width / 8.3,
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
            dropDownItemCount: 8,
            listPadding: ListPadding(top: 0, bottom: 0),
            dropDownList: widget.isReadOnly
                ? []
                : widget.countries
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

class ReligionDropdown extends StatefulWidget {
  final String? initialValue;
  final bool enableSearch;
  final bool isReadOnly;
  final String? selectedValue;
  final List<String> religionOptions;
  final Function(String?) onChanged;

  const ReligionDropdown({
    Key? key,
    required this.initialValue,
    required this.enableSearch,
    required this.isReadOnly,
    required this.selectedValue,
    required this.religionOptions,
    required this.onChanged,
  }) : super(key: key);

  @override
  _ReligionDropdownState createState() => _ReligionDropdownState();
}

class _ReligionDropdownState extends State<ReligionDropdown> {
  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Text(
          "Religion",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          height: width / 35,
          width: width / 8.8,
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
                : widget.religionOptions
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

class CitizenshipCheckbox extends StatefulWidget {
  final bool byBirthChecked;
  final bool byNaturalizedChecked;
  final Function(bool, bool) onChanged;

  const CitizenshipCheckbox({
    Key? key,
    required this.byBirthChecked,
    required this.byNaturalizedChecked,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CitizenshipCheckboxState createState() => _CitizenshipCheckboxState();
}

class _CitizenshipCheckboxState extends State<CitizenshipCheckbox> {
  late bool _byBirthChecked;
  late bool _byNaturalizedChecked;

  @override
  void initState() {
    super.initState();
    _byBirthChecked = widget.byBirthChecked;
    _byNaturalizedChecked = widget.byNaturalizedChecked;
  }

  void _onCheckboxChanged(String type) {
    setState(() {
      if (type == 'birth') {
        _byBirthChecked = !_byBirthChecked;
        _byNaturalizedChecked = false; // Ensure only one can be selected
      } else if (type == 'naturalize') {
        _byNaturalizedChecked = !_byNaturalizedChecked;
        _byBirthChecked = false; // Ensure only one can be selected
      }
      widget.onChanged(_byBirthChecked, _byNaturalizedChecked);
    });
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Container(
          height: width / 40,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "By Birth",
              style: TextStyle(
                fontSize: width / 120,
                color: Colors.black,
                fontFamily: "R",
              ),
            ),
            value: _byBirthChecked,
            onChanged: (_) => _onCheckboxChanged('birth'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
        Container(
          height: width / 40,
          child: CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(
              "By Naturalize",
              style: TextStyle(
                fontSize: width / 120,
                color: Colors.black,
                fontFamily: "R",
              ),
            ),
            value: _byNaturalizedChecked,
            onChanged: (_) => _onCheckboxChanged('naturalize'),
            controlAffinity: ListTileControlAffinity.leading,
          ),
        ),
      ],
    );
  }
}

class BirthDatePicker extends StatefulWidget {
  final String initialDate;
  final bool isReadOnly;
  final Function(String) onDateSelected;

  const BirthDatePicker({
    Key? key,
    required this.initialDate,
    required this.isReadOnly,
    required this.onDateSelected,
  }) : super(key: key);

  @override
  _BirthDatePickerState createState() => _BirthDatePickerState();
}

class _BirthDatePickerState extends State<BirthDatePicker> {
  late TextEditingController _dateController;
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _dateController = TextEditingController(text: widget.initialDate);
  }

  // This will show a Date Picker
  Future<void> _selectDate(BuildContext context) async {
    var results = await showCalendarDatePicker2Dialog(
      context: context,
      config: CalendarDatePicker2WithActionButtonsConfig(
        calendarType: CalendarDatePicker2Type.single,
      ),
      dialogSize: const Size(325, 400),
      value: _selectedDate != null ? [_selectedDate] : [],
      borderRadius: BorderRadius.circular(15),
    );

    if (results != null && results.isNotEmpty && results[0] != null) {
      setState(() {
        _selectedDate = results[0];
        String formattedDate =
            "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
        _dateController.text = formattedDate;
        widget.onDateSelected(formattedDate);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;

    return Column(
      children: [
        Text(
          "Birth Date",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          width: width / 8,
          height: width / 35,
          decoration: BoxDecoration(
            color: widget.isReadOnly ? Colors.grey[300] : Colors.white,
            borderRadius: BorderRadius.circular(width / 150),
          ),
          child: TextField(
            controller: _dateController,
            readOnly: true, // Prevent manual input
            style: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.symmetric(horizontal: width / 60),
              hintText: widget.isReadOnly ? null : "Enter Birthdate",
              hintStyle: TextStyle(
                fontSize: width / 110,
                color: Colors.grey,
                fontFamily: "R",
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(width / 150),
              ),
              suffixIcon: Icon(Icons.calendar_today), // Calendar icon
            ),
            onTap: widget.isReadOnly ? null : () => _selectDate(context),
          ),
        ),
      ],
    );
  }
}
