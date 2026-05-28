import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _message = "Veuillez entrer votre adresse email";
        _isError = true;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _message = null;
    });

    try {
      await AuthService.forgotPassword(_emailController.text);
      setState(() {
        _message = "Lien envoyé ! Vérifiez votre boîte de réception.";
        _isError = false;
      });
    } catch (e) {
      setState(() {
        _message = "Impossible d'envoyer l'email. Réessayez plus tard.";
        _isError = true;
      });
    } finally {
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
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text("Connexion", style: TextStyle(color: Colors.grey, fontSize: 13)),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 30),
        child: Column(
          children: [
            const SizedBox(height: 20),
            // ✨ TaskFlow Pro Header
            const Text(
              "TaskFlow Pro",
              style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold, fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            // ✨ Icone Header (Cercle avec cadenas)
            Center(
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A1F26),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: const Icon(Icons.lock_reset_rounded, color: Color(0xFF2563EB), size: 40),
              ),
            ),
            const SizedBox(height: 40),
            
            // Titre et Sous-titre
            const Text(
              "Mot de passe oublié ?",
              style: TextStyle(color: Colors.white, fontSize: 26, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              "Ne vous inquiétez pas, cela arrive. Entrez votre adresse e-mail pour recevoir les instructions de réinitialisation.",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.grey[500], fontSize: 14, height: 1.5),
            ),
            const SizedBox(height: 40),

            if (_message != null)
              _statusMessage(_message!, _isError ? Colors.red : Colors.green),

            // Champ Email
            const Align(
              alignment: Alignment.centerLeft,
              child: Text("Adresse e-mail", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
            ),
            const SizedBox(height: 10),
            TextField(
              controller: _emailController,
              style: const TextStyle(color: Colors.white),
              decoration: _inputDecoration("nom@exemple.com", Icons.email_outlined),
            ),
            
            const SizedBox(height: 30),

            // Bouton Envoyer
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _requestReset,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF2563EB),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                ),
                child: _isLoading
                    ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                    : const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Envoyer le lien", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                          SizedBox(width: 10),
                          Icon(Icons.arrow_forward_rounded, color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),

            const SizedBox(height: 40),
            const Text("ou", style: TextStyle(color: Colors.grey, fontSize: 12)),
            const SizedBox(height: 20),

            // Retour Login
            GestureDetector(
              onTap: () => Navigator.pop(context),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.chevron_left, color: Color(0xFF2563EB), size: 20),
                  Text("Retour à la connexion", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold)),
                ],
              ),
            ),

            const SizedBox(height: 60),
            Text(
              "© 2024 TaskFlow Pro — Sécurisé par cryptage AES-256",
              style: TextStyle(color: Colors.grey[800], fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _statusMessage(String text, Color color) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.only(bottom: 25),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.3))
      ),
      child: Text(text, style: TextStyle(color: color, fontSize: 13), textAlign: TextAlign.center),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
      suffixIcon: Icon(icon, color: Colors.grey[700], size: 20),
      filled: true,
      fillColor: const Color(0xFF1A1F26),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2F36))),
    );
  }
}
