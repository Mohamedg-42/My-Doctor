// ════════════════════════════════════════════════════════════
//  medical_record_screen.dart
//  HELLO DOC - Dossier médical patient
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class MedicalRecordScreen extends StatefulWidget {
  const MedicalRecordScreen({super.key});

  @override
  State<MedicalRecordScreen> createState() => _MedicalRecordScreenState();
}

class _MedicalRecordScreenState extends State<MedicalRecordScreen> with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Dossier médical',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          isScrollable: true,
          tabs: const [
            Tab(text: 'Antécédents'),
            Tab(text: 'Ordonnances'),
            Tab(text: 'Examens'),
            Tab(text: 'Allergies'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _AntecedentsTab(),
          _OrdonnancesTab(),
          _ExamensTab(),
          _AllergiesTab(),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecordDialog(context),
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter'),
      ),
    );
  }

  void _showAddRecordDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter une entrée'),
        content: const Text('Sélectionnez le type d\'information à ajouter'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddAntecedentDialog(context);
            },
            child: const Text('Antécédent'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              _showAddAllergieDialog(context);
            },
            child: const Text('Allergie'),
          ),
        ],
      ),
    );
  }

  void _showAddAntecedentDialog(BuildContext context) {
    final typeCtrl = TextEditingController();
    final descCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvel antécédent'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: typeCtrl,
              decoration: const InputDecoration(
                labelText: 'Type',
                hintText: 'Ex: Diabète, Hypertension...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                labelText: 'Description',
                hintText: 'Détails supplémentaires...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Sauvegarder l'antécédent
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Antécédent ajouté')),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }

  void _showAddAllergieDialog(BuildContext context) {
    final nomCtrl = TextEditingController();
    final reactionCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Nouvelle allergie'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nomCtrl,
              decoration: const InputDecoration(
                labelText: 'Allergène',
                hintText: 'Ex: Pénicilline, Arachides...',
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: reactionCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Réaction',
                hintText: 'Description de la réaction...',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Annuler'),
          ),
          ElevatedButton(
            onPressed: () {
              // TODO: Sauvegarder l'allergie
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Allergie ajoutée')),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET ANTÉCÉDENTS
// ═══════════════════════════════════════════════════════════════

class _AntecedentsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _AntecedentCard(
          type: 'Diabète de type 2',
          date: 'Diagnostiqué en 2018',
          description: 'Contrôlé par régime alimentaire et médication',
          color: Colors.orange,
        ),
        _AntecedentCard(
          type: 'Hypertension',
          date: 'Diagnostiqué en 2020',
          description: 'Traitement: Amlodipine 5mg/jour',
          color: Colors.red,
        ),
        _EmptyStateMessage(
          message: 'Vous pouvez ajouter vos antécédents médicaux en cliquant sur le bouton +',
        ),
      ],
    );
  }
}

class _AntecedentCard extends StatelessWidget {
  final String type;
  final String date;
  final String description;
  final Color color;

  const _AntecedentCard({
    required this.type,
    required this.date,
    required this.description,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.medical_information, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    type,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    date,
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET ORDONNANCES
// ═══════════════════════════════════════════════════════════════

class _OrdonnancesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _OrdonnanceCard(
          doctorName: 'Dr. KOUAME Jean',
          date: '15 Janvier 2025',
          medications: ['Paracétamol 500mg - 3x/jour', 'Ibuprofène 400mg - 2x/jour'],
          status: 'Active',
        ),
        _OrdonnanceCard(
          doctorName: 'Dr. YAO Marie',
          date: '10 Décembre 2024',
          medications: ['Amoxicilline 1g - 2x/jour'],
          status: 'Terminée',
        ),
        _EmptyStateMessage(
          message: 'Vos ordonnances apparaîtront ici après vos consultations',
        ),
      ],
    );
  }
}

class _OrdonnanceCard extends StatelessWidget {
  final String doctorName;
  final String date;
  final List<String> medications;
  final String status;

  const _OrdonnanceCard({
    required this.doctorName,
    required this.date,
    required this.medications,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = status == 'Active';
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        doctorName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.success.withValues(alpha: 0.1) : Colors.grey[200],
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    status,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: isActive ? AppColors.success : Colors.grey[600],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            const Divider(),
            const SizedBox(height: 8),
            ...medications.map((med) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    children: [
                      const Icon(Icons.medication, size: 16, color: AppColors.primary),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          med,
                          style: const TextStyle(fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                )),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () {},
                icon: const Icon(Icons.download, size: 18),
                label: const Text('Télécharger le PDF'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET EXAMENS
// ═══════════════════════════════════════════════════════════════

class _ExamensTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _ExamenCard(
          type: 'Analyses de sang',
          date: '20 Janvier 2025',
          lieu: 'Laboratoire BioLab',
          resultats: 'Résultats disponibles',
          color: Colors.red,
        ),
        _ExamenCard(
          type: 'Radiographie thoracique',
          date: '5 Janvier 2025',
          lieu: 'Centre d\'Imagerie Médicale',
          resultats: 'Résultats disponibles',
          color: Colors.blue,
        ),
        _EmptyStateMessage(
          message: 'Vos examens médicaux et résultats apparaîtront ici',
        ),
      ],
    );
  }
}

class _ExamenCard extends StatelessWidget {
  final String type;
  final String date;
  final String lieu;
  final String resultats;
  final Color color;

  const _ExamenCard({
    required this.type,
    required this.date,
    required this.lieu,
    required this.resultats,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.science, color: color, size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        type,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        date,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: AppColors.textSecondary),
                const SizedBox(width: 4),
                Text(
                  lieu,
                  style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: AppColors.success.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle, color: AppColors.success, size: 18),
                  const SizedBox(width: 8),
                  Text(
                    resultats,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.success,
                    ),
                  ),
                  const Spacer(),
                  TextButton(
                    onPressed: () {},
                    child: const Text('Voir'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// ONGLET ALLERGIES
// ═══════════════════════════════════════════════════════════════

class _AllergiesTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        _AllergieCard(
          allergene: 'Pénicilline',
          reaction: 'Éruptions cutanées, démangeaisons',
          severite: 'Modérée',
          color: Colors.orange,
        ),
        _AllergieCard(
          allergene: 'Arachides',
          reaction: 'Difficultés respiratoires, urticaire',
          severite: 'Sévère',
          color: Colors.red,
        ),
        _EmptyStateMessage(
          message: 'Ajoutez vos allergies pour informer vos médecins',
        ),
      ],
    );
  }
}

class _AllergieCard extends StatelessWidget {
  final String allergene;
  final String reaction;
  final String severite;
  final Color color;

  const _AllergieCard({
    required this.allergene,
    required this.reaction,
    required this.severite,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.warning, color: color, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          allergene,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          severite,
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: color,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Réaction: $reaction',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// MESSAGE ÉTAT VIDE
// ═══════════════════════════════════════════════════════════════

class _EmptyStateMessage extends StatelessWidget {
  final String message;

  const _EmptyStateMessage({required this.message});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 20),
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: AppColors.primary.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
        children: [
          Icon(Icons.info_outline, size: 48, color: AppColors.primary.withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            message,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 14,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
