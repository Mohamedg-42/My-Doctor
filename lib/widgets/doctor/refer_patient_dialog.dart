// lib/widgets/doctor/refer_patient_dialog.dart
//
// Dialogue permettant à un praticien de référer un patient vers un confrère
// au lieu de refuser sa demande de médecin traitant ou de consultation.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../providers/treating_request_provider.dart';

class ReferPatientDialog extends StatefulWidget {
  final String requestId;
  final String patientName;
  final String currentDoctorId;
  final VoidCallback? onReferred;

  const ReferPatientDialog({
    super.key,
    required this.requestId,
    required this.patientName,
    required this.currentDoctorId,
    this.onReferred,
  });

  static Future<bool?> show(
    BuildContext context, {
    required String requestId,
    required String patientName,
    required String currentDoctorId,
  }) {
    return showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => ReferPatientDialog(
        requestId: requestId,
        patientName: patientName,
        currentDoctorId: currentDoctorId,
      ),
    );
  }

  @override
  State<ReferPatientDialog> createState() => _ReferPatientDialogState();
}

class _ReferPatientDialogState extends State<ReferPatientDialog> {
  final TextEditingController _noteCtrl = TextEditingController();
  DbUser? _selectedDoctor;
  bool _loading = false;
  List<DbUser> _availableDoctors = [];

  @override
  void initState() {
    super.initState();
    _loadDoctors();
  }

  void _loadDoctors() {
    final all = DatabaseService().getAllDoctors(onlyActive: true);
    // Exclure le médecin actuel
    _availableDoctors = all.where((d) => d.id != widget.currentDoctorId).toList();
    if (_availableDoctors.isNotEmpty) {
      _selectedDoctor = _availableDoctors.first;
    }
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _submitReferral() async {
    if (_selectedDoctor == null) return;

    setState(() => _loading = true);
    try {
      final trProvider = context.read<TreatingRequestProvider>();
      await trProvider.referRequest(
        requestId: widget.requestId,
        targetDoctorId: _selectedDoctor!.id,
        targetDoctorName: 'Dr. ${_selectedDoctor!.fullName}',
        targetDoctorSpecialty: _selectedDoctor!.specialty ?? 'Médecin Généraliste',
        referralNote: _noteCtrl.text.trim().isNotEmpty ? _noteCtrl.text.trim() : null,
      );

      if (mounted) {
        Navigator.pop(context, true);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.circle_check, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Dossier de ${widget.patientName} référé avec succès au Dr. ${_selectedDoctor!.fullName}.',
                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF185FA5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() => _loading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la référence : $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      title: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: const Color(0xFF185FA5).withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.user_round_cog, color: Color(0xFF185FA5), size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Référer à un confrère',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Info patient
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.user, size: 18, color: Color(0xFF475569)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Patient : ${widget.patientName}',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Explication déontologique
                Text(
                  'Plutôt que de refuser, transmettez ce dossier à un médecin confrère disponible qui prendra le relais auprès du patient.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 16),

                // Sélection du confrère
                const Text(
                  'Choisir le médecin confrère :',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 8),

                if (_availableDoctors.isEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Text(
                      'Aucun autre médecin n\'est actuellement disponible pour la référence.',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.amber.shade900),
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<DbUser>(
                        value: _selectedDoctor,
                        isExpanded: true,
                        icon: const Icon(LucideIcons.chevron_down, size: 18),
                        items: _availableDoctors.map((doc) {
                          final spec = doc.specialty ?? 'Généraliste';
                          return DropdownMenuItem<DbUser>(
                            value: doc,
                            child: Row(
                              children: [
                                CircleAvatar(
                                  radius: 12,
                                  backgroundColor: const Color(0xFF185FA5).withValues(alpha: 0.12),
                                  child: Text(
                                    doc.firstName.isNotEmpty ? doc.firstName[0] : 'D',
                                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Color(0xFF185FA5)),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Dr. ${doc.fullName} ($spec)',
                                    style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }).toList(),
                        onChanged: (v) => setState(() => _selectedDoctor = v),
                      ),
                    ),
                  ),
                const SizedBox(height: 16),

                // Note de transmission médicale (optionnelle)
                const Text(
                  'Note de transmission médicale (facultative) :',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF0F172A)),
                ),
                const SizedBox(height: 6),
                TextField(
                  controller: _noteCtrl,
                  maxLines: 2,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Ex: Patient orienté pour avis cardiologique ou planning complet...',
                    hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey.shade400),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide(color: Colors.grey.shade300)),
                    contentPadding: const EdgeInsets.all(12),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _loading ? null : () => Navigator.pop(context, false),
          child: const Text('Annuler', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
        ),
        ElevatedButton.icon(
          onPressed: (_loading || _availableDoctors.isEmpty) ? null : _submitReferral,
          icon: _loading
              ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Icon(LucideIcons.send, size: 14),
          label: const Text('Confirmer la référence', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w700)),
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF185FA5),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        ),
      ],
    );
  }
}
