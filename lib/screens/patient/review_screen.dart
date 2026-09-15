import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/app_provider.dart';
import '../../providers/auth_provider.dart';
import '../../models/doctor_model.dart';

class ReviewScreen extends StatefulWidget {
  final DoctorModel doctor;
  final String? appointmentId;

  const ReviewScreen({
    super.key,
    required this.doctor,
    this.appointmentId,
  });

  @override
  State<ReviewScreen> createState() => _ReviewScreenState();
}

class _ReviewScreenState extends State<ReviewScreen> {
  int _rating = 0;
  final _commentCtrl = TextEditingController();
  bool _isAnonymous = false;
  bool _isSubmitting = false;

  // Critères détaillés
  int _punctualityRating = 0;
  int _listeningRating = 0;
  int _explanationRating = 0;
  int _waitTimeRating = 0;

  final List<String> _quickComments = [
    'Excellent médecin',
    'Très attentionné',
    'Explications claires',
    'Recommande vivement',
    'Consultation rapide',
    'Disponible et à l\'écoute',
  ];

  @override
  void dispose() {
    _commentCtrl.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_rating == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez attribuer une note'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    if (_commentCtrl.text.trim().length < 10) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Commentaire trop court (minimum 10 caractères)'),
          backgroundColor: AppColors.warning,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);
    final auth = context.read<AuthProvider>();

    await context.read<AppProvider>().submitReview(
          patientId: auth.currentUser?.id ?? 'patient',
          patientName: auth.userName,
          doctorId: widget.doctor.id,
          doctorName: widget.doctor.fullName,
          rating: _rating.toDouble(),
          comment: _commentCtrl.text.trim(),
          isAnonymous: _isAnonymous,
        );

    if (!mounted) return;
    setState(() => _isSubmitting = false);

    _showThankYouDialog();
  }

  void _showThankYouDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: const BoxDecoration(
                  gradient: AppColors.primaryGradient,
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.star_rounded, color: Colors.white, size: 40),
              ),
              const SizedBox(height: 20),
              const Text(
                'Merci pour votre avis !',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                'Votre évaluation de ${widget.doctor.fullName} a été publiée. Cela aide la communauté à choisir les meilleurs médecins.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 20),
              // Affichage de la note
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(5, (i) => Icon(
                  Icons.star_rounded,
                  color: i < _rating ? const Color(0xFFFFB800) : AppColors.backgroundGrey,
                  size: 28,
                )),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14)),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  onPressed: () {
                    Navigator.pop(_);
                    Navigator.pop(context);
                  },
                  child: const Text('Terminé',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text('Évaluer le médecin'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Carte médecin
            _DoctorInfoCard(doctor: widget.doctor),
            const SizedBox(height: 24),

            // Note globale
            const _SectionTitle(title: 'Note globale'),
            const SizedBox(height: 12),
            _StarRating(
              rating: _rating,
              size: 48,
              onChanged: (r) => setState(() => _rating = r),
            ),
            const SizedBox(height: 6),
            Center(
              child: Text(
                _ratingLabel(_rating),
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 14,
                  color: _ratingColor(_rating),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            const SizedBox(height: 28),

            // Critères détaillés
            const _SectionTitle(title: 'Évaluation détaillée'),
            const SizedBox(height: 14),
            _CriterionRating(
              label: 'Ponctualité',
              icon: Icons.schedule_rounded,
              rating: _punctualityRating,
              onChanged: (r) => setState(() => _punctualityRating = r),
            ),
            _CriterionRating(
              label: 'Écoute',
              icon: Icons.hearing_rounded,
              rating: _listeningRating,
              onChanged: (r) => setState(() => _listeningRating = r),
            ),
            _CriterionRating(
              label: 'Clarté des explications',
              icon: Icons.chat_outlined,
              rating: _explanationRating,
              onChanged: (r) => setState(() => _explanationRating = r),
            ),
            _CriterionRating(
              label: 'Temps d\'attente',
              icon: Icons.timer_outlined,
              rating: _waitTimeRating,
              onChanged: (r) => setState(() => _waitTimeRating = r),
            ),
            const SizedBox(height: 24),

            // Commentaires rapides
            const _SectionTitle(title: 'Mots-clés (optionnel)'),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _quickComments.map((c) {
                final isSelected =
                    _commentCtrl.text.contains(c);
                return GestureDetector(
                  onTap: () {
                    setState(() {
                      if (isSelected) {
                        _commentCtrl.text =
                            _commentCtrl.text.replaceAll('$c. ', '').replaceAll(c, '').trim();
                      } else {
                        final current = _commentCtrl.text.trim();
                        _commentCtrl.text =
                            current.isEmpty ? '$c. ' : '$current $c. ';
                      }
                    });
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.backgroundCard,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                        color: isSelected
                            ? AppColors.primary
                            : AppColors.backgroundGrey,
                      ),
                    ),
                    child: Text(
                      c,
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: isSelected
                            ? Colors.white
                            : AppColors.textPrimary,
                        fontWeight: isSelected
                            ? FontWeight.w600
                            : FontWeight.normal,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),

            // Commentaire libre
            const _SectionTitle(title: 'Votre commentaire'),
            const SizedBox(height: 10),
            TextField(
              controller: _commentCtrl,
              maxLines: 5,
              maxLength: 500,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: InputDecoration(
                hintText:
                    'Partagez votre expérience avec ce médecin...',
                hintStyle: const TextStyle(
                  fontFamily: 'Poppins',
                  color: AppColors.textLight,
                  fontSize: 13,
                ),
                filled: true,
                fillColor: AppColors.backgroundCard,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: AppColors.backgroundGrey),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: AppColors.backgroundGrey),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                      color: AppColors.primary, width: 1.5),
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 16),

            // Option anonymat
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.backgroundCard,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(Icons.person_off_outlined,
                      color: AppColors.textSecondary, size: 20),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Publier anonymement',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w600,
                                fontSize: 13)),
                        Text('Votre nom ne sera pas affiché',
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                color: AppColors.textSecondary,
                                fontSize: 11)),
                      ],
                    ),
                  ),
                  Switch.adaptive(
                    value: _isAnonymous,
                    activeColor: AppColors.primary,
                    onChanged: (v) => setState(() => _isAnonymous = v),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 28),

            // Bouton soumettre
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isSubmitting ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16)),
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: _isSubmitting
                    ? const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                                color: Colors.white, strokeWidth: 2),
                          ),
                          SizedBox(width: 12),
                          Text('Publication...',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  color: Colors.white)),
                        ],
                      )
                    : const Text('Publier l\'évaluation',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        )),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  String _ratingLabel(int r) {
    switch (r) {
      case 1: return 'Très décevant';
      case 2: return 'Décevant';
      case 3: return 'Correct';
      case 4: return 'Très bien';
      case 5: return 'Excellent !';
      default: return 'Appuyez sur une étoile';
    }
  }

  Color _ratingColor(int r) {
    if (r <= 2) return AppColors.error;
    if (r == 3) return AppColors.warning;
    if (r == 4) return AppColors.success;
    if (r == 5) return const Color(0xFFFFB800);
    return AppColors.textLight;
  }
}

