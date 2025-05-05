import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_address_provider.dart';
import 'package:attendance_app/edit_mode_provider.dart';
import 'package:dropdown_textfield/dropdown_textfield.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:provider/provider.dart';

class CurrentAddressPick extends StatefulWidget {
  const CurrentAddressPick({super.key});

  @override
  State<CurrentAddressPick> createState() => _CurrentAddressPickState();
}

class _CurrentAddressPickState extends State<CurrentAddressPick> {
  final PSGCService psgcService = PSGCService();
  MainAxisAlignment _axisRow = MainAxisAlignment.start;
  // Selected values for dropdowns
  String? selectedCity;
  String? selectedMunicipality;
  String? selectedRegion;
  String? selectedProvince;
  String? selectedCityOrMunicipality;
  String? selectedBarangay;

  bool textFieldReadOnly = true;
  bool dropDownReadOnly = true;
  bool dropDownSearchReadOnly = true;

  // Lists to store dropdown options
  List<dynamic> cities = [];
  List<dynamic> municipalities = [];
  List<dynamic> regions = [];
  List<dynamic> provinces = [];
  List<dynamic> citiesMunicipalities = [];
  List<dynamic> barangays = [];

  final TextEditingController zipCodeController = TextEditingController();
  final TextEditingController houseNumberController = TextEditingController();
  final TextEditingController streetController = TextEditingController();
  final TextEditingController subdivisionController = TextEditingController();

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

    // Clear only the necessary state variables
    selectedProvince = null;
    selectedCityOrMunicipality = null;
    selectedBarangay = null;
    provinces = [];
    citiesMunicipalities = [];
    barangays = [];

    // Fetch province data
    var provinceResult = await psgcService.fetchProvinces(regionCode);

