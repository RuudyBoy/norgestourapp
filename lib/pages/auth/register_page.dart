import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:norges_tour_app/pages/auth/login_page.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';
import 'package:norges_tour_app/theme/app_theme.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({super.key});

  @override
  State<RegisterPage> createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  final _teamNameController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final credentials = await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (credentials.user != null) {
        await credentials.user!.sendEmailVerification();
        await FirebaseFirestore.instance.collection('users').doc(credentials.user!.uid).set({
          'email': credentials.user!.email,
          'name': _nameController.text.trim(),
          'teamName': _teamNameController.text.trim().isEmpty ? 'Ukjent Lag' : _teamNameController.text.trim(),
          'createdAt': FieldValue.serverTimestamp(),
          'isPlayer': false,
        });
        await FirebaseAuth.instance.signOut();
      }
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Konto opprettet! Sjekk e-posten din for bekreftelseslenke.', style: AppText.uiBody.copyWith(color: Colors.white)),
            backgroundColor: AppColors.green,
            duration: const Duration(seconds: 5),
          ),
        );
        Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const LoginPage()));
      }
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message ?? 'Feil ved registrering.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Registrer deg', style: AppText.dispH2(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.pageHPad * 1.5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Step indicator
              Row(
                children: List.generate(3, (i) => Expanded(
                  child: Container(
                    height: 4,
                    margin: EdgeInsets.only(right: i < 2 ? 6 : 0),
                    decoration: BoxDecoration(
                      color: AppColors.coral,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                )),
              ),
              const SizedBox(height: 24),

              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_add_outlined, size: 44, color: AppColors.coral),
                ),
              ),
              const SizedBox(height: 20),
              Text('Opprett konto', style: AppText.dispH1(26), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Bli med i Norges Tour Fantasy', style: AppText.uiCaption, textAlign: TextAlign.center),
              const SizedBox(height: 32),

              TextField(
                controller: _nameController,
                decoration: InputDecoration(
                  labelText: 'Fullt navn',
                  prefixIcon: const Icon(Icons.badge_outlined, color: AppColors.ink3),
                ),
                style: AppText.uiBody,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _teamNameController,
                decoration: InputDecoration(
                  labelText: 'Fantasy Lagnavn',
                  prefixIcon: const Icon(Icons.sports_volleyball, color: AppColors.ink3),
                ),
                style: AppText.uiBody,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _emailController,
                decoration: InputDecoration(
                  labelText: 'E-post',
                  prefixIcon: const Icon(Icons.email_outlined, color: AppColors.ink3),
                  hintText: 'din@epost.no',
                ),
                keyboardType: TextInputType.emailAddress,
                style: AppText.uiBody,
              ),
              const SizedBox(height: 14),
              TextField(
                controller: _passwordController,
                decoration: InputDecoration(
                  labelText: 'Passord',
                  prefixIcon: const Icon(Icons.lock_outline, color: AppColors.ink3),
                ),
                obscureText: true,
                style: AppText.uiBody,
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.10),
                    borderRadius: BorderRadius.circular(AppTheme.radiusInput),
                    border: Border.all(color: AppColors.coral.withValues(alpha: 0.4)),
                  ),
                  child: Text(_errorMessage!, style: AppText.uiCaption.copyWith(color: AppColors.coral)),
                ),
              ],

              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _register,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Opprett konto', style: AppText.uiCta),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Har du allerede konto?', style: AppText.uiCaption),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const LoginPage()),
                    ),
                    child: Text('Logg inn', style: AppText.uiCta.copyWith(color: AppColors.coral, fontSize: 13)),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
