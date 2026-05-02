<<<<<<< Updated upstream
import 'package:flutter/material.dart';
class HomeScreen extends StatelessWidget {
=======
// ============================================================
//  lib/screens/home_screens.dart
//  Écran principal avec navigation entre :
//  - Page Statistiques (données réelles depuis Firestore)
//  - Page Lecteur Audio
// ============================================================

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../widgets/app_theme.dart';
import '../services/stats_service.dart';
import 'player_screen.dart';

class HomeScreen extends StatefulWidget {
>>>>>>> Stashed changes
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
<<<<<<< Updated upstream
      appBar: AppBar(title: const Text('Home')),
      body: const Center(child: Text('Welcome!')),
=======
      backgroundColor: AppColors.background,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border(top: BorderSide(color: AppColors.border)),
      ),
      child: BottomNavigationBar(
        currentIndex: _currentIndex,
        onTap: (i) => setState(() => _currentIndex = i),
        backgroundColor: Colors.transparent,
        elevation: 0,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textSecondary,
        selectedLabelStyle: GoogleFonts.syne(
          fontSize: 11,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.syne(fontSize: 11),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart_rounded),
            activeIcon: Icon(Icons.bar_chart_rounded),
            label: 'Statistiques',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.headphones_outlined),
            activeIcon: Icon(Icons.headphones_rounded),
            label: 'Lecteur',
          ),
        ],
      ),
    );
  }
}

// ============================================================
//  Page Statistiques — données réelles depuis Firestore
// ============================================================
class _StatistiquesPage extends StatefulWidget {
  const _StatistiquesPage();

  @override
  State<_StatistiquesPage> createState() => _StatistiquesPageState();
}

class _StatistiquesPageState extends State<_StatistiquesPage> {
  final _auth         = FirebaseAuth.instance;
  final _db           = FirebaseFirestore.instance;
  final _statsService = StatsService();

  String _prenom = '';
  String _nom    = '';
  int _objectif  = 20;
  bool _loading  = true;

  // Données dynamiques depuis Firestore
  List<int> _minutesParJour              = [];
  List<Map<String, dynamic>> _topMorceaux = [];
  bool _loadingStats = true;

  @override
  void initState() {
    super.initState();
    _loadProfil();
    _loadStats();
  }

