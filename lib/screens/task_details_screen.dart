import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';

class TaskDetailsScreen extends StatefulWidget {
  final Task task;

  const TaskDetailsScreen({
    Key? key,
    required this.task,
  }) : super(key: key);

  @override
  State<TaskDetailsScreen> createState() => _TaskDetailsScreenState();
}

class _TaskDetailsScreenState extends State<TaskDetailsScreen> {
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late DateTime _selectedDate;
  late TaskPriority _selectedPriority;
  late TaskStatus _selectedStatus;
  bool _isEditing = false; // Par défaut en mode lecture

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedDate = widget.task.dueDate;
    _selectedPriority = widget.task.priority;
    _selectedStatus = widget.task.status;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime(2030),
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: Color(0xFF2563EB),
              surface: Color(0xFF1A1F26),
              onSurface: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) setState(() => _selectedDate = picked);
  }

  void _saveChanges() async {
    if (_titleController.text.isEmpty) return;

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      await ApiService.updateTask(
        id: int.parse(widget.task.id),
        title: _titleController.text,
        content: _descriptionController.text,
        priority: Task.priorityToBackendString(_selectedPriority),
        status: Task.statusToBackendString(_selectedStatus),
        dueDate: _selectedDate,
        color: 'blue',
      );
      Navigator.pop(context); // Fermer le chargement
      ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Tâche mise à jour !"), backgroundColor: Colors.green)
      );
      Navigator.pop(context, true); // Retour au dashboard avec rafraîchissement
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur: $e'), backgroundColor: Colors.red)
      );
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
        title: Text(_isEditing ? "Modifier la tâche" : "Détails",
            style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          // ✨ Bouton d'édition dans l'AppBar
          if (!_isEditing)
            IconButton(
              icon: const Icon(Icons.edit, color: Color(0xFF2563EB)),
              onPressed: () => setState(() => _isEditing = true),
            )
          else
            IconButton(
              icon: const Icon(Icons.close, color: Colors.grey),
              onPressed: () => setState(() => _isEditing = false),
            ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.red),
            onPressed: _showDeleteDialog,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildLabel("Titre de la tâche"),
            _isEditing
                ? _buildTextField(_titleController, "Titre")
                : _buildDisplayBox(_titleController.text),

            const SizedBox(height: 24),
            _buildLabel("Description"),
            _isEditing
                ? _buildTextField(_descriptionController, "Description", maxLines: 4)
                : _buildDisplayBox(_descriptionController.text, maxLines: 4),

            const SizedBox(height: 24),
            _buildLabel("Date d'échéance"),
            _buildDateSelector(),

            const SizedBox(height: 24),
            _buildLabel("Priorité"),
            _buildPrioritySelector(),

            const SizedBox(height: 24),
            _buildLabel("Statut"),
            _buildStatusSelector(),

            const SizedBox(height: 40),
            // ✨ Affiche le bouton Sauvegarder uniquement en mode édition
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text("Sauvegarder les modifications",
                      style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)),
    );
  }

  Widget _buildDisplayBox(String text, {int maxLines = 1}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12)),
      child: Text(text.isEmpty ? "Aucun contenu" : text, style: const TextStyle(color: Colors.white, fontSize: 14)),
    );
  }

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
        filled: true,
        fillColor: const Color(0xFF1A1F26),
        contentPadding: const EdgeInsets.all(16),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      ),
    );
  }

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: _isEditing ? () => _selectDate(context) : null,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text("${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}", style: const TextStyle(color: Colors.white)),
            Icon(Icons.calendar_today_outlined, color: _isEditing ? const Color(0xFF2563EB) : Colors.grey[600], size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildPrioritySelector() {
    return Row(
      children: [
        _priorityItem("Basse", TaskPriority.low, const Color(0xFF10B981), Icons.low_priority),
        const SizedBox(width: 10),
        _priorityItem("Moyenne", TaskPriority.medium, const Color(0xFFF59E0B), Icons.priority_high),
        const SizedBox(width: 10),
        _priorityItem("Haute", TaskPriority.high, const Color(0xFFEF4444), Icons.report_problem_outlined),
      ],
    );
  }

  Widget _priorityItem(String label, TaskPriority priority, Color color, IconData icon) {
    bool isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: _isEditing ? () => setState(() => _selectedPriority = priority) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            color: isSelected ? color.withOpacity(0.1) : const Color(0xFF1A1F26),
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? color : Colors.transparent, width: 2),
          ),
          child: Column(
            children: [
              Icon(icon, color: isSelected ? color : Colors.grey[600], size: 24),
              const SizedBox(height: 8),
              Text(label, style: TextStyle(color: isSelected ? color : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final List<Map<String, dynamic>> statuses = [
      {'label': 'À faire', 'value': TaskStatus.todo},
      {'label': 'En cours', 'value': TaskStatus.inProgress},
      {'label': 'Terminé', 'value': TaskStatus.completed},
      {'label': 'En attente', 'value': TaskStatus.pending},
      {'label': 'Annulé', 'value': TaskStatus.cancelled},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: statuses.map((s) {
          bool isSelected = _selectedStatus == s['value'];
          return GestureDetector(
            onTap: _isEditing ? () => setState(() => _selectedStatus = s['value']) : null,
            child: Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Text(
                s['label'],
                style: TextStyle(color: isSelected ? Colors.white : Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  void _showDeleteDialog() {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        backgroundColor: const Color(0xFF1A1F26),
        title: const Text("Supprimer ?", style: TextStyle(color: Colors.white)),
        content: const Text("Voulez-vous vraiment supprimer cette tâche ?", style: TextStyle(color: Colors.grey)),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")),
          TextButton(
            onPressed: () async {
              await ApiService.deleteTask(int.parse(widget.task.id));
              if (mounted) {
                Navigator.pop(context);
                Navigator.pop(context, true);
              }
            },
            child: const Text("Supprimer", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}