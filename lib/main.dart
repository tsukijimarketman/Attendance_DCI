import 'package:attendance_app/404.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/super_user_dashboard.dart';
import 'package:attendance_app/firebase_options.dart';
import 'package:attendance_app/form/form.dart';
import 'package:attendance_app/head/login.dart';
import 'package:attendance_app/head/splashscreen.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
// import 'package:supabase_flutter/supabase_flutter.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // await Supabase.initialize(
  //   url: 'https://yvzrahtqpzwzawbzdeym.supabase.co', 
  //   anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2enJhaHRxcHp3emF3YnpkZXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4NTAwNDAsImV4cCI6MjA1NzQyNjA0MH0.UOxsh2Zif4Fq72MJhWfS1MAtGqg_w8w5c8DsmkaP8DI', 
  // );
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
        return MaterialPageRoute(builder: (context) => const SuperUserDashboard());

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
        lastName: uri.queryParameters['last_name'] ?? "",
      ),
    );
  }
}