    if (provinceResult.isNotEmpty) {
      // Region has provinces, so update only provinces
      setState(() {
        provinces = provinceResult;
        citiesMunicipalities = []; // Clear city/municipality list
      });
    } else {
      // Region has no provinces, fetch cities/municipalities directly
      var cityMunicipalityResult =
          await psgcService.fetchCitiesMunicipalitiesByRegion(regionCode);
      setState(() {
        citiesMunicipalities = cityMunicipalityResult;
        provinces = []; // Clear provinces if none exist
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

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    return Scaffold(
      body: Container(
        color: Color(0xFFf2edf3),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: _axisRow,
              children: [
                // Region Dropdown
                RegionDropdown(
                  initialValue: selectedRegion,
                  regions: regions
                      .map<Map<String, String>>((region) => {
                            'name': region['name'].toString(),
                            'code': region['code'].toString(),
                          })
                      .toList(),
                  onChanged: (String? newRegion) {
                    setState(() {
                      selectedRegion = newRegion;
                      selectedProvince = null;
                      selectedCity = null;
                      selectedMunicipality = null;
                      selectedBarangay = null;
                      barangays = [];
                      _axisRow = MainAxisAlignment.start;
                    });

                    _loadProvincesOrCities(
                        Provider.of<AdminAddressProvider>(context, listen: false)
                            .selectedRegionCode!);
                  },
                ),

                if (selectedRegion != null) ...[
                  SizedBox(width: width / 50),

                  // Province Dropdown (Only if region has provinces)
                  if (provinces.isNotEmpty) ...[
                    ProvinceDropdown(
                      initialValue: selectedProvince,
                      provinces: provinces
                          .map<Map<String, String>>((province) => {
                                'name': province['name'].toString(),
                                'code': province['code'].toString(),
                              })
                          .toList(),
                      onChanged: (String? newProvince) {
                        setState(() {
                          selectedProvince = newProvince;
                          selectedCity = null;
                          selectedMunicipality = null;
                          selectedBarangay = null;
                          barangays = [];
                        });

                        // Get province code from provider
                        String? selectedProvinceCode =
                            Provider.of<AdminAddressProvider>(context, listen: false)
                                .selectedProvinceCode;

                        _loadMunicipalities(selectedProvinceCode!);
                        _loadCities(selectedProvinceCode!);
                      },
                    ),
                  ],

                  SizedBox(width: width / 50),

                  // NCR Handling: If NCR is selected, show a single dropdown
                  if (provinces.isEmpty) ...[
                    CityMunicipalityDropdown(
                      initialValue: selectedCity,
                      citiesMunicipalities: citiesMunicipalities
                          .map<Map<String, String>>((city) => {
                                'name': city['name'].toString(),
                                'code': city['code'].toString(),
                              })
                          .toList(),
                      onChanged: (String? newCity) {
                        setState(() {
                          selectedCity = newCity;
                          selectedBarangay = null;
                          barangays = [];
                        });

                        // Pass city to provider
                        String? selectedCityCode =
                            Provider.of<AdminAddressProvider>(context, listen: false)
                                .selectedCityCode;

                        _loadBarangaysFromCity(selectedCityCode!);
                      },
                    ),
                  ],

                  // If NOT NCR, show separate City & Municipality dropdowns
                  if (provinces.isNotEmpty) ...[
                    CityDropdown(
                      initialValue: selectedCity,
                      selectedMunicipality:
                          selectedMunicipality, // Pass municipality state
                      cities: cities
                          .map<Map<String, String>>((city) => {
                                'name': city['name'].toString(),
                                'code': city['code'].toString(),
                              })
                          .toList(),
                      onChanged: (String? newCity) {
                        setState(() {
                          selectedCity = newCity;
                          selectedBarangay = null;
                          barangays = [];
                        });

                        // Pass city to provider
                        String? selectedCityCode =
                            Provider.of<AdminAddressProvider>(context, listen: false)
                                .selectedCityCode;

                        _loadBarangaysFromCity(selectedCityCode!);
                      },
                    ),
                    SizedBox(width: width / 50),
                    MunicipalityDropdown(
                      initialValue: selectedMunicipality,
                      selectedCity: selectedCity, // Pass city state
                      municipalities: municipalities
                          .map<Map<String, String>>((municipality) => {
                                'name': municipality['name'].toString(),
                                'code': municipality['code'].toString(),
                              })
                          .toList(),
                      onChanged: (String? newMunicipality) {
                        setState(() {
                          selectedMunicipality = newMunicipality;
                          selectedBarangay = null;
                          barangays = [];
                        });

                        // Pass municipality to provider
                        String? selectedMunicipalityCode =
                            Provider.of<AdminAddressProvider>(context, listen: false)
                                .selectedMunicipalityCode;

                        _loadBarangaysFromMunicipality(
                            selectedMunicipalityCode!);
                      },
                    ),
                  ],
                ],

                if (selectedCity != null || selectedMunicipality != null) ...[
                  SizedBox(width: width / 50),

                  // Barangay Dropdown
                  BarangayDropdown(
                    initialValue: selectedBarangay,
                    barangays: barangays
                        .map<Map<String, String>>((barangay) => {
                              'name': barangay['name'].toString(),
                              'code': barangay['code'].toString(),
                            })
                        .toList(),
                    onChanged: (String? newBarangay) {
                      setState(() {
                        selectedBarangay = newBarangay;
                      });

                      // Pass barangay to provider
                      String? selectedBarangayCode =
                          Provider.of<AdminAddressProvider>(context, listen: false)
                              .selectedBarangayCode;

                      print(
                          "Selected Barangay: $selectedBarangay ($selectedBarangayCode)");
                    },
                  ),
                ],
              ],
            ),
            SizedBox(height: MediaQuery.of(context).size.height / 50),
            if (selectedBarangay != null) ...[
              Container(
                  child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                    ZipcodeTextField(
                        initialValue:
                            Provider.of<AdminAddressProvider>(context).zipcode),
                    SizedBox(width: MediaQuery.of(context).size.width / 50),
                    HouseNumberTextField(
                        initialValue:
                            Provider.of<AdminAddressProvider>(context).houseNumber),
                    SizedBox(width: MediaQuery.of(context).size.width / 50),
                    StreetTextField(initialValue: Provider.of<AdminAddressProvider>(context).street),
                    SizedBox(width: MediaQuery.of(context).size.width / 50),
                    //here
                    SubdivisionTextField(initialValue: Provider.of<AdminAddressProvider>(context).subdivision),
                  ]))
            ],
          ],
        ),
      ),
    );
  }
}
// Import EditModeProvider

class RegionDropdown extends StatefulWidget {
  final String? initialValue;
  final List<Map<String, String>> regions;
  final Function(String?) onChanged;

  const RegionDropdown({
    Key? key,
    required this.initialValue,
    required this.regions,
    required this.onChanged,
  }) : super(key: key);

  @override
  _RegionDropdownState createState() => _RegionDropdownState();
}

class _RegionDropdownState extends State<RegionDropdown> {
  String? selectedRegion;

