import 'package:flutter/material.dart';
class EditModeProvider with ChangeNotifier {
  bool textFieldReadOnly = true;
  bool dropDownReadOnly = true;
  bool dropDownSearchReadOnly = true;
  bool calendarReadOnly = true;
  bool isEditing = false;

  void toggleEditMode() {
    isEditing = !isEditing;
    textFieldReadOnly = !isEditing;
    dropDownReadOnly = !isEditing;
    dropDownSearchReadOnly = !isEditing;
    calendarReadOnly = !isEditing;
    notifyListeners();
  }
}
