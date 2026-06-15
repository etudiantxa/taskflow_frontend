import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../core/constants.dart';
import 'session_service.dart';

class ProfileService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String profileEndpoint = '$baseUrl/auths/profils';

  static Future<User> getProfile() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.get(
        Uri.parse(profileEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final userData = json is Map && json.containsKey('user') ? json['user'] : json;
        return User.fromJson(userData);
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur récupération profil: $e');
    }
  }

  // ✨ RÉCUPÉRER TOUS LES UTILISATEURS
  static Future<List<User>> getAllUsers() async {
    try {
      final token = await SessionService.getToken();
      // ✨ Utilisation de /users comme indiqué pour votre backend
      final response = await http.get(
        Uri.parse('$baseUrl/users'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      print('📥 Response Users Status: ${response.statusCode}');
      print('📥 Response Users Body: ${response.body}');

      if (response.statusCode == 200) {
        final List<dynamic> json = jsonDecode(response.body);
        return json.map((u) => User.fromJson(u)).toList();
      }
      return [];
    } catch (e) {
      print('❌ Erreur getAllUsers: $e');
      return [];
    }
  }

  static Future<User> updateProfile({
    required String nom,
    required String prenom,
    required String email,
    required String username,
    String? photo,
  }) async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.put(
        Uri.parse(profileEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'nom': nom,
          'prenom': prenom,
          'email': email,
          'username': username,
          if (photo != null) 'photo': photo,
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        final userData = json is Map && json.containsKey('user') ? json['user'] : json;
        final user = User.fromJson(userData);
        await SessionService.saveUser(user);
        return user;
      } else {
        throw Exception('Erreur ${response.statusCode}: ${response.body}');
      }
    } catch (e) {
      throw Exception('Erreur mise à jour profil: $e');
    }
  }
}