// ─── Widgets ──────────────────────────────────────────────────────────────────

class _DoctorInfoCard extends StatelessWidget {
  final DoctorModel doctor;
  const _DoctorInfoCard({required this.doctor});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppColors.primaryGradient,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                doctor.initials,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  doctor.fullName,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  doctor.specialty,
                  style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    color: Colors.white70,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.star_rounded,
                        color: Color(0xFFFFD700), size: 14),
                    const SizedBox(width: 3),
                    Flexible(
                      child: Text(
                        '${doctor.rating} (${doctor.reviewCount} avis)',
                        style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          color: Colors.white70,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w700,
        color: AppColors.textPrimary,
      ),
    );
  }
}

class _StarRating extends StatelessWidget {
  final int rating;
  final double size;
  final void Function(int) onChanged;

  const _StarRating({
    required this.rating,
    this.size = 32,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(5, (i) {
        return GestureDetector(
          onTap: () => onChanged(i + 1),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 150),
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Icon(
              i < rating ? Icons.star_rounded : Icons.star_border_rounded,
              color: i < rating
                  ? const Color(0xFFFFB800)
                  : AppColors.backgroundGrey,
              size: size,
            ),
          ),
        );
      }),
    );
  }
}

class _CriterionRating extends StatelessWidget {
  final String label;
  final IconData icon;
  final int rating;
  final void Function(int) onChanged;

  const _CriterionRating({
    required this.label,
    required this.icon,
    required this.rating,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primaryUltraLight,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: AppColors.primary, size: 18),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(label,
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                )),
          ),
          Row(
            children: List.generate(5, (i) {
              return GestureDetector(
                onTap: () => onChanged(i + 1),
                child: Icon(
                  i < rating ? Icons.star_rounded : Icons.star_border_rounded,
                  color: i < rating
                      ? const Color(0xFFFFB800)
                      : AppColors.backgroundGrey,
                  size: 20,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }
}