  @override
  void initState() {
    super.initState();
    selectedRegion = widget.initialValue; // Initialize with passed value
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final editModeProvider = Provider.of<EditModeProvider>(context);
    final addressProvider =
        Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Specify Region",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          height: width / 35,
          width: width / 8,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(width / 150),
            color: editModeProvider.isEditing ? Colors.white : Colors.grey[300],
          ),
          child: DropDownTextField(
            onChanged: (selected) {
              setState(() {
                selectedRegion = selected?.value; // Store region NAME
              });

              // Find the selected region's code
              String? selectedRegionCode = widget.regions.firstWhere(
                  (region) => region['name'] == selectedRegion,
                  orElse: () => {'code': ''})['code'];

              Provider.of<AdminAddressProvider>(context, listen: false).updateRegion(
                  selectedRegion, selectedRegionCode); // Pass both name & code

              widget.onChanged(selectedRegion);
            },
            initialValue: selectedRegion, // Keep value persistent
            readOnly:
                !editModeProvider.isEditing, // Disable when not in edit mode
            enableSearch: false, // Enable search only in edit mode
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
            searchTextStyle: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            searchKeyboardType: TextInputType.text,
            searchDecoration: InputDecoration(
              hintText: editModeProvider.isEditing ? "Search" : "",
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
            validator: (value) => value == null ? "Required field" : null,
            dropDownItemCount: 8,
            listPadding: ListPadding(top: 0, bottom: 0),
            dropDownList: editModeProvider.isEditing
                ? widget.regions
                    .map((region) => DropDownValueModel(
                          name: region['name']!,
                          value: region['name']!,
                        ))
                    .toList()
                : [], // Show empty list when not in edit mode
          ),
        ),
      ],
    );
  }
}

class ProvinceDropdown extends StatefulWidget {
  final String? initialValue;
  final List<Map<String, String>> provinces;
  final Function(String?) onChanged;

  const ProvinceDropdown({
    Key? key,
    required this.initialValue,
    required this.provinces,
    required this.onChanged,
  }) : super(key: key);

  @override
  _ProvinceDropdownState createState() => _ProvinceDropdownState();
}

class _ProvinceDropdownState extends State<ProvinceDropdown> {
  String? selectedProvince;

  @override
  void initState() {
    super.initState();
    selectedProvince = widget.initialValue; // Initialize with passed value
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final editModeProvider = Provider.of<EditModeProvider>(context);
    final addressProvider =
        Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Specify Province",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          height: width / 35,
          width: width / 8,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(width / 150),
            color: editModeProvider.isEditing ? Colors.white : Colors.grey[300],
          ),
          child: DropDownTextField(
            onChanged: (selected) {
              setState(() {
                selectedProvince = selected?.value; // Store province NAME
              });

              // Find the selected province's code
              String? selectedProvinceCode = widget.provinces.firstWhere(
                  (province) => province['name'] == selectedProvince,
                  orElse: () => {'code': ''})['code'];

              // Update provider with both name & code
              addressProvider.updateProvince(
                  selectedProvince, selectedProvinceCode);

              widget.onChanged(selectedProvince);
            },
            initialValue: selectedProvince, // Keep value persistent
            readOnly:
                !editModeProvider.isEditing, // Disable when not in edit mode
            enableSearch: false, // Enable search only in edit mode
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
            searchTextStyle: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            searchKeyboardType: TextInputType.text,
            searchDecoration: InputDecoration(
              hintText: editModeProvider.isEditing ? "Search" : "",
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
            validator: (value) => value == null ? "Required field" : null,
            dropDownItemCount: 8,
            listPadding: ListPadding(top: 0, bottom: 0),
            dropDownList: editModeProvider.isEditing
                ? widget.provinces
                    .map((province) => DropDownValueModel(
                          name: province['name']!,
                          value: province['name']!, // Store the name
                        ))
                    .toList()
                : [], // Show empty list when not in edit mode
          ),
        ),
      ],
    );
  }
}

class CityMunicipalityDropdown extends StatefulWidget {
  final String? initialValue;
  final List<Map<String, String>> citiesMunicipalities;
  final Function(String?) onChanged;

