// ════════════════════════════════════════════════════════════
//  vaccination_card_screen.dart
//  HELLO DOC - Carnet de vaccination
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class VaccinationCardScreen extends StatefulWidget {
  const VaccinationCardScreen({super.key});

  @override
  State<VaccinationCardScreen> createState() => _VaccinationCardScreenState();
}

class _VaccinationCardScreenState extends State<VaccinationCardScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Carnet de vaccinations',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: AppColors.success,
        foregroundColor: Colors.white,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.qr_code),
            onPressed: () => _showQRCode(context),
            tooltip: 'Afficher le QR Code',
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Carte résumé
            Container(
              width: double.infinity,
              margin: const EdgeInsets.all(16),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.success, AppColors.success.withValues(alpha: 0.7)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.success.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Icon(Icons.vaccines, color: Colors.white, size: 32),
                      ),
                      const SizedBox(width: 16),
                      const Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Statut vaccinal',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 14,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'À jour',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 24,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _StatItem(label: 'Vaccins reçus', value: '8'),
                        _StatItem(label: 'Rappels à venir', value: '2'),
                        _StatItem(label: 'En retard', value: '0'),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Prochains rappels
            const _SectionHeader(
              title: 'Prochains rappels',
              icon: Icons.notification_important,
              color: AppColors.warning,
            ),
            const _RappelCard(
              vaccin: 'Tétanos - Rappel décennal',
              datePrevu: '15 Mars 2025',
              description: 'Dernier rappel: 15 Mars 2015',
              urgent: true,
            ),
            const _RappelCard(
              vaccin: 'Grippe saisonnière',
              datePrevu: 'Octobre 2025',
              description: 'Vaccin annuel recommandé',
              urgent: false,
            ),

            // Vaccinations effectuées
            const _SectionHeader(
              title: 'Vaccinations effectuées',
              icon: Icons.check_circle,
              color: AppColors.success,
            ),
            const _VaccinCard(
              vaccin: 'COVID-19 (3ème dose)',
              date: '10 Janvier 2024',
              lieu: 'Centre de vaccination Cocody',
              lot: 'AB12345',
              medecin: 'Dr. KOUAME Jean',
            ),
            const _VaccinCard(
              vaccin: 'Fièvre jaune',
              date: '5 Juin 2023',
              lieu: 'Institut Pasteur',
              lot: 'YF789012',
              medecin: 'Dr. YAO Marie',
            ),
            const _VaccinCard(
              vaccin: 'Hépatite B (3ème dose)',
              date: '20 Mars 2022',
              lieu: 'Clinique du Plateau',
              lot: 'HB345678',
              medecin: 'Dr. DIALLO Amadou',
            ),
            const _VaccinCard(
              vaccin: 'Tétanos',
              date: '15 Mars 2015',
              lieu: 'CHU de Treichville',
              lot: 'TT901234',
              medecin: 'Dr. KONE Fatou',
            ),

            const SizedBox(height: 80),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddVaccinDialog(context),
        backgroundColor: AppColors.success,
        icon: const Icon(Icons.add),
        label: const Text('Ajouter un vaccin'),
      ),
    );
  }

  void _showQRCode(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('QR Code - Carnet vaccinal'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 200,
              height: 200,
              decoration: BoxDecoration(
                color: Colors.grey[200],
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.qr_code_2, size: 150, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            const Text(
              'Présentez ce QR code aux professionnels de santé',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Fermer'),
          ),
        ],
      ),
    );
  }

  void _showAddVaccinDialog(BuildContext context) {
    final vaccinCtrl = TextEditingController();
    final dateCtrl = TextEditingController();
    final lieuCtrl = TextEditingController();
    final lotCtrl = TextEditingController();
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ajouter un vaccin'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: vaccinCtrl,
                decoration: const InputDecoration(
                  labelText: 'Nom du vaccin',
                  hintText: 'Ex: COVID-19, Grippe...',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: dateCtrl,
                decoration: const InputDecoration(
                  labelText: 'Date',
                  hintText: 'JJ/MM/AAAA',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lieuCtrl,
                decoration: const InputDecoration(
                  labelText: 'Lieu de vaccination',
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: lotCtrl,
                decoration: const InputDecoration(
                  labelText: 'Numéro de lot',
                  hintText: 'Optionnel',
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
              // TODO: Sauvegarder le vaccin
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Vaccin ajouté avec succès')),
              );
            },
            child: const Text('Ajouter'),
          ),
        ],
      ),
    );
  }
}

class _StatItem extends StatelessWidget {
  final String label;
  final String value;

  const _StatItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 28,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 11,
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;

  const _SectionHeader({
    required this.title,
    required this.icon,
    required this.color,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 12),
      child: Row(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(width: 8),
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _RappelCard extends StatelessWidget {
  final String vaccin;
  final String datePrevu;
  final String description;
  final bool urgent;

  const _RappelCard({
    required this.vaccin,
    required this.datePrevu,
    required this.description,
    required this.urgent,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: urgent ? AppColors.error.withValues(alpha: 0.1) : AppColors.warning.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                urgent ? Icons.warning : Icons.schedule,
                color: urgent ? AppColors.error : AppColors.warning,
                size: 28,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    vaccin,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 14, color: AppColors.textSecondary),
                      const SizedBox(width: 4),
                      Text(
                        datePrevu,
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textLight,
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.arrow_forward_ios, size: 16),
              onPressed: () {},
            ),
          ],
        ),
      ),
    );
  }
}

class _VaccinCard extends StatelessWidget {
  final String vaccin;
  final String date;
  final String lieu;
  final String lot;
  final String medecin;

  const _VaccinCard({
    required this.vaccin,
    required this.date,
    required this.lieu,
    required this.lot,
    required this.medecin,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.check_circle, color: AppColors.success, size: 24),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        vaccin,
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
            _InfoRow(icon: Icons.location_on, text: lieu),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.qr_code, text: 'Lot: $lot'),
            const SizedBox(height: 6),
            _InfoRow(icon: Icons.person, text: medecin),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({required this.icon, required this.text});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 16, color: AppColors.textSecondary),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 13,
              color: AppColors.textLight,
            ),
          ),
        ),
      ],
    );
  }
}
