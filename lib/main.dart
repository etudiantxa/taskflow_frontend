import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'services/cache_service.dart';
import 'services/session_service.dart';
import 'screens/login_screen.dart';
import 'screens/register_screen.dart';
import 'screens/tasks_dashboard.dart';
import 'screens/task_details_screen.dart';
import 'screens/add_task_screen.dart';
import 'screens/notifications_screen.dart';
import 'screens/profile_screen.dart';
import 'screens/forgot_password_screen.dart';
import 'screens/reset_password_screen.dart';
import 'screens/calendar_screen.dart';
import 'screens/projects_screen.dart';
import 'screens/add_project_screen.dart';
import 'screens/project_details_screen.dart';
import 'models/task.dart';
import 'models/project.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('fr_FR', null);
  await CacheService.initHive();
  final isLoggedIn = await SessionService.isLoggedIn();
  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatefulWidget {
  final bool isLoggedIn;
  const MyApp({Key? key, this.isLoggedIn = false}) : super(key: key);
  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late AppLinks _appLinks;
  StreamSubscription<Uri>? _linkSubscription;
  final _navigatorKey = GlobalKey<NavigatorState>();

  @override
  void initState() {
    super.initState();
    initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) => _handleDeepLink(uri));
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) _handleDeepLink(initialUri);
  }

  void _handleDeepLink(Uri uri) {
    if (uri.path.contains('reset-password') || uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        _navigatorKey.currentState?.pushNamed('/reset-password', arguments: {'token': token});
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey,
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFF0F1419),
      ),
      home: widget.isLoggedIn ? const TasksDashboard() : const LoginScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/reset-password') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(builder: (context) => ResetPasswordScreen(token: args?['token']));
        }
        return null;
      },
      routes: {
        '/login': (context) => const LoginScreen(),
        '/register': (context) => const RegisterScreen(),
        '/forgot-password': (context) => const ForgotPasswordScreen(),
        '/reset-password-manual': (context) => const ResetPasswordScreen(),
        '/dashboard': (context) => const TasksDashboard(),
        '/task_details': (context) {
          final task = ModalRoute.of(context)?.settings.arguments as Task;
          return TaskDetailsScreen(task: task);
        },
        '/add_task': (context) => const AddTaskScreen(),
        '/notifications': (context) => const NotificationsScreen(),
        '/profile': (context) => const ProfileScreen(),
        '/calendar': (context) => const CalendarScreen(),
        '/projects': (context) => const ProjectsScreen(),
        '/add_project': (context) => const AddProjectScreen(),
        '/project_details': (context) {
          final project = ModalRoute.of(context)?.settings.arguments as Project;
          return ProjectDetailsScreen(project: project);
        },
      },
    );
  }
}
