import 'package:attendance_app/404.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/manager_dashoard.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/su_address_provider.dart';
import 'package:attendance_app/edit_mode_provider.dart';
import 'package:attendance_app/firebase_options.dart';
import 'package:attendance_app/form/form.dart';
import 'package:attendance_app/Auth/Persistent.dart';
import 'package:attendance_app/Auth/login.dart';
import 'package:attendance_app/head/splashscreen.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await Supabase.initialize(
    url: 'https://yvzrahtqpzwzawbzdeym.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Inl2enJhaHRxcHp3emF3YnpkZXltIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NDE4NTAwNDAsImV4cCI6MjA1NzQyNjA0MH0.UOxsh2Zif4Fq72MJhWfS1MAtGqg_w8w5c8DsmkaP8DI');

  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  runApp(MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (context) => EditModeProvider(),),
      ChangeNotifierProvider(create: (_) => AddressProvider()),
    ],
    child: MyApp()));
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
      onGenerateRoute: _generateRoute,
      home: AuthPersistent(), // New wrapper to check authentication status
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
    int selectedScheduleTime =
        int.tryParse(uri.queryParameters['selectedScheduleTime'] ?? "") ?? 0;

    print("Schedule Appointment Time: $selectedScheduleTime");

    print("Extracted expiryTime: $expiryTime, Current Time: $currentTime");

    if (expiryTime == 0 || expiryTime < currentTime) {
      return MaterialPageRoute(builder: (context) => const NotFoundPage());
    }

    return MaterialPageRoute(
      builder: (context) => AttendanceForm(
        selectedScheduleTime: selectedScheduleTime,
        expiryTime: expiryTime,
        createdBy: uri.queryParameters['createdBy'] ?? "",
        roles: uri.queryParameters['roles'] ?? "",
        department: uri.queryParameters['department'] ?? "",
        agenda: uri.queryParameters['agenda'] ?? "",
        firstName: uri.queryParameters['first_name'] ?? "",
        lastName: uri.queryParameters['last_name'] ?? "",
      ),
    );
  }
}