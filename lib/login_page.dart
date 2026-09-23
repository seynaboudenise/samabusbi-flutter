import 'package:flutter/material.dart';
import 'dashboard_page.dart';
import 'inscription_page.dart';
import 'services/api_service.dart';

const bleu = Color(0xFF1565C0);
const dark = Color(0xFF17221C);

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _loading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_emailController.text.trim().isEmpty || _passwordController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Veuillez remplir tous les champs.')),
      );
      return;
    }
    setState(() => _loading = true);
    try {
      final result = await ApiService.login(_emailController.text.trim(), _passwordController.text);
      setState(() => _loading = false);
      if (result['success'] == true) {
        if (!mounted) return;
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (_) => const DashboardPage()));
      } else {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(result['erreur'] ?? 'Erreur de connexion.')),
        );
      }
    } catch (e) {
      setState(() => _loading = false);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Impossible de contacter le serveur. Vérifiez votre connexion.')),
      );
    }
  }

  void _connexionIndisponible(String service) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Connexion avec $service — bientôt disponible'), behavior: SnackBarBehavior.floating),
    );
  }

  InputDecoration _decoration({required String hint, required IconData icon, Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: Colors.black45),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF5F7FA),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: bleu, width: 2),
      ),
    );
  }

  Widget _boutonSocial(IconData icon, String label, VoidCallback onTap) => Expanded(
        child: OutlinedButton.icon(
          onPressed: onTap,
          icon: Icon(icon, size: 18, color: dark),
          label: Text(label, style: const TextStyle(color: dark, fontSize: 13)),
          style: OutlinedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 13),
            side: const BorderSide(color: Color(0xFFE0E0E0)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 460),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Container(
                      width: 74,
                      height: 74,
                      decoration: BoxDecoration(color: bleu, borderRadius: BorderRadius.circular(22)),
                      child: const Icon(Icons.directions_bus_rounded, color: Colors.white, size: 40),
                    ),
                  ),
                  const SizedBox(height: 14),
                  const Center(
                    child: Text('SAMA BUS BI',
                        style: TextStyle(color: bleu, fontSize: 24, fontWeight: FontWeight.w900, letterSpacing: 2)),
                  ),
                  const SizedBox(height: 32),
                  const Text('Connexion', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold, color: dark)),
                  const SizedBox(height: 6),
                  const Text('Accédez à votre compte pour profiter de toutes les fonctionnalités.',
                      style: TextStyle(color: Colors.black54, fontSize: 13)),
                  const SizedBox(height: 26),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: _decoration(hint: 'Adresse e-mail', icon: Icons.email_outlined),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: _decoration(
                      hint: 'Mot de passe',
                      icon: Icons.lock_outline,
                      suffix: IconButton(
                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        icon: Icon(_obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                            color: Colors.black45),
                      ),
                    ),
                  ),
                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: const Text('Mot de passe oublié ?', style: TextStyle(color: bleu, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: ElevatedButton(
                      onPressed: _loading ? null : _login,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: bleu,
                        elevation: 0,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 22, height: 22,
                              child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                          : const Text('Se connecter',
                              style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  ),
                  const SizedBox(height: 22),
                  Row(children: [
                    const Expanded(child: Divider()),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('ou', style: TextStyle(color: Colors.grey.shade500, fontSize: 12)),
                    ),
                    const Expanded(child: Divider()),
                  ]),
                  const SizedBox(height: 18),
                  Row(children: [
                    _boutonSocial(Icons.g_mobiledata_rounded, 'Google', () => _connexionIndisponible('Google')),
                    const SizedBox(width: 12),
                    _boutonSocial(Icons.apple_rounded, 'Apple', () => _connexionIndisponible('Apple')),
                  ]),
                  const SizedBox(height: 26),
                  Center(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text("Vous n'avez pas de compte ? ", style: TextStyle(color: Colors.black54, fontSize: 13)),
                        GestureDetector(
                          onTap: () => Navigator.push(context, MaterialPageRoute(builder: (_) => const InscriptionPage())),
                          child: const Text('S\'inscrire',
                              style: TextStyle(color: bleu, fontWeight: FontWeight.bold, fontSize: 13)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
