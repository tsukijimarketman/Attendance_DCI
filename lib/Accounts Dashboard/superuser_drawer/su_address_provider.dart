import 'package:flutter/material.dart';

class AddressProvider extends ChangeNotifier {
  // New Fields for Address
  String? zipcode;
  String? houseNumber;
  String? street;
  String? subdivision;

  // Region & Location Fields
  String? selectedRegionName;
  String? selectedRegionCode;
  String? selectedProvinceName;
  String? selectedProvinceCode;
  String? selectedCityName;
  String? selectedCityCode;
  String? selectedMunicipalityName;
  String? selectedMunicipalityCode;
  String? selectedCityOrMunicipalityName;
  String? selectedCityOrMunicipalityCode;
  String? selectedBarangayName;
  String? selectedBarangayCode;

  // ✅ Update Zipcode (Number Only)
  void updateZipcode(String? newZipcode) {
    zipcode = newZipcode;
    notifyListeners();
  }

  // ✅ Update House Number (Number Only)
  void updateHouseNumber(String? newHouseNumber) {
    houseNumber = newHouseNumber;
    notifyListeners();
  }

  // ✅ Update Street
  void updateStreet(String? newStreet) {
    street = newStreet;
    notifyListeners();
  }

  // ✅ Update Subdivision
  void updateSubdivision(String? newSubdivision) {
    subdivision = newSubdivision;
    notifyListeners();
  }

  // ✅ Update Region
  void updateRegion(String? regionName, String? regionCode) {
    selectedRegionName = regionName;
    selectedRegionCode = regionCode;
    selectedProvinceName = null;
    selectedProvinceCode = null;
    selectedCityName = null;
    selectedCityCode = null;
    selectedMunicipalityName = null;
    selectedMunicipalityCode = null;
    selectedBarangayName = null;
    selectedBarangayCode = null;
    notifyListeners();
  }

  // ✅ Update Province
  void updateProvince(String? provinceName, String? provinceCode) {
    selectedProvinceName = provinceName;
    selectedProvinceCode = provinceCode;
    selectedCityName = null;
    selectedCityCode = null;
    selectedMunicipalityName = null;
    selectedMunicipalityCode = null;
    selectedBarangayName = null;
    selectedBarangayCode = null;
    notifyListeners();
  }

  // ✅ Update City
  void updateCity(String? cityName, String? cityCode) {
    selectedCityName = cityName;
    selectedCityCode = cityCode;
    selectedMunicipalityName = null;
    selectedMunicipalityCode = null;
    selectedBarangayName = null;
    selectedBarangayCode = null;
    notifyListeners();
  }

  // ✅ Update Municipality
  void updateMunicipality(String? municipalityName, String? municipalityCode) {
    selectedMunicipalityName = municipalityName;
    selectedMunicipalityCode = municipalityCode;
    selectedCityName = null;
    selectedCityCode = null;
    selectedBarangayName = null;
    selectedBarangayCode = null;
    notifyListeners();
  }

  // ✅ Update Barangay
  void updateBarangay(String? barangayName, String? barangayCode) {
    selectedBarangayName = barangayName;
    selectedBarangayCode = barangayCode;
    notifyListeners();
  }
}
