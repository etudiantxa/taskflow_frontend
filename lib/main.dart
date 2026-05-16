import 'package:flutter/material.dart';
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
import 'models/task.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✨ Initialiser Hive
  await CacheService.initHive();

  // ✨ Vérifier si utilisateur est connecté
  final isLoggedIn = await SessionService.isLoggedIn();

  runApp(MyApp(isLoggedIn: isLoggedIn));
}

class MyApp extends StatelessWidget {
  final bool isLoggedIn;

  const MyApp({
    Key? key,
    this.isLoggedIn = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TaskFlow',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        primaryColor: const Color(0xFF2563EB),
        scaffoldBackgroundColor: const Color(0xFF0F1419),
      ),
      // ✨ REDIRECTION INTELLIGENTE
      home: isLoggedIn ? const TasksDashboard() : const LoginScreen(),
      onGenerateRoute: (settings) {
        if (settings.name == '/reset-password') {
          final args = settings.arguments as Map<String, dynamic>?;
          return MaterialPageRoute(
            builder: (context) => ResetPasswordScreen(token: args?['token']),
          );
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
      },
    );
  }
}
