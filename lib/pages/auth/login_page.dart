import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:norges_tour_app/pages/auth/register_page.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';
import 'package:norges_tour_app/theme/app_theme.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _login() async {
    setState(() { _isLoading = true; _errorMessage = null; });
    try {
      final credentials = await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (credentials.user != null && !credentials.user!.emailVerified) {
        await FirebaseAuth.instance.signOut();
        setState(() {
          _errorMessage = 'Du må bekrefte e-posten din før du kan logge inn. Sjekk innboksen din.';
          _isLoading = false;
        });
        return;
      }
      if (mounted) Navigator.pop(context);
    } on FirebaseAuthException catch (e) {
      setState(() { _errorMessage = e.message ?? 'Feil ved innlogging.'; });
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Logg inn', style: AppText.dispH2(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(AppTheme.pageHPad * 1.5),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Logo / icon
              Center(
                child: Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.person_outline, size: 44, color: AppColors.coral),
                ),
              ),
              const SizedBox(height: 24),
              Text('Velkommen tilbake', style: AppText.dispH1(26), textAlign: TextAlign.center),
              const SizedBox(height: 6),
              Text('Logg inn for å fortsette', style: AppText.uiCaption, textAlign: TextAlign.center),
              const SizedBox(height: 32),

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
                  onPressed: _isLoading ? null : _login,
                  child: _isLoading
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : Text('Logg inn', style: AppText.uiCta),
                ),
              ),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Har du ikke konto?', style: AppText.uiCaption),
                  TextButton(
                    onPressed: () => Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (context) => const RegisterPage()),
                    ),
                    child: Text('Registrer deg', style: AppText.uiCta.copyWith(color: AppColors.coral, fontSize: 13)),
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