  const CityMunicipalityDropdown({
    Key? key,
    required this.initialValue,
    required this.citiesMunicipalities,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CityMunicipalityDropdownState createState() =>
      _CityMunicipalityDropdownState();
}

class _CityMunicipalityDropdownState extends State<CityMunicipalityDropdown> {
  String? selectedCityMunicipality;

  @override
  void initState() {
    super.initState();
    selectedCityMunicipality =
        widget.initialValue; // Initialize with passed value
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final editModeProvider = Provider.of<EditModeProvider>(context);
    final addressProvider =
        Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Specify City/Municipality",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          height: width / 35,
          width: width / 8,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(width / 150),
            color: editModeProvider.isEditing ? Colors.white : Colors.grey[300],
          ),
          child: DropDownTextField(
            onChanged: (selected) {
              setState(() {
                selectedCityMunicipality = selected?.value; // Store name
              });

              // Find the selected city's code
              String? selectedCityMunicipalityCode = widget.citiesMunicipalities
                  .firstWhere(
                      (city) => city['name'] == selectedCityMunicipality,
                      orElse: () => {'code': ''})['code'];

              // Update provider with both name and code
              addressProvider.updateCity(
                  selectedCityMunicipality, selectedCityMunicipalityCode);

              widget.onChanged(selectedCityMunicipality);
            },
            initialValue: selectedCityMunicipality, // Keep value persistent
            readOnly:
                !editModeProvider.isEditing, // Disable when not in edit mode
            enableSearch: false, // Disable search
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
            searchTextStyle: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            searchKeyboardType: TextInputType.text,
            searchDecoration: InputDecoration(
              hintText: editModeProvider.isEditing ? "Search" : "",
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
            validator: (value) => value == null ? "Required field" : null,
            dropDownItemCount: 8,
            listPadding: ListPadding(top: 0, bottom: 0),
            dropDownList: editModeProvider.isEditing
                ? widget.citiesMunicipalities
                    .map((city) => DropDownValueModel(
                          name: city['name']!,
                          value: city['name']!, // Store name instead of code
                        ))
                    .toList()
                : [],
          ),
        ),
      ],
    );
  }
}

class CityDropdown extends StatefulWidget {
  final String? initialValue;
  final String? selectedMunicipality;
  final List<Map<String, String>> cities;
  final Function(String?) onChanged;

  const CityDropdown({
    Key? key,
    required this.initialValue,
    required this.selectedMunicipality,
    required this.cities,
    required this.onChanged,
  }) : super(key: key);

  @override
  _CityDropdownState createState() => _CityDropdownState();
}

class _CityDropdownState extends State<CityDropdown> {
  String? selectedCity;

  @override
  void initState() {
    super.initState();
    selectedCity = widget.initialValue; // Initialize with passed value
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final editModeProvider = Provider.of<EditModeProvider>(context);
    final addressProvider =
        Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Specify City",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          height: width / 35,
          width: width / 8,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(width / 150),
            color: widget.selectedMunicipality == null
                ? (editModeProvider.isEditing ? Colors.white : Colors.grey[300])
                : Colors.grey[300], // Disable if municipality is selected
          ),
          child: DropDownTextField(
            onChanged: (selected) {
              setState(() {
                selectedCity = selected?.value; // Store name
              });

              // Find the selected city's code
              String? selectedCityCode = widget.cities.firstWhere(
                  (city) => city['name'] == selectedCity,
                  orElse: () => {'code': ''})['code'];

              // Update provider with both name and code
              addressProvider.updateCity(selectedCity, selectedCityCode);

              widget.onChanged(selectedCity);
            },
            initialValue: selectedCity, // Keep value persistent
            isEnabled: widget.selectedMunicipality == null,
            readOnly: widget.selectedMunicipality != null ||
                !editModeProvider
                    .isEditing, // Disable if municipality is selected
            enableSearch: false, // Disable search
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
            searchTextStyle: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            searchKeyboardType: TextInputType.text,
            searchDecoration: InputDecoration(
              hintText: editModeProvider.isEditing ? "Search" : "",
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
            validator: (value) => value == null ? "Required field" : null,
            dropDownItemCount: 8,
            listPadding: ListPadding(top: 0, bottom: 0),
            dropDownList: editModeProvider.isEditing
                ? widget.cities
                    .map((city) => DropDownValueModel(
                          name: city['name']!,
                          value: city['name']!, // Store name instead of code
                        ))
                    .toList()
                : [],
          ),
        ),
      ],
    );
  }
}

class MunicipalityDropdown extends StatefulWidget {
  final String? initialValue;
  final String? selectedCity;
  final List<Map<String, String>> municipalities;
  final Function(String?) onChanged;

  const MunicipalityDropdown({
    Key? key,
    required this.initialValue,
    required this.selectedCity,
    required this.municipalities,
    required this.onChanged,
  }) : super(key: key);

  @override
  _MunicipalityDropdownState createState() => _MunicipalityDropdownState();
}

