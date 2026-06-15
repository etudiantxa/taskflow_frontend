import 'package:flutter/material.dart' hide Notification;
import '../models/notification.dart';
import '../services/notification_service.dart';
import 'package:intl/intl.dart';
import 'dart:async';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({Key? key}) : super(key: key);

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<Notification> _notifications = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadNotifications();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadNotifications() async {
    setState(() => _isLoading = true);
    try {
      final data = await NotificationService.getAllNotifications();
      setState(() {
        _notifications = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Notifications", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF2563EB),
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          tabs: const [
            Tab(text: "Toutes"),
            Tab(text: "Non lues"),
            Tab(text: "Urgentes"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildList(_notifications),
          _buildList(_notifications.where((n) => !n.isRead).toList()),
          _buildList(_notifications.where((n) => 
            n.type == 'OVERDUE' || n.type == 'URGENT' || n.type == 'TASK_EXPIRED'
          ).toList()),
        ],
      ),
    );
  }

  Widget _buildList(List<Notification> list) {
    if (_isLoading) return const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)));
    if (list.isEmpty) return const Center(child: Text("Aucune notification", style: TextStyle(color: Colors.grey)));

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: list.length,
      itemBuilder: (context, i) => _buildDismissibleCard(list[i]),
    );
  }

  Widget _buildDismissibleCard(Notification n) {
    return Dismissible(
      key: Key(n.id.toString()),
      direction: DismissDirection.endToStart,
      onDismissed: (direction) async {
        await NotificationService.deleteNotification(n.id);
        setState(() => _notifications.removeWhere((item) => item.id == n.id));
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: Colors.red.withOpacity(0.8), borderRadius: BorderRadius.circular(16)),
        child: const Icon(Icons.delete, color: Colors.white),
      ),
      child: _NotificationCard(
        notification: n, 
        onTap: () => _showNotificationPopup(n),
      ),
    );
  }

  void _showNotificationPopup(Notification n) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        backgroundColor: const Color(0xFF1A1F26),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        child: Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Color(n.getColor()).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      n.type == 'OVERDUE' || n.type == 'DUE_SOON' || n.type == 'TASK_EXPIRED' 
                        ? Icons.alarm_on_rounded 
                        : Icons.notifications_active_rounded,
                      color: Color(n.getColor()),
                      size: 28,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close, color: Colors.grey, size: 24),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      n.title,
                      style: const TextStyle(
                        color: Colors.white, 
                        fontSize: 22, 
                        fontWeight: FontWeight.bold,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    getTimeAgo(n.createdAt),
                    style: TextStyle(color: Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Text(
                n.content,
                style: TextStyle(
                  color: Colors.grey[400], 
                  fontSize: 15, 
                  height: 1.6,
                  fontWeight: FontWeight.w400,
                ),
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                height: 56,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    elevation: 0,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Fermer", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                ),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        _markAsRead(n.id);
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: BorderSide(color: Colors.grey[800]!),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.done_all, color: Colors.white.withOpacity(0.9), size: 18),
                          const SizedBox(width: 8),
                          const Flexible(
                            child: Text(
                              "Marquer comme lu", 
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () async {
                        await NotificationService.deleteNotification(n.id);
                        setState(() => _notifications.removeWhere((item) => item.id == n.id));
                        Navigator.pop(context);
                      },
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        side: const BorderSide(color: Color(0xFFEF4444)),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.delete_outline, color: Color(0xFFEF4444), size: 18),
                          const SizedBox(width: 8),
                          Text("Supprimer", style: TextStyle(color: Color(0xFFEF4444), fontSize: 12, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _markAsRead(int id) async {
    await NotificationService.markAsRead(id);
    _loadNotifications();
  }
}

class _NotificationCard extends StatelessWidget {
  final Notification notification;
  final VoidCallback onTap;

  const _NotificationCard({required this.notification, required this.onTap});

  @override
  Widget build(BuildContext context) {
    Color typeColor = Color(notification.getColor());
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(16)),
        child: IntrinsicHeight(
          child: Row(
            children: [
              if (!notification.isRead)
                Container(width: 4, decoration: const BoxDecoration(color: Colors.red, borderRadius: BorderRadius.only(topLeft: Radius.circular(16), bottomLeft: Radius.circular(16))))
              else
                const SizedBox(width: 4),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(color: typeColor.withOpacity(0.1), borderRadius: BorderRadius.circular(12)),
                        child: Text(notification.getIcon(), style: const TextStyle(fontSize: 18)),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Expanded(child: Text(notification.title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14), overflow: TextOverflow.ellipsis)),
                                Text(getTimeAgo(notification.createdAt), style: const TextStyle(color: Colors.grey, fontSize: 11)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(notification.content, style: TextStyle(color: Colors.grey[400], fontSize: 13, height: 1.4), maxLines: 3, overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

String getTimeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inDays > 0) return "${diff.inDays} j";
  if (diff.inHours > 0) return "${diff.inHours} h";
  if (diff.inMinutes > 0) return "${diff.inMinutes} min";
  return "Maintenant";
}
