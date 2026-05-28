import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ResetPasswordScreen extends StatefulWidget {
  final String? token;
  const ResetPasswordScreen({Key? key, this.token}) : super(key: key);

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final TextEditingController _passwordController = TextEditingController();
  final TextEditingController _confirmPasswordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;
  
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  String _strengthText = "FAIBLE";
  Color _strengthColor = Colors.grey;

  @override
  void initState() {
    super.initState();
    _passwordController.addListener(_checkPasswordStrength);
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _checkPasswordStrength() {
    final pass = _passwordController.text;
    if (pass.isEmpty) {
      setState(() { _strengthText = "VIDE"; _strengthColor = Colors.grey; });
    } else if (pass.length < 6) {
      setState(() { _strengthText = "FAIBLE"; _strengthColor = Colors.red; });
    } else if (pass.length < 10) {
      setState(() { _strengthText = "MOYENNE"; _strengthColor = Colors.orange; });
    } else {
      setState(() { _strengthText = "FORTE"; _strengthColor = Colors.green; });
    }
  }

  Future<void> _resetPassword() async {
    final String? token = widget.token;

    if (token == null || token.isEmpty) {
      setState(() => _errorMessage = "Lien de réinitialisation invalide ou expiré");
      return;
    }

    if (_passwordController.text.length < 6) {
      setState(() => _errorMessage = "Le mot de passe est trop court");
      return;
    }

    if (_passwordController.text != _confirmPasswordController.text) {
      setState(() => _errorMessage = "Les mots de passe ne correspondent pas");
      return;
    }

    setState(() { _isLoading = true; _errorMessage = null; });

    try {
      await AuthService.resetPassword(token, _passwordController.text);
      setState(() => _isSuccess = true);
      if (mounted) {
        Future.delayed(const Duration(seconds: 2), () {
          Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false);
        });
      }
    } catch (e) {
      setState(() => _errorMessage = "Échec de la réinitialisation. Le lien a peut-être expiré.");
    } finally {
      if (mounted) setState(() => _isLoading = false);
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
          icon: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text("TaskFlow Pro", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.help_outline, color: Colors.grey, size: 22), onPressed: () {}),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), borderRadius: BorderRadius.circular(20)),
                child: const Icon(Icons.rotate_left_rounded, color: Color(0xFF2563EB), size: 40),
              ),
            ),
            const SizedBox(height: 30),
            const Text("Nouveau mot de passe", style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
            const SizedBox(height: 12),
            Text("Choisissez un mot de passe sécurisé pour protéger votre compte TaskFlow Pro.", textAlign: TextAlign.center, style: TextStyle(color: Colors.grey[500], fontSize: 14)),
            const SizedBox(height: 40),

            if (_errorMessage != null) _statusMessage(_errorMessage!, Colors.red),
            if (_isSuccess) _statusMessage("Mot de passe réinitialisé ! Redirection...", Colors.green),

            _buildLabel("Nouveau mot de passe"),
            TextField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("********", _obscurePassword ? Icons.visibility_off : Icons.visibility, () => setState(() => _obscurePassword = !_obscurePassword)),
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: Text("SÉCURITÉ: $_strengthText", style: TextStyle(color: _strengthColor, fontSize: 10, fontWeight: FontWeight.bold)),
            ),
            
            const SizedBox(height: 24),
            _buildLabel("Confirmer le mot de passe"),
            TextField(
              controller: _confirmPasswordController,
              obscureText: _obscureConfirm,
              style: const TextStyle(color: Colors.black),
              decoration: _inputDecoration("********", _obscureConfirm ? Icons.visibility_off : Icons.visibility, () => setState(() => _obscureConfirm = !_obscureConfirm)),
            ),
            
            const SizedBox(height: 40),
            SizedBox(
              width: double.infinity,
              height: 54,
              child: ElevatedButton(
                onPressed: (_isLoading || _isSuccess) ? null : _resetPassword,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                        Text("Réinitialiser le mot de passe", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                        SizedBox(width: 10),
                        Icon(Icons.check_circle_outline, color: Colors.white, size: 20),
                      ]),
              ),
            ),
            const SizedBox(height: 30),
            GestureDetector(
              onTap: () => Navigator.of(context).pushNamedAndRemoveUntil('/login', (route) => false),
              child: const Row(mainAxisAlignment: MainAxisAlignment.center, children: [
                Icon(Icons.arrow_back, color: Colors.grey, size: 16),
                SizedBox(width: 10),
                Text("Retour à la connexion", style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w500)),
              ]),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildLabel(String label) => Align(alignment: Alignment.centerLeft, child: Padding(padding: const EdgeInsets.only(bottom: 10.0), child: Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500))));

  Widget _statusMessage(String text, Color color) => Container(width: double.infinity, padding: const EdgeInsets.all(12), margin: const EdgeInsets.only(bottom: 25), decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(10), border: Border.all(color: color.withOpacity(0.3))), child: Text(text, style: TextStyle(color: color, fontSize: 13), textAlign: TextAlign.center));

  InputDecoration _inputDecoration(String hint, IconData icon, VoidCallback onToggle) => InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14), suffixIcon: IconButton(icon: Icon(icon, color: Colors.grey[400], size: 20), onPressed: onToggle), filled: true, fillColor: Colors.white, contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none));
}