class _MunicipalityDropdownState extends State<MunicipalityDropdown> {
  String? selectedMunicipality;

  @override
  void initState() {
    super.initState();
    selectedMunicipality = widget.initialValue; // Initialize with passed value
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final editModeProvider = Provider.of<EditModeProvider>(context);
    final addressProvider =
        Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Specify Municipality",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          height: width / 35,
          width: width / 8,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(width / 150),
            color: widget.selectedCity == null
                ? (editModeProvider.isEditing ? Colors.white : Colors.grey[300])
                : Colors.grey[300], // Disable if city is selected
          ),
          child: DropDownTextField(
            onChanged: (selected) {
              setState(() {
                selectedMunicipality = selected?.value; // Store name
              });

              // Find the selected municipality's code
              String? selectedMunicipalityCode = widget.municipalities
                  .firstWhere(
                      (municipality) =>
                          municipality['name'] == selectedMunicipality,
                      orElse: () => {'code': ''})['code'];

              // Update provider with both name and code
              addressProvider.updateMunicipality(
                  selectedMunicipality, selectedMunicipalityCode);

              widget.onChanged(selectedMunicipality);
            },
            initialValue: selectedMunicipality, // Keep value persistent
            isEnabled: widget.selectedCity == null,
            readOnly: widget.selectedCity != null ||
                !editModeProvider.isEditing, // Disable if city is selected
            enableSearch: false, // Disable search
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
            searchTextStyle: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            searchKeyboardType: TextInputType.text,
            searchDecoration: InputDecoration(
              hintText: editModeProvider.isEditing ? "Search" : "",
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
            validator: (value) => value == null ? "Required field" : null,
            dropDownItemCount: 8,
            listPadding: ListPadding(top: 0, bottom: 0),
            dropDownList: editModeProvider.isEditing
                ? widget.municipalities
                    .map((municipality) => DropDownValueModel(
                          name: municipality['name']!,
                          value: municipality[
                              'name']!, // Store name instead of code
                        ))
                    .toList()
                : [],
          ),
        ),
      ],
    );
  }
}

class BarangayDropdown extends StatefulWidget {
  final String? initialValue;
  final List<Map<String, String>> barangays;
  final Function(String?) onChanged;

  const BarangayDropdown({
    Key? key,
    required this.initialValue,
    required this.barangays,
    required this.onChanged,
  }) : super(key: key);

  @override
  _BarangayDropdownState createState() => _BarangayDropdownState();
}

class _BarangayDropdownState extends State<BarangayDropdown> {
  String? selectedBarangay;

  @override
  void initState() {
    super.initState();
    selectedBarangay = widget.initialValue; // Initialize with passed value
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final editModeProvider = Provider.of<EditModeProvider>(context);
    final addressProvider =
        Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Specify Barangay",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          height: width / 35,
          width: width / 8,
          decoration: BoxDecoration(
            border: Border.all(color: Colors.black54),
            borderRadius: BorderRadius.circular(width / 150),
            color: editModeProvider.isEditing ? Colors.white : Colors.grey[300],
          ),
          child: DropDownTextField(
            onChanged: (selected) {
              setState(() {
                selectedBarangay = selected?.value; // Store name
              });

              // Find the selected barangay's code
              String? selectedBarangayCode = widget.barangays.firstWhere(
                  (barangay) => barangay['name'] == selectedBarangay,
                  orElse: () => {'code': ''})['code'];

              // Update provider with both name and code
              addressProvider.updateBarangay(
                  selectedBarangay, selectedBarangayCode);

              widget.onChanged(selectedBarangay);
            },
            initialValue: selectedBarangay, // Keep value persistent
            readOnly:
                !editModeProvider.isEditing, // Disable when not in edit mode
            enableSearch: false, // Disable search
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
            searchTextStyle: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            searchKeyboardType: TextInputType.text,
            searchDecoration: InputDecoration(
              hintText: editModeProvider.isEditing ? "Search" : "",
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
            validator: (value) => value == null ? "Required field" : null,
            dropDownItemCount: 8,
            listPadding: ListPadding(top: 0, bottom: 0),
            dropDownList: editModeProvider.isEditing
                ? widget.barangays
                    .map((barangay) => DropDownValueModel(
                          name: barangay['name']!,
                          value:
                              barangay['name']!, // Store name instead of code
                        ))
                    .toList()
                : [],
          ),
        ),
      ],
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

class ZipcodeTextField extends StatefulWidget {
  final String? initialValue;

