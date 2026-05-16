import 'package:hive/hive.dart';
import 'task.dart';

part 'task_hive.g.dart';

// ✨ MODÈLE HIVE POUR STOCKER LES TÂCHES LOCALEMENT
@HiveType(typeId: 0)
class TaskHive {
  @HiveField(0)
  final String id;

  @HiveField(1)
  final String title;

  @HiveField(2)
  final String description;

  @HiveField(3)
  final String priority; // 'low', 'medium', 'high'

  @HiveField(4)
  final DateTime dueDate;

  @HiveField(5)
  final DateTime createdAt;

  TaskHive({
    required this.id,
    required this.title,
    required this.description,
    required this.priority,
    required this.dueDate,
    required this.createdAt,
  });

  // ✨ Convertir Task en TaskHive (pour sauvegarder)
  factory TaskHive.fromTask(Task task) {
    return TaskHive(
      id: task.id,
      title: task.title,
      description: task.description,
      priority: task.getPriorityLabel().toLowerCase(),
      dueDate: task.dueDate,
      createdAt: task.createdAt,
    );
  }

  // ✨ Convertir TaskHive en Task (pour afficher)
  Task toTask() {
    return Task(
      id: id,
      title: title,
      description: description,
      priority: _parsePriority(priority),
      category: TaskCategory.work, // Valeur par défaut
      isCompleted: false,
      assignedTo: 'Moi (Responsable)',
      dueDate: dueDate,
      createdAt: createdAt,
    );
  }

  // ✨ Convertir string en TaskPriority
  static TaskPriority _parsePriority(String priority) {
    switch (priority.toLowerCase()) {
      case 'low':
        return TaskPriority.low;
      case 'medium':
        return TaskPriority.medium;
      case 'high':
        return TaskPriority.high;
      default:
        return TaskPriority.medium;
    }
  }
}