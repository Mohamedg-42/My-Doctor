import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../widgets/common/profile_photo_picker.dart';

/// Dashboard Allo Doc - Design moderne avec Bento Layout
/// Reproduit le design du fichier stitch_allo_doc_telemedicine_platform
class DashboardAlloDocTab extends StatefulWidget {
  const DashboardAlloDocTab({super.key});

  @override
  State<DashboardAlloDocTab> createState() => _DashboardAlloDocTabState();
}

class _DashboardAlloDocTabState extends State<DashboardAlloDocTab> {
  bool _isOnline = true;

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doctor = context.watch<DoctorProvider>();
    final stats = doctor.stats;
    final now = DateTime.now();

    return Scaffold(
      backgroundColor: const Color(0xFFF6F9FF), // background
      body: Column(
        children: [
          // ═══════════════════════════════════════════════════════════
          // HEADER (TopAppBar)
          // ═══════════════════════════════════════════════════════════
          _buildHeader(context, auth),

          // ═══════════════════════════════════════════════════════════
          // CONTENU PRINCIPAL (Main Canvas)
          // ═══════════════════════════════════════════════════════════
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ═══════════════════════════════════════════════════════════
                  // BENTO LAYOUT - 3 Cartes en grille
                  // ═══════════════════════════════════════════════════════════
                  _buildBentoGrid(context, stats),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // DEMANDES IMMÉDIATES (Urgent Alerts)
                  // ═══════════════════════════════════════════════════════════
                  _buildUrgentRequests(context),
                  const SizedBox(height: 24),

                  // ═══════════════════════════════════════════════════════════
                  // AGENDA DU JOUR (Daily Appointments)
                  // ═══════════════════════════════════════════════════════════
                  _buildDailyAgenda(context),
                  const SizedBox(height: 100), // Padding for bottom nav
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Header (TopAppBar)
  // ═══════════════════════════════════════════════════════════
  Widget _buildHeader(BuildContext context, AuthProvider auth) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(
          bottom: BorderSide(color: Color(0xFFC2C6D4), width: 1),
        ),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          child: Row(
            children: [
              // Logo + Nom
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF00478D), width: 2),
                ),
                child: ProfileAvatar(
                  base64Data: auth.currentUserAvatarBase64,
                  networkUrl: auth.currentUser?.avatarUrl,
                  initials: auth.userInitials,
                  size: 40,
                  showBorder: false,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Allo Doc',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF00478D),
                      ),
                    ),
                    Text(
                      'Dr. ${auth.currentUser?.lastName ?? ''}',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF424752),
                      ),
                    ),
                  ],
                ),
              ),
              // Icône localisation
              IconButton(
                icon: const Icon(Icons.location_on, color: Color(0xFF00478D)),
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('📍 Localisation')),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Bento Grid (3 cartes)
  // ═══════════════════════════════════════════════════════════
  Widget _buildBentoGrid(BuildContext context, DoctorStats stats) {
    return LayoutBuilder(
      builder: (context, constraints) {
        // Responsive: 1 colonne sur mobile, 3 colonnes sur desktop
        final isMobile = constraints.maxWidth < 768;
        
        return GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: isMobile ? 1 : 3,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: isMobile ? 2.5 : 1.3,
          children: [
            // Carte 1: Statut avec toggle
            _buildStatusCard(),
            // Carte 2: Revenus du jour
            _buildRevenueCard(stats),
            // Carte 3: Prochain RDV
            _buildNextAppointmentCard(),
          ],
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Carte Statut (avec toggle En ligne/Hors ligne)
  // ═══════════════════════════════════════════════════════════
  Widget _buildStatusCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFC2C6D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'STATUT',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424752),
                  letterSpacing: 1.2,
                ),
              ),
              // Badge En ligne/Hors ligne
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: _isOnline
                      ? const Color(0xFF75F999) // secondary-container
                      : const Color(0xFFD4E5F5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _isOnline
                            ? const Color(0xFF007236) // on-secondary-container
                            : const Color(0xFF424752),
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      _isOnline ? 'En ligne' : 'Hors ligne',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: _isOnline
                            ? const Color(0xFF007236)
                            : const Color(0xFF424752),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          // Content
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Disponibilité',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Prêt pour consultations',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: Color(0xFF424752),
                    ),
                  ),
                ],
              ),
              // Toggle Switch
              Switch(
                value: _isOnline,
                onChanged: (value) {
                  setState(() {
                    _isOnline = value;
                  });
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        value
                            ? '✅ Vous êtes maintenant en ligne'
                            : '⚠️ Vous êtes maintenant hors ligne',
                      ),
                    ),
                  );
                },
                activeThumbColor: const Color(0xFF006D33), // secondary
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Carte Revenus (fond bleu)
  // ═══════════════════════════════════════════════════════════
  Widget _buildRevenueCard(DoctorStats stats) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF00478D), // primary
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF00478D).withValues(alpha: 0.3),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFF005EB8)), // primary-container
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'REVENUS DU JOUR',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1.2,
                ),
              ),
              const Icon(Icons.payments, color: Colors.white, size: 24),
            ],
          ),
          // Content
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                '${(stats.revenue / 1000).toStringAsFixed(0)}.500 FCFA',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '${stats.completedThisMonth} consultations terminées',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Carte Prochain RDV
  // ═══════════════════════════════════════════════════════════
  Widget _buildNextAppointmentCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 20,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(color: const Color(0xFFC2C6D4)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Header
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PROCHAIN RDV',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF424752),
                  letterSpacing: 1.2,
                ),
              ),
              Icon(Icons.schedule, color: Color(0xFF00478D), size: 24),
            ],
          ),
          // Content
          Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: const Color(0xFFD4E5F5), // surface-container-highest
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Center(
                  child: Text(
                    '14:30',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF00478D),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Moussa Traoré',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                    Text(
                      'Suivi Cardiologie',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: Color(0xFF424752),
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

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Demandes Immédiates (Urgent)
  // ═══════════════════════════════════════════════════════════
  Widget _buildUrgentRequests(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Titre de section
        Row(
          children: [
            const Text(
              'Demandes Immédiates',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFFBA1A1A), // error
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Text(
                'URGENT',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  letterSpacing: 1,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Carte d'alerte urgente
        TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: -4.0),
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
          builder: (context, value, child) {
            return Transform.translate(
              offset: Offset(0, value.abs() == 4 ? 0 : value),
              child: child,
            );
          },
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFFFDAD6), // error-container
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFFBA1A1A).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              children: [
                // Icône urgence
                Container(
                  width: 48,
                  height: 48,
                  decoration: const BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.emergency,
                    color: Color(0xFFBA1A1A),
                    size: 28,
                  ),
                ),
                const SizedBox(width: 16),
                // Info patient
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Amadou Barry',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF93000A), // on-error-container
                        ),
                      ),
                      Text(
                        'Symptômes grippaux sévères • Il y a 2 min',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF93000A),
                        ),
                      ),
                    ],
                  ),
                ),
                // Bouton Accepter
                ElevatedButton(
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('✅ Demande acceptée'),
                        backgroundColor: Color(0xFF006D33),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFBA1A1A), // error
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                  ),
                  child: const Text(
                    'Accepter',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Agenda du Jour
  // ═══════════════════════════════════════════════════════════
  Widget _buildDailyAgenda(BuildContext context) {
    final appointments = [
      {
        'time': '15:00',
        'duration': '30 min',
        'patient': 'Marie-Claire Yao',
        'reason': 'Renouvellement ordonnance',
        'status': 'Confirmé',
        'statusColor': const Color(0xFFD4E5F5),
        'icon': Icons.videocam,
        'completed': false,
      },
      {
        'time': '15:45',
        'duration': '20 min',
        'patient': 'Jean-Baptiste Kouassi',
        'reason': 'Première consultation',
        'status': 'Payé',
        'statusColor': const Color(0xFF75F999),
        'icon': Icons.chat,
        'completed': false,
      },
      {
        'time': '11:00',
        'duration': 'Terminé',
        'patient': 'Fatou N\'diaye',
        'reason': 'Consultation générale',
        'status': null,
        'statusColor': null,
        'icon': Icons.check_circle,
        'completed': true,
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Agenda du Jour',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.w600,
                color: Colors.black87,
              ),
            ),
            TextButton.icon(
              onPressed: () {
                DefaultTabController.of(context).animateTo(1);
              },
              icon: const Text(
                'Voir tout l\'agenda',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Color(0xFF00478D),
                ),
              ),
              label: const Icon(
                Icons.arrow_forward,
                color: Color(0xFF00478D),
                size: 16,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        // Liste des rendez-vous
        Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 20,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: const Color(0xFFC2C6D4)),
          ),
          child: Column(
            children: appointments.asMap().entries.map((entry) {
              final index = entry.key;
              final appt = entry.value;
              final isLast = index == appointments.length - 1;

              return Container(
                decoration: BoxDecoration(
                  color: (appt['completed'] as bool)
                      ? const Color(0xFFE0F0FF).withValues(alpha: 0.6)
                      : Colors.white,
                  border: !isLast
                      ? const Border(
                          bottom: BorderSide(color: Color(0xFFC2C6D4)),
                        )
                      : null,
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('📅 Détails: ${appt['patient']}'),
                        ),
                      );
                    },
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Heure
                          SizedBox(
                            width: 48,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appt['time'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: (appt['completed'] as bool)
                                        ? Colors.grey
                                        : const Color(0xFF00478D),
                                  ),
                                ),
                                Text(
                                  appt['duration'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFF424752),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          // Avatar
                          Container(
                            width: 40,
                            height: 40,
                            decoration: const BoxDecoration(
                              color: Color(0xFFD4E5F5),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF424752),
                              size: 20,
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Info
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  appt['patient'] as String,
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.black87,
                                    decoration: (appt['completed'] as bool)
                                        ? TextDecoration.lineThrough
                                        : null,
                                  ),
                                ),
                                Text(
                                  appt['reason'] as String,
                                  style: const TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 12,
                                    color: Color(0xFF424752),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          // Badge statut + icône
                          if (!(appt['completed'] as bool)) ...[
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: appt['statusColor'] as Color,
                                borderRadius: BorderRadius.circular(20),
                              ),
                              child: Text(
                                appt['status'] as String,
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  fontWeight: FontWeight.bold,
                                  color: appt['status'] == 'Payé'
                                      ? const Color(0xFF007236)
                                      : const Color(0xFF424752),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              icon: Icon(
                                appt['icon'] as IconData,
                                color: const Color(0xFF00478D),
                                size: 20,
                              ),
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('📹 Démarrer la consultation'),
                                  ),
                                );
                              },
                            ),
                          ] else
                            const Icon(
                              Icons.check_circle,
                              color: Color(0xFF006D33),
                              size: 24,
                            ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}
