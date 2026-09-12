import 'package:flutter/foundation.dart';
import '../../data/models/ordonnance_model.dart';
import '../../data/models/paiement_mobile_model.dart';

/// Provider dédié à la gestion des ordonnances côté pharmacie.
class OrdonnanceProvider extends ChangeNotifier {
  List<OrdonnanceModel> _ordonnances = [];
  bool _isLoading = false;
  String? _errorMessage;
  StatutOrdonnance? _filtreStatut;
  String _recherche = '';

  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StatutOrdonnance? get filtreStatut => _filtreStatut;
  String get recherche => _recherche;

  List<OrdonnanceModel> get toutesLesOrdonnances => _ordonnances;

  List<OrdonnanceModel> get ordonnancesFiltrees {
    var liste = _ordonnances;
    if (_filtreStatut != null) {
      liste = liste.where((o) => o.statut == _filtreStatut).toList();
    }
    if (_recherche.isNotEmpty) {
      final q = _recherche.toLowerCase();
      liste = liste
          .where((o) =>
              o.patientNomComplet.toLowerCase().contains(q) ||
              o.id.toLowerCase().contains(q) ||
              o.medicaments.any((m) => m.nom.toLowerCase().contains(q)))
          .toList();
    }
    return liste;
  }

  List<OrdonnanceModel> get enAttente =>
      _ordonnances.where((o) => o.statut == StatutOrdonnance.enAttente).toList();
  List<OrdonnanceModel> get validees =>
      _ordonnances.where((o) => o.statut == StatutOrdonnance.validee).toList();
  List<OrdonnanceModel> get payees =>
      _ordonnances.where((o) => o.statut == StatutOrdonnance.payee).toList();
  List<OrdonnanceModel> get pretes =>
      _ordonnances.where((o) => o.statut == StatutOrdonnance.prete).toList();
  int get badgeEnAttente => enAttente.length;

  void setFiltre(StatutOrdonnance? statut) {
    _filtreStatut = statut;
    notifyListeners();
  }

  void setRecherche(String q) {
    _recherche = q;
    notifyListeners();
  }

  void clearFiltre() {
    _filtreStatut = null;
    _recherche = '';
    notifyListeners();
  }

  Future<void> chargerOrdonnances(String pharmacieId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 800));
    _ordonnances = OrdonnanceDemo.ordonnances
        .where((o) => o.pharmacieId == pharmacieId || o.pharmacieId != null)
        .toList();
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> validerOrdonnance(String ordonnanceId, double montant) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx == -1) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
    _ordonnances[idx] = _ordonnances[idx].copyWith(
      statut: StatutOrdonnance.validee,
      montantTotal: montant,
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> refuserOrdonnance(String ordonnanceId, String raison) async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 600));
    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx == -1) {
      _isLoading = false;
      notifyListeners();
      return false;
    }
    _ordonnances[idx] = _ordonnances[idx].copyWith(
      statut: StatutOrdonnance.refusee,
      motifRefus: raison,
    );
    _isLoading = false;
    notifyListeners();
    return true;
  }

  Future<bool> marquerPrete(String ordonnanceId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx == -1) return false;
    _ordonnances[idx] =
        _ordonnances[idx].copyWith(statut: StatutOrdonnance.prete);
    notifyListeners();
    return true;
  }

  Future<bool> confirmerPaiementRecu(
      String ordonnanceId, PaiementMobileModel paiement) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx == -1) return false;
    _ordonnances[idx] =
        _ordonnances[idx].copyWith(statut: StatutOrdonnance.payee);
    notifyListeners();
    return true;
  }
}
