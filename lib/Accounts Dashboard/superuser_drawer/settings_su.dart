import 'package:attendance_app/hover_extensions.dart';
import 'package:calendar_date_picker2/calendar_date_picker2.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class SettingsSU extends StatefulWidget {
  const SettingsSU({super.key});

  @override
  State<SettingsSU> createState() => _SettingsSUState();
}

class _SettingsSUState extends State<SettingsSU> {
  MainAxisAlignment _axisRow = MainAxisAlignment.start;
  final PSGCService psgcService = PSGCService();

// Selected values for dropdowns
  String? selectedCity;
  String? selectedMunicipality;
  String? selectedRegion;
  String? selectedProvince;
  String? selectedCityOrMunicipality;
  String? selectedBarangay;

// Lists to store dropdown options
  List<dynamic> cities = [];
  List<dynamic> municipalities = [];
  List<dynamic> regions = [];
  List<dynamic> provinces = [];
  List<dynamic> citiesMunicipalities = [];
  List<dynamic> barangays = [];

  @override
  void initState() {
    super.initState();
    _loadRegions();
  }

// Fetch regions
  void _loadRegions() async {
    var result = await psgcService.fetchRegions();
    setState(() {
      regions = result;
    });
  }

// Fetch provinces or cities/municipalities based on region selection
  void _loadProvincesOrCities(String regionCode) async {
    print("Loading data for region: $regionCode");

    // First, clear all lower-level selections
    setState(() {
      selectedProvince = null;
      selectedCityOrMunicipality = null;
      selectedBarangay = null;
      provinces = [];
      citiesMunicipalities = [];
      barangays = [];
    });

    // Check if the region has provinces
    var provinceResult = await psgcService.fetchProvinces(regionCode);
    if (provinceResult.isNotEmpty) {
      // This region has provinces, so populate the province dropdown
      setState(() {
        provinces = provinceResult;
      });
    } else {
      // No provinces, fetch cities/municipalities directly
      var cityMunicipalityResult =
          await psgcService.fetchCitiesMunicipalitiesByRegion(regionCode);
      setState(() {
        citiesMunicipalities = cityMunicipalityResult;
      });
    }
  }

// Fetch municipalities when a province is selected
  void _loadMunicipalitiesForNCR(String provinceCode) async {
    var result = await psgcService.fetchMunicipalitiesForNCR(provinceCode);
    setState(() {
      citiesMunicipalities =
          result; // Municipalities will be treated as city options
      selectedCityOrMunicipality = null;
      selectedBarangay = null;
      barangays = [];
    });
  }

// Fetch cities when a province is selected
  void _loadCitiesForNCR(String provinceCode) async {
    var result = await psgcService.fetchCitiesForNCR(provinceCode);
    setState(() {
      citiesMunicipalities = result;
      selectedCityOrMunicipality = null;
      selectedBarangay = null;
      barangays = [];
    });
  }

// Fetch barangays when a city/municipality is selected
  void _loadBarangaysForNCR(String cityOrMunicipalityCode) async {
    var result = await psgcService.fetchBarangaysForNCR(cityOrMunicipalityCode);
    setState(() {
      barangays = result;
      selectedBarangay = null;
    });
  }

  // Fetch municipalities when a province is selected
  void _loadMunicipalities(String provinceCode) async {
    var municipalitiesResult =
        await psgcService.fetchMunicipalitiesByProvince(provinceCode);

    setState(() {
      municipalities = municipalitiesResult;
      selectedMunicipality = null;
      selectedBarangay = null;
      barangays = [];
    });
  }

// Fetch cities when a province is selected
  void _loadCities(String provinceCode) async {
    var citiesResult = await psgcService.fetchCitiesByProvince(provinceCode);

    setState(() {
      cities = citiesResult;
      selectedCity = null;
      selectedBarangay = null;
      barangays = [];
    });
  }

// Fetch barangays when a city is selected
  void _loadBarangaysFromCity(String cityCode) async {
    var result = await psgcService.fetchBarangaysByCity(cityCode);

    setState(() {
      barangays = result;
      selectedBarangay = null;
    });
  }

// Fetch barangays when a municipality is selected
  void _loadBarangaysFromMunicipality(String municipalityCode) async {
    var result =
        await psgcService.fetchBarangaysByMunicipality(municipalityCode);

    setState(() {
      barangays = result;
      selectedBarangay = null;
    });
  }

