import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';
import 'register_screen.dart';
import 'reset_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _authService = AuthService();
  bool _loading = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _loading = true);
    try {
      await _authService.login(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
      );
      // Navigation gérée par le StreamBuilder dans main.dart
    } on Exception catch (e) {
      if (mounted) {
        showAuthSnackbar(context, _parseFirebaseError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseFirebaseError(String error) {
    if (error.contains('user-not-found') || error.contains('wrong-password') ||
        error.contains('invalid-credential')) {
      return 'Email ou mot de passe incorrect.';
    }
    if (error.contains('too-many-requests')) {
      return 'Trop de tentatives. Réessayez plus tard.';
    }
    return 'Une erreur est survenue. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 40),

                // ── Logo / Titre ──────────────────────────────────────────
                Center(
                  child: Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: AppColors.primary.withOpacity(0.3),
                      ),
                    ),
                    child: const Icon(
                      Icons.headphones_rounded,
                      color: AppColors.primary,
                      size: 36,
                    ),
                  ),
                ).animate().fadeIn(duration: 500.ms).scale(begin: const Offset(0.8, 0.8)),

                const SizedBox(height: 32),

                Text(
                  'Bon retour,',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary,
                    fontSize: 16,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                Text(
                  'Connexion',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 32,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn(delay: 150.ms).slideX(begin: -0.1),

                const SizedBox(height: 40),

                // ── Champs ────────────────────────────────────────────────
                AuthTextField(
                  label: 'ADRESSE EMAIL',
                  hint: 'exemple@email.com',
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  prefixIcon: Icons.email_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Champ requis';
                    if (!v.contains('@') || !v.contains('.')) {
                      return 'Email invalide';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                AuthTextField(
                  label: 'MOT DE PASSE',
                  hint: '••••••••',
                  controller: _passwordCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v.length < 6) return 'Minimum 6 caractères';
                    return null;
                  },
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                // ── Mot de passe oublié ───────────────────────────────────
                Align(
                  alignment: Alignment.centerRight,
                  child: TextButton(
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                          builder: (_) => const ResetPasswordScreen()),
                    ),
                    child: Text(
                      'Mot de passe oublié ?',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.primaryLight,
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ).animate().fadeIn(delay: 300.ms),

                const SizedBox(height: 28),

                // ── Bouton connexion ──────────────────────────────────────
                AuthButton(
                  label: 'SE CONNECTER',
                  onPressed: _login,
                  isLoading: _loading,
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                const SizedBox(height: 24),

                // ── Séparateur ────────────────────────────────────────────
                Row(
                  children: [
                    Expanded(child: Divider(color: AppColors.border)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Text(
                        'ou',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                      ),
                    ),
                    Expanded(child: Divider(color: AppColors.border)),
                  ],
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 24),

                // ── Bouton inscription ────────────────────────────────────
                AuthButton(
                  label: 'CRÉER UN COMPTE',
                  onPressed: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const RegisterScreen()),
                  ),
                  outlined: true,
                ).animate().fadeIn(delay: 450.ms),

                const SizedBox(height: 32),
              ],
            ),
          ),
        ),
      ),
    );
  }
}