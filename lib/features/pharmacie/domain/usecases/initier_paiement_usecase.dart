import '../../data/models/paiement_mobile_model.dart';
import '../../data/repositories/pharmacie_repository.dart';

class InitierPaiementUsecase {
  final PharmacieRepository repository;
  InitierPaiementUsecase(this.repository);

  Future<PaiementMobileModel> execute(PaiementMobileModel paiement) {
    return repository.initierPaiement(paiement);
  }

  Future<bool> confirmer(String paiementId) {
    return repository.confirmerPaiement(paiementId);
  }
}
