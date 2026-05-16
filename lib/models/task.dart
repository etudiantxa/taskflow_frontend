import 'package:flutter/material.dart';

enum TaskPriority { low, medium, high }
enum TaskCategory { work, personal, shopping, other }
// 1. Enum complet pour correspondre au backend
enum TaskStatus { todo, inProgress, completed, pending, cancelled }

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
    required this.createdAt,
  });

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
      case TaskStatus.pending: return Colors.orange;
      case TaskStatus.cancelled: return Colors.grey;
    }
  }

  String getStatusLabel() {
    switch (status) {
      case TaskStatus.todo: return 'À FAIRE';
      case TaskStatus.inProgress: return 'EN COURS';
      case TaskStatus.completed: return 'TERMINÉ';
      case TaskStatus.pending: return 'EN ATTENTE';
      case TaskStatus.cancelled: return 'ANNULÉ';
    }
  }

  factory Task.fromJson(Map<String, dynamic> json) {
    return Task(
      id: json['id']?.toString() ?? '0',
      title: json['title'] ?? 'Sans titre',
      description: json['content'] ?? '',
      dueDate: json['dueDate'] != null ? DateTime.parse(json['dueDate']) : DateTime.now(),
      priority: _parsePriority(json['priority'] ?? 'Medium'),
      status: _parseStatus(json['status'] ?? 'Todo'),
      category: TaskCategory.work,
      isCompleted: json['completed'] ?? false,
      assignedTo: 'API',
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
    // 2. Parsing robuste qui ignore la casse
    switch (s.toUpperCase()) {
      case 'INPROGRESS':
      case 'IN_PROGRESS': return TaskStatus.inProgress;
      case 'COMPLETED': return TaskStatus.completed;
      case 'PENDING': return TaskStatus.pending;
      case 'CANCELLED': return TaskStatus.cancelled;
      case 'TODO': return TaskStatus.todo;
      default: return TaskStatus.todo;
    }
  }

  // 3. Transformation pour le Backend (Respect strict de la casse PascalCase)
  static String statusToBackendString(TaskStatus s) {
    switch(s) {
      case TaskStatus.inProgress: return 'InProgress';
      case TaskStatus.completed: return 'Completed';
      case TaskStatus.pending: return 'Pending';
      case TaskStatus.cancelled: return 'Cancelled';
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