// lib/screens/doctor/doctor_call_settings_screen.dart
//
// Écran de configuration des permissions d'appels entrants pour le médecin.

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';
import '../../providers/message_provider.dart';
import '../../services/database_service.dart';

class DoctorCallSettingsScreen extends StatefulWidget {
  final String? doctorId;
  const DoctorCallSettingsScreen({super.key, this.doctorId});

  @override
  State<DoctorCallSettingsScreen> createState() => _DoctorCallSettingsScreenState();
}

class _DoctorCallSettingsScreenState extends State<DoctorCallSettingsScreen> {
  late DoctorCallPolicy _policy;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadPolicy();
  }

  void _loadPolicy() {
    final auth = context.read<AuthProvider>();
    final doctorId = widget.doctorId ?? auth.doctorProfile?.id ?? auth.currentUser?.id ?? 'doctor';
    final db = DatabaseService();
    _policy = db.getDoctorCallPolicy(doctorId);
    setState(() => _isLoading = false);
  }

  Future<void> _updatePolicy(DoctorCallPolicy newPolicy) async {
    setState(() => _policy = newPolicy);
    await DatabaseService().saveDoctorCallPolicy(newPolicy);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Row(
            children: [
              Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
              SizedBox(width: 8),
              Text('Préférences d\'appels enregistrées',
                  style: TextStyle(fontFamily: 'Poppins')),
            ],
          ),
          backgroundColor: AppColors.success,
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 2),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    final auth = context.watch<AuthProvider>();
    final doctorId = widget.doctorId ?? auth.doctorProfile?.id ?? auth.currentUser?.id ?? 'doctor';
    final msgProvider = context.watch<MessageProvider>();
    final conversations = msgProvider.conversationsForDoctor(doctorId);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'Gestion des Appels',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w700,
            fontSize: 17,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF0F172A),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_rounded, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          // Carte Info Règles
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.brandBlue.withValues(alpha: 0.08),
                  AppColors.primary.withValues(alpha: 0.04),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColors.brandBlue.withValues(alpha: 0.2),
              ),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.shield_outlined, color: AppColors.brandBlue, size: 24),
                SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Contrôle strict des appels directs',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: Color(0xFF0F172A),
                        ),
                      ),
                      SizedBox(height: 4),
                      Text(
                        'Vous décidez qui peut vous joindre par appel audio et vidéo. Par défaut, seuls les patients disposant d\'un abonnement actif peuvent initier un appel.',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 12,
                          color: Color(0xFF475569),
                          height: 1.4,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          // Section Règles Générales
          const Text(
            'Règles générales d\'appels',
            style: TextStyle(
              fontFamily: 'Poppins',
              fontWeight: FontWeight.w700,
              fontSize: 15,
              color: Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 10),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: const Color(0xFFE2E8F0)),
            ),
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text(
                    'Recevoir des appels directs',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
                  ),
                  subtitle: Text(
                    _policy.callsEnabled
                        ? 'Votre ligne est ouverte aux patients autorisés'
                        : 'Mode Ne pas déranger : tous les appels sont temporairement suspendus',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  activeThumbColor: AppColors.brandBlue,
                  value: _policy.callsEnabled,
                  onChanged: (val) {
                    _updatePolicy(_policy.copyWith(callsEnabled: val));
                  },
                ),
                const Divider(height: 1),
                SwitchListTile(
                  title: const Row(
                    children: [
                      Expanded(
                        child: Text(
                          'Autoriser les patients abonnés',
                          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600, fontSize: 14),
                        ),
                      ),
                      SizedBox(width: 6),
                      Icon(Icons.workspace_premium_rounded, color: Color(0xFFD97706), size: 18),
                    ],
                  ),
                  subtitle: const Text(
                    'Les patients avec un abonnement actif (Essentiel, Confort, Famille) peuvent vous appeler directement',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B)),
                  ),
                  activeThumbColor: AppColors.brandBlue,
                  value: _policy.allowSubscribedPatients,
                  onChanged: (val) {
                    _updatePolicy(_policy.copyWith(allowSubscribedPatients: val));
                  },
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // Section Permissions par Patient
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Text(
                  'Permissions par patient',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    color: Color(0xFF0F172A),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${conversations.length} patient(s)',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Color(0xFF64748B)),
              ),
            ],
          ),
          const SizedBox(height: 10),

          if (conversations.isEmpty) ...[
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: const Center(
                child: Text(
                  'Aucun patient dans votre messagerie pour le moment.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, color: Color(0xFF94A3B8)),
                ),
              ),
            ),
          ] else ...[
            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: conversations.length,
                separatorBuilder: (_, __) => const Divider(height: 1),
                itemBuilder: (ctx, i) {
                  final conv = conversations[i];
                  final patientId = conv.patientId;
                  final isBlocked = _policy.blockedPatientIds.contains(patientId);
                  final isExplicitlyAllowed = _policy.allowedPatientIds.contains(patientId);

                  return ListTile(
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    leading: CircleAvatar(
                      backgroundColor: isBlocked
                          ? AppColors.error.withValues(alpha: 0.12)
                          : AppColors.primaryUltraLight,
                      child: Text(
                        conv.patientName.isNotEmpty ? conv.patientName[0].toUpperCase() : 'P',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.bold,
                          color: isBlocked ? AppColors.error : AppColors.primary,
                        ),
                      ),
                    ),
                    title: Text(
                      conv.patientName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w700,
                        fontSize: 14,
                        color: Color(0xFF0F172A),
                      ),
                    ),
                    subtitle: Text(
                      isBlocked
                          ? 'Appels expressément bloqués'
                          : (isExplicitlyAllowed
                              ? 'Appels expressément autorisés'
                              : (_policy.allowSubscribedPatients
                                  ? 'Autorisé si abonnement actif'
                                  : 'Appels non autorisés')),
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isBlocked
                            ? AppColors.error
                            : (isExplicitlyAllowed
                                ? AppColors.success
                                : const Color(0xFF64748B)),
                      ),
                    ),
                    trailing: Switch(
                      value: !isBlocked,
                      activeThumbColor: AppColors.brandBlue,
                      onChanged: (allow) async {
                        await DatabaseService().togglePatientCallPermission(
                          doctorId: doctorId,
                          patientId: patientId,
                          isAllowed: allow,
                        );
                        _loadPolicy();
                      },
                    ),
                  );
                },
              ),
            ),
          ],
        ],
      ),
    );
  }
}
