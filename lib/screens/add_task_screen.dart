import 'package:flutter/material.dart';
import '../models/task.dart';
import '../services/api_service.dart';


extension StringExtension on String {
  String capitalize() {
    if (isEmpty) return this;
    return this[0].toUpperCase() + substring(1).toLowerCase();
  }
}

class AddTaskScreen extends StatefulWidget {
  const AddTaskScreen({Key? key}) : super(key: key);

  @override
  State<AddTaskScreen> createState() => _AddTaskScreenState();
}

class _AddTaskScreenState extends State<AddTaskScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  DateTime? _selectedDate;
  TaskPriority _selectedPriority = TaskPriority.medium;
  TaskStatus _selectedStatus = TaskStatus.todo;
  TaskCategory _selectedCategory = TaskCategory.work;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
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
      initialDate: _selectedDate ?? DateTime.now(),
      firstDate: DateTime.now(),
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

  void _createTask() async {
    if (_titleController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez donner un titre à la tâche")),
      );
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator()));

    try {
      await ApiService.createTask(
        title: _titleController.text,
        content: _descriptionController.text,
        priority: _selectedPriority.name.capitalize(),
        status: Task.statusToBackendString(_selectedStatus),
        dueDate: _selectedDate,
        color: 'blue',
      );
      Navigator.pop(context); // Fermer loading
      Navigator.pop(context, true); // Retour au dashboard
    } catch (e) {
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
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
        title: const Text("Nouvelle tâche", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildLabel("Titre de la tâche"),
            _buildTextField(_titleController, "ex: Réunion de design"),

            const SizedBox(height: 24),
            _buildLabel("Description"),
            _buildTextField(_descriptionController, "Ajoutez des détails sur la tâche...", maxLines: 4),

            const SizedBox(height: 24),
            _buildLabel("Date d'échéance"),
            GestureDetector(
              onTap: () => _selectDate(context),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F26),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      _selectedDate == null
                        ? "Sélectionner une date"
                        : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
                      style: TextStyle(color: _selectedDate == null ? Colors.grey[600] : Colors.white),
                    ),
                    Icon(Icons.calendar_today_outlined, color: Colors.grey[600], size: 20),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 24),
            _buildLabel("Priorité"),
            _buildPrioritySelector(),

            const SizedBox(height: 24),
            _buildLabel("Statut"),
            _buildStatusSelector(),

            const SizedBox(height: 24),
            _buildLabel("Catégorie"),
            _buildCategorySelector(),

            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: _createTask,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                child: const Text("Créer la tâche", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
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
        onTap: () => setState(() => _selectedPriority = priority),
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
            onTap: () => setState(() => _selectedStatus = s['value']),
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

  Widget _buildCategorySelector() {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _categoryItem("Travail", TaskCategory.work, Icons.work_outline),
          _categoryItem("Maison", TaskCategory.personal, Icons.home_outlined),
          _categoryItem("Courses", TaskCategory.shopping, Icons.shopping_cart_outlined),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: const BoxDecoration(color: Color(0xFF1A1F26), shape: BoxShape.circle),
            child: const Icon(Icons.add, color: Colors.grey, size: 20),
          ),
        ],
      ),
    );
  }

  Widget _categoryItem(String label, TaskCategory category, IconData icon) {
    bool isSelected = _selectedCategory == category;
    return GestureDetector(
      onTap: () => setState(() => _selectedCategory = category),
      child: Container(
        margin: const EdgeInsets.only(right: 10),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: const Color(0xFF1A1F26),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.transparent),
        ),
        child: Row(
          children: [
            Icon(icon, color: isSelected ? const Color(0xFF2563EB) : Colors.grey[500], size: 16),
            const SizedBox(width: 8),
            Text(label, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[500], fontSize: 13)),
          ],
        ),
      ),
    );
  }
}
