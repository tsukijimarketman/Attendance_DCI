import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
class ProfileImageNotifier extends ChangeNotifier {
  String? _imageUrl;
  String? get imageUrl => _imageUrl;

  void updateImageUrl(String? url) {
    _imageUrl = url;
    notifyListeners();
  }
}