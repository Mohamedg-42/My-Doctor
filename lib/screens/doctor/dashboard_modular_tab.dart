import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';
import '../../providers/app_provider.dart';
import '../../providers/doctor_provider.dart';
import '../../providers/treating_request_provider.dart';
import '../../widgets/common/profile_photo_picker.dart';
import 'doctor_notifications_screen.dart';
import 'doctor_payment_screen.dart';
import 'manage_slots_screen.dart';
import 'doctor_requests_screen.dart';

class DashboardModularTab extends StatelessWidget {
  const DashboardModularTab({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final doctor = context.watch<DoctorProvider>();
    final stats = doctor.stats;
    final now = DateTime.now();
    final timeOfDay = now.hour < 12 ? 'Bonjour' : (now.hour < 18 ? 'Bon après-midi' : 'Bonsoir');

    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ═══════════════════════════════════════════════════════════
          // HEADER PERSONNALISÉ
          // ═══════════════════════════════════════════════════════════
          Container(
            padding: const EdgeInsets.fromLTRB(20, 56, 20, 24),
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Color(0xFF4DD0E1),
                  Color(0xFF26C6DA),
                ],
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Ligne 1: Avatar + Accueil + Notification + Paramètres
                Row(
                  children: [
                    // Avatar avec badge en ligne
                    ProfileAvatar(
                      base64Data: auth.currentUserAvatarBase64,
                      networkUrl: auth.currentUser?.avatarUrl,
                      initials: auth.userInitials,
                      size: 48,
                      showBorder: true,
                    ),
                    const SizedBox(width: 12),
                    // Message d'accueil
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '$timeOfDay, ',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: Colors.white.withValues(alpha: 0.9),
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              Icon(
                                _getWeatherIcon(now.hour),
                                size: 18,
                                color: Colors.white.withValues(alpha: 0.9),
                              ),
                            ],
                          ),
                          Text(
                            'Dr. ${auth.currentUser?.firstName ?? ''} ${auth.currentUser?.lastName ?? ''}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                    // Bouton notification
                    Consumer<AppProvider>(
                      builder: (_, app, __) {
                        final unreadCount = app.notifications.where((n) => !n.isRead).length;
                        
                        return GestureDetector(
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) => const DoctorNotificationsScreen(),
                              ),
                            );
                          },
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                padding: const EdgeInsets.all(10),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.2),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(
                                  Icons.notifications_outlined,
                                  color: Colors.white,
                                  size: 22,
                                ),
                              ),
                              if (unreadCount > 0)
                                Positioned(
                                  top: -4,
                                  right: -4,
                                  child: Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.red,
                                      borderRadius: BorderRadius.circular(10),
                                      border: Border.all(color: Colors.white, width: 2),
                                    ),
                                    constraints: const BoxConstraints(minWidth: 18, minHeight: 18),
                                    child: Text(
                                      unreadCount > 99 ? '99+' : unreadCount.toString(),
                                      style: const TextStyle(
                                        fontFamily: 'Poppins',
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.white,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Date et spécialité
                Row(
                  children: [
                    Icon(Icons.medical_services_outlined, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text(
                      auth.doctorProfile?.specialty ?? 'Médecin',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Icon(Icons.calendar_today_outlined, size: 14, color: Colors.white.withValues(alpha: 0.8)),
                    const SizedBox(width: 6),
                    Text(
                      DateFormat('EEEE d MMMM', 'fr_FR').format(now),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.9),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),

          // ═══════════════════════════════════════════════════════════
          // CONTENU PRINCIPAL
          // ═══════════════════════════════════════════════════════════
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ═══════════════════════════════════════════════════════════
                // CARTES INTERACTIVES (Grid 2x2)
                // ═══════════════════════════════════════════════════════════
                Row(
                  children: [
                    Expanded(
                      child: _buildInteractiveCard(
                        context: context,
                        icon: Icons.event_available_rounded,
                        iconColor: const Color(0xFF4DD0E1),
                        title: 'Agenda',
                        value: '${stats.pendingAppointments}',
                        subtitle: stats.pendingAppointments > 0 
                            ? 'RDV en attente' 
                            : 'Aucun RDV',
                        footer: stats.pendingAppointments > 0 
                            ? 'Prochain: 09:00' 
                            : null,
                        onTap: () {
                          // Navigation vers onglet Rendez-vous
                          DefaultTabController.of(context).animateTo(1);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInteractiveCard(
                        context: context,
                        icon: Icons.chat_bubble_rounded,
                        iconColor: const Color(0xFF2196F3),
                        title: 'Messages',
                        value: '2',
                        subtitle: 'Non lus',
                        footer: 'Dernier: Mme K.',
                        onTap: () {
                          // Navigation vers onglet Messages
                          DefaultTabController.of(context).animateTo(2);
                        },
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildInteractiveCard(
                        context: context,
                        icon: Icons.people_rounded,
                        iconColor: const Color(0xFF9C27B0),
                        title: 'Patients',
                        value: '${stats.totalPatients}',
                        subtitle: 'Total',
                        footer: '+12 nouveaux',
                        badge: null,
                        onTap: () {
                          // Navigation vers onglet Patients
                          DefaultTabController.of(context).animateTo(3);
                        },
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _buildInteractiveCard(
                        context: context,
                        icon: Icons.account_balance_wallet_rounded,
                        iconColor: const Color(0xFF4CAF50),
                        title: 'Revenus',
                        value: '${(stats.revenue / 1000).toStringAsFixed(0)}k F',
                        subtitle: 'Ce mois',
                        footer: '↗ +15%',
                        trend: true,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => const DoctorPaymentScreen(),
                            ),
                          );
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 24),

                // ═══════════════════════════════════════════════════════════
                // SECTION: ACTIONS RAPIDES
                // ═══════════════════════════════════════════════════════════
                _buildSectionTitle('Actions rapides'),
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.add_circle_outline,
                              label: 'Nouveau RDV',
                              color: const Color(0xFF4DD0E1),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const ManageSlotsScreen()),
                                );
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.medication_outlined,
                              label: 'Ordonnance',
                              color: const Color(0xFFFF5722),
                              onTap: () {
                                _showOrdonnanceModal(context);
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.note_add_outlined,
                              label: 'Note patient',
                              color: const Color(0xFF9C27B0),
                              onTap: () {
                                _showNoteModal(context);
                              },
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildQuickAction(
                              icon: Icons.receipt_long_outlined,
                              label: 'Facture',
                              color: const Color(0xFF4CAF50),
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (_) => const DoctorPaymentScreen()),
                                );
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // ═══════════════════════════════════════════════════════════
                // SECTION: DEMANDES MÉDECIN TRAITANT
                // ═══════════════════════════════════════════════════════════
                Consumer2<AuthProvider, TreatingRequestProvider>(
                  builder: (context, auth, trProvider, _) {
                    final doctorId = auth.doctorProfile?.id ?? '';
                    final pendingReqs = trProvider.pendingForDoctor(doctorId);
                    
                    if (pendingReqs.isEmpty) {
                      return const SizedBox.shrink();
                    }

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildSectionTitle('Demandes médecin traitant (${pendingReqs.length})'),
                        const SizedBox(height: 12),
                        ...pendingReqs.take(3).map((req) {
                          final timeDiff = DateTime.now().difference(req.createdAt);
                          final timeAgo = timeDiff.inHours > 0 
                              ? 'Il y a ${timeDiff.inHours}h' 
                              : 'Il y a ${timeDiff.inMinutes} min';

                          return _buildRequestCard(
                            context: context,
                            patientName: req.patientName,
                            timeAgo: timeAgo,
                            onAccept: () {
                              // Accepter la demande
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('✅ Demande de ${req.patientName} acceptée'),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            },
                            onDecline: () {
                              // Refuser la demande
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text('❌ Demande de ${req.patientName} refusée'),
                                  backgroundColor: Colors.orange,
                                ),
                              );
                            },
                          );
                        }),
                        if (pendingReqs.length > 3) ...[
                          const SizedBox(height: 12),
                          Center(
                            child: TextButton(
                              onPressed: () {
                                // Navigation vers toutes les demandes
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('📋 Voir toutes les demandes')),
                                );
                              },
                              child: Text(
                                'Voir les ${pendingReqs.length - 3} autres demandes',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Color(0xFF4DD0E1),
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ],
                    );
                  },
                ),

                const SizedBox(height: 100),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Carte interactive
  // ═══════════════════════════════════════════════════════════
  Widget _buildInteractiveCard({
    required BuildContext context,
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    String? footer,
    String? badge,
    bool trend = false,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: iconColor.withValues(alpha: 0.2), width: 1),
          boxShadow: [
            BoxShadow(
              color: iconColor.withValues(alpha: 0.1),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(icon, color: iconColor, size: 24),
                ),
                if (badge != null)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      badge,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.grey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 24,
                fontWeight: FontWeight.bold,
                color: iconColor,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              subtitle,
              style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: Colors.grey,
              ),
            ),
            if (footer != null) ...[
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: trend ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  footer,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 10,
                    color: trend ? Colors.green : Colors.grey[700],
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Action rapide
  // ═══════════════════════════════════════════════════════════
  Widget _buildQuickAction({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.05),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.2)),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 28),
            const SizedBox(height: 8),
            Text(
              label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: color,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Carte de demande
  // ═══════════════════════════════════════════════════════════
  Widget _buildRequestCard({
    required BuildContext context,
    required String patientName,
    required String timeAgo,
    required VoidCallback onAccept,
    required VoidCallback onDecline,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey[200]!),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4DD0E1).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.person_outline,
              color: Color(0xFF4DD0E1),
              size: 24,
            ),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  patientName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  timeAgo,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          // Boutons
          Row(
            children: [
              IconButton(
                onPressed: onDecline,
                icon: const Icon(Icons.close_rounded, color: Colors.red),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.red.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: onAccept,
                icon: const Icon(Icons.check_rounded, color: Colors.green),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.green.withValues(alpha: 0.1),
                  padding: const EdgeInsets.all(8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // WIDGET: Titre de section
  void _showOrdonnanceModal(BuildContext context) {
    final patientCtrl = TextEditingController();
    final medCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.medication_outlined, color: Color(0xFFFF5722)),
            SizedBox(width: 8),
            Text('Nouvelle ordonnance', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: patientCtrl,
              decoration: const InputDecoration(labelText: 'Nom du patient', hintText: 'ex: Kouamé Jean'),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: medCtrl,
              maxLines: 3,
              decoration: const InputDecoration(labelText: 'Médicaments & Posologie', hintText: 'ex: Paracétamol 1g 3x/jour pendant 5 jours'),
            ),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFFFF5722)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Ordonnance numérique générée avec succès !'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Émettre'),
          ),
        ],
      ),
    );
  }

  void _showNoteModal(BuildContext context) {
    final noteCtrl = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Row(
          children: [
            Icon(Icons.note_add_outlined, color: Color(0xFF9C27B0)),
            SizedBox(width: 8),
            Text('Note médicale', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 16)),
          ],
        ),
        content: TextField(
          controller: noteCtrl,
          maxLines: 4,
          decoration: const InputDecoration(
            hintText: 'Saisissez vos observations cliniques...',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Annuler')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: const Color(0xFF9C27B0)),
            onPressed: () {
              Navigator.pop(ctx);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Note clinique enregistrée au dossier patient !'),
                  backgroundColor: AppColors.success,
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            child: const Text('Enregistrer'),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: Colors.black87,
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPER: Icône météo selon l'heure
  // ═══════════════════════════════════════════════════════════
  IconData _getWeatherIcon(int hour) {
    if (hour >= 6 && hour < 12) {
      return Icons.wb_sunny_outlined; // Matin
    } else if (hour >= 12 && hour < 18) {
      return Icons.wb_cloudy_outlined; // Après-midi
    } else {
      return Icons.nights_stay_outlined; // Soir/Nuit
    }
  }
}
