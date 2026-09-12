import '../../data/repositories/pharmacie_repository.dart';

class ValiderOrdonnanceUsecase {
  final PharmacieRepository repository;
  ValiderOrdonnanceUsecase(this.repository);

  Future<bool> execute(String ordonnanceId, double montant) {
    return repository.validerOrdonnance(ordonnanceId, montant);
  }

  Future<bool> refuser(String ordonnanceId, String raison) {
    return repository.refuserOrdonnance(ordonnanceId, raison);
  }
}
