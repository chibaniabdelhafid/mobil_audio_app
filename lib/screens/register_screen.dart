import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/auth_service.dart';
import '../widgets/auth_widgets.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  final _authService = AuthService();

  DateTime? _dateNaissance;
  bool _loading = false;

  @override
  void dispose() {
    _nomCtrl.dispose();
    _prenomCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 16),
      firstDate: DateTime(1920),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.dark().copyWith(
            colorScheme: const ColorScheme.dark(
              primary: AppColors.primary,
              surface: AppColors.card,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateNaissance = picked);
    }
  }

  int? _calculateAge() {
    if (_dateNaissance == null) return null;
    final today = DateTime.now();
    int age = today.year - _dateNaissance!.year;
    if (today.month < _dateNaissance!.month ||
        (today.month == _dateNaissance!.month &&
            today.day < _dateNaissance!.day)) {
      age--;
    }
    return age;
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    if (_dateNaissance == null) {
      showAuthSnackbar(context, 'Veuillez sélectionner votre date de naissance.');
      return;
    }

    final age = _calculateAge()!;
    if (age < 13) {
      showAuthSnackbar(context, 'Vous devez avoir au moins 13 ans.');
      return;
    }

    setState(() => _loading = true);
    try {
      await _authService.register(
        email: _emailCtrl.text.trim(),
        password: _passwordCtrl.text,
        nom: _nomCtrl.text.trim(),
        prenom: _prenomCtrl.text.trim(),
        dateNaissance: _dateNaissance!,
      );
      if (mounted) {
        showAuthSnackbar(context, 'Compte créé avec succès !', isError: false);
        Navigator.pop(context);
      }
    } on Exception catch (e) {
      if (mounted) {
        showAuthSnackbar(context, _parseFirebaseError(e.toString()));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  String _parseFirebaseError(String error) {
    if (error.contains('email-already-in-use')) {
      return 'Cet email est déjà utilisé.';
    }
    if (error.contains('weak-password')) {
      return 'Mot de passe trop faible (min. 6 caractères).';
    }
    if (error.contains('au moins 13 ans')) {
      return 'Vous devez avoir au moins 13 ans.';
    }
    return 'Erreur lors de l\'inscription. Réessayez.';
  }

  @override
  Widget build(BuildContext context) {
    final age = _calculateAge();

    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded,
              color: AppColors.textPrimary),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 8),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Titre ─────────────────────────────────────────────────
                Text(
                  'Créer un compte',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textPrimary,
                    fontSize: 30,
                    fontWeight: FontWeight.w800,
                  ),
                ).animate().fadeIn().slideX(begin: -0.1),

                const SizedBox(height: 6),
                Text(
                  'Rejoignez-nous dès maintenant',
                  style: GoogleFonts.spaceGrotesk(
                    color: AppColors.textSecondary,
                    fontSize: 14,
                  ),
                ).animate().fadeIn(delay: 100.ms),

                const SizedBox(height: 32),

                // ── Nom & Prénom côte à côte ───────────────────────────────
                Row(
                  children: [
                    Expanded(
                      child: AuthTextField(
                        label: 'NOM',
                        hint: 'Dupont',
                        controller: _nomCtrl,
                        prefixIcon: Icons.person_outline_rounded,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: AuthTextField(
                        label: 'PRÉNOM',
                        hint: 'Jean',
                        controller: _prenomCtrl,
                        prefixIcon: Icons.badge_outlined,
                        validator: (v) =>
                            (v == null || v.trim().isEmpty) ? 'Requis' : null,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 150.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // ── Date de naissance ─────────────────────────────────────
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'DATE DE NAISSANCE',
                      style: GoogleFonts.spaceGrotesk(
                        color: AppColors.textSecondary,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 8),
                    GestureDetector(
                      onTap: _pickDate,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 16),
                        decoration: BoxDecoration(
                          color: AppColors.card,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: _dateNaissance != null && age! < 13
                                ? AppColors.error
                                : AppColors.border,
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: _dateNaissance != null
                                  ? AppColors.primary
                                  : AppColors.textSecondary,
                              size: 20,
                            ),
                            const SizedBox(width: 12),
                            Text(
                              _dateNaissance == null
                                  ? 'Sélectionner une date'
                                  : '${_dateNaissance!.day.toString().padLeft(2, '0')}/'
                                      '${_dateNaissance!.month.toString().padLeft(2, '0')}/'
                                      '${_dateNaissance!.year}',
                              style: GoogleFonts.spaceGrotesk(
                                color: _dateNaissance == null
                                    ? AppColors.textSecondary.withOpacity(0.5)
                                    : AppColors.textPrimary,
                                fontSize: 15,
                              ),
                            ),
                            const Spacer(),
                            if (_dateNaissance != null)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: age! >= 13
                                      ? AppColors.accent.withOpacity(0.15)
                                      : AppColors.error.withOpacity(0.15),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  '$age ans',
                                  style: GoogleFonts.spaceGrotesk(
                                    color: age >= 13
                                        ? AppColors.accent
                                        : AppColors.error,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                    if (_dateNaissance != null && age! < 13)
                      Padding(
                        padding: const EdgeInsets.only(top: 6, left: 4),
                        child: Text(
                          'Vous devez avoir au moins 13 ans',
                          style: GoogleFonts.spaceGrotesk(
                            color: AppColors.error,
                            fontSize: 11,
                          ),
                        ),
                      ),
                  ],
                ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // ── Email ─────────────────────────────────────────────────
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
                ).animate().fadeIn(delay: 250.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // ── Mot de passe ──────────────────────────────────────────
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
                ).animate().fadeIn(delay: 300.ms).slideY(begin: 0.1),

                const SizedBox(height: 20),

                // ── Confirmer mot de passe ────────────────────────────────
                AuthTextField(
                  label: 'CONFIRMER LE MOT DE PASSE',
                  hint: '••••••••',
                  controller: _confirmPasswordCtrl,
                  isPassword: true,
                  prefixIcon: Icons.lock_outline_rounded,
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Champ requis';
                    if (v != _passwordCtrl.text) {
                      return 'Les mots de passe ne correspondent pas';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 350.ms).slideY(begin: 0.1),

                const SizedBox(height: 36),

                // ── Bouton s'inscrire ─────────────────────────────────────
                AuthButton(
                  label: "S'INSCRIRE",
                  onPressed: _register,
                  isLoading: _loading,
                ).animate().fadeIn(delay: 400.ms),

                const SizedBox(height: 16),

                // ── Retour connexion ──────────────────────────────────────
                Center(
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: RichText(
                      text: TextSpan(
                        text: 'Déjà un compte ? ',
                        style: GoogleFonts.spaceGrotesk(
                          color: AppColors.textSecondary,
                          fontSize: 13,
                        ),
                        children: [
                          TextSpan(
                            text: 'Se connecter',
                            style: GoogleFonts.spaceGrotesk(
                              color: AppColors.primaryLight,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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