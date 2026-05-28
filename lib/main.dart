import 'dart:async';
import 'package:flutter/material.dart';
import 'package:app_links/app_links.dart';
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

class MyApp extends StatefulWidget {
  final bool isLoggedIn;

  const MyApp({
    Key? key,
    this.isLoggedIn = false,
  }) : super(key: key);

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

  // ✨ Configuration du Deep Linking
  Future<void> initDeepLinks() async {
    _appLinks = AppLinks();

    // 1. Gère le lien si l'app est déjà ouverte en arrière-plan
    _linkSubscription = _appLinks.uriLinkStream.listen((uri) {
      debugPrint('🔗 Lien reçu (ouvert): $uri');
      _handleDeepLink(uri);
    });

    // 2. Gère le lien si l'app était complètement fermée
    final initialUri = await _appLinks.getInitialLink();
    if (initialUri != null) {
      debugPrint('🔗 Lien initial (fermé): $initialUri');
      _handleDeepLink(initialUri);
    }
  }

  void _handleDeepLink(Uri uri) {
    // Vérifie si le chemin correspond à la réinitialisation
    if (uri.path.contains('reset-password') || uri.host == 'reset-password') {
      final token = uri.queryParameters['token'];
      if (token != null) {
        debugPrint('✅ Token extrait du lien: $token');
        _navigatorKey.currentState?.pushNamed(
          '/reset-password',
          arguments: {'token': token},
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      navigatorKey: _navigatorKey, // ✨ Important pour la navigation automatique
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
