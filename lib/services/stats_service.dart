// ============================================================
//  lib/services/stats_service.dart
//  Sauvegarde et lecture des statistiques d'écoute dans Firestore
//
//  Structure Firestore :
//  users/{uid}/sessions/{YYYY-MM-DD}/
//    minutesTotal : int
//    sourates : {
//      "{numero}" : { nom: String, minutes: int, ecoutes: int }
//    }
// ============================================================

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class StatsService {
  final _db  = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get _uid => _auth.currentUser?.uid;

  // ── Clé du document du jour (format : "2025-05-01") ──────────────────────
  String _cleJour([DateTime? date]) {
    final d = date ?? DateTime.now();
    return '${d.year}-${d.month.toString().padLeft(2,'0')}-${d.day.toString().padLeft(2,'0')}';
  }

  // ── Référence du document du jour ─────────────────────────────────────────
  DocumentReference? _docJour([DateTime? date]) {
    final uid = _uid;
    if (uid == null) return null;
    return _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(_cleJour(date));
  }

  // ── Enregistrer 1 minute d'écoute ─────────────────────────────────────────
  //  Appelé toutes les 60 secondes depuis PlayerScreen pendant la lecture.
  //  soumeroSourate : numéro de la sourate (ex: 1 pour Al-Fatiha)
  //  nomSourate     : nom anglais (ex: "Al-Fatiha")
  Future<void> enregistrerMinute({
    required int numeroSourate,
    required String nomSourate,
  }) async {
    final ref = _docJour();
    if (ref == null) return;

    final cleS = '$numeroSourate';

    await ref.set({
      'minutesTotal': FieldValue.increment(1),
      'sourates': {
        cleS: {
          'nom'    : nomSourate,
          'minutes': FieldValue.increment(1),
        },
      },
    }, SetOptions(merge: true));
  }

  // ── Enregistrer 1 écoute (quand on clique sur une sourate) ───────────────
  //  Appelé une seule fois au démarrage de chaque sourate.
  Future<void> enregistrerEcoute({
    required int numeroSourate,
    required String nomSourate,
  }) async {
    final ref = _docJour();
    if (ref == null) return;

    final cleS = '$numeroSourate';

    await ref.set({
      'sourates': {
        cleS: {
          'nom'    : nomSourate,
          'ecoutes': FieldValue.increment(1),
        },
      },
    }, SetOptions(merge: true));
  }

  // ── Lire les minutes par jour du mois en cours ───────────────────────────
  //  Retourne une liste de 31 entiers (index 0 = jour 1, etc.)
  //  Les jours sans données valent 0.
  Future<List<int>> getMinutesParJourMoisEnCours() async {
    final uid = _uid;
    if (uid == null) return List.filled(31, 0);

    final now = DateTime.now();
    final nbJours = DateTime(now.year, now.month + 1, 0).day;

    // On génère toutes les clés du mois
    final cles = List.generate(nbJours, (i) {
      final j = i + 1;
      return '${now.year}-${now.month.toString().padLeft(2,'0')}-${j.toString().padLeft(2,'0')}';
    });

    // On lit tous les documents en une seule requête (batch)
    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where(FieldPath.documentId, whereIn: cles)
        .get();

    // On construit un map clé → minutesTotal
    final map = <String, int>{};
    for (final doc in snap.docs) {
      map[doc.id] = (doc.data()['minutesTotal'] as int?) ?? 0;
    }

    // On retourne la liste ordonnée par jour
    return cles.map((c) => map[c] ?? 0).toList();
  }

  // ── Lire le top 5 sourates du mois en cours ──────────────────────────────
  //  Retourne une liste triée par nombre d'écoutes décroissant.
  Future<List<Map<String, dynamic>>> getTopSourates({int limit = 5}) async {
    final uid = _uid;
    if (uid == null) return [];

    final now = DateTime.now();
    final nbJours = DateTime(now.year, now.month + 1, 0).day;

    final cles = List.generate(nbJours, (i) {
      final j = i + 1;
      return '${now.year}-${now.month.toString().padLeft(2,'0')}-${j.toString().padLeft(2,'0')}';
    });

    final snap = await _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .where(FieldPath.documentId, whereIn: cles)
        .get();

    // Agrégation : additionner minutes et écoutes par sourate sur tout le mois
    final agregat = <String, Map<String, dynamic>>{};
    for (final doc in snap.docs) {
      final data = doc.data();
      final sourates = data['sourates'] as Map<String, dynamic>? ?? {};
      for (final entry in sourates.entries) {
        final s = entry.value as Map<String, dynamic>;
        final cle = entry.key;
        if (!agregat.containsKey(cle)) {
          agregat[cle] = {
            'titre'   : 'Sourate ${s['nom'] ?? cle}',
            'artiste' : 'Mishary Rashid Al-Afasy',
            'minutes' : 0,
            'ecoutes' : 0,
          };
        }
        agregat[cle]!['minutes'] =
            (agregat[cle]!['minutes'] as int) + ((s['minutes'] as int?) ?? 0);
        agregat[cle]!['ecoutes'] =
            (agregat[cle]!['ecoutes'] as int) + ((s['ecoutes'] as int?) ?? 0);
      }
    }

    // Tri par écoutes décroissant, puis on prend le top N
    final liste = agregat.values.toList()
      ..sort((a, b) =>
          (b['ecoutes'] as int).compareTo(a['ecoutes'] as int));

    return liste.take(limit).toList();
  }

  // ── Stream temps réel des stats du jour (pour mise à jour instantanée) ───
  Stream<Map<String, dynamic>> streamStatsJour() {
    final uid = _uid;
    if (uid == null) return const Stream.empty();
    final ref = _db
        .collection('users')
        .doc(uid)
        .collection('sessions')
        .doc(_cleJour());
    return ref.snapshots().map((snap) => snap.data() ?? {});
  }
}
