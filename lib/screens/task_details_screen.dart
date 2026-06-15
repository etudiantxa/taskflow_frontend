import 'package:flutter/material.dart';
import '../models/task.dart';
import '../models/user.dart';
import '../services/api_service.dart';
import '../services/profile_service.dart';
import 'package:intl/intl.dart';

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
  bool _isEditing = false;
  bool _isLoading = false;

  List<User> _availableUsers = [];
  List<User> _selectedUsers = [];
  bool _isFetchingUsers = false;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.task.title);
    _descriptionController = TextEditingController(text: widget.task.description);
    _selectedDate = widget.task.dueDate;
    _selectedPriority = widget.task.priority;
    _selectedStatus = widget.task.status;

    // ✨ Initialiser avec les collaborateurs déjà présents
    _selectedUsers = List.from(widget.task.assignedUsers);
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    if (!mounted) return;
    setState(() => _isFetchingUsers = true);
    try {
      final users = await ProfileService.getAllUsers();
      if (mounted) {
        setState(() {
          _availableUsers = users;
          _isFetchingUsers = false;
        });
      }
    } catch (e) {
      debugPrint('❌ Erreur chargement collaborateurs: $e');
      if (mounted) setState(() => _isFetchingUsers = false);
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
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text("Le titre est obligatoire")));
      return;
    }

    if (_selectedUsers.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Veuillez assigner au moins un collaborateur"), backgroundColor: Colors.orange),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      await ApiService.updateTask(
        id: int.parse(widget.task.id),
        title: _titleController.text.trim(),
        content: _descriptionController.text.trim(),
        priority: Task.priorityToBackendString(_selectedPriority),
        status: Task.statusToBackendString(_selectedStatus),
        dueDate: _selectedDate,
        color: 'blue',
        assignedUserIds: _selectedUsers.map((u) => u.id).toList(),
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Erreur: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    bool isExpired = _selectedStatus == TaskStatus.expired;

    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("Détails de la tâche", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
        actions: [
          if (!_isEditing)
            IconButton(icon: const Icon(Icons.edit, color: Color(0xFF2563EB)), onPressed: () => setState(() => _isEditing = true))
          else
            IconButton(icon: const Icon(Icons.close, color: Colors.grey), onPressed: () => setState(() => _isEditing = false)),
          IconButton(icon: const Icon(Icons.delete_outline, color: Colors.red), onPressed: _showDeleteDialog),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB)))
        : SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isExpired && !_isEditing)
              _buildExpiredBanner(),

            _buildLabel("Titre"),
            _isEditing ? _buildTextField(_titleController, "Titre") : _buildDisplayBox(_titleController.text),
            const SizedBox(height: 24),

            _buildLabel("Description"),
            _isEditing ? _buildTextField(_descriptionController, "Description", maxLines: 4) : _buildDisplayBox(_descriptionController.text, maxLines: 4),
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
            if (_isEditing)
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _saveChanges,
                  style: ElevatedButton.styleFrom(backgroundColor: Colors.green, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                  child: const Text("Sauvegarder les modifications", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildExpiredBanner() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(bottom: 24),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, color: Colors.red, size: 20),
          SizedBox(width: 8),
          Text("Cette tâche a expiré", style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
        ],
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)));

  Widget _buildDisplayBox(String text, {int maxLines = 1}) => Container(
    width: double.infinity,
    padding: const EdgeInsets.all(16),
    decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12)),
    child: Text(
      text.isEmpty ? "Aucun contenu" : text,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      maxLines: maxLines,
    ),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1}) => TextField(
    controller: controller,
    maxLines: maxLines,
    style: const TextStyle(color: Colors.white),
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[700]),
      filled: true,
      fillColor: const Color(0xFF1A1F26),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
    ),
  );

  Widget _buildDateSelector() => GestureDetector(
    onTap: _isEditing ? () => _selectDate(context) : null,
    child: Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12)),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            "${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}",
            style: const TextStyle(color: Colors.white),
          ),
          Icon(Icons.calendar_today_outlined, color: _isEditing ? const Color(0xFF2563EB) : Colors.grey[600], size: 20),
        ],
      ),
    ),
  );

  Widget _buildAssigneeSelector() {
    return Row(
      children: [
        if (_isEditing)
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
              ? const Text("Aucun collaborateur", style: TextStyle(color: Colors.grey, fontSize: 12))
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
                        widthFactor: 0.6, // ✨ Chevauchement sécurisé
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
              if (_isFetchingUsers) const Expanded(child: Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))))
              else if (_availableUsers.isEmpty) const Expanded(child: Center(child: Text("Aucun utilisateur trouvé", style: TextStyle(color: Colors.grey))))
              else Expanded(
                child: ListView.builder(
                  itemCount: _availableUsers.length,
                  itemBuilder: (context, i) {
                    final user = _availableUsers[i];
                    final isChecked = _selectedUsers.any((u) => u.id == user.id);
                    return ListTile(
                      leading: CircleAvatar(backgroundColor: const Color(0xFF2563EB), child: Text(user.prenom.isNotEmpty ? user.prenom[0] : 'U', style: const TextStyle(color: Colors.white))),
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

  Widget _buildPrioritySelector() => Row(children: [
    _priorityItem("Basse", TaskPriority.low, const Color(0xFF10B981), Icons.low_priority),
    const SizedBox(width: 10),
    _priorityItem("Moyenne", TaskPriority.medium, const Color(0xFFF59E0B), Icons.priority_high),
    const SizedBox(width: 10),
    _priorityItem("Haute", TaskPriority.high, const Color(0xFFEF4444), Icons.report_problem_outlined),
  ]);

  Widget _priorityItem(String label, TaskPriority priority, Color color, IconData icon) {
    bool isSelected = _selectedPriority == priority;
    return Expanded(
      child: GestureDetector(
        onTap: _isEditing ? () => setState(() => _selectedPriority = priority) : null,
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(color: isSelected ? color.withOpacity(0.1) : const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12), border: Border.all(color: isSelected ? color : Colors.transparent, width: 2)),
          child: Column(children: [Icon(icon, color: isSelected ? color : Colors.grey[600], size: 24), const SizedBox(height: 8), Text(label, style: TextStyle(color: isSelected ? color : Colors.grey[600], fontSize: 13, fontWeight: FontWeight.bold))]),
        ),
      ),
    );
  }

  Widget _buildStatusSelector() {
    final ss = [{'l': 'À faire', 'v': TaskStatus.todo}, {'l': 'En cours', 'v': TaskStatus.inProgress}, {'l': 'Terminé', 'v': TaskStatus.completed}, {'l': 'Expiré', 'v': TaskStatus.expired}];
    return SingleChildScrollView(scrollDirection: Axis.horizontal, child: Row(children: ss.map((s) { bool isSelected = _selectedStatus == s['v']; return GestureDetector(onTap: _isEditing ? () => setState(() => _selectedStatus = s['v'] as TaskStatus) : null, child: Container(margin: const EdgeInsets.only(right: 12), padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10), decoration: BoxDecoration(color: isSelected ? const Color(0xFF2563EB) : const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(20)), child: Text(s['l'] as String, style: TextStyle(color: isSelected ? Colors.white : Colors.grey[500], fontSize: 13, fontWeight: FontWeight.w600)))); }).toList()));
  }

  void _showDeleteDialog() {
    showDialog(context: context, builder: (context) => AlertDialog(backgroundColor: const Color(0xFF1A1F26), title: const Text("Supprimer ?", style: TextStyle(color: Colors.white)), content: const Text("Voulez-vous vraiment supprimer cette tâche ?", style: TextStyle(color: Colors.grey)), actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Annuler")), TextButton(onPressed: () async { await ApiService.deleteTask(int.parse(widget.task.id)); if (mounted) { Navigator.pop(context); Navigator.pop(context, true); } }, child: const Text("Supprimer", style: TextStyle(color: Colors.red)))]));
  }
}