  const ZipcodeTextField({
    Key? key,
    required this.initialValue,
  }) : super(key: key);

  @override
  _ZipcodeTextFieldState createState() => _ZipcodeTextFieldState();
}

class _ZipcodeTextFieldState extends State<ZipcodeTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? "");
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final addressProvider =
        Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Zipcode",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          width: width / 6,
          height: width / 35,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width / 150),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Allows numbers only
              LengthLimitingTextInputFormatter(4), // Limits length to 6 digits
            ],
            style: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(width / 120),
              hintText: "Zipcode",
              hintStyle: TextStyle(
                fontSize: width / 110,
                color: Colors.grey,
                fontFamily: "R",
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(width / 150),
              ),
            ),
            onChanged: (value) {
              addressProvider.updateZipcode(value); // Update provider value
            },
          ),
        ),
      ],
    );
  }
}

class HouseNumberTextField extends StatefulWidget {
  final String? initialValue;

  const HouseNumberTextField({
    Key? key,
    required this.initialValue,
  }) : super(key: key);

  @override
  _HouseNumberTextFieldState createState() => _HouseNumberTextFieldState();
}

class _HouseNumberTextFieldState extends State<HouseNumberTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? "");
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final addressProvider =
        Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "House/Block/Lot Number",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          width: width / 6,
          height: width / 35,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width / 150),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.number,
            inputFormatters: [
              FilteringTextInputFormatter.digitsOnly, // Allows numbers only
              LengthLimitingTextInputFormatter(6), // Limits length to 6 digits
            ],
            style: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(width / 120),
              hintText: "House/Block/Lot Number",
              hintStyle: TextStyle(
                fontSize: width / 110,
                color: Colors.grey,
                fontFamily: "R",
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(width / 150),
              ),
            ),
            onChanged: (value) {
              addressProvider.updateHouseNumber(value); // Update provider value
            },
          ),
        ),
      ],
    );
  }
}

class StreetTextField extends StatefulWidget {
  final String? initialValue;

  const StreetTextField({
    Key? key,
    required this.initialValue,
  }) : super(key: key);

  @override
  _StreetTextFieldState createState() => _StreetTextFieldState();
}

class _StreetTextFieldState extends State<StreetTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? "");
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final addressProvider = Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Street",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          width: width / 6,
          height: width / 35,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width / 150),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9 ]*$')), // Allows letters, numbers & spaces
              LengthLimitingTextInputFormatter(50), // Limits length to 50 characters
            ],
            style: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(width / 120),
              hintText: "Street",
              hintStyle: TextStyle(
                fontSize: width / 110,
                color: Colors.grey,
                fontFamily: "R",
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(width / 150),
              ),
            ),
            onChanged: (value) {
              addressProvider.updateStreet(value); // Update provider value
            },
          ),
        ),
      ],
    );
  }
}

class SubdivisionTextField extends StatefulWidget {
  final String? initialValue;

  const SubdivisionTextField({
    Key? key,
    required this.initialValue,
  }) : super(key: key);

  @override
  _SubdivisionTextFieldState createState() => _SubdivisionTextFieldState();
}

class _SubdivisionTextFieldState extends State<SubdivisionTextField> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.initialValue ?? "");
  }

  @override
  Widget build(BuildContext context) {
    double width = MediaQuery.of(context).size.width;
    final addressProvider = Provider.of<AdminAddressProvider>(context, listen: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          "Subdivision",
          style: TextStyle(
            fontSize: width / 90,
            color: Colors.black,
            fontFamily: "R",
          ),
        ),
        SizedBox(height: width / 170),
        Container(
          width: width / 6,
          height: width / 35,
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(width / 150),
          ),
          child: TextField(
            controller: _controller,
            keyboardType: TextInputType.text,
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^[a-zA-Z0-9 ]*$')), // Allows letters, numbers & spaces
              LengthLimitingTextInputFormatter(50), // Limits length to 50 characters
            ],
            style: TextStyle(
              fontSize: width / 110,
              color: Colors.black,
              fontFamily: "R",
            ),
            decoration: InputDecoration(
              contentPadding: EdgeInsets.all(width / 120),
              hintText: "Subdivision",
              hintStyle: TextStyle(
                fontSize: width / 110,
                color: Colors.grey,
                fontFamily: "R",
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(width / 150),
              ),
            ),
            onChanged: (value) {
              addressProvider.updateSubdivision(value); // Update provider value
            },
          ),
        ),
      ],
    );
  }
}