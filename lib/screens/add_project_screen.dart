import 'package:flutter/material.dart';
import '../models/project.dart';
import '../models/user.dart';
import '../services/profile_service.dart';

class AddProjectScreen extends StatefulWidget {
  const AddProjectScreen({Key? key}) : super(key: key);

  @override
  State<AddProjectScreen> createState() => _AddProjectScreenState();
}

class _AddProjectScreenState extends State<AddProjectScreen> {
  final TextEditingController _titleController = TextEditingController();
  final TextEditingController _clientController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  
  DateTime? _selectedDate;
  String _selectedPriority = 'Haute';
  String _selectedStatus = 'Actif';
  
  List<User> _availableUsers = [];
  List<User> _selectedMembers = [];
  bool _isFetchingUsers = false;

  @override
  void initState() {
    super.initState();
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
      setState(() => _isFetchingUsers = false);
    }
  }

  Future<void> _selectDate(BuildContext context) async {
    final DateTime? picked = await showDatePicker(
      context: context,
      initialDate: DateTime.now().add(const Duration(days: 7)),
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
    if (picked != null) setState(() => _selectedDate = picked);
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
        title: const Text("Nouveau Projet", style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        actions: [
          IconButton(onPressed: () {}, icon: const Icon(Icons.settings_outlined, color: Colors.grey)),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 20),
            _buildLabel("Titre du Projet"),
            _buildTextField(_titleController, "ex: Refonte Site E-commerce"),
            const SizedBox(height: 24),
            _buildLabel("Nom du Client"),
            _buildTextField(_clientController, "Chercher un client...", suffixIcon: Icons.person_search_outlined),
            const SizedBox(height: 24),
            _buildLabel("Description"),
            _buildTextField(_descriptionController, "Décrivez les objectifs et les livrables...", maxLines: 4),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Statut"),
                      _buildStatusSelector(),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel("Échéance"),
                      _buildDatePicker(),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildLabel("Membres de l'équipe"),
                TextButton(onPressed: () {}, child: const Text("Voir tout", style: TextStyle(color: Color(0xFF2563EB), fontSize: 12))),
              ],
            ),
            _buildMemberSelector(),
            const SizedBox(height: 24),
            _buildLabel("Priorité"),
            _buildPrioritySelector(),
            const SizedBox(height: 40),
            _buildCreateButton(),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String text) => Padding(
    padding: const EdgeInsets.only(bottom: 10),
    child: Text(text, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600)),
  );

  Widget _buildTextField(TextEditingController controller, String hint, {int maxLines = 1, IconData? suffixIcon}) {
    return TextField(
      controller: controller,
      maxLines: maxLines,
      style: const TextStyle(color: Colors.white, fontSize: 14),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
        suffixIcon: suffixIcon != null ? Icon(suffixIcon, color: Colors.grey[700], size: 20) : null,
        filled: true,
        fillColor: const Color(0xFF1A1F26),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _buildStatusSelector() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12)),
      child: const Center(
        child: Text("Actif", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 14)),
      ),
    );
  }

  Widget _buildDatePicker() {
    return GestureDetector(
      onTap: () => _selectDate(context),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(12)),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              _selectedDate == null ? "jj/mm/aaaa" : "${_selectedDate!.day}/${_selectedDate!.month}/${_selectedDate!.year}",
              style: TextStyle(color: _selectedDate == null ? Colors.grey[400] : Colors.black, fontSize: 13),
            ),
            const Icon(Icons.calendar_today_outlined, color: Colors.grey, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildMemberSelector() {
    return Row(
      children: [
        GestureDetector(
          onTap: () {}, // Selection logic
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: Colors.grey[800]!, style: BorderStyle.solid, width: 1),
            ),
            child: const Icon(Icons.add, color: Colors.grey, size: 20),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: SizedBox(
            height: 44,
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: 4, // Dummy count
              itemBuilder: (context, i) {
                return Align(
                  widthFactor: 0.8,
                  child: Stack(
                    children: [
                      CircleAvatar(
                        radius: 22,
                        backgroundColor: const Color(0xFF1A1F26),
                        backgroundImage: NetworkImage('https://i.pravatar.cc/150?u=$i'),
                      ),
                      if (i == 0)
                        Positioned(
                          right: 0, top: 0,
                          child: Container(
                            padding: const EdgeInsets.all(2),
                            decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                            child: const Icon(Icons.check, color: Colors.white, size: 10),
                          ),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPrioritySelector() {
    final priorities = ['Haute', 'Moyenne', 'Basse'];
    return Row(
      children: priorities.map((p) {
        bool isSelected = _selectedPriority == p;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _selectedPriority = p),
            child: Container(
              margin: EdgeInsets.only(right: p == 'Basse' ? 0 : 12),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: isSelected ? const Color(0xFF2563EB).withOpacity(0.1) : const Color(0xFF1A1F26),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: isSelected ? const Color(0xFF2563EB) : Colors.transparent),
              ),
              child: Center(
                child: Text(p, style: TextStyle(color: isSelected ? const Color(0xFF2563EB) : Colors.grey, fontSize: 12, fontWeight: FontWeight.w600)),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCreateButton() {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: ElevatedButton(
        onPressed: () {},
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFB4C6FC), // Matching the light blue in the image
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          elevation: 0,
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_circle_outline, color: Color(0xFF1E3A8A), size: 20),
            SizedBox(width: 10),
            Text("Créer le projet", style: TextStyle(color: Color(0xFF1E3A8A), fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
      ),
    );
  }
}
