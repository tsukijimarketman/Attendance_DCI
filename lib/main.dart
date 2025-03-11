import 'package:attendance_app/404.dart';
import 'package:attendance_app/firebase_options.dart';
import 'package:attendance_app/form/form.dart';
import 'package:attendance_app/head/login.dart';
import 'package:attendance_app/head/splashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(MyApp());
  _hideBar();
}

Future _hideBar() async {
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.manual, overlays: []);
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'QR Code Attendance',
      initialRoute: '/',
      onGenerateRoute: _generateRoute,
    );
  }

  /// **Route Handler Function**
  Route<dynamic> _generateRoute(RouteSettings settings) {
    Uri uri = Uri.parse(settings.name ?? "/");

    switch (uri.path) {
      case '/':
        return MaterialPageRoute(builder: (context) => const Login());

      case '/attendance_form':
        return _handleAttendanceFormRoute(uri);

      default:
        return MaterialPageRoute(builder: (context) => const NotFoundPage());
    }
  }

  /// **Handles the `/attendance_form` route safely**
  MaterialPageRoute _handleAttendanceFormRoute(Uri uri) {
    // Parse expiry time and validate
    int expiryTime = int.tryParse(uri.queryParameters['expiryTime'] ?? "") ?? 0;
    int currentTime = DateTime.now().millisecondsSinceEpoch;

    print("Extracted expiryTime: $expiryTime, Current Time: $currentTime");

    if (expiryTime == 0 || expiryTime < currentTime) {
      return MaterialPageRoute(builder: (context) => const NotFoundPage());
    }

    return MaterialPageRoute(
      builder: (context) => AttendanceForm(
        expiryTime: expiryTime,
        roles: uri.queryParameters['roles'] ?? "",
        department: uri.queryParameters['department'] ?? "",
        agenda: uri.queryParameters['agenda'] ?? "",
        firstName: uri.queryParameters['first_name'] ?? "",
        middleName: uri.queryParameters['middle_name'] ?? "",
        lastName: uri.queryParameters['last_name'] ?? "",
      ),
    );
  }
}
