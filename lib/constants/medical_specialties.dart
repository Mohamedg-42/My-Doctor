// ════════════════════════════════════════════════════════════
//  medical_specialties.dart
//  Liste complète des spécialités médicales
// ════════════════════════════════════════════════════════════

class MedicalSpecialties {
  static const List<String> specialties = [
    'Médecine Générale',
    'Pédiatrie',
    'Gynécologie-Obstétrique',
    'Cardiologie',
    'Dermatologie',
    'Ophtalmologie',
    'ORL (Oto-Rhino-Laryngologie)',
    'Pneumologie',
    'Gastro-entérologie',
    'Endocrinologie',
    'Néphrologie',
    'Urologie',
    'Neurologie',
    'Psychiatrie',
    'Rhumatologie',
    'Orthopédie et Traumatologie',
    'Chirurgie Générale',
    'Chirurgie Plastique et Reconstructrice',
    'Chirurgie Cardiovasculaire',
    'Neurochirurgie',
    'Anesthésie-Réanimation',
    'Radiologie',
    'Médecine Interne',
    'Allergologie',
    'Infectiologie',
    'Hématologie',
    'Oncologie Médicale',
    'Médecine du Travail',
    'Médecine du Sport',
    'Gériatrie',
    'Médecine d\'Urgence',
    'Réanimation Médicale',
    'Stomatologie',
    'Odontologie',
    'Nutrition',
    'Andrologie',
    'Médecine Physique et Réadaptation',
    'Génétique Médicale',
    'Médecine Nucléaire',
    'Anatomie et Cytologie Pathologiques',
    'Biologie Médicale',
    'Pharmacologie',
    'Santé Publique',
  ];

  /// Obtenir les spécialités les plus courantes (pour affichage rapide)
  static List<String> get commonSpecialties => [
        'Médecine Générale',
        'Pédiatrie',
        'Gynécologie-Obstétrique',
        'Cardiologie',
        'Dermatologie',
        'Ophtalmologie',
        'ORL (Oto-Rhino-Laryngologie)',
        'Chirurgie Générale',
      ];

  /// Vérifier si une spécialité existe dans la liste
  static bool isValid(String specialty) {
    return specialties.contains(specialty);
  }
}
