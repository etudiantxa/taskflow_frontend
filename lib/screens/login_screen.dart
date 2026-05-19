import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import '../services/auth_service.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({Key? key}) : super(key: key);

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late TextEditingController _usernameController;
  late TextEditingController _passwordController;
  bool _isLoading = false;
  String? _errorMessage;

  // ✨ Configuration Google Sign-In compatible WEB et ANDROID
  final GoogleSignIn _googleSignIn = GoogleSignIn(
    // Indispensable pour le WEB
    clientId: '1001312901323-lc814c59bk011tpu982gl6e7vkm3f8lr.apps.googleusercontent.com',
    // Indispensable pour le Backend NestJS
    serverClientId: '1001312901323-lc814c59bk011tpu982gl6e7vkm3f8lr.apps.googleusercontent.com',
    scopes: ['email', 'profile'],
  );

  @override
  void initState() {
    super.initState();
    _usernameController = TextEditingController();
    _passwordController = TextEditingController();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_usernameController.text.isEmpty || _passwordController.text.isEmpty) {
      setState(() => _errorMessage = 'Veuillez remplir tous les champs');
      return;
    }
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      await AuthService.login(username: _usernameController.text, password: _passwordController.text);
      if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
    } catch (e) {
      setState(() => _errorMessage = 'Identifiants incorrects');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _loginWithGoogle() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final GoogleSignInAccount? googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        setState(() => _isLoading = false);
        return;
      }
      final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
      final String? idToken = googleAuth.idToken;

      if (idToken != null) {
        await AuthService.loginWithGoogle(idToken);
        if (mounted) Navigator.of(context).pushNamedAndRemoveUntil('/dashboard', (route) => false);
      }
    } catch (e) {
      print('❌ Erreur Google Sign-In: $e');
      setState(() => _errorMessage = 'Échec de la connexion Google.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0F1419),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            children: [
              const SizedBox(height: 60),
              _buildLogo(),
              const SizedBox(height: 30),
              _buildHeaderImage(),
              const SizedBox(height: 30),
              _buildWelcomeText(),
              const SizedBox(height: 30),
              if (_errorMessage != null) _buildError(),
              _buildField("Nom d'utilisateur", _usernameController, "votre_utilisateur", Icons.person_outline),
              const SizedBox(height: 20),
              _buildPasswordField(),
              const SizedBox(height: 30),
              _buildLoginButton(),
              const SizedBox(height: 25),
              const Text("OR CONTINUE WITH", style: TextStyle(color: Colors.grey, fontSize: 11, letterSpacing: 1)),
              const SizedBox(height: 25),
              _socialButton("Continue with Google", Icons.g_mobiledata, onTap: _isLoading ? null : _loginWithGoogle),
              const SizedBox(height: 30),
              _buildRegisterLink(),
              const SizedBox(height: 40),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogo() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: const Color(0xFF2563EB).withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.check_circle_outline, color: Color(0xFF2563EB), size: 28)),
    const SizedBox(width: 10),
    const Text("TaskFlow", style: TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold)),
  ]);

  Widget _buildHeaderImage() => Container(height: 180, decoration: BoxDecoration(borderRadius: BorderRadius.circular(16), image: const DecorationImage(image: NetworkImage('https://images.unsplash.com/photo-1484480974693-6ca0a78fb36b?q=80&w=500&auto=format&fit=crop'), fit: BoxFit.cover)));

  Widget _buildWelcomeText() => Column(children: [
    const Text("Welcome Back", style: TextStyle(color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold)),
    const SizedBox(height: 8),
    Text("Login to manage your tasks efficiently", style: TextStyle(color: Colors.grey[500], fontSize: 14)),
  ]);

  Widget _buildError() => Padding(padding: const EdgeInsets.only(bottom: 10), child: Text(_errorMessage!, style: const TextStyle(color: Colors.red, fontSize: 13)));

  Widget _buildField(String label, TextEditingController controller, String hint, IconData icon) => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Text(label, style: const TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
    const SizedBox(height: 8),
    TextField(controller: controller, style: const TextStyle(color: Colors.white), decoration: _inputDecoration(hint, icon)),
  ]);

  Widget _buildPasswordField() => Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
      const Text("Password", style: TextStyle(color: Colors.white, fontSize: 13, fontWeight: FontWeight.w500)),
      GestureDetector(onTap: () => Navigator.pushNamed(context, '/forgot-password'), child: const Text("Forgot Password?", style: TextStyle(color: Color(0xFF2563EB), fontSize: 12))),
    ]),
    const SizedBox(height: 8),
    TextField(controller: _passwordController, obscureText: true, style: const TextStyle(color: Colors.white), decoration: _inputDecoration("********", Icons.lock_outline)),
  ]);

  Widget _buildLoginButton() => SizedBox(width: double.infinity, height: 52, child: ElevatedButton(onPressed: _isLoading ? null : _login, style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFF2563EB), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))), child: _isLoading ? const CircularProgressIndicator(color: Colors.white) : const Text("Sign In", style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold))));

  Widget _buildRegisterLink() => Row(mainAxisAlignment: MainAxisAlignment.center, children: [
    const Text("Don't have an account? ", style: TextStyle(color: Colors.grey)),
    GestureDetector(onTap: () => Navigator.pushNamed(context, '/register'), child: const Text("Create one for free", style: TextStyle(color: Color(0xFF2563EB), fontWeight: FontWeight.bold))),
  ]);

  InputDecoration _inputDecoration(String hint, IconData icon) => InputDecoration(hintText: hint, hintStyle: TextStyle(color: Colors.grey[700], fontSize: 14), suffixIcon: Icon(icon, color: Colors.grey[700], size: 20), filled: true, fillColor: const Color(0xFF1A1F26), contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14), border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: const BorderSide(color: Color(0xFF2A2F36))));

  Widget _socialButton(String label, IconData icon, {VoidCallback? onTap}) => GestureDetector(onTap: onTap, child: Container(width: double.infinity, padding: const EdgeInsets.symmetric(vertical: 14), decoration: BoxDecoration(color: const Color(0xFF1A1F26), borderRadius: BorderRadius.circular(12), border: Border.all(color: const Color(0xFF2A2F36))), child: Row(mainAxisAlignment: MainAxisAlignment.center, children: [Icon(icon, color: Colors.white, size: 24), const SizedBox(width: 12), Text(label, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w600))])));
}