  // ── Chargement profil ─────────────────────────────────────────────────────
  Future<void> _loadProfil() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    try {
      final doc = await _db.collection('users').doc(uid).get();
      final data = doc.data();
      if (data != null && mounted) {
        setState(() {
          _prenom   = data['prenom'] ?? '';
          _nom      = data['nom']    ?? '';
          _objectif = data['objectifMensuel'] ?? 20;
          _loading  = false;
        });
      }
    } catch (_) {
      if (mounted) setState(() => _loading = false);
    }
  }

  // ── Chargement stats depuis Firestore ─────────────────────────────────────
  Future<void> _loadStats() async {
    try {
      final minutes = await _statsService.getMinutesParJourMoisEnCours();
      final top     = await _statsService.getTopSourates(limit: 5);
      if (mounted) {
        setState(() {
          _minutesParJour = minutes;
          _topMorceaux    = top;
          _loadingStats   = false;
        });
      }
    } catch (_) {
      if (mounted) {
        // En cas d'erreur on affiche des zéros plutôt que de planter
        setState(() {
          _minutesParJour = List.filled(_nbJoursMois, 0);
          _topMorceaux    = [];
          _loadingStats   = false;
        });
      }
    }
  }

  Future<void> _updateObjectif(int val) async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) return;
    setState(() => _objectif = val);
    await _db.collection('users').doc(uid).update({'objectifMensuel': val});
  }

  // ── Calculs ───────────────────────────────────────────────────────────────
  int get _totalMinutes =>
      _minutesParJour.isEmpty ? 0 : _minutesParJour.fold(0, (a, b) => a + b);
  int get _totalHeures  => _totalMinutes ~/ 60;
  int get _restMinutes  => _totalMinutes % 60;
  double get _progression =>
      (_totalMinutes / (_objectif * 60)).clamp(0.0, 1.0);
  int get _joursActifs =>
      _minutesParJour.where((m) => m > 0).length;
  int get _maxMinutes =>
      _minutesParJour.isEmpty ? 1 : _minutesParJour.reduce((a, b) => a > b ? a : b);
  int get _nbJoursMois {
    final now = DateTime.now();
    return DateTime(now.year, now.month + 1, 0).day;
  }
  List<int> get _joursAffiches {
    if (_minutesParJour.isEmpty) return List.filled(_nbJoursMois, 0);
    return _minutesParJour.take(_nbJoursMois).toList();
  }

  // ── BUILD ─────────────────────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.background,
        body: Center(child: CircularProgressIndicator(color: AppColors.primary)),
      );
    }

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: RefreshIndicator(
          color: AppColors.primary,
          backgroundColor: AppColors.card,
          onRefresh: () async {
            setState(() => _loadingStats = true);
            await _loadStats();
          },
          child: CustomScrollView(
            slivers: [
              SliverToBoxAdapter(child: _buildHeader()),
              SliverToBoxAdapter(child: _buildStatsGlobales()),
              SliverToBoxAdapter(child: _buildObjectif()),
              SliverToBoxAdapter(
                child: _loadingStats
                    ? _buildSkeletonHistogramme()
                    : _buildHistogramme(),
              ),
              SliverToBoxAdapter(
                child: _loadingStats
                    ? _buildSkeletonTop()
                    : _buildTopMorceaux(),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 16)),
            ],
          ),
        ),
      ),
    );
  }

  // ── Header ────────────────────────────────────────────────────────────────
  Widget _buildHeader() {
    final now = DateTime.now();
    final mois = ['','Janvier','Février','Mars','Avril','Mai','Juin',
        'Juillet','Août','Septembre','Octobre','Novembre','Décembre'][now.month];
    return Container(
      padding: const EdgeInsets.fromLTRB(24, 24, 24, 16),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$mois ${now.year}',
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        letterSpacing: 2)),
                const SizedBox(height: 4),
                RichText(
                  text: TextSpan(
                    text: 'Bonjour, ',
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary, fontSize: 22),
                    children: [
                      TextSpan(
                        text: '$_prenom $_nom',
                        style: GoogleFonts.syne(
                            color: AppColors.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.w800),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          GestureDetector(
            onTap: () => _auth.signOut(),
            child: Container(
              width: 42, height: 42,
              decoration: BoxDecoration(
                color: AppColors.card,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.border),
              ),
              child: const Icon(Icons.logout_rounded,
                  color: AppColors.textSecondary, size: 18),
            ),
          ),
        ],
      ),
    );
  }

  // ── Stats globales ────────────────────────────────────────────────────────
  Widget _buildStatsGlobales() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 0, 24, 0),
      child: Row(
        children: [
          Expanded(child: _statCard(
            label: 'Écoute totale',
            value: '${_totalHeures}h ${_restMinutes}min',
            icon: Icons.headphones_rounded,
            color: AppColors.primary,
          )),
          const SizedBox(width: 12),
          Expanded(child: _statCard(
            label: 'Jours actifs',
            value: '$_joursActifs j.',
            icon: Icons.calendar_today_rounded,
            color: AppColors.accent,
          )),
        ],
      ),
    );
  }

  Widget _statCard({
    required String label,
    required String value,
    required IconData icon,
    required Color color,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(value,
                    style: GoogleFonts.syne(
                        color: AppColors.textPrimary,
                        fontSize: 15,
                        fontWeight: FontWeight.w800)),
                Text(label,
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary, fontSize: 10)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Objectif mensuel ──────────────────────────────────────────────────────
  Widget _buildObjectif() {
    final pct = (_progression * 100).toInt();
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text('Objectif mensuel',
                  style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 15,
                      fontWeight: FontWeight.w700)),
              const Spacer(),
              // Dropdown objectif
              DropdownButton<int>(
                value: _objectif,
                dropdownColor: AppColors.surface,
                underline: const SizedBox(),
                style: GoogleFonts.syne(
                    color: AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w700),
                items: [5, 10, 15, 20, 25, 30, 40, 50]
                    .map((h) => DropdownMenuItem(
                          value: h,
                          child: Text('$h h'),
                        ))
                    .toList(),
                onChanged: (v) { if (v != null) _updateObjectif(v); },
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Barre de progression dégradée
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: _progression,
              minHeight: 10,
              backgroundColor: AppColors.border,
              valueColor: AlwaysStoppedAnimation(
                _progression >= 1.0 ? AppColors.accent : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Text('${_totalHeures}h ${_restMinutes}min écoutées',
                  style: GoogleFonts.syne(
                      color: AppColors.textSecondary, fontSize: 12)),
              const Spacer(),
              Text('$pct%',
                  style: GoogleFonts.syne(
                    color: _progression >= 1.0
                        ? AppColors.accent
                        : AppColors.primary,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  )),
            ],
          ),
          if (_progression >= 1.0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: AppColors.accent.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                    color: AppColors.accent.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.check_circle_rounded,
                      color: AppColors.accent, size: 14),
                  const SizedBox(width: 6),
                  Text('Objectif atteint ! 🎉',
                      style: GoogleFonts.syne(
                          color: AppColors.accent,
                          fontSize: 12,
                          fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  // ── Histogramme ───────────────────────────────────────────────────────────
  Widget _buildHistogramme() {
    final jours = _joursAffiches;
    final now   = DateTime.now();
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Minutes écoutées ce mois',
                      style: GoogleFonts.syne(
                          color: AppColors.textPrimary,
                          fontSize: 15,
                          fontWeight: FontWeight.w700)),
                  Text('Chaque barre = 1 jour',
                      style: GoogleFonts.syne(
                          color: AppColors.textSecondary, fontSize: 11)),
                ],
              ),
              const Spacer(),
              // Bouton rafraîchir
              GestureDetector(
                onTap: () async {
                  setState(() => _loadingStats = true);
                  await _loadStats();
                },
                child: const Icon(Icons.refresh_rounded,
                    color: AppColors.textSecondary, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(jours.length, (i) {
                final isToday = (i + 1) == now.day;
                final ratio = _maxMinutes > 0
                    ? jours[i] / _maxMinutes
                    : 0.0;
                return Expanded(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 1.5),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        Flexible(
                          child: FractionallySizedBox(
                            heightFactor: ratio > 0
                                ? ratio.clamp(0.05, 1.0)
                                : 0.03,
                            child: Container(
                              decoration: BoxDecoration(
                                color: isToday
                                    ? AppColors.accent
                                    : ratio > 0
                                        ? AppColors.primary.withValues(
                                            alpha: 0.7 + ratio * 0.3)
                                        : AppColors.border,
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: List.generate(jours.length, (i) {
              final show = (i + 1) == 1 ||
                  (i + 1) % 5 == 0 ||
                  (i + 1) == jours.length;
              return Expanded(
                child: Text(
                  show ? '${i + 1}' : '',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.syne(
                    color: (i + 1) == now.day
                        ? AppColors.accent
                        : AppColors.textSecondary,
                    fontSize: 9,
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ── Top morceaux ──────────────────────────────────────────────────────────
  Widget _buildTopMorceaux() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Sourates les plus écoutées',
              style: GoogleFonts.syne(
                  color: AppColors.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w700)),
          const SizedBox(height: 16),
          if (_topMorceaux.isEmpty)
            // Message quand aucune écoute ce mois
            Center(
              child: Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: Column(
                  children: [
                    const Icon(Icons.headphones_outlined,
                        color: AppColors.textSecondary, size: 36),
                    const SizedBox(height: 8),
                    Text('Aucune écoute ce mois',
                        style: GoogleFonts.syne(
                            color: AppColors.textSecondary, fontSize: 13)),
                    const SizedBox(height: 4),
                    Text('Lance une sourate pour commencer !',
                        style: GoogleFonts.syne(
                            color: AppColors.textSecondary, fontSize: 11)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(
                _topMorceaux.length,
                (i) => _morceauRow(i + 1, _topMorceaux[i])),
        ],
      ),
    );
  }

  Widget _morceauRow(int rang, Map<String, dynamic> m) {
    final colors = [
      AppColors.accent, AppColors.primary, AppColors.primaryLight,
      AppColors.textSecondary, AppColors.textSecondary,
    ];
    final color = colors[(rang - 1).clamp(0, colors.length - 1)];
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        children: [
          SizedBox(
            width: 28,
            child: Text('#$rang',
                style: GoogleFonts.syne(
                    color: color,
                    fontSize: 13,
                    fontWeight: FontWeight.w800)),
          ),
          Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(Icons.music_note_rounded, color: color, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(m['titre'] ?? '',
                    style: GoogleFonts.syne(
                        color: AppColors.textPrimary,
                        fontSize: 13,
                        fontWeight: FontWeight.w600),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                Text(m['artiste'] ?? '',
                    style: GoogleFonts.syne(
                        color: AppColors.textSecondary, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${m['ecoutes']}x',
                  style: GoogleFonts.syne(
                      color: AppColors.textPrimary,
                      fontSize: 13,
                      fontWeight: FontWeight.w700)),
              Text('${m['minutes']} min',
                  style: GoogleFonts.syne(
                      color: AppColors.textSecondary, fontSize: 10)),
            ],
          ),
        ],
      ),
>>>>>>> Stashed changes
    );
  }

  // ── Skeletons (placeholders pendant le chargement) ────────────────────────
  Widget _buildSkeletonHistogramme() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBox(120, 14),
          const SizedBox(height: 6),
          _skeletonBox(80, 10),
          const SizedBox(height: 20),
          SizedBox(
            height: 120,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(30, (i) => Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 1.5),
                  child: FractionallySizedBox(
                    heightFactor: (0.1 + (i % 5) * 0.15).clamp(0.05, 0.9),
                    child: Container(
                      decoration: BoxDecoration(
                        color: AppColors.border,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                  ),
                ),
              )),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSkeletonTop() {
    return Container(
      margin: const EdgeInsets.fromLTRB(24, 16, 24, 0),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _skeletonBox(160, 14),
          const SizedBox(height: 16),
          ...List.generate(3, (_) => Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Row(
              children: [
                _skeletonBox(40, 40),
                const SizedBox(width: 12),
                Expanded(child: _skeletonBox(double.infinity, 14)),
              ],
            ),
          )),
        ],
      ),
    );
  }

  Widget _skeletonBox(double w, double h) {
    return Container(
      width: w == double.infinity ? null : w,
      height: h,
      decoration: BoxDecoration(
        color: AppColors.border,
        borderRadius: BorderRadius.circular(6),
      ),
    );
  }
}
