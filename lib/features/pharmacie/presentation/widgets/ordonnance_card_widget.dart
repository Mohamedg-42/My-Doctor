import 'package:flutter/material.dart';
import '../../data/models/ordonnance_model.dart';
import 'statut_badge_widget.dart';

class OrdonnanceCardWidget extends StatelessWidget {
  final OrdonnanceModel ordonnance;
  final VoidCallback onTap;

  const OrdonnanceCardWidget({
    super.key,
    required this.ordonnance,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isUrgent = ordonnance.statut == StatutOrdonnance.enAttente;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(18),
          border: isUrgent
              ? Border.all(color: const Color(0xFFF39C12).withValues(alpha: 0.5), width: 1.5)
              : Border.all(color: Colors.grey.shade100),
          boxShadow: [
            BoxShadow(
              color: isUrgent
                  ? const Color(0xFFF39C12).withValues(alpha: 0.08)
                  : Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            // ── Header ──────────────────────────────────────────────────────
            Container(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
              decoration: BoxDecoration(
                color: isUrgent
                    ? const Color(0xFFFFF8E7)
                    : const Color(0xFFF8FAFB),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(18)),
              ),
              child: Row(
                children: [
                  // Avatar patient
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text(
                        _initiales(ordonnance.patientPrenom, ordonnance.patientNom),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ordonnance.patientNomComplet,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF1A2340),
                          ),
                        ),
                        const SizedBox(height: 2),
                        Row(
                          children: [
                            const Icon(Icons.local_hospital_rounded,
                                size: 11, color: Color(0xFF7A8BA0)),
                            const SizedBox(width: 3),
                            Expanded(
                              child: Text(
                                '${ordonnance.medecinNom} · ${ordonnance.medecinSpecialite}',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: Color(0xFF7A8BA0),
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  StatutBadgeWidget(statut: ordonnance.statut, compact: true),
                ],
              ),
            ),

            // ── Corps ───────────────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 14),
              child: Column(
                children: [
                  // Médicaments résumé
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(9),
                        ),
                        child: const Icon(Icons.medication_rounded,
                            color: Color(0xFF2E7D32), size: 15),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${ordonnance.nombreMedicaments} médicament${ordonnance.nombreMedicaments > 1 ? 's' : ''}',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF1A2340),
                              ),
                            ),
                            Text(
                              ordonnance.medicaments
                                  .take(2)
                                  .map((m) => m.nom)
                                  .join(', ') +
                                  (ordonnance.nombreMedicaments > 2 ? '...' : ''),
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: Color(0xFF7A8BA0),
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      if (ordonnance.montantTotal != null)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              '${_formatMontant(ordonnance.montantTotal!)} FCFA',
                              style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            if (ordonnance.remboursableCmu)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 5, vertical: 1),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF185FA5).withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: const Text(
                                  'CMU',
                                  style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 8,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF185FA5),
                                  ),
                                ),
                              ),
                          ],
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),

                  // Footer: date + CMU + téléphone
                  Row(
                    children: [
                      const Icon(Icons.access_time_rounded,
                          size: 12, color: Color(0xFFB0BEC5)),
                      const SizedBox(width: 4),
                      Text(
                        _formatDate(ordonnance.dateEmission),
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Color(0xFFB0BEC5),
                        ),
                      ),
                      const Spacer(),
                      if (ordonnance.patientCmuNumber != null) ...[
                        const Icon(Icons.verified_rounded,
                            size: 11, color: Color(0xFF185FA5)),
                        const SizedBox(width: 3),
                        Text(
                          ordonnance.patientCmuNumber!,
                          style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 9,
                            color: Color(0xFF185FA5),
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color: const Color(0xFF2E7D32).withValues(alpha: 0.08),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Voir détails',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: Color(0xFF2E7D32),
                              ),
                            ),
                            SizedBox(width: 3),
                            Icon(Icons.arrow_forward_ios_rounded,
                                size: 9, color: Color(0xFF2E7D32)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _initiales(String prenom, String nom) {
    final p = prenom.isNotEmpty ? prenom[0].toUpperCase() : '';
    final n = nom.isNotEmpty ? nom[0].toUpperCase() : '';
    return '$p$n';
  }

  String _formatDate(DateTime dt) {
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 60) return 'Il y a ${diff.inMinutes} min';
    if (diff.inHours < 24) return 'Il y a ${diff.inHours}h';
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year}';
  }

  String _formatMontant(double m) {
    if (m >= 1000) {
      return '${(m / 1000).toStringAsFixed(m % 1000 == 0 ? 0 : 1)}k';
    }
    return m.toInt().toString();
  }
}
