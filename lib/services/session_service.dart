import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';

class SessionService {
  // ✨ Clés pour SharedPreferences
  static const String _tokenKey = 'auth_token';
  static const String _userKey = 'auth_user';
  static const String _usernameKey = 'auth_username';
  static const String _emailKey = 'auth_email';

  // ✨ SAUVEGARDER LE TOKEN
  static Future<void> saveToken(String token) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_tokenKey, token);
      print('✅ Token sauvegardé');
    } catch (e) {
      print('❌ Erreur sauvegarde token: $e');
    }
  }

  // ✨ RÉCUPÉRER LE TOKEN
  static Future<String?> getToken() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final token = prefs.getString(_tokenKey);
      if (token != null) {
        print('✅ Token récupéré');
      }
      return token;
    } catch (e) {
      print('❌ Erreur récupération token: $e');
      return null;
    }
  }

  // ✨ SAUVEGARDER L'UTILISATEUR
  static Future<void> saveUser(User user) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_userKey, user.toJsonString());
      await prefs.setString(_usernameKey, user.username);
      await prefs.setString(_emailKey, user.email);
      print('✅ Utilisateur sauvegardé: ${user.fullName}');
    } catch (e) {
      print('❌ Erreur sauvegarde utilisateur: $e');
    }
  }

  // ✨ RÉCUPÉRER L'UTILISATEUR
  static Future<User?> getUser() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userJson = prefs.getString(_userKey);
      if (userJson != null) {
        final user = User.fromJsonString(userJson);
        print('✅ Utilisateur récupéré: ${user.fullName}');
        return user;
      }
      return null;
    } catch (e) {
      print('❌ Erreur récupération utilisateur: $e');
      return null;
    }
  }

  // ✨ VÉRIFIER SI UTILISATEUR EST CONNECTÉ
  static Future<bool> isLoggedIn() async {
    try {
      final token = await getToken();
      return token != null && token.isNotEmpty;
    } catch (e) {
      print('❌ Erreur vérification session: $e');
      return false;
    }
  }

  // ✨ DÉCONNEXION
  static Future<void> logout() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_tokenKey);
      await prefs.remove(_userKey);
      await prefs.remove(_usernameKey);
      await prefs.remove(_emailKey);
      print('✅ Session supprimée (logout)');
    } catch (e) {
      print('❌ Erreur logout: $e');
    }
  }

  // ✨ OBTENIR LE USERNAME
  static Future<String?> getUsername() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_usernameKey);
    } catch (e) {
      print('❌ Erreur récupération username: $e');
      return null;
    }
  }

  // ✨ OBTENIR L'EMAIL
  static Future<String?> getEmail() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_emailKey);
    } catch (e) {
      print('❌ Erreur récupération email: $e');
      return null;
    }
  }

  // ✨ EFFACER TOUTE LA SESSION
  static Future<void> clearAll() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.clear();
      print('✅ Toute la session effacée');
    } catch (e) {
      print('❌ Erreur effacement session: $e');
    }
  }
}