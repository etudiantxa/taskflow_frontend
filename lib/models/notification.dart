class Notification {
  final int id;
  final int userId;
  final int taskId;
  final String title;
  final String content;
  final String type; 
  final bool isRead;
  final DateTime createdAt;

  Notification({
    required this.id,
    required this.userId,
    required this.taskId,
    required this.title,
    required this.content,
    required this.type,
    required this.isRead,
    required this.createdAt,
  });

  factory Notification.fromJson(Map<String, dynamic> json) {
    return Notification(
      id: json['id'] ?? 0,
      userId: json['userId'] ?? 0,
      taskId: json['taskId'] ?? 0,
      title: json['title'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'TASK_CREATED',
      isRead: json['isRead'] ?? false,
      createdAt: DateTime.parse(json['createdAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  String getIcon() {
    switch (type) {
      case 'TASK_CREATED': return '✨';
      case 'OVERDUE': return '⏰';
      case 'DUE_SOON': return '📅';
      case 'COMPLETED': return '✅';
      case 'TASK_EXPIRED': return '🚫'; // ✨ Nouvel icône pour expiré
      default: return '🔔';
    }
  }

  int getColor() {
    switch (type) {
      case 'OVERDUE': return 0xFFEF4444;
      case 'TASK_EXPIRED': return 0xFF991B1B; // ✨ Rouge foncé pour expiration
      case 'TASK_CREATED': return 0xFF2563EB;
      case 'COMPLETED': return 0xFF10B981;
      default: return 0xFF6B7280;
    }
  }
}
