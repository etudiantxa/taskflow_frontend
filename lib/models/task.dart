import 'package:flutter/material.dart';
import 'user.dart';

enum TaskPriority { low, medium, high }
enum TaskCategory { work, personal, shopping, other }
enum TaskStatus { todo, inProgress, completed, pending, cancelled, expired }

class Task {
  final String id;
  final String title;
  final String description;
  final DateTime dueDate;
  final TaskPriority priority;
  final TaskCategory category;
  final TaskStatus status;
  final bool isCompleted;
  final String assignedTo;
  final List<User> assignedUsers; // ✨ Liste des collaborateurs
  final DateTime createdAt;

  Task({
    required this.id,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.priority,
    required this.category,
    this.status = TaskStatus.todo,
    this.isCompleted = false,
    required this.assignedTo,
    this.assignedUsers = const [],
    required this.createdAt,
  });

  // ✨ Getter pour la compatibilité (récupère le premier utilisateur de la liste)
  User? get assignedUser => assignedUsers.isNotEmpty ? assignedUsers.first : null;

  Color getPriorityColor() {
    switch (priority) {
      case TaskPriority.low: return const Color(0xFF10B981);
      case TaskPriority.medium: return const Color(0xFFF59E0B);
      case TaskPriority.high: return const Color(0xFFEF4444);
    }
  }

  String getPriorityLabel() {
    switch (priority) {
      case TaskPriority.low: return 'LOW PRIORITY';
      case TaskPriority.medium: return 'MEDIUM PRIORITY';
      case TaskPriority.high: return 'HIGH PRIORITY';
    }
  }

  Color getStatusColor() {
    switch (status) {
      case TaskStatus.todo: return const Color(0xFF60A5FA);
      case TaskStatus.inProgress: return const Color(0xFF2563EB);
      case TaskStatus.completed: return const Color(0xFF10B981);
      case TaskStatus.expired: return const Color(0xFFEF4444);
      case TaskStatus.pending: return Colors.orange;
      default: return Colors.grey;
    }
  }

  String getStatusLabel() {
    switch (status) {
      case TaskStatus.todo: return 'À FAIRE';
      case TaskStatus.inProgress: return 'EN COURS';
      case TaskStatus.completed: return 'TERMINÉ';
      case TaskStatus.pending: return 'EN ATTENTE';
      case TaskStatus.cancelled: return 'ANNULÉ';
      case TaskStatus.expired: return 'EXPIRÉ';
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    var usersList = json['assignedUsers'] as List? ?? [];
    return Task(
      id: json['id']?.toString() ?? '0',
      title: json['title'] ?? 'Sans titre',
      description: json['content'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      priority: _parsePriority(json['priority'] ?? 'Medium'),
      status: _parseStatus(json['status'] ?? 'Todo'),
      category: TaskCategory.work,
      isCompleted: json['completed'] ?? false,
      assignedTo: json['assignedTo'] ?? 'N/A',
      assignedUsers: usersList.map((u) => User.fromJson(u)).toList(),
      createdAt: json['createdAt'] != null ? DateTime.parse(json['createdAt']) : DateTime.now(),
    );
  }

  static TaskPriority _parsePriority(String p) {
    final priority = p.toLowerCase();
    if (priority == 'high') return TaskPriority.high;
    if (priority == 'low') return TaskPriority.low;
    return TaskPriority.medium;
  }

  static TaskStatus _parseStatus(String s) {
    switch (s.toLowerCase()) {
      case 'inprogress':
      case 'in_progress': return TaskStatus.inProgress;
      case 'completed': return TaskStatus.completed;
      case 'pending': return TaskStatus.pending;
      case 'cancelled': return TaskStatus.cancelled;
      case 'expired': return TaskStatus.expired;
      case 'todo': return TaskStatus.todo;
      default: return TaskStatus.todo;
    }
  }

  static String statusToBackendString(TaskStatus s) {
    switch(s) {
      case TaskStatus.inProgress: return 'InProgress';
      case TaskStatus.completed: return 'Completed';
      case TaskStatus.pending: return 'Pending';
      case TaskStatus.cancelled: return 'Cancelled';
      case TaskStatus.expired: return 'Expired';
      default: return 'Todo';
    }
  }

  static String priorityToBackendString(TaskPriority p) {
    switch(p) {
      case TaskPriority.high: return 'High';
      case TaskPriority.low: return 'Low';
      default: return 'Medium';
    }
  }
}
