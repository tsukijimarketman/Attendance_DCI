import 'package:attendance_app/404.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/depthead_address_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/head_drawer/depthead_sidebar_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/internaluser_drawer/sidebar_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/internaluser_drawer/su_address_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/manager_address_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/manager_drawer/manager_sidebar_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/profileimagenotifier.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/sidebar_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_sidebar_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/superuser_drawer/su_address_provider.dart';
import 'package:attendance_app/Accounts%20Dashboard/admin_drawer/admin_address_provider.dart';
import 'package:attendance_app/Auth/SessionManager.dart';
import 'package:attendance_app/Auth/SessionWrapper.dart';
import 'package:attendance_app/edit_mode_provider.dart';
import 'package:attendance_app/firebase_options.dart';
import 'package:attendance_app/form/form.dart';
import 'package:attendance_app/Auth/Persistent.dart';
import 'package:attendance_app/Auth/login.dart';
import 'package:attendance_app/secrets.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  // Ensure that plugin services are initialized before running the app.
  // This is necessary for plugins that require platform-specific initialization.
  // For example, Firebase and Supabase require this to set up their services.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase services.
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Initialize Supabase services.
  await Supabase.initialize(
      url: AppSecrets.supaUrl, anonKey: AppSecrets.supaAnon);

  // Set Firebase authentication persistence to LOCAL.
  // This means that the user's authentication state will be persisted even after the app is closed.
  // This is useful for keeping users logged in across app restarts.
  // The persistence can be set to LOCAL, SESSION, or NONE.
  // LOCAL: The user's authentication state will be persisted even after the app is closed.
  await FirebaseAuth.instance.setPersistence(Persistence.LOCAL);

  runApp(
      //multiprovider is used to provide multiple providers to the widget tree
      //it is like a global variable but it is disposable to reduce memory leak.
      MultiProvider(
    providers: [
      ChangeNotifierProvider(create: (_) => ProfileImageNotifier()),
      ChangeNotifierProvider(
        create: (context) => EditModeProvider(),
      ),
      ChangeNotifierProvider(create: (_) => AddressProvider()),
      ChangeNotifierProvider(create: (_) => AdminAddressProvider()),
      ChangeNotifierProvider(create: (_) => SidebarProvider()),
      ChangeNotifierProvider(create: (_) => DeptHeadAddressProvider()),
      ChangeNotifierProvider(create: (_) => DeptHeadSidebarProvider()),
      ChangeNotifierProvider(create: (_) => AdminSidebarProvider()),
      ChangeNotifierProvider(create: (_) => ManagerAddressProvider()),
      ChangeNotifierProvider(create: (_) => ManagerSidebarProvider()),
      ChangeNotifierProvider(create: (_) => InternalSidebarProvider()),
      ChangeNotifierProvider(create: (_) => InternalAddressProvider()),
    ],
    child: SessionWrapper(child: MyApp()),
  ));
}

class MyApp extends StatelessWidget {
  MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: navigatorKey,
      debugShowCheckedModeBanner: false,
      title: 'QR Code Attendance',
      onGenerateRoute: _generateRoute,
      home: AuthPersistent(), // New wrapper to check authentication status
    );
  }

  /// Handles route generation based on the incoming route settings.
  Route<dynamic> _generateRoute(RouteSettings settings) {
    Uri uri = Uri.parse(settings.name ?? "/");

    /// - If the route is '/', navigates to Login page.
    switch (uri.path) {
      case '/':
        return MaterialPageRoute(builder: (context) => const Login());

      /// - If the route is '/attendance_form', validates expiry time and opens AttendanceForm page.
      case '/attendance_form':
        return _handleAttendanceFormRoute(uri);

      /// - For any unknown routes, navigates to NotFoundPage.
      default:
        return MaterialPageRoute(builder: (context) => const NotFoundPage());
    }
  }

  /// **Handles the `/attendance_form` route**
  MaterialPageRoute _handleAttendanceFormRoute(Uri uri) {
    /// - Extracts and validates important parameters like `expiryTime` and `selectedScheduleTime`.
    int expiryTime = int.tryParse(uri.queryParameters['expiryTime'] ?? "") ?? 0;
    // Fix: Ensure proper parsing of the schedule time
    String scheduleParam = uri.queryParameters['selectedScheduleTime'] ?? "";
    int selectedScheduleTime = 0;

    // Try to parse the schedule parameter
    try {
      selectedScheduleTime = int.parse(scheduleParam);
      // Add a debug print to verify the value (you can remove this later)
      print("Parsed schedule time: $selectedScheduleTime");
    } catch (e) {
      print("Error parsing schedule time: $e, using default value");
    }

    /// - If valid, passes all query parameters to the AttendanceForm widget.
    return MaterialPageRoute(
      builder: (context) => AttendanceForm(
        selectedScheduleTime: selectedScheduleTime,
        createdBy: uri.queryParameters['createdBy'] ?? "",
        roles: uri.queryParameters['roles'] ?? "",
        deptID: uri.queryParameters['department'] ?? "",
        agenda: uri.queryParameters['agenda'] ?? "",
        firstName: uri.queryParameters['first_name'] ?? "",
        lastName: uri.queryParameters['last_name'] ?? "",
      ),
    );
  }
}
