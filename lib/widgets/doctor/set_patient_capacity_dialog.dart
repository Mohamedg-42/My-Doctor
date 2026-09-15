// lib/widgets/doctor/set_patient_capacity_dialog.dart
//
// Dialogue permettant au médecin de configurer le nombre maximum de patients
// qu'il souhaite suivre en tant que médecin traitant.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../services/database_service.dart';
import '../../providers/auth_provider.dart';

class SetPatientCapacityDialog extends StatefulWidget {
  final String doctorId;
  final int currentCapacity;
  final int activePatientsCount;

  const SetPatientCapacityDialog({
    super.key,
    required this.doctorId,
    required this.currentCapacity,
    this.activePatientsCount = 0,
  });

  static Future<int?> show(
    BuildContext context, {
    required String doctorId,
    required int currentCapacity,
    int activePatientsCount = 0,
  }) {
    return showDialog<int>(
      context: context,
      builder: (_) => SetPatientCapacityDialog(
        doctorId: doctorId,
        currentCapacity: currentCapacity,
        activePatientsCount: activePatientsCount,
      ),
    );
  }

  @override
  State<SetPatientCapacityDialog> createState() => _SetPatientCapacityDialogState();
}

class _SetPatientCapacityDialogState extends State<SetPatientCapacityDialog> {
  late int _selectedCapacity;
  final TextEditingController _customCtrl = TextEditingController();
  bool _isCustom = false;
  bool _saving = false;

  final List<int> _quickPresets = [15, 30, 50, 75, 100];

  @override
  void initState() {
    super.initState();
    _selectedCapacity = widget.currentCapacity;
    if (!_quickPresets.contains(_selectedCapacity)) {
      _isCustom = true;
      _customCtrl.text = '$_selectedCapacity';
    }
  }

  @override
  void dispose() {
    _customCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    int finalCapacity = _selectedCapacity;
    if (_isCustom) {
      final parsed = int.tryParse(_customCtrl.text.trim());
      if (parsed == null || parsed <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Veuillez renseigner un nombre valide de patients.')),
        );
        return;
      }
      finalCapacity = parsed;
    }

    setState(() => _saving = true);
    try {
      await DatabaseService().updateDoctorPatientCapacity(widget.doctorId, finalCapacity);
      if (mounted) {
        await context.read<AuthProvider>().refreshCurrentUser();
        if (mounted) {
          Navigator.pop(context, finalCapacity);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(LucideIcons.circle_check, color: Colors.white, size: 20),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text('Capacité de patientèle mise à jour : $finalCapacity patients maximum.'),
                  ),
                ],
              ),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() => _saving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
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
              color: AppColors.primary.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: const Icon(LucideIcons.users, color: AppColors.primary, size: 20),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Capacité de patientèle',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
      content: SizedBox(
        width: double.maxFinite,
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 400),
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'Définissez le nombre maximum de patients que vous pouvez suivre activement pour garantir un suivi médical optimal.',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade600, height: 1.4),
                ),
                const SizedBox(height: 16),

                // État actuel
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF8FAFC),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Patients suivis actuellement', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Colors.grey), overflow: TextOverflow.ellipsis),
                            Text('${widget.activePatientsCount} patients', style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.bold, color: Color(0xFF0F172A))),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Plafond : $_selectedCapacity',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                const Text('Plafonds recommandés :', style: TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600)),
                const SizedBox(height: 8),

                // Boutons presets
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: _quickPresets.map((preset) {
                    final isSel = !_isCustom && _selectedCapacity == preset;
                    return ChoiceChip(
                      label: Text('$preset patients'),
                      selected: isSel,
                      onSelected: (_) {
                        setState(() {
                          _isCustom = false;
                          _selectedCapacity = preset;
                        });
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: isSel ? FontWeight.bold : FontWeight.w500,
                        color: isSel ? Colors.white : const Color(0xFF1E293B),
                      ),
                    );
                  }).toList(),
                ),
                const SizedBox(height: 14),

                // Option personnalisé
                Row(
                  children: [
                    ChoiceChip(
                      label: const Text('Personnalisé'),
                      selected: _isCustom,
                      onSelected: (_) {
                        setState(() {
                          _isCustom = true;
                          if (_customCtrl.text.isEmpty) {
                            _customCtrl.text = '$_selectedCapacity';
                          }
                        });
                      },
                      selectedColor: AppColors.primary,
                      labelStyle: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        fontWeight: _isCustom ? FontWeight.bold : FontWeight.w500,
                        color: _isCustom ? Colors.white : const Color(0xFF1E293B),
                      ),
                    ),
                    if (_isCustom) ...[
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 40,
                          child: TextField(
                            controller: _customCtrl,
                            keyboardType: TextInputType.number,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.bold),
                            decoration: InputDecoration(
                              hintText: 'Ex: 40',
                              suffixText: 'patients',
                              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: _saving ? null : () => Navigator.pop(context),
          child: const Text('Annuler', style: TextStyle(fontFamily: 'Poppins', color: Colors.grey)),
        ),
        ElevatedButton(
          onPressed: _saving ? null : _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
          child: _saving
              ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
              : const Text('Enregistrer', style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold)),
        ),
      ],
    );
  }
}
