// ════════════════════════════════════════════════════════════
//  medical_record_screen.dart
//  HELLO DOC - Dossier médical patient
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../core/theme/app_theme.dart';
import '../../widgets/common/avatar_widget.dart';

class MedicalRecordScreen extends StatefulWidget {
  final String? patientName;
  final String? patientId;
  final String? patientAvatar;
  final bool isDoctorView;
  final String? bloodGroup;
  final String? allergies;
  final String? cmuNumber;

  const MedicalRecordScreen({
    super.key,
    this.patientName,
    this.patientId,
    this.patientAvatar,
    this.isDoctorView = false,
    this.bloodGroup,
    this.allergies,
    this.cmuNumber,
  });

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
    final title = widget.isDoctorView && widget.patientName != null
        ? 'Dossier : ${widget.patientName}'
        : 'Dossier médical';

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: Text(
          title,
          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 16),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        backgroundColor: widget.isDoctorView ? AppColors.brandNavy : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          if (widget.isDoctorView)
            Container(
              margin: const EdgeInsets.only(right: 12),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.brandTurquoise.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: AppColors.brandTurquoise),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(LucideIcons.stethoscope, size: 12, color: Colors.white),
                  SizedBox(width: 4),
                  Text(
                    'Espace Praticien',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
        ],
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
      body: Column(
        children: [
          // Bannière d'identité vitale si vue Médecin ou patient spécifié
          if (widget.isDoctorView) _buildDoctorPatientBanner(),

          // Contenu des onglets
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _AntecedentsTab(isDoctorView: widget.isDoctorView),
                _OrdonnancesTab(
                  isDoctorView: widget.isDoctorView,
                  onNewOrdonnance: () => _showAddOrdonnanceDialog(context),
                ),
                _ExamensTab(isDoctorView: widget.isDoctorView),
                _AllergiesTab(isDoctorView: widget.isDoctorView),
              ],
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddRecordDialog(context),
        backgroundColor: widget.isDoctorView ? AppColors.brandNavy : AppColors.primary,
        icon: const Icon(Icons.add_rounded, color: Colors.white),
        label: Text(
          widget.isDoctorView ? 'Ajouter une note' : 'Ajouter',
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ),
    );
  }

  /// Bannière récapitulative médicale du patient pour le praticien
  Widget _buildDoctorPatientBanner() {
    final patientName = widget.patientName ?? 'Patient';
    final bloodGroup = widget.bloodGroup ?? 'O+';
    final allergies = widget.allergies ?? 'Pénicilline';
    final cmuNumber = widget.cmuNumber ?? 'CMU-CI-98421';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
        border: const Border(
          bottom: BorderSide(color: AppColors.borderSubtle),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              AvatarWidget(
                imageUrl: widget.patientAvatar,
                initials: patientName.isNotEmpty ? patientName[0].toUpperCase() : 'P',
                size: 40,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      patientName,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'N° National / $cmuNumber',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          // Badges vitaux médicaux
          Wrap(
            spacing: 8,
            runSpacing: 6,
            children: [
              // Groupe sanguin
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFDC2626).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFDC2626).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.droplets, size: 12, color: Color(0xFFDC2626)),
                    const SizedBox(width: 4),
                    Text(
                      'Groupe: $bloodGroup',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFDC2626),
                      ),
                    ),
                  ],
                ),
              ),
              // Allergie critique
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFD97706).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: const Color(0xFFD97706).withValues(alpha: 0.3)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(LucideIcons.triangle_alert, size: 12, color: Color(0xFFD97706)),
                    const SizedBox(width: 4),
                    Text(
                      'Allergie: $allergies',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFFD97706),
                      ),
                    ),
                  ],
                ),
              ),
              // Constantes indicatives
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(LucideIcons.activity, size: 12, color: AppColors.brandBlue),
                    SizedBox(width: 4),
                    Text(
                      'TA: 12/8 • 74 bpm',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showAddOrdonnanceDialog(BuildContext context) {
    final medCtrl = TextEditingController();
    final posoCtrl = TextEditingController();
    final dureeCtrl = TextEditingController();

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Row(
          children: [
            Icon(LucideIcons.pill, color: AppColors.primary, size: 20),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Nouvelle Ordonnance',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.w700),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: medCtrl,
                decoration: const InputDecoration(
                  labelText: 'Médicament',
                  hintText: 'Ex: Amoxicilline 1g, Paracétamol...',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: posoCtrl,
                decoration: const InputDecoration(
                  labelText: 'Posologie',
                  hintText: 'Ex: 1 comprimé matin et soir',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dureeCtrl,
                decoration: const InputDecoration(
                  labelText: 'Durée du traitement',
                  hintText: 'Ex: Pendant 7 jours',
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Annuler'),
          ),
          ElevatedButton.icon(
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Ordonnance enregistrée et transmise au patient.'),
                  backgroundColor: AppColors.success,
                ),
              );
            },
            icon: const Icon(Icons.check, size: 16),
            label: const Text('Délivrer'),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
            ),
          ),
        ],
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
        content: SingleChildScrollView(
          child: Column(
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
        content: SingleChildScrollView(
          child: Column(
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
  final bool isDoctorView;
  const _AntecedentsTab({this.isDoctorView = false});

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
  final bool isDoctorView;
  final VoidCallback? onNewOrdonnance;

  const _OrdonnancesTab({this.isDoctorView = false, this.onNewOrdonnance});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (isDoctorView) ...[
          Container(
            margin: const EdgeInsets.only(bottom: 14),
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: onNewOrdonnance,
              icon: const Icon(LucideIcons.pill, size: 16, color: Colors.white),
              label: const Text(
                'Rédiger une ordonnance',
                style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, color: Colors.white),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.brandBlue,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
        const _OrdonnanceCard(
          doctorName: 'Dr. KOUAME Jean',
          date: '15 Janvier 2025',
          medications: ['Paracétamol 500mg - 3x/jour', 'Ibuprofène 400mg - 2x/jour'],
          status: 'Active',
        ),
        const _OrdonnanceCard(
          doctorName: 'Dr. YAO Marie',
          date: '10 Décembre 2024',
          medications: ['Amoxicilline 1g - 2x/jour'],
          status: 'Terminée',
        ),
        const _EmptyStateMessage(
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
  final bool isDoctorView;
  const _ExamensTab({this.isDoctorView = false});

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
                Expanded(
                  child: Text(
                    lieu,
                    style: const TextStyle(fontSize: 13, color: AppColors.textSecondary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
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
                  Expanded(
                    child: Text(
                      resultats,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.success,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
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
  final bool isDoctorView;
  const _AllergiesTab({this.isDoctorView = false});

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
