import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({Key? key}) : super(key: key);

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailController = TextEditingController();
  final TextEditingController _tokenController = TextEditingController();
  bool _isLoading = false;
  String? _message;
  bool _isError = false;
  bool _isSent = false;

  @override
  void dispose() {
    _emailController.dispose();
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _requestReset() async {
    if (_emailController.text.isEmpty) {
      setState(() {
        _message = "Veuillez entrer votre email";
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
        _message = "Si cet email existe, vous allez recevoir un code de récupération.";
        _isError = false;
        _isSent = true;
      });
    } catch (e) {
      setState(() {
        _message = "Une erreur est survenue. Veuillez réessayer.";
        _isError = true;
      });
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _goToResetPassword() {
    if (_tokenController.text.isEmpty) {
      setState(() {
        _message = "Veuillez coller le code/jeton reçu par email";
        _isError = true;
      });
      return;
    }
    // On navigue vers l'écran de réinitialisation en passant le token
    Navigator.pushNamed(
      context, 
      '/reset-password', 
      arguments: {'token': _tokenController.text}
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
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              _isSent ? "Vérifiez vos emails" : "Mot de passe oublié ?",
              style: const TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Text(
              _isSent 
                ? "Collez ci-dessous le jeton de sécurité que vous avez reçu par email."
                : "Entrez votre adresse email pour recevoir un lien de réinitialisation.",
              style: TextStyle(color: Colors.grey[500], fontSize: 16),
            ),
            const SizedBox(height: 40),
            
            if (_message != null)
              Container(
                padding: const EdgeInsets.all(12),
                margin: const EdgeInsets.only(bottom: 20),
                decoration: BoxDecoration(
                  color: _isError ? Colors.red.withOpacity(0.1) : Colors.green.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _isError ? Colors.red : Colors.green),
                ),
                child: Text(
                  _message!,
                  style: TextStyle(color: _isError ? Colors.red : Colors.green, fontSize: 14),
                ),
              ),

            if (!_isSent) ...[
              const Text("Email", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("votre@email.com", Icons.email_outlined),
              ),
              const SizedBox(height: 30),
              
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
                      ? const CircularProgressIndicator(color: Colors.white)
                      : const Text("Envoyer le lien", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
            ] else ...[
              const Text("Jeton de sécurité", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              TextField(
                controller: _tokenController,
                style: const TextStyle(color: Colors.white),
                decoration: _inputDecoration("Collez le jeton ici...", Icons.security),
              ),
              const SizedBox(height: 30),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: _goToResetPassword,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                  child: const Text("Continuer", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
                ),
              ),
              TextButton(
                onPressed: () => setState(() => _isSent = false),
                child: const Center(child: Text("Renvoyer l'email", style: TextStyle(color: Colors.grey))),
              )
            ],
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(String hint, IconData icon) {
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14),
      suffixIcon: Icon(icon, color: Colors.grey[700], size: 20),
      filled: true,
      fillColor: const Color(0xFF1A1F26),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
      enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2F36))),
    );
  }
}
