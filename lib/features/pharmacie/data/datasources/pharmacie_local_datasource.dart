import '../models/pharmacie_model.dart';
import '../models/ordonnance_model.dart';
import '../models/paiement_mobile_model.dart';

/// Datasource local pour le stockage temporaire (session en mémoire).
/// En production, remplacer par FirebaseFirestoreDatasource.
class PharmacieLocalDatasource {
  static final PharmacieLocalDatasource _instance =
      PharmacieLocalDatasource._internal();
  factory PharmacieLocalDatasource() => _instance;
  PharmacieLocalDatasource._internal();

  PharmacieModel? _pharmacieConnectee;
  final List<OrdonnanceModel> _ordonnances = [];
  final List<PaiementMobileModel> _paiements = [];

  // ─── Pharmacie ─────────────────────────────────────────────────────────────
  PharmacieModel? get pharmacieConnectee => _pharmacieConnectee;

  void connecter(PharmacieModel pharmacie) {
    _pharmacieConnectee = pharmacie;
  }

  void deconnecter() {
    _pharmacieConnectee = null;
  }

  void mettreAJourPharmacie(PharmacieModel pharmacie) {
    _pharmacieConnectee = pharmacie;
  }

  // ─── Ordonnances ──────────────────────────────────────────────────────────
  List<OrdonnanceModel> getOrdonnances() => List.unmodifiable(_ordonnances);

  void setOrdonnances(List<OrdonnanceModel> ordonnances) {
    _ordonnances
      ..clear()
      ..addAll(ordonnances);
  }

  void ajouterOrdonnance(OrdonnanceModel ordonnance) {
    _ordonnances.add(ordonnance);
  }

  bool mettreAJourOrdonnance(OrdonnanceModel updated) {
    final idx = _ordonnances.indexWhere((o) => o.id == updated.id);
    if (idx == -1) return false;
    _ordonnances[idx] = updated;
    return true;
  }

  OrdonnanceModel? getOrdonnanceParId(String id) {
    try {
      return _ordonnances.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }

  // ─── Paiements ─────────────────────────────────────────────────────────────
  List<PaiementMobileModel> getPaiements() => List.unmodifiable(_paiements);

  void ajouterPaiement(PaiementMobileModel paiement) {
    _paiements.add(paiement);
  }

  bool mettreAJourPaiement(PaiementMobileModel updated) {
    final idx = _paiements.indexWhere((p) => p.id == updated.id);
    if (idx == -1) return false;
    _paiements[idx] = updated;
    return true;
  }

  double get chiffreAffaireTotal => _paiements
      .where((p) => p.statut == StatutPaiement.confirme)
      .fold(0.0, (sum, p) => sum + p.montantFCFA);

  double get chiffreAffaireJour {
    final today = DateTime.now();
    return _paiements
        .where((p) =>
            p.statut == StatutPaiement.confirme &&
            p.createdAt.year == today.year &&
            p.createdAt.month == today.month &&
            p.createdAt.day == today.day)
        .fold(0.0, (sum, p) => sum + p.montantFCFA);
  }
}
