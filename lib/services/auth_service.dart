import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/auth_response.dart';
import '../core/constants.dart'; // ✨ Import centralisé
import 'session_service.dart';

class AuthService {
  // ✨ Utilisation de l'URL centralisée
  static const String authEndpoint = '${ApiConstants.baseUrl}/auths';

  // ✨ LOGIN
  static Future<AuthResponse> login({
    required String username,
    required String password,
  }) async {
    try {
      print('🔄 Tentative de connexion...');

      final response = await http.post(
        Uri.parse('$authEndpoint/login'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'username': username,
          'password': password,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout : Le serveur ne répond pas'),
      );

      return _handleAuthResponse(response);
    } catch (e) {
      print('❌ Erreur login: $e');
      throw Exception('Erreur de connexion: $e');
    }
  }

  // ✨ GOOGLE LOGIN
  static Future<AuthResponse> loginWithGoogle(String idToken) async {
    try {
      print('🔄 Tentative de connexion Google...');

      final response = await http.post(
        Uri.parse('$authEndpoint/google'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'idToken': idToken,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout : Le serveur ne répond pas'),
      );

      return _handleAuthResponse(response);
    } catch (e) {
      print('❌ Erreur Google Login: $e');
      throw Exception('Erreur de connexion Google: $e');
    }
  }

  static Future<AuthResponse> _handleAuthResponse(http.Response response) async {
    if (response.statusCode == 200 || response.statusCode == 201) {
      final json = jsonDecode(response.body);
      final authResponse = AuthResponse.fromJson(json);

      // ✨ Sauvegarder la session
      await SessionService.saveToken(authResponse.token);

      // ✨ SI l'user est vide, le récupérer depuis l'API
      if (authResponse.user.id.isEmpty || authResponse.user.nom.isEmpty) {
        print('⚠️ User vide dans la réponse, récupération depuis l\'API...');
        try {
          final userFromApi = await getProfile();
          await SessionService.saveUser(userFromApi);
          print('✅ Profil récupéré depuis l\'API et sauvegardé');
        } catch (e) {
          print('❌ Impossible de récupérer le profil: $e');
          await SessionService.saveUser(authResponse.user);
        }
      } else {
        await SessionService.saveUser(authResponse.user);
      }

      print('✅ Authentification réussie : ${authResponse.user.fullName}');
      return authResponse;
    } else {
      throw Exception('Erreur ${response.statusCode}: Authentification échouée');
    }
  }

  // ✨ REGISTER
  static Future<AuthResponse> register({
    required String nom,
    required String prenom,
    required String username,
    required String email,
    required String password,
    String? photo,
  }) async {
    try {
      print('🔄 Inscription en cours...');

      final response = await http.post(
        Uri.parse('$authEndpoint/register'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'username': username,
          'email': email,
          'password': password,
          'photo': photo,
        }),
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout : Le serveur ne répond pas'),
      );

      return _handleAuthResponse(response);
    } catch (e) {
      print('❌ Erreur register: $e');
      throw Exception('Erreur d\'inscription: $e');
    }
  }

  // ✨ FORGOT PASSWORD
  static Future<void> forgotPassword(String email) async {
    try {
      final response = await http.post(
        Uri.parse('$authEndpoint/forgot-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'email': email}),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur lors de la demande de réinitialisation');
      }
    } catch (e) {
      throw Exception('Erreur forgotPassword: $e');
    }
  }

  // ✨ RESET PASSWORD
  static Future<void> resetPassword(String token, String newPassword) async {
    try {
      final response = await http.post(
        Uri.parse('$authEndpoint/reset-password'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'token': token,
          'newPassword': newPassword,
        }),
      );

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur lors de la réinitialisation du mot de passe');
      }
    } catch (e) {
      throw Exception('Erreur resetPassword: $e');
    }
  }

  // ✨ GET PROFIL (Utiliser le token pour récupérer le profil)
  static Future<User> getProfile() async {
    try {
      print('🔄 Récupération du profil...');

      final token = await SessionService.getToken();
      if (token == null) {
        throw Exception('Pas de token - utilisateur non connecté');
      }

      final response = await http.get(
        Uri.parse('$authEndpoint/profils'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      ).timeout(
        const Duration(seconds: 10),
        onTimeout: () => throw Exception('Timeout : Le serveur ne répond pas'),
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        final userData = json is Map && json.containsKey('user')
            ? json['user']
            : json;
        final user = User.fromJson(userData);

        print('✅ Profil récupéré : ${user.fullName}');
        return user;
      } else {
        throw Exception('Erreur ${response.statusCode}: Impossible de récupérer le profil');
      }
    } catch (e) {
      print('❌ Erreur getProfile: $e');
      throw Exception('Erreur récupération profil: $e');
    }
  }

  // ✨ LOGOUT
  static Future<void> logout() async {
    try {
      print('🔄 Déconnexion...');
      await SessionService.logout();
      print('✅ Déconnexion réussie');
    } catch (e) {
      print('❌ Erreur logout: $e');
    }
  }
}
