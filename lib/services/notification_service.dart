import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/notification.dart';
import '../core/constants.dart'; // ✨ Import centralisé
import 'session_service.dart';

class NotificationService {
  // ✨ Utilisation de l'URL centralisée
  static const String baseUrl = ApiConstants.baseUrl; 
  static const String notificationEndpoint = '$baseUrl/notifications';

  // ✨ Récupérer toutes les notifications
  static Future<List<Notification>> getAllNotifications() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) throw Exception('Non authentifié');

      final response = await http.get(
        Uri.parse(notificationEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Notification.fromJson(json)).toList();
      } else {
        throw Exception('Erreur ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Erreur: $e');
    }
  }

  // ✨ Marquer une notification comme lue
  static Future<void> markAsRead(int id) async {
    try {
      final token = await SessionService.getToken();
      await http.patch(
        Uri.parse('$notificationEndpoint/$id/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      print('Erreur markAsRead: $e');
    }
  }

  // ✨ Marquer toutes les notifications comme lues
  static Future<void> markAllAsRead() async {
    try {
      final token = await SessionService.getToken();
      await http.patch(
        Uri.parse('$notificationEndpoint/all/read'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      print('Erreur markAllAsRead: $e');
    }
  }

  // ✨ Supprimer une notification
  static Future<void> deleteNotification(int id) async {
    try {
      final token = await SessionService.getToken();
      await http.delete(
        Uri.parse('$notificationEndpoint/$id'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      print('Erreur suppression notification: $e');
    }
  }

  // ✨ Compter les notifications non lues
  static Future<int> countUnreadNotifications() async {
    try {
      final token = await SessionService.getToken();
      if (token == null) return 0;

      final response = await http.get(
        Uri.parse('$notificationEndpoint/count/unread'),
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);
        return json['unreadCount'] ?? 0;
      }
      return 0;
    } catch (e) {
      return 0;
    }
  }
}
