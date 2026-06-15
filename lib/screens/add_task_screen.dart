import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';

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
  
  List<User> _availableUsers = [];
  List<User> _selectedUsers = []; 
  bool _isFetchingUsers = false;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    setState(() => _isFetchingUsers = true);
    try {
      final users = await ProfileService.getAllUsers();
      setState(() {
        _availableUsers = users;
        _isFetchingUsers = false;
      });
    } catch (e) {
      debugPrint('❌ Erreur chargement utilisateurs: $e');
      setState(() => _isFetchingUsers = false);
    }
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
      lastDate: DateTime(2101),
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
    if (picked != null && picked != _selectedDate) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  void _createTask() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Veuillez donner un titre")));
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez assigner au moins un collaborateur"), backgroundColor: Colors.orange),
      );
      return;
    }

    showDialog(context: context, barrierDismissible: false, builder: (c) => const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))));

    try {
      await ApiService.createTask(
        title: _titleController.text.trim(),
        content: _descriptionController.text.trim(),
        priority: _selectedPriority.name.capitalize(),
        status: Task.statusToBackendString(_selectedStatus),
        dueDate: _selectedDate,
        color: 'blue',
        assignedUserIds: _selectedUsers.map((u) => u.id).toList(),
      );
      Navigator.pop(context); 
      Navigator.pop(context, true); 
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
        title: const Text("Nouvelle tâche", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildLabel("Titre"),
            _buildTextField(_titleController, "ex: Réunion de design"),
            const SizedBox(height: 24),
            _buildLabel("Description"),
            _buildTextField(_descriptionController, "Détails...", maxLines: 3),
            const SizedBox(height: 24),
            _buildLabel("Date d'échéance"),
            _buildDateSelector(),
            const SizedBox(height: 24),
            _buildLabel("Assigner à *"), 
            _buildAssigneeSelector(),
            const SizedBox(height: 24),
            _buildLabel("Priorité"),
            _buildPrioritySelector(),
            const SizedBox(height: 24),
            _buildLabel("Statut"),
            _buildStatusSelector(),
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity, height: 54,
              child: ElevatedButton(
                onPressed: _createTask,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))),
                child: const Text("Créer la tâche", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600)));

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) => TextField(controller: controller, maxLines: maxLines, style: const TextStyle(color: Colors.white), decoration: InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey[700]), filled: true, fillColor: const Color(0xFF1A1F26), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none)));

  Widget _buildDateSelector() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null 
                ? "Sélectionner une date" 
                : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              style: const TextStyle(color: Colors.white),
            ),
            const Icon(Icons.calendar_today_outlined, color: Color(0xFF2563EB), size: 20),
          ],
        ),
      ),
    );
  }

  Widget _buildAssigneeSelector() {
    return Row(
      children: [
        GestureDetector(
          onTap: _showUserSelectionSheet,
          child: Container(
            width: 45, height: 45,
            decoration: BoxDecoration(shape: BoxShape.circle, border: Border.all(color: Colors.grey[800]!, width: 1)),
            child: const Icon(Icons.add, color: Colors.grey, size: 22),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _selectedUsers.isEmpty 
            ? const Text("Aucun sélectionné", style: TextStyle(color: Colors.grey, fontSize: 12))
            : SizedBox(
                height: 45,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  itemCount: _selectedUsers.length,
                  itemBuilder: (context, i) {
                    final user = _selectedUsers[i];
                    final initials = "${user.prenom.isNotEmpty ? user.prenom[0] : ''}${user.nom.isNotEmpty ? user.nom[0] : ''}".toUpperCase();
                    final colors = [const Color(0xFF3B82F6), const Color(0xFFA855F7), const Color(0xFF10B981), const Color(0xFFF59E0B)];
                    return Align(
                      widthFactor: 0.6, // ✨ Correction du crash : chevauchement sans marge négative
                      alignment: Alignment.centerLeft,
                      child: Container(
                        width: 45, height: 45,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle, 
                          color: colors[i % colors.length], 
                          border: Border.all(color: const Color(0xFF0F1419), width: 2)
                        ),
                        child: Center(child: Text(initials, style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold))),
                      ),
                    );
                  },
                ),
              ),
        ),
      ],
    );
  }

  void _showUserSelectionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1A1F26),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) => StatefulBuilder(builder: (context, setModalState) {
        return Container(
          padding: const EdgeInsets.all(20),
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            children: [
              Container(width: 40, height: 4, decoration: BoxDecoration(color: Colors.grey[800], borderRadius: BorderRadius.circular(2))),
              const SizedBox(height: 20),
              const Text("Sélectionner les collaborateurs", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 20),
              if (_isFetchingUsers)
                const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))))
              else if (_availableUsers.isEmpty)
                const Expanded(child: Center(child: Text("Aucun utilisateur trouvé sur le serveur", style: TextStyle(color: Colors.grey))))
              else
                Expanded(
                  child: ListView.builder(
                    itemCount: _availableUsers.length,
                    itemBuilder: (context, i) {
                      final user = _availableUsers[i];
                      final isChecked = _selectedUsers.any((u) => u.id == user.id);
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: const Color(0xFF2563EB),
                          child: Text(user.prenom.isNotEmpty ? user.prenom[0] : 'U', style: const TextStyle(color: Colors.white)),
                        ),
                        title: Text(user.fullName, style: const TextStyle(color: Colors.white)),
                        subtitle: Text(user.email, style: const TextStyle(color: Colors.grey, fontSize: 11)),
                        trailing: Checkbox(
                          value: isChecked,
                          activeColor: const Color(0xFF2563EB),
                          onChanged: (val) {
                            setState(() {
                              if (val == true) _selectedUsers.add(user);
                              else _selectedUsers.removeWhere((u) => u.id == user.id);
                            });
                            setModalState(() {}); 
                          },
                        ),
                      );
                    },
                  ),
                ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 50,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB)),
                  child: const Text("Valider la sélection", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
            ],
          ),
        );
      }),
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
          decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.1) : const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? color : Colors.transparent, width: 2)),
          child: Column(children: [Icon(icon, color: isSelected ? color : Colors.grey[600], size: 24), const SizedBox(height: 8), Text(label, style: TextStyle(color: isSelected ? color : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold))]),
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final List<Map<String, dynamic>> statuses = [{'label': 'À faire', 'value': TaskStatus.todo}, {'label': 'En cours', 'value': TaskStatus.inProgress}, {'label': 'Terminé', 'value': TaskStatus.completed}, {'label': 'Annulé', 'value': TaskStatus.cancelled}];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: statuses.map((s) { bool isSelected = _selectedStatus == s['value']; return GestureDetector(onTap: () => setState(() => _selectedStatus = s['value']), child: Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(20)), child: Text(s['label'], style: TextStyle(color: isSelected ? Colors.white : Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)))); }).toList()));
  }
}
