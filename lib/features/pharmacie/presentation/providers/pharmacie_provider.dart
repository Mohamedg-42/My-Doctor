import 'package:flutter/foundation.dart';
import '../../data/models/pharmacie_model.dart';
import '../../data/models/ordonnance_model.dart';
import '../../data/models/paiement_mobile_model.dart';

enum PharmacieAuthState { initial, loading, authenticated, unauthenticated, error }

class PharmacieProvider extends ChangeNotifier {
  PharmacieAuthState _authState = PharmacieAuthState.unauthenticated;
  PharmacieModel? _pharmacieCourante;
  List<OrdonnanceModel> _ordonnances = [];
  List<PaiementMobileModel> _paiements = [];
  bool _isLoading = false;
  String? _errorMessage;
  StatutOrdonnance? _filtreStatut;

  // ─── Getters ────────────────────────────────────────────────────────────────
  PharmacieAuthState get authState => _authState;
  PharmacieModel? get pharmacieCourante => _pharmacieCourante;
  bool get isAuthenticated => _authState == PharmacieAuthState.authenticated;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  StatutOrdonnance? get filtreStatut => _filtreStatut;

  List<OrdonnanceModel> get ordonnances {
    if (_filtreStatut == null) return _ordonnances;
    return _ordonnances.where((o) => o.statut == _filtreStatut).toList();
  }

  List<OrdonnanceModel> get ordonnancesEnAttente =>
      _ordonnances.where((o) => o.statut == StatutOrdonnance.enAttente).toList();

  List<OrdonnanceModel> get ordonnancesValidees =>
      _ordonnances.where((o) => o.statut == StatutOrdonnance.validee).toList();

  List<OrdonnanceModel> get ordonnancesPaYees =>
      _ordonnances.where((o) => o.statut == StatutOrdonnance.payee).toList();

  List<OrdonnanceModel> get ordonnancesPretes =>
      _ordonnances.where((o) => o.statut == StatutOrdonnance.prete).toList();

  int get totalEnAttente => ordonnancesEnAttente.length;
  int get totalValidees => ordonnancesValidees.length;
  int get totalPayees => ordonnancesPaYees.length;

  double get chiffreAffaireJour {
    final today = DateTime.now();
    return _paiements
        .where((p) =>
            p.statut == StatutPaiement.confirme &&
            p.createdAt.day == today.day &&
            p.createdAt.month == today.month &&
            p.createdAt.year == today.year)
        .fold(0.0, (sum, p) => sum + p.montantFCFA);
  }

