import '../models/pharmacie_model.dart';
import '../models/ordonnance_model.dart';
import '../models/paiement_mobile_model.dart';

/// Repository abstrait pour le module Pharmacie.
/// En production, l'implémentation concrète utilisera Firebase Firestore.
abstract class PharmacieRepository {
  Future<PharmacieModel> inscrirePharmacien(PharmacieModel pharmacie, String motDePasse);
  Future<PharmacieModel?> connecterPharmacien(String email, String motDePasse);
  Future<PharmacieModel?> getPharmacieParId(String id);
  Future<void> mettreAJourPharmacie(PharmacieModel pharmacie);
  Future<List<OrdonnanceModel>> getOrdonnancesPharmacien(String pharmacieId);
  Future<bool> validerOrdonnance(String ordonnanceId, double montant);
  Future<bool> refuserOrdonnance(String ordonnanceId, String raison);
  Future<bool> marquerOrdonnancePrete(String ordonnanceId);
  Future<PaiementMobileModel> initierPaiement(PaiementMobileModel paiement);
  Future<bool> confirmerPaiement(String paiementId);
}

/// Implémentation locale (mock) utilisée en mode demo/web preview.
class PharmacieRepositoryLocal implements PharmacieRepository {
  final List<PharmacieModel> _pharmacies = [];
  final List<OrdonnanceModel> _ordonnances = [];
  final List<PaiementMobileModel> _paiements = [];

  @override
  Future<PharmacieModel> inscrirePharmacien(
      PharmacieModel pharmacie, String motDePasse) async {
    await Future.delayed(const Duration(seconds: 1));
    _pharmacies.add(pharmacie);
    return pharmacie;
  }

  @override
  Future<PharmacieModel?> connecterPharmacien(
      String email, String motDePasse) async {
    await Future.delayed(const Duration(milliseconds: 800));
    // Compte démo
    if (email == 'pharmacie@medilink.ci' && motDePasse == 'allodoc2025') {
      return PharmacieModel(
        id: 'pharmacie_demo_001',
        nomPharmacie: 'Pharmacie Centrale du Plateau',
        nomTitulaire: 'KONAN',
        prenomTitulaire: 'Jean-Baptiste',
        numeroOrdreOPCI: 'OPCI-2023-4521',
        numeroLicenceExploitation: 'LIC-ABJ-2023-1189',
        commune: 'Plateau',
        adresseComplete: 'Rue du Commerce, Immeuble Alpha, 01 BP 1234 Abidjan 01',
        telephone: '+225 07 08 09 10 11',
        email: 'pharmacie@medilink.ci',
        motDePasse: '',
        horaires: {
          'Lun-Ven': '08h00 - 20h00',
          'Sam': '09h00 - 18h00',
          'Dim': '10h00 - 14h00',
        },
        estDeGarde: true,
        estVerifiee: true,
        accepteOrdonnances: true,
        createdAt: DateTime(2023, 6, 15),
      );
    }
    return null;
  }

  @override
  Future<PharmacieModel?> getPharmacieParId(String id) async {
    await Future.delayed(const Duration(milliseconds: 300));
    try {
      return _pharmacies.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> mettreAJourPharmacie(PharmacieModel pharmacie) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _pharmacies.indexWhere((p) => p.id == pharmacie.id);
    if (idx != -1) _pharmacies[idx] = pharmacie;
  }

  @override
  Future<List<OrdonnanceModel>> getOrdonnancesPharmacien(
      String pharmacieId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    return _ordonnances
        .where((o) => o.pharmacieId == pharmacieId)
        .toList();
  }

  @override
  Future<bool> validerOrdonnance(String ordonnanceId, double montant) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx == -1) return false;
    _ordonnances[idx] = _ordonnances[idx].copyWith(
      statut: StatutOrdonnance.validee,
      montantTotal: montant,
    );
    return true;
  }

  @override
  Future<bool> refuserOrdonnance(String ordonnanceId, String raison) async {
    await Future.delayed(const Duration(milliseconds: 500));
    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx == -1) return false;
    _ordonnances[idx] = _ordonnances[idx].copyWith(
      statut: StatutOrdonnance.refusee,
      motifRefus: raison,
    );
    return true;
  }

  @override
  Future<bool> marquerOrdonnancePrete(String ordonnanceId) async {
    await Future.delayed(const Duration(milliseconds: 400));
    final idx = _ordonnances.indexWhere((o) => o.id == ordonnanceId);
    if (idx == -1) return false;
    _ordonnances[idx] =
        _ordonnances[idx].copyWith(statut: StatutOrdonnance.prete);
    return true;
  }

  @override
  Future<PaiementMobileModel> initierPaiement(
      PaiementMobileModel paiement) async {
    await Future.delayed(const Duration(milliseconds: 800));
    final p = paiement.copyWith(statut: StatutPaiement.enCours);
    _paiements.add(p);
    return p;
  }

  @override
  Future<bool> confirmerPaiement(String paiementId) async {
    await Future.delayed(const Duration(milliseconds: 600));
    final idx = _paiements.indexWhere((p) => p.id == paiementId);
    if (idx == -1) return false;
    _paiements[idx] =
        _paiements[idx].copyWith(statut: StatutPaiement.confirme);
    return true;
  }
}