  DateTime? _selectedDate;
  TextEditingController _dateController = TextEditingController();

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
        _dateController.text =
            "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}";
      });
    }
  }

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
  String? selectedCitizenship;
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
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
                  child: Text(
                    "Personal Information",
                    style: TextStyle(
                        fontSize: MediaQuery.of(context).size.width / 50,
                        color: Color.fromARGB(255, 11, 55, 99),
                        fontFamily: "BL"),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: MediaQuery.of(context).size.width / 5.5,
                      height: MediaQuery.of(context).size.width / 5.28,
                      child: Column(
                        children: [
                          Spacer(),
                          CircleAvatar(
                            radius: MediaQuery.of(context).size.width / 17,
                            backgroundColor: Colors.grey,
                            child: Icon(
                              Icons.person,
                              size: MediaQuery.of(context).size.width / 12,
                              color: Colors.white,
                            ),
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.width / 40,
                          ),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                              height: MediaQuery.of(context).size.width / 35,
                              width: MediaQuery.of(context).size.width / 8,
                              decoration: BoxDecoration(
                                color: Color.fromARGB(255, 11, 55, 99),
                                borderRadius: BorderRadius.circular(
                                    MediaQuery.of(context).size.width / 150),
                              ),
                              child: Center(
                                child: Text(
                                  "Edit Profile",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              80,
                                      color: Colors.white,
                                      fontFamily: "R"),
                                ),
                              ),
                            ),
                          ).showCursorOnHover,
                        ],
                      ),
                    ),
                    Container(
                      height: MediaQuery.of(context).size.width / 5,
                      width: MediaQuery.of(context).size.width / 1.75,
                      child: Column(
                        children: [
                          SizedBox(
                            height: MediaQuery.of(context).size.width / 80,
                          ),
                          Row(
                            children: [
                              Column(
                                children: [
                                  Text("First Name",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 7,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "First Name",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Column(
                                children: [
                                  Text("Middle Name",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 7,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Middle Name",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Column(
                                children: [
                                  Text("Last Name",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 7,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Last Name",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Column(
                                children: [
                                  Text("Suffix",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width /
                                        12.1,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Suffix",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                            height: MediaQuery.of(context).size.width / 80,
                          ),
                          Row(
                            children: [
                              Column(
                                children: [
                                  Text("Sex",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    height: MediaQuery.of(context).size.width /
                                        35, // Adjust height
                                    width: MediaQuery.of(context).size.width /
                                        13, // Adjust width
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                      color: Colors.white,
                                    ),
                                    child: DropdownButton<String>(
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              120),
                                      value: selectedSex,
                                      hint: Text(
                                        'Select',
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R",
                                        ),
                                      ),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedSex = newValue;
                                        });
                                      },
                                      items: options
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical:
                                                    4.0), // Add space between items
                                            child: Text(value),
                                          ),
                                        );
                                      }).toList(),
                                      underline: SizedBox.shrink(),
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      icon: Icon(Icons
                                          .arrow_drop_down), // Use custom dropdown icon
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Column(
                                children: [
                                  Text(
                                    "Citizenship",
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R",
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    height: MediaQuery.of(context).size.width /
                                        35, // Adjust height
                                    width: MediaQuery.of(context).size.width /
                                        10, // Adjust width
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                      color: Colors.white,
                                    ),
                                    child: DropDownTextField(
                                      searchTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      searchKeyboardType: TextInputType.text,
                                      searchDecoration: InputDecoration(
                                        hintText: "Search",
                                        hintStyle: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              140,
                                          color: Colors.black,
                                          fontFamily: "R",
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                      ),
                                      clearOption: true,
                                      listTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      textStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      enableSearch: true,
                                      validator: (value) {
                                        if (value == null) {
                                          return "Required field";
                                        } else {
                                          return null;
                                        }
                                      },
                                      dropDownItemCount: 6,
                                      listPadding:
                                          ListPadding(top: 0, bottom: 0),
                                      dropDownList: [
                                        for (int i = 0;
                                            i < citizenshipOptions.length;
                                            i++)
                                          DropDownValueModel(
                                            name: citizenshipOptions[i]
                                                .toString(),
                                            value: citizenshipOptions[i]
                                                .toString(),
                                          ),
                                      ],
                                    ),
                                  ),
                                  //insert dropdrown here
                                ],
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Column(
                                children: [
                                  Text("Dual Citizen",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    height: MediaQuery.of(context).size.width /
                                        35, // Adjust height
                                    width: MediaQuery.of(context).size.width /
                                        13, // Adjust width
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                      color: Colors.white,
                                    ),
                                    child: DropdownButton<String>(
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              120),
                                      value: selectedAnswer,
                                      hint: Text(
                                        'Select',
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R",
                                        ),
                                      ),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedAnswer = newValue;
                                        });
                                      },
                                      items: yon.map<DropdownMenuItem<String>>(
                                          (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical:
                                                    4.0), // Add space between items
                                            child: Text(value),
                                          ),
                                        );
                                      }).toList(),
                                      underline: SizedBox.shrink(),
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      icon: Icon(Icons
                                          .arrow_drop_down), // Use custom dropdown icon
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 8.55,
                                height: MediaQuery.of(context).size.width / 20,
                                child: Column(
                                  children: [
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.width /
                                              40,
                                      child: CheckboxListTile(
                                        contentPadding: EdgeInsets
                                            .zero, // Removes default padding
                                        title: Text(
                                          "By Birth",
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                120,
                                            color: Colors.black,
                                            fontFamily: "R",
                                          ),
                                        ),
                                        value: byBirthChecked,
                                        onChanged: (_) {
                                          _onCheckboxChanged('birth');
                                        },
                                        controlAffinity: ListTileControlAffinity
                                            .leading, // Position the checkbox before the text
                                      ),
                                    ),
                                    Container(
                                      height:
                                          MediaQuery.of(context).size.width /
                                              40,
                                      child: CheckboxListTile(
                                        contentPadding: EdgeInsets
                                            .zero, // Removes default padding
                                        title: Text(
                                          "By Naturalize",
                                          style: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                120,
                                            color: Colors.black,
                                            fontFamily: "R",
                                          ),
                                        ),
                                        value: byNaturalizedChecked,
                                        onChanged: (_) {
                                          _onCheckboxChanged('naturalize');
                                        },
                                        controlAffinity: ListTileControlAffinity
                                            .leading, // Position the checkbox before the text
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Column(
                                children: [
                                  Text(
                                    "Specify Country",
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R",
                                    ),
                                  ),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    height: MediaQuery.of(context).size.width /
                                        35, // Adjust height
                                    width: MediaQuery.of(context).size.width /
                                        8.3, // Adjust width
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                      color: Colors.white,
                                    ),
                                    child: DropDownTextField(
                                      searchTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      searchKeyboardType: TextInputType.text,
                                      searchDecoration: InputDecoration(
                                        hintText: "Search",
                                        hintStyle: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              140,
                                          color: Colors.black,
                                          fontFamily: "R",
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                      ),
                                      clearOption: true,
                                      listTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      textStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      enableSearch: true,
                                      validator: (value) {
                                        if (value == null) {
                                          return "Required field";
                                        } else {
                                          return null;
                                        }
                                      },
                                      dropDownItemCount: 8,
                                      listPadding:
                                          ListPadding(top: 0, bottom: 0),
                                      dropDownList: [
                                        for (int i = 0;
                                            i < countries.length;
                                            i++)
                                          DropDownValueModel(
                                            name: countries[i].toString(),
                                            value: countries[i].toString(),
                                          ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          SizedBox(
                            height: MediaQuery.of(context).size.width / 80,
                          ),
                          Row(
                            children: [
                              Column(
                                children: [
                                  Text("Civil Status",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    height: MediaQuery.of(context).size.width /
                                        35, // Adjust height
                                    width: MediaQuery.of(context).size.width /
                                        10, // Adjust width
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                      color: Colors.white,
                                    ),
                                    child: DropdownButton<String>(
                                      style: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      padding: EdgeInsets.symmetric(
                                          horizontal: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              120),
                                      value: selectedCivilStatus,
                                      hint: Text(
                                        'Select',
                                        style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R",
                                        ),
                                      ),
                                      onChanged: (String? newValue) {
                                        setState(() {
                                          selectedCivilStatus = newValue;
                                        });
                                      },
                                      items: civilStatus
                                          .map<DropdownMenuItem<String>>(
                                              (String value) {
                                        return DropdownMenuItem<String>(
                                          value: value,
                                          child: Padding(
                                            padding: EdgeInsets.symmetric(
                                                vertical:
                                                    4.0), // Add space between items
                                            child: Text(value),
                                          ),
                                        );
                                      }).toList(),
                                      underline: SizedBox.shrink(),
                                      isExpanded: true,
                                      dropdownColor: Colors.white,
                                      icon: Icon(Icons
                                          .arrow_drop_down), // Use custom dropdown icon
                                    ),
                                  )
                                ],
                              ),
                              SizedBox(
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Column(
                                children: [
                                  Text("Mobile Number",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 9,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Mobile Number",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Column(
                                children: [
                                  Text("Telephone Number",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 9,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Telephone Number",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                width: MediaQuery.of(context).size.width / 50,
                              ),
                              Column(
                                children: [
                                  Text("Email Address",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width: MediaQuery.of(context).size.width /
                                        5.29,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Email Address",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                Container(
                  width: MediaQuery.of(context).size.width / 1.375,
                  margin: EdgeInsets.only(
                      left: MediaQuery.of(context).size.width / 37),
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            children: [
                              Text(
                                "Birth Date",
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 90,
                                  color: Colors.black,
                                  fontFamily: "R",
                                ),
                              ),
                              SizedBox(
                                  height:
                                      MediaQuery.of(context).size.width / 170),
                              Container(
                                width: MediaQuery.of(context).size.width / 8,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: TextField(
                                  controller: _dateController,
                                  readOnly: true, // Prevents manual input
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 110,
                                    color: Colors.black,
                                    fontFamily: "R",
                                  ),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.symmetric(
                                        horizontal:
                                            MediaQuery.of(context).size.width /
                                                60),
                                    hintText: "Enter Birthdate",
                                    hintStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.grey,
                                      fontFamily: "R",
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    suffixIcon: Icon(
                                        Icons.calendar_today), // Calendar icon
                                  ),
                                  onTap: () => _selectDate(
                                      context), // Open calendar on tap
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text("Place of Birth",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 5.52,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: TextField(
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R"),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width /
                                            120),
                                    hintText: "Place of Birth",
                                    hintStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.grey,
                                        fontFamily: "R"),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
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
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 15,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: TextField(
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R"),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width /
                                            120),
                                    hintText: "Height",
                                    hintStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.grey,
                                        fontFamily: "R"),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
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
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 15,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: TextField(
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R"),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width /
                                            120),
                                    hintText: "Weight",
                                    hintStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.grey,
                                        fontFamily: "R"),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          Column(
                            children: [
                              Text("Blood Type",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black54),
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                  color: Colors.white,
                                ),
                                child: DropdownButton<String>(
                                  style: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 110,
                                    color: Colors.black,
                                    fontFamily: "R",
                                  ),
                                  padding: EdgeInsets.symmetric(
                                    horizontal:
                                        MediaQuery.of(context).size.width / 120,
                                    vertical:
                                        MediaQuery.of(context).size.width / 150,
                                  ),
                                  value: selectedBloodType,
                                  hint: Text(
                                    'Select',
                                    style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R",
                                    ),
                                  ),
                                  onChanged: (String? newValue) {
                                    setState(() {
                                      selectedBloodType = newValue;
                                    });
                                  },
                                  items: bloodTypes
                                      .map<DropdownMenuItem<String>>(
                                          (String value) {
                                    return DropdownMenuItem<String>(
                                      value: value,
                                      child: Text(value),
                                    );
                                  }).toList(),
                                  underline: SizedBox.shrink(),
                                  isExpanded:
                                      false, // Make sure the dropdown is not fully expanded
                                  dropdownColor: Colors.white,
                                  icon: Icon(Icons
                                      .arrow_drop_down), // Use custom dropdown icon
                                  isDense:
                                      true, // Reduce the size of each item in the dropdown
                                  selectedItemBuilder: (BuildContext context) {
                                    return bloodTypes
                                        .map<Widget>((String value) {
                                      return Text(value);
                                    }).toList();
                                  },
                                  menuMaxHeight:
                                      MediaQuery.of(context).size.width / 7,
                                  menuWidth: MediaQuery.of(context).size.width /
                                      15, // Set the max height for the dropdown
                                ),
                              )
                            ],
                          ),
                          Column(
                            children: [
                              Text(
                                "Religion",
                                style: TextStyle(
                                  fontSize:
                                      MediaQuery.of(context).size.width / 90,
                                  color: Colors.black,
                                  fontFamily: "R",
                                ),
                              ),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                height: MediaQuery.of(context).size.width /
                                    35, // Adjust height
                                width: MediaQuery.of(context).size.width /
                                    8.8, // Adjust width
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black54),
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                  color: Colors.white,
                                ),
                                child: DropDownTextField(
                                  padding: EdgeInsets.all(
                                          MediaQuery.of(context).size.width) /
                                      200,
                                  searchTextStyle: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 110,
                                    color: Colors.black,
                                    fontFamily: "R",
                                  ),
                                  searchKeyboardType: TextInputType.text,
                                  searchDecoration: InputDecoration(
                                    hintText: "Search",
                                    hintStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              140,
                                      color: Colors.black,
                                      fontFamily: "R",
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                  ),
                                  clearOption: true,
                                  listTextStyle: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 110,
                                    color: Colors.black,
                                    fontFamily: "R",
                                  ),
                                  textStyle: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 110,
                                    color: Colors.black,
                                    fontFamily: "R",
                                  ),
                                  enableSearch: true,
                                  validator: (value) {
                                    if (value == null) {
                                      return "Required field";
                                    } else {
                                      return null;
                                    }
                                  },
                                  dropDownItemCount: 6,
                                  listPadding: ListPadding(top: 0, bottom: 0),
                                  dropDownList: [
                                    for (int i = 0; i < religion.length; i++)
                                      DropDownValueModel(
                                        name: religion[i].toString(),
                                        value: religion[i].toString(),
                                      ),
                                  ],
                                ),
                              ),
                              //insert dropdrown here
                            ],
                          ),
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).size.width / 80),
                      Container(
                        width: MediaQuery.of(context).size.width / 1.328,
                        decoration: BoxDecoration(
                          border:
                              Border(bottom: BorderSide(color: Colors.grey)),
                        ),
                        child: Text(
                          "Current Address",
                          style: TextStyle(
                              fontSize: MediaQuery.of(context).size.width / 70,
                              color: Colors.black,
                              fontFamily: "SB"),
                        ),
                      ),
                      SizedBox(
                        height: MediaQuery.of(context).size.width / 100,
                      ),
                      Row(
                        mainAxisAlignment: _axisRow,
                        children: [
                          // Region Dropdown
                          Column(
                            children: [
                              Text(
                                "Specify Region",
                                style: TextStyle(
                                    fontSize: width / 90,
                                    color: Colors.black,
                                    fontFamily: "R"),
                              ),
                              SizedBox(height: width / 170),
                              Container(
                                height: width / 35,
                                width: width / 8,
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.black54),
                                  borderRadius:
                                      BorderRadius.circular(width / 150),
                                  color: Colors.white,
                                ),
                                child: DropDownTextField(
                                  searchTextStyle: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 110,
                                    color: Colors.black,
                                    fontFamily: "R",
                                  ),
                                  searchKeyboardType: TextInputType.text,
                                  searchDecoration: InputDecoration(
                                    hintText: "Search",
                                    hintStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              140,
                                      color: Colors.black,
                                      fontFamily: "R",
                                    ),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                  ),
                                  clearOption: true,
                                  listTextStyle: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 110,
                                    color: Colors.black,
                                    fontFamily: "R",
                                  ),
                                  textStyle: TextStyle(
                                    fontSize:
                                        MediaQuery.of(context).size.width / 110,
                                    color: Colors.black,
                                    fontFamily: "R",
                                  ),
                                  enableSearch: true,
                                  validator: (value) {
                                    if (value == null) {
                                      return "Required field";
                                    } else {
                                      return null;
                                    }
                                  },
                                  dropDownItemCount: 8,
                                  listPadding: ListPadding(top: 0, bottom: 0),
                                  dropDownList: [
                                    for (var item in regions)
                                      DropDownValueModel(
                                          name: item['name'],
                                          value: item['code']),
                                  ],
                                  onChanged: (selected) {
                                    setState(() {
                                      selectedRegion = selected?.value;
                                      selectedProvince = null;
                                      selectedCity = null;
                                      selectedMunicipality = null;
                                      selectedBarangay = null;
                                      barangays = [];

                                      _axisRow = MainAxisAlignment.start;
                                    });
                                    _loadProvincesOrCities(selectedRegion!);
                                  },
                                ),
                              ),
                            ],
                          ),

                          if (selectedRegion != null) ...[
                            SizedBox(width: width / 50),

                            // Province Dropdown (Only if region has provinces)
                            if (provinces.isNotEmpty) ...[
                              Column(
                                children: [
                                  Text(
                                    "Specify Province",
                                    style: TextStyle(
                                        fontSize: width / 90,
                                        color: Colors.black,
                                        fontFamily: "R"),
                                  ),
                                  SizedBox(height: width / 170),
                                  Container(
                                    height: width / 35,
                                    width: width / 8,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius:
                                          BorderRadius.circular(width / 150),
                                      color: Colors.white,
                                    ),
                                    child: DropDownTextField(
                                      searchTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      searchKeyboardType: TextInputType.text,
                                      searchDecoration: InputDecoration(
                                        hintText: "Search",
                                        hintStyle: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              140,
                                          color: Colors.black,
                                          fontFamily: "R",
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                      ),
                                      clearOption: true,
                                      listTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      textStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      enableSearch: true,
                                      validator: (value) {
                                        if (value == null) {
                                          return "Required field";
                                        } else {
                                          return null;
                                        }
                                      },
                                      dropDownItemCount: 8,
                                      listPadding:
                                          ListPadding(top: 0, bottom: 0),
                                      dropDownList: [
                                        for (var item in provinces)
                                          DropDownValueModel(
                                              name: item['name'],
                                              value: item['code']),
                                      ],
                                      onChanged: (selected) {
                                        setState(() {
                                          selectedProvince = selected?.value;
                                          selectedCity = null;
                                          selectedMunicipality = null;
                                          selectedBarangay = null;
                                          barangays = [];
                                        });
                                        _loadMunicipalities(selectedProvince!);
                                        _loadCities(selectedProvince!);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            SizedBox(width: width / 50),

                            // NCR Handling: If NCR is selected, show a single dropdown
                            if (provinces.isEmpty) ...[
                              Column(
                                children: [
                                  Text(
                                    "Specify City/Municipality",
                                    style: TextStyle(
                                        fontSize: width / 90,
                                        color: Colors.black,
                                        fontFamily: "R"),
                                  ),
                                  SizedBox(height: width / 170),
                                  Container(
                                    height: width / 35,
                                    width: width / 8,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius:
                                          BorderRadius.circular(width / 150),
                                      color: Colors.white,
                                    ),
                                    child: DropDownTextField(
                                      searchTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      searchKeyboardType: TextInputType.text,
                                      searchDecoration: InputDecoration(
                                        hintText: "Search",
                                        hintStyle: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              140,
                                          color: Colors.black,
                                          fontFamily: "R",
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                      ),
                                      clearOption: true,
                                      listTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      textStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      enableSearch: true,
                                      validator: (value) {
                                        if (value == null) {
                                          return "Required field";
                                        } else {
                                          return null;
                                        }
                                      },
                                      dropDownItemCount: 8,
                                      listPadding:
                                          ListPadding(top: 0, bottom: 0),
                                      dropDownList: [
                                        for (var item in citiesMunicipalities)
                                          DropDownValueModel(
                                              name: item['name'],
                                              value: item['code']),
                                      ],
                                      onChanged: (selected) {
                                        setState(() {
                                          selectedCity = selected?.value;
                                          selectedMunicipality = null;
                                          selectedBarangay = null;
                                          barangays = [];
                                        });
                                        _loadBarangaysFromCity(selectedCity!);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],

                            // If NOT NCR, show separate City & Municipality dropdowns
                            if (provinces.isNotEmpty) ...[
                              Column(
                                children: [
                                  Text(
                                    "Specify City",
                                    style: TextStyle(
                                        fontSize: width / 90,
                                        color: Colors.black,
                                        fontFamily: "R"),
                                  ),
                                  SizedBox(height: width / 170),
                                  Container(
                                    height: width / 35,
                                    width: width / 8,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius:
                                          BorderRadius.circular(width / 150),
                                      color: selectedMunicipality == null
                                          ? Colors.white
                                          : Colors.grey[300],
                                    ),
                                    child: DropDownTextField(
                                      isEnabled: selectedMunicipality ==
                                          null, // Disable if municipality is selected
                                      searchTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      searchKeyboardType: TextInputType.text,
                                      searchDecoration: InputDecoration(
                                        hintText: "Search",
                                        hintStyle: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              140,
                                          color: Colors.black,
                                          fontFamily: "R",
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                      ),
                                      clearOption: true,
                                      listTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      textStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      enableSearch: true,
                                      validator: (value) {
                                        if (value == null) {
                                          return "Required field";
                                        } else {
                                          return null;
                                        }
                                      },
                                      dropDownItemCount: 8,
                                      listPadding:
                                          ListPadding(top: 0, bottom: 0),
                                      dropDownList: [
                                        for (var item in cities)
                                          DropDownValueModel(
                                              name: item['name'],
                                              value: item['code']),
                                      ],
                                      onChanged: (selected) {
                                        setState(() {
                                          selectedCity = selected?.value;
                                          selectedMunicipality =
                                              null; // Disable municipality dropdown
                                          selectedBarangay = null;
                                          barangays = [];

                                          _axisRow =
                                              MainAxisAlignment.spaceBetween;
                                        });
                                        _loadBarangaysFromCity(selectedCity!);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                              SizedBox(width: width / 50),
                              Column(
                                children: [
                                  Text(
                                    "Specify Municipality",
                                    style: TextStyle(
                                        fontSize: width / 90,
                                        color: Colors.black,
                                        fontFamily: "R"),
                                  ),
                                  SizedBox(height: width / 170),
                                  Container(
                                    height: width / 35,
                                    width: width / 8,
                                    decoration: BoxDecoration(
                                      border: Border.all(color: Colors.black54),
                                      borderRadius:
                                          BorderRadius.circular(width / 150),
                                      color: selectedCity == null
                                          ? Colors.white
                                          : Colors.grey[300],
                                    ),
                                    child: DropDownTextField(
                                      isEnabled: selectedCity ==
                                          null, // Disable if city is selected
                                      searchTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      searchKeyboardType: TextInputType.text,
                                      searchDecoration: InputDecoration(
                                        hintText: "Search",
                                        hintStyle: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              140,
                                          color: Colors.black,
                                          fontFamily: "R",
                                        ),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
                                              MediaQuery.of(context)
                                                      .size
                                                      .width /
                                                  150),
                                        ),
                                      ),
                                      clearOption: true,
                                      listTextStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      textStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                110,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      enableSearch: true,
                                      validator: (value) {
                                        if (value == null) {
                                          return "Required field";
                                        } else {
                                          return null;
                                        }
                                      },
                                      dropDownItemCount: 8,
                                      listPadding:
                                          ListPadding(top: 0, bottom: 0),
                                      dropDownList: [
                                        for (var item in municipalities)
                                          DropDownValueModel(
                                              name: item['name'],
                                              value: item['code']),
                                      ],
                                      onChanged: (selected) {
                                        setState(() {
                                          selectedMunicipality =
                                              selected?.value;
                                          selectedCity =
                                              null; // Disable city dropdown
                                          selectedBarangay = null;
                                          barangays = [];

                                          _axisRow =
                                              MainAxisAlignment.spaceBetween;
                                        });
                                        _loadBarangaysFromMunicipality(
                                            selectedMunicipality!);
                                      },
                                    ),
                                  ),
                                ],
                              ),
                            ],
                          ],

                          if (selectedCity != null ||
                              selectedMunicipality != null) ...[
                            SizedBox(width: width / 50),

                            // Barangay Dropdown
                            Column(
                              children: [
                                Text(
                                  "Specify Barangay",
                                  style: TextStyle(
                                      fontSize: width / 90,
                                      color: Colors.black,
                                      fontFamily: "R"),
                                ),
                                SizedBox(height: width / 170),
                                Container(
                                  height: width / 35,
                                  width: width / 8,
                                  decoration: BoxDecoration(
                                    border: Border.all(color: Colors.black54),
                                    borderRadius:
                                        BorderRadius.circular(width / 150),
                                    color: Colors.white,
                                  ),
                                  child: DropDownTextField(
                                    searchTextStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R",
                                    ),
                                    searchKeyboardType: TextInputType.text,
                                    searchDecoration: InputDecoration(
                                      hintText: "Search",
                                      hintStyle: TextStyle(
                                        fontSize:
                                            MediaQuery.of(context).size.width /
                                                140,
                                        color: Colors.black,
                                        fontFamily: "R",
                                      ),
                                      border: OutlineInputBorder(
                                        borderRadius: BorderRadius.circular(
                                            MediaQuery.of(context).size.width /
                                                150),
                                      ),
                                    ),
                                    clearOption: true,
                                    listTextStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R",
                                    ),
                                    textStyle: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R",
                                    ),
                                    enableSearch: true,
                                    validator: (value) {
                                      if (value == null) {
                                        return "Required field";
                                      } else {
                                        return null;
                                      }
                                    },
                                    dropDownItemCount: 8,
                                    listPadding: ListPadding(top: 0, bottom: 0),
                                    dropDownList: [
                                      for (var item in barangays)
                                        DropDownValueModel(
                                            name: item['name'],
                                            value: item['code']),
                                    ],
                                    onChanged: (selected) {
                                      setState(() {
                                        selectedBarangay = selected?.value;
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                      SizedBox(height: MediaQuery.of(context).size.height / 50),
                      Container(
                          child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                            if (selectedBarangay != null) ...[
                              Column(
                                children: [
                                  Text("Zipcode",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 6,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Zipcode",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                      MediaQuery.of(context).size.width / 50),
                              Column(
                                children: [
                                  Text("House/Block/Lot Number",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 6,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "House/Block/Lot Number",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                      MediaQuery.of(context).size.width / 50),
                              Column(
                                children: [
                                  Text("Street",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 6,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Street",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                                      MediaQuery.of(context).size.width / 50),
                              Column(
                                children: [
                                  Text("Subdivision",
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              90,
                                          color: Colors.black,
                                          fontFamily: "R")),
                                  SizedBox(
                                    height:
                                        MediaQuery.of(context).size.width / 170,
                                  ),
                                  Container(
                                    width:
                                        MediaQuery.of(context).size.width / 6,
                                    height:
                                        MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.white,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                    child: TextField(
                                      style: TextStyle(
                                          fontSize: MediaQuery.of(context)
                                                  .size
                                                  .width /
                                              110,
                                          color: Colors.black,
                                          fontFamily: "R"),
                                      decoration: InputDecoration(
                                        contentPadding: EdgeInsets.all(
                                            MediaQuery.of(context).size.width /
                                                120),
                                        hintText: "Subdivision",
                                        hintStyle: TextStyle(
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                110,
                                            color: Colors.grey,
                                            fontFamily: "R"),
                                        border: OutlineInputBorder(
                                          borderRadius: BorderRadius.circular(
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
                          ])),
                      SizedBox(height: MediaQuery.of(context).size.height / 50),
                    ],
                  ),
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
                    height: MediaQuery.of(context).size.width / 5,
                    width: MediaQuery.of(context).size.width / 1.328,
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Column(children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.width / 80),
                          Column(
                            children: [
                              Text("Email",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 5.52,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: TextField(
                                  showCursor: false,
                                  readOnly: true,
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R"),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width /
                                            120),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.width / 80),
                          GestureDetector(
                            onTap: () {},
                            child: Container(
                                width: MediaQuery.of(context).size.width / 5.52,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.yellow,
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: Center(
                                    child: Text("Change Password",
                                        style: TextStyle(
                                            color: Colors.black,
                                            fontFamily: "M",
                                            fontSize: MediaQuery.of(context)
                                                    .size
                                                    .width /
                                                100)))),
                          ).showCursorOnHover.moveUpOnHover,
                        ]),
                        SizedBox(width: MediaQuery.of(context).size.width/50),
                        Column(children: [
                          SizedBox(
                              height: MediaQuery.of(context).size.width / 80),
                          Column(
                            children: [
                              Text("Password",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 5.52,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: TextField(
                                  showCursor: false,
                                  readOnly: true,
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R"),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width /
                                            120),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.width / 80),
                          Column(
                            children: [
                              Text("Confirm Password",
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              90,
                                      color: Colors.black,
                                      fontFamily: "R")),
                              SizedBox(
                                height: MediaQuery.of(context).size.width / 170,
                              ),
                              Container(
                                width: MediaQuery.of(context).size.width / 5.52,
                                height: MediaQuery.of(context).size.width / 35,
                                decoration: BoxDecoration(
                                  color: Colors.grey[300],
                                  borderRadius: BorderRadius.circular(
                                      MediaQuery.of(context).size.width / 150),
                                ),
                                child: TextField(
                                  showCursor: false,
                                  readOnly: true,
                                  style: TextStyle(
                                      fontSize:
                                          MediaQuery.of(context).size.width /
                                              110,
                                      color: Colors.black,
                                      fontFamily: "R"),
                                  decoration: InputDecoration(
                                    contentPadding: EdgeInsets.all(
                                        MediaQuery.of(context).size.width /
                                            120),
                                    border: OutlineInputBorder(
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width /
                                              150),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          SizedBox(
                              height: MediaQuery.of(context).size.width / 80),
                          Row(
                            children: [
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                    width: MediaQuery.of(context).size.width / 10,
                                    height: MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width / 150),
                                    ),
                                    child: Center(
                                        child: Text("Cancel",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: "M",
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    100)))),
                              ).showCursorOnHover.moveUpOnHover,
                              SizedBox(width: MediaQuery.of(context).size.width/100),
                              GestureDetector(
                                onTap: () {},
                                child: Container(
                                    width: MediaQuery.of(context).size.width / 10,
                                    height: MediaQuery.of(context).size.width / 35,
                                    decoration: BoxDecoration(
                                      color: Colors.green,
                                      borderRadius: BorderRadius.circular(
                                          MediaQuery.of(context).size.width / 150),
                                    ),
                                    child: Center(
                                        child: Text("Save",
                                            style: TextStyle(
                                                color: Colors.white,
                                                fontFamily: "M",
                                                fontSize: MediaQuery.of(context)
                                                        .size
                                                        .width /
                                                    100)))),
                              ).showCursorOnHover.moveUpOnHover,
                            ],
                          ),
                        ])
                      ],
                    )),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class PSGCService {
  final String baseUrl = 'https://psgc.gitlab.io/api';

  /// Fetch all regions
  Future<List<dynamic>> fetchRegions() async {
    final response = await http.get(Uri.parse('$baseUrl/regions.json'));
    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load regions');
    }
  }

  /// Fetch provinces by regionCode (if the region has provinces)
  Future<List<dynamic>> fetchProvinces(String regionCode) async {
    final response = await http
        .get(Uri.parse('$baseUrl/regions/$regionCode/provinces.json'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load provinces');
    }
  }

  /// Fetch cities/municipalities if the region does NOT have provinces (e.g., NCR)
  Future<List<dynamic>> fetchCitiesMunicipalitiesByRegion(
      String regionCode) async {
    final response = await http.get(
        Uri.parse('$baseUrl/regions/$regionCode/cities-municipalities.json'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load cities/municipalities');
    }
  }

  /// Fetch municipalities by province code
  Future<List<dynamic>> fetchMunicipalitiesForNCR(String provinceCode) async {
    final response = await http
        .get(Uri.parse('$baseUrl/provinces/$provinceCode/municipalities.json'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load municipalities');
    }
  }

  /// Fetch cities by province code
  Future<List<dynamic>> fetchCitiesForNCR(String provinceCode) async {
    final response = await http
        .get(Uri.parse('$baseUrl/provinces/$provinceCode/cities.json'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load cities');
    }
  }

  /// Fetch barangays by city/municipality code
  Future<List<dynamic>> fetchBarangaysForNCR(
      String cityOrMunicipalityCode) async {
    final response = await http.get(Uri.parse(
        '$baseUrl/cities-municipalities/$cityOrMunicipalityCode/barangays.json'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load barangays');
    }
  }

  /// Fetch municipalities by province code
  Future<List<dynamic>> fetchMunicipalitiesByProvince(
      String provinceCode) async {
    final response = await http
        .get(Uri.parse('$baseUrl/provinces/$provinceCode/municipalities.json'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load municipalities');
    }
  }

  /// Fetch cities by province code
  Future<List<dynamic>> fetchCitiesByProvince(String provinceCode) async {
    final response = await http
        .get(Uri.parse('$baseUrl/provinces/$provinceCode/cities.json'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load cities');
    }
  }

  /// Fetch barangays by city or municipality code
  Future<List<dynamic>> fetchBarangaysByCity(String cityCode) async {
    final response =
        await http.get(Uri.parse('$baseUrl/cities/$cityCode/barangays.json'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load barangays for city');
    }
  }

  Future<List<dynamic>> fetchBarangaysByMunicipality(
      String municipalityCode) async {
    final response = await http.get(
        Uri.parse('$baseUrl/municipalities/$municipalityCode/barangays.json'));

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Failed to load barangays for municipality');
    }
  }
}
