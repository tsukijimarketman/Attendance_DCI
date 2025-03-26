import 'package:flutter/material.dart';

class AddressProvider extends ChangeNotifier {
  String? selectedCity;
  String? selectedRegionCode;
  String? selectedMunicipality;
  String? selectedRegionName;
  String? selectedProvince;
  String? selectedCityOrMunicipality;
  String? selectedBarangay;

  void updateRegion(String? regionName, String? regionCode) {
    selectedRegionName = regionName; 
    selectedRegionCode = regionCode;
    selectedProvince = null;
    selectedCity = null;
    selectedMunicipality = null;
    selectedBarangay = null;
    notifyListeners();
  }

  void updateProvince(String? province) {
    selectedProvince = province;
    selectedCity = null;
    selectedMunicipality = null;
    selectedBarangay = null;
    notifyListeners();
  }

  void updateCity(String? city) {
    selectedCity = city;
    selectedMunicipality = null;
    selectedBarangay = null;
    notifyListeners();
  }

  void updateMunicipality(String? municipality) {
    selectedMunicipality = municipality;
    selectedCity = null;
    selectedBarangay = null;
    notifyListeners();
  }

  void updateBarangay(String? barangay) {
    selectedBarangay = barangay;
    notifyListeners();
  }
}