  // ─── Connexion Pharmacie ────────────────────────────────────────────────────
  Future<bool> connecter({required String email, required String motDePasse}) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 1));

    // Chercher dans les pharmacies démo
    final pharma = PharmacieDemo.all.where((p) =>
        (p.email.toLowerCase() == email.toLowerCase() ||
         p.telephone.replaceAll(' ', '') == email.replaceAll(' ', '')) &&
        p.motDePasse == motDePasse).firstOrNull;

    if (pharma != null) {
      _pharmacieCourante = pharma;
      _authState = PharmacieAuthState.authenticated;
      _chargerOrdonnances();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    // Accès démo avec email générique
    if ((email == 'pharmacie@medilink.ci' || email == 'demo') &&
        (motDePasse == 'pharma2025' || motDePasse == 'demo')) {
      _pharmacieCourante = PharmacieDemo.pharma1;
      _authState = PharmacieAuthState.authenticated;
      _chargerOrdonnances();
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _errorMessage = 'Email/téléphone ou mot de passe incorrect';
    _authState = PharmacieAuthState.unauthenticated;
    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ─── Connexion directe démo ─────────────────────────────────────────────────
  Future<bool> connexionDemoDirecte() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(milliseconds: 500));
    _pharmacieCourante = PharmacieDemo.pharma1;
    _authState = PharmacieAuthState.authenticated;
    _chargerOrdonnances();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ─── Inscription Pharmacie ──────────────────────────────────────────────────
  Future<bool> inscrire(PharmacieModel pharmacie) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    _pharmacieCourante = pharmacie.copyWith(estVerifiee: false);
    _authState = PharmacieAuthState.authenticated;
    _chargerOrdonnances();
    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ─── Déconnexion ─────────────────────────────────────────────────────────────
  void deconnecter() {
    _pharmacieCourante = null;
    _authState = PharmacieAuthState.unauthenticated;
    _ordonnances = [];
    _paiements = [];
    _filtreStatut = null;
    notifyListeners();
  }

  // ─── Charger ordonnances ────────────────────────────────────────────────────
  void _chargerOrdonnances() {
    if (_pharmacieCourante == null) return;
    _ordonnances = OrdonnanceDemo.ordonnances
        .where((o) => o.pharmacieId == _pharmacieCourante!.id)
        .toList();
    _ordonnances.sort((a, b) => b.dateEmission.compareTo(a.dateEmission));
    _chargerPaiements();
  }

  void _chargerPaiements() {
    _paiements = [
      PaiementMobileModel(
        id: 'pay_001',
        ordonnanceId: 'ord_003',
        patientId: 'usr_konan',
        pharmacieId: _pharmacieCourante?.id ?? '',
        montantFCFA: 28500,
        operateur: OperateurMobileMoney.orangeMoney,
        numeroTelephone: '+225 07 23 45 67 89',
        statut: StatutPaiement.confirme,
        createdAt: DateTime.now().subtract(const Duration(hours: 3)),
        reference: 'OM-2025-789456',
      ),
      PaiementMobileModel(
        id: 'pay_002',
        ordonnanceId: 'ord_004',
        patientId: 'usr_akissi',
        pharmacieId: _pharmacieCourante?.id ?? '',
        montantFCFA: 30000,
        operateur: OperateurMobileMoney.wave,
        numeroTelephone: '+225 07 77 88 99 00',
        statut: StatutPaiement.confirme,
        createdAt: DateTime.now().subtract(const Duration(minutes: 45)),
        reference: 'WV-2025-123789',
        montantCmuRembourse: 18000,
      ),
    ];
  }

  // ─── Filtrer ordonnances ────────────────────────────────────────────────────
  void setFiltreStatut(StatutOrdonnance? statut) {
    _filtreStatut = statut;
    notifyListeners();
  }

  // ─── Valider ordonnance ─────────────────────────────────────────────────────
  Future<bool> validerOrdonnance(String ordonnanceId, double montant) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx != -1) {
      _ordonnances[idx] = _ordonnances[idx].copyWith(
        statut: StatutOrdonnance.validee,
        montantTotal: montant,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ─── Refuser ordonnance ─────────────────────────────────────────────────────
  Future<bool> refuserOrdonnance(String ordonnanceId, String motif) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 800));

    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx != -1) {
      _ordonnances[idx] = _ordonnances[idx].copyWith(
        statut: StatutOrdonnance.refusee,
        motifRefus: motif,
      );
      _isLoading = false;
      notifyListeners();
      return true;
    }

    _isLoading = false;
    notifyListeners();
    return false;
  }

  // ─── Marquer prête ──────────────────────────────────────────────────────────
  Future<bool> marquerPrete(String ordonnanceId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx != -1) {
      _ordonnances[idx] = _ordonnances[idx].copyWith(statut: StatutOrdonnance.prete);
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Marquer livrée ────────────────────────────────────────────────────────
  Future<bool> marquerLivree(String ordonnanceId) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx != -1) {
      _ordonnances[idx] = _ordonnances[idx].copyWith(statut: StatutOrdonnance.livree);
      notifyListeners();
      return true;
    }
    return false;
  }

  // ─── Initier paiement ──────────────────────────────────────────────────────
  Future<bool> initierPaiement(PaiementMobileModel paiement) async {
    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(seconds: 2));

    // Simuler succès paiement
    final paiementConfirme = PaiementMobileModel(
      id: paiement.id,
      ordonnanceId: paiement.ordonnanceId,
      patientId: paiement.patientId,
      pharmacieId: paiement.pharmacieId,
      montantFCFA: paiement.montantFCFA,
      operateur: paiement.operateur,
      numeroTelephone: paiement.numeroTelephone,
      statut: StatutPaiement.confirme,
      createdAt: paiement.createdAt,
      reference: 'MED-${DateTime.now().millisecondsSinceEpoch}',
      montantCmuRembourse: paiement.montantCmuRembourse,
    );

    _paiements.add(paiementConfirme);

    // Mettre à jour le statut de l'ordonnance
    final idx = _ordonnances.indexWhere((o) => o.id == paiement.ordonnanceId);
    if (idx != -1) {
      _ordonnances[idx] = _ordonnances[idx].copyWith(statut: StatutOrdonnance.payee);
    }

    _isLoading = false;
    notifyListeners();
    return true;
  }

  // ─── Mettre à jour profil ───────────────────────────────────────────────────
  Future<bool> mettreAJourProfil({
    bool? estDeGarde,
    bool? accepteOrdonnances,
    Map<String, String>? horaires,
  }) async {
    if (_pharmacieCourante == null) return false;

    await Future.delayed(const Duration(milliseconds: 500));

    _pharmacieCourante = _pharmacieCourante!.copyWith(
      estDeGarde: estDeGarde,
      accepteOrdonnances: accepteOrdonnances,
      horaires: horaires,
    );
    notifyListeners();
    return true;
  }

  // ─── Rafraîchir ────────────────────────────────────────────────────────────
  Future<void> rafraichir() async {
    _isLoading = true;
    notifyListeners();
    await Future.delayed(const Duration(seconds: 1));
    _chargerOrdonnances();
    _isLoading = false;
    notifyListeners();
  }

  OrdonnanceModel? getOrdonnanceById(String id) {
    try {
      return _ordonnances.firstWhere((o) => o.id == id);
    } catch (_) {
      return null;
    }
  }
}
