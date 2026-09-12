import '../../data/models/pharmacie_model.dart';
import '../../data/repositories/pharmacie_repository.dart';

class InscrirePharmacieUsecase {
  final PharmacieRepository repository;
  InscrirePharmacieUsecase(this.repository);

  Future<PharmacieModel> execute(PharmacieModel pharmacie, String motDePasse) {
    return repository.inscrirePharmacien(pharmacie, motDePasse);
  }
}
