import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/task.dart';
import '../core/constants.dart';
import 'cache_service.dart';
import 'session_service.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl;
  static const String taskEndpoint = '$baseUrl/task';

  static Future<Map<String, dynamic>> getAllTasks({
    String? priority,
    String? status,
    int limit = 100,
    int offset = 0,
  }) async {
    try {
      final token = await SessionService.getToken();
      String url = taskEndpoint;
      List<String> params = [];
      if (priority != null && priority != 'All') params.add('priority=$priority');
      if (status != null && status != 'All') params.add('status=$status');
      params.add('limit=$limit');
      params.add('offset=$offset');
      if (params.isNotEmpty) url += '?' + params.join('&');

      final response = await http.get(Uri.parse(url), headers: {
        'Authorization': 'Bearer $token',
        'Content-Type': 'application/json',
      });

      if (response.statusCode == 200) {
        final jsonData = jsonDecode(response.body);
        if (jsonData is Map && jsonData.containsKey('tasks')) {
          final List<dynamic> tasksList = jsonData['tasks'] ?? [];
          final tasks = tasksList.map((json) => Task.fromJson(json)).toList();
          return {'tasks': tasks, 'pagination': jsonData['pagination'] ?? {}};
        }
        return {'tasks': (jsonData as List).map((j) => Task.fromJson(j)).toList(), 'pagination': {}};
      }
      throw Exception('Erreur ${response.statusCode}');
    } catch (e) {
      return {'tasks': [], 'pagination': {}};
    }
  }

  static Future<void> createTask({
    required String title,
    required String content,
    required String priority,
    DateTime? dueDate,
    String? status,
    String? color,
    List<String>? assignedUserIds,
  }) async {
    try {
      final token = await SessionService.getToken();
      
      // ✨ Conversion des IDs en entiers pour NestJS
      final List<int> numericIds = (assignedUserIds ?? [])
          .map((id) => int.tryParse(id))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      final body = jsonEncode({
        'title': title,
        'content': content,
        'priority': priority,
        'status': status ?? 'Todo',
        'color': color ?? 'blue',
        'dueDate': dueDate?.toIso8601String(),
        'assignedUserIds': numericIds,
      });

      final response = await http.post(
        Uri.parse(taskEndpoint),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 201) {
        throw Exception('Erreur serveur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> updateTask({
    required int id,
    required String title,
    required String content,
    required String priority,
    DateTime? dueDate,
    String? status,
    String? color,
    List<String>? assignedUserIds,
  }) async {
    try {
      final token = await SessionService.getToken();
      
      // ✨ Conversion des IDs en entiers pour NestJS
      final List<int> numericIds = (assignedUserIds ?? [])
          .map((id) => int.tryParse(id))
          .where((id) => id != null)
          .cast<int>()
          .toList();

      final body = jsonEncode({
        'title': title,
        'content': content,
        'priority': priority,
        'status': status,
        'color': color ?? 'blue',
        'dueDate': dueDate?.toIso8601String(),
        'assignedUserIds': numericIds,
      });

      final response = await http.patch(
        Uri.parse('$taskEndpoint/$id'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json'
        },
        body: body,
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode != 200 && response.statusCode != 204) {
        throw Exception('Erreur serveur (${response.statusCode}): ${response.body}');
      }
    } catch (e) {
      rethrow;
    }
  }

  static Future<void> deleteTask(int id) async {
    final token = await SessionService.getToken();
    await http.delete(Uri.parse('$taskEndpoint/$id'), headers: {'Authorization': 'Bearer $token'});
  }

  static Future<List<Task>> searchTasks(String query) async {
    final token = await SessionService.getToken();
    final response = await http.get(Uri.parse('$taskEndpoint/search/${Uri.encodeComponent(query)}'), headers: {'Authorization': 'Bearer $token'});
    if (response.statusCode == 200) {
      return (jsonDecode(response.body) as List).map((j) => Task.fromJson(j)).toList();
    }
    return [];
  }
}
