import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../models/user.dart';
import '../models/task.dart';
import '../services/auth_service.dart';
import '../services/session_service.dart';
import '../services/profile_service.dart';
import '../services/api_service.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({Key? key}) : super(key: key);

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  User? _currentUser;
  bool _isLoading = true;
  bool _isEditing = false;
  bool _isSaving = false;

  int _completedCount = 0;
  int _pendingCount = 0;

  late TextEditingController _nomController;
  late TextEditingController _prenomController;
  late TextEditingController _emailController;
  late TextEditingController _usernameController;
  late TextEditingController _photoController;

  XFile? _pickedXFile;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    _nomController = TextEditingController();
    _prenomController = TextEditingController();
    _emailController = TextEditingController();
    _usernameController = TextEditingController();
    _photoController = TextEditingController();
    _loadData();
  }

  @override
  void dispose() {
    _nomController.dispose();
    _prenomController.dispose();
    _emailController.dispose();
    _usernameController.dispose();
    _photoController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    if (!mounted) return;
    setState(() => _isLoading = true);
    try {
      final user = await SessionService.getUser();
      final result = await ApiService.getAllTasks(limit: 1000);
      final List<Task> tasks = (result['tasks'] as List).cast<Task>();

      if (mounted) {
        setState(() {
          if (user != null) {
            _currentUser = user;
            _nomController.text = user.nom;
            _prenomController.text = user.prenom;
            _emailController.text = user.email;
            _usernameController.text = user.username;
            _photoController.text = user.photo ?? '';
          }
          
          _completedCount = tasks.where((t) => t.status == TaskStatus.completed).length;
          _pendingCount = tasks.where((t) => 
            t.status == TaskStatus.todo || 
            t.status == TaskStatus.inProgress || 
            t.status == TaskStatus.pending
          ).length;
          
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 50,
      );
      if (image != null) {
        setState(() {
          _pickedXFile = image;
          _isEditing = true;
        });
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Erreur d'accès à la galerie"))
      );
    }
  }

  Future<void> _handleSave() async {
    if (_emailController.text.isEmpty || _nomController.text.isEmpty || 
        _prenomController.text.isEmpty || _usernameController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Tous les champs sont obligatoires"))
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      String? photoData = _currentUser?.photo;
      
      if (_pickedXFile != null) {
        final bytes = await _pickedXFile!.readAsBytes();
        photoData = base64Encode(bytes);
      }

      final updatedUser = await ProfileService.updateProfile(
        nom: _nomController.text.trim(),
        prenom: _prenomController.text.trim(),
        email: _emailController.text.trim(),
        username: _usernameController.text.trim(),
        photo: photoData,
      );
      
      await SessionService.saveUser(updatedUser);
      
      if (mounted) {
        setState(() {
          _currentUser = updatedUser;
          _pickedXFile = null;
          _isEditing = false;
          _isSaving = false;
        });
        
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Profil mis à jour !"), backgroundColor: Colors.green)
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Erreur Backend : $e"), backgroundColor: Colors.red)
        );
      }
    }
  }

  void _showComingSoon() {
    ScaffoldMessenger.of(context).clearSnackBars();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Cette fonctionnalité sera implémentée plus tard"),
        duration: Duration(seconds: 2),
        backgroundColor: Color(0xFF2563EB),
      ),
    );
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
          onPressed: () => Navigator.of(context).pushReplacementNamed('/dashboard'),
        ),
        title: const Text("Profil", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.more_vert, color: Colors.white), onPressed: () {}),
        ],
      ),
      body: _isLoading 
        ? const Center(child: CircularProgressIndicator(color: Color(0xFF2563EB))) 
        : SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Column(
              children: [
                const SizedBox(height: 10),
                _buildAvatarSection(),
                const SizedBox(height: 20),
                
                if (!_isEditing) ...[
                  Text(_currentUser?.fullName ?? "", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.bold)),
                  Text(_currentUser?.email ?? "", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
                ] else ...[
                  _buildEditField("Prénom", _prenomController),
                  _buildEditField("Nom", _nomController),
                  _buildEditField("Nom d'utilisateur", _usernameController),
                  _buildEditField("Email", _emailController, keyboardType: TextInputType.emailAddress),
                ],

                const SizedBox(height: 24),
                _buildMainButton(),
                
                if (_isEditing) 
                  TextButton(
                    onPressed: () { setState(() { _isEditing = false; _pickedXFile = null; _loadData(); }); },
                    child: const Text("Annuler", style: TextStyle(color: Colors.grey))
                  ),
                
                const SizedBox(height: 32),
                Row(
                  children: [
                    _buildStatCard("Tâches terminées", "$_completedCount", Icons.check_circle, const Color(0xFF2563EB)),
                    const SizedBox(width: 16),
                    _buildStatCard("En attente", "$_pendingCount", Icons.assignment_late, const Color(0xFFF59E0B)),
                  ],
                ),
                
                const SizedBox(height: 32),
                const Align(
                  alignment: Alignment.centerLeft,
                  child: Text("Paramètres", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
                const SizedBox(height: 16),
                
                _buildMenuItem(Icons.notifications_none, "Notifications", onTap: () => Navigator.pushNamed(context, '/notifications')),
                _buildMenuItem(Icons.palette_outlined, "Apparence", onTap: _showComingSoon),
                _buildMenuItem(Icons.security_outlined, "Sécurité", onTap: _showComingSoon),
                _buildMenuItem(Icons.help_outline, "Aide & Support", onTap: _showComingSoon),
                
                const SizedBox(height: 24),
                _buildLogoutButton(),
                const SizedBox(height: 40),
              ],
            ),
          ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildAvatarSection() {
    ImageProvider avatarImage;
    if (_pickedXFile != null) {
      avatarImage = kIsWeb ? NetworkImage(_pickedXFile!.path) : FileImage(File(_pickedXFile!.path)) as ImageProvider;
    } else if (_currentUser?.photo != null && _currentUser!.photo!.isNotEmpty) {
      if (_currentUser!.photo!.startsWith('http')) {
        avatarImage = NetworkImage(_currentUser!.photo!);
      } else {
        try {
          avatarImage = MemoryImage(base64Decode(_currentUser!.photo!));
        } catch (e) {
          avatarImage = NetworkImage('https://ui-avatars.com/api/?name=${_currentUser?.nom ?? "U"}&background=random');
        }
      }
    } else {
      avatarImage = NetworkImage('https://ui-avatars.com/api/?name=${_currentUser?.nom ?? "U"}&background=random');
    }

    return Center(
      child: GestureDetector(
        onTap: _pickImage,
        child: Stack(
          alignment: Alignment.center,
          children: [
            Container(
              width: 120, height: 120,
              decoration: BoxDecoration(
                color: const Color(0xFFFDE68A).withOpacity(0.15),
                shape: BoxShape.circle,
              ),
            ),
            CircleAvatar(
              radius: 50,
              backgroundColor: const Color(0xFF1A1F26),
              backgroundImage: avatarImage,
            ),
            Positioned(
              right: 4,
              bottom: 4,
              child: Container(
                padding: const EdgeInsets.all(6),
                decoration: const BoxDecoration(color: Color(0xFF2563EB), shape: BoxShape.circle),
                child: const Icon(Icons.camera_alt, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMainButton() {
    return ElevatedButton(
      onPressed: () => _isEditing ? _handleSave() : setState(() => _isEditing = true),
      style: ElevatedButton.styleFrom(
        backgroundColor: _isEditing ? Colors.green : const Color(0xFF2563EB),
        minimumSize: const Size(200, 48),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(30)),
      ),
      child: _isSaving 
        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
        : Text(_isEditing ? "Enregistrer" : "Modifier le profil", 
            style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
    );
  }

  Widget _buildEditField(String label, TextEditingController controller, {TextInputType? keyboardType}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: controller,
        style: const TextStyle(color: Colors.white, fontSize: 14),
        keyboardType: keyboardType,
        decoration: InputDecoration(
          labelText: label,
          labelStyle: const TextStyle(color: Colors.grey),
          enabledBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.white10)),
          focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Color(0xFF2563EB))),
        ),
      ),
    );
  }

  Widget _buildStatCard(String label, String count, IconData icon, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(16)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color, size: 18),
                const SizedBox(width: 8),
                Expanded(child: Text(label, style: const TextStyle(color: Colors.grey, fontSize: 11, fontWeight: FontWeight.w500))),
              ],
            ),
            const SizedBox(height: 12),
            Text(count, style: const TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuItem(IconData icon, String title, {VoidCallback? onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12)),
      child: ListTile(
        leading: Icon(icon, color: Colors.grey[400], size: 22),
        title: Text(title, style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w500)),
        trailing: const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
        onTap: onTap,
      ),
    );
  }

  Widget _buildLogoutButton() {
    return GestureDetector(
      onTap: () async {
        await AuthService.logout();
        if (mounted) Navigator.pushNamedAndRemoveUntil(context, '/login', (route) => false);
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 16),
        decoration: BoxDecoration(
          color: const Color(0xFFEF4444).withOpacity(0.1),
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.logout, color: Color(0xFFEF4444), size: 20),
            const SizedBox(width: 10),
            Text("Déconnexion", style: TextStyle(color: Color(0xFFEF4444), fontWeight: FontWeight.bold)),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav() {
    return BottomAppBar(
      color: const Color(0xFF0F1419),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _navItem(Icons.check_circle_outline, "Tâches", false, () => Navigator.pushReplacementNamed(context, '/dashboard')),
          _navItem(Icons.calendar_today_outlined, "Calendrier", false, () {}),
          _navItem(Icons.folder_open_outlined, "Projets", false, () {}),
          _navItem(Icons.person, "Profil", true, () {}),
        ],
      ),
    );
  }

  Widget _navItem(IconData icon, String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600], size: 22),
          const SizedBox(height: 4),
          Text(label, style: TextStyle(color: isSelected ? const Color(0xFF2563EB) : Colors.grey[600], fontSize: 10)),
        ],
      ),
    );
  }
}
