import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../providers/cmu_provider.dart';
import '../../models/cmu_model.dart';
import '../../widgets/common/profile_photo_picker.dart';

// ─── Écran principal CMU ──────────────────────────────────────────────────────

class CmuScreen extends StatefulWidget {
  const CmuScreen({super.key});

  @override
  State<CmuScreen> createState() => _CmuScreenState();
}

class _CmuScreenState extends State<CmuScreen> with TickerProviderStateMixin {
  late TabController _tabCtrl;

  @override
  void initState() {
    super.initState();
    _tabCtrl = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: const Color(0xFF185FA5),
        elevation: 0,
        automaticallyImplyLeading: false,
        leading: Navigator.canPop(context)
            ? IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.pop(context),
              )
            : null,
        title: Row(
          children: [
            Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  shape: BoxShape.circle),
              child: const Center(
                  child: Text('CMU',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: Colors.white))),
            ),
            const SizedBox(width: 10),
            const Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('CMU-CI',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: Colors.white)),
                  Text('Couverture Maladie Universelle',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 9,
                          color: Colors.white70)),
                ],
              ),
            ),
          ],
        ),
        bottom: TabBar(
          controller: _tabCtrl,
          indicatorColor: Colors.white,
          indicatorWeight: 3,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          labelStyle: const TextStyle(
              fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600),
          unselectedLabelStyle:
              const TextStyle(fontFamily: 'Poppins', fontSize: 10),
          tabs: const [
            Tab(
                icon: Icon(Icons.credit_card_rounded, size: 16),
                text: 'Ma Carte'),
            Tab(
                icon: Icon(Icons.compare_arrows_rounded, size: 16),
                text: 'Économies'),
            Tab(icon: Icon(Icons.favorite_rounded, size: 16), text: 'Santé'),
            Tab(icon: Icon(Icons.shield_rounded, size: 16), text: 'Couverture'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabCtrl,
        children: const [
          _CmuCardTab(),
          _CostComparisonTab(),
          _HealthTrackingTab(),
          _CoverageTab(),
        ],
      ),
    );
  }
}

// ─── Tab 1: Carte CMU ─────────────────────────────────────────────────────────

class _CmuCardTab extends StatelessWidget {
  const _CmuCardTab();

  @override
  Widget build(BuildContext context) {
    final cmu = context.watch<CmuProvider>();
    final card = cmu.card;

    if (card == null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: const Color(0xFF185FA5).withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.credit_card_off_rounded,
                    size: 36, color: Color(0xFF185FA5)),
              ),
              const SizedBox(height: 18),
              const Text(
                'Aucune carte CMU active',
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 17,
                  fontWeight: FontWeight.w700,
                  color: Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Renseignez votre numéro de Couverture Maladie Universelle pour activer votre carte digitale.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  color: Colors.grey.shade600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          // Carte CMU digitale
          _DigitalCmuCard(card: card),
          const SizedBox(height: 20),
          // Actions
          Row(
            children: [
              Expanded(
                child: _ActionButton(
                  icon: Icons.download_rounded,
                  label: 'Télécharger',
                  color: const Color(0xFF185FA5),
                  onTap: () => _showDownloadDialog(context),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _ActionButton(
                  icon: Icons.share_rounded,
                  label: 'Partager',
                  color: AppColors.success,
                  onTap: () => _showShareDialog(context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          _ActionButton(
            icon: Icons.qr_code_scanner_rounded,
            label: 'Afficher QR Code complet',
            color: const Color(0xFF185FA5),
            onTap: () => _showQrDialog(context, card),
            fullWidth: true,
          ),
          const SizedBox(height: 20),
          // Informations de couverture
          _InfoSection(card: card),
          const SizedBox(height: 20),
          // Statut
          _StatusSection(card: card),
        ],
      ),
    );
  }

  void _showDownloadDialog(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Row(
          children: [
            Icon(Icons.check_circle_rounded, color: Colors.white, size: 18),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Carte téléchargée avec succès',
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontFamily: 'Poppins'),
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showShareDialog(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: const Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Partager avec',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 16,
                    fontWeight: FontWeight.w700)),
            SizedBox(height: 20),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _ShareOption(
                    icon: Icons.local_hospital_rounded,
                    label: 'Médecin',
                    color: Color(0xFF185FA5)),
                _ShareOption(
                    icon: Icons.medication_rounded,
                    label: 'Pharmacie',
                    color: AppColors.success),
                _ShareOption(
                    icon: Icons.science_rounded,
                    label: 'Laboratoire',
                    color: AppColors.warning),
                _ShareOption(
                    icon: Icons.print_rounded,
                    label: 'Imprimer',
                    color: AppColors.textSecondary),
              ],
            ),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showQrDialog(BuildContext context, CmuCard card) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('QR Code CMU',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                textBaseline: TextBaseline.alphabetic),
            textHeightBehavior: TextHeightBehavior()),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _QrCodeWidget(
                data:
                    '${card.cmuNumber}|${card.fullName}|${card.formattedBirthDate}'),
            const SizedBox(height: 12),
            Text(card.cmuNumber,
                style: const TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 14)),
            const Text('Scanner pour vérifier la validité de la carte',
                textAlign: TextAlign.center,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 11,
                    color: AppColors.textSecondary)),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(_),
            child:
                const Text('Fermer', style: TextStyle(fontFamily: 'Poppins')),
          ),
        ],
      ),
    );
  }
}

class _DigitalCmuCard extends StatefulWidget {
  final CmuCard card;
  const _DigitalCmuCard({required this.card});

  @override
  State<_DigitalCmuCard> createState() => _DigitalCmuCardState();
}

class _DigitalCmuCardState extends State<_DigitalCmuCard> {
  bool _obscureCmu = true;

  String _formatMaskedCmu(String cmu) {
    if (cmu.length > 7) {
      return '${cmu.substring(0, 6)}•••••••';
    }
    return '••••••••••••';
  }

  @override
  Widget build(BuildContext context) {
    final card = widget.card;
    return Container(
      constraints: const BoxConstraints(minHeight: 220),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF185FA5), Color(0xFF0D3B6B), Color(0xFF1A7A5A)],
          stops: [0, 0.6, 1],
        ),
        boxShadow: [
          BoxShadow(
              color: const Color(0xFF185FA5).withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 8)),
        ],
      ),
      child: Stack(
        children: [
          // Motifs de sécurité
          Positioned.fill(child: _CardPatternPainter()),
          // Drapeau CI
          Positioned(
            top: 14,
            right: 14,
            child: Row(
              children: [
                Container(
                    width: 10,
                    height: 18,
                    decoration: BoxDecoration(
                        color: const Color(0xFFF77F00),
                        borderRadius: BorderRadius.circular(1))),
                Container(width: 10, height: 18, color: Colors.white),
                Container(
                    width: 10,
                    height: 18,
                    decoration: BoxDecoration(
                        color: const Color(0xFF009A44),
                        borderRadius: BorderRadius.circular(1))),
              ],
            ),
          ),
          // Contenu principal
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(4),
                      decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8)),
                      child: const Icon(Icons.shield_rounded,
                          color: Colors.white, size: 18),
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('RÉPUBLIQUE DE CÔTE D\'IVOIRE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 7,
                                  color: Colors.white70,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5)),
                          Text('COUVERTURE MALADIE UNIVERSELLE',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                  fontSize: 9,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  letterSpacing: 0.3)),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                const Text('CARTE D\'ASSURÉ',
                    style: TextStyle(
                        fontSize: 11,
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1)),
                const SizedBox(height: 12),
                // Photo + Infos
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Photo
                    Container(
                      width: 62,
                      height: 78,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: Colors.white.withValues(alpha: 0.4),
                            width: 1.5),
                      ),
                      clipBehavior: Clip.hardEdge,
                      child: card.photoBase64 != null || card.photoUrl != null
                          ? ProfileAvatar(
                              base64Data: card.photoBase64,
                              networkUrl: card.photoUrl,
                              initials:
                                  '${card.firstName.isNotEmpty ? card.firstName[0] : ''}${card.lastName.isNotEmpty ? card.lastName[0] : ''}',
                              width: 62,
                              height: 78,
                              borderRadius: BorderRadius.circular(6),
                            )
                          : Container(
                              color: Colors.white.withValues(alpha: 0.1),
                              child: const Icon(Icons.person,
                                  color: Colors.white60, size: 38),
                            ),
                    ),
                    const SizedBox(width: 12),
                    // Infos assuré
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _CardField(
                              label: 'NOM & PRÉNOMS', value: card.fullName),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              _CardField(label: 'SEXE', value: card.gender),
                              const SizedBox(width: 8),
                              Expanded(
                                  child: _CardField(
                                      label: 'NÉ(E) LE',
                                      value: card.formattedBirthDate)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          _CardField(
                              label: 'PROFESSION', value: card.profession),
                        ],
                      ),
                    ),
                    // QR Code
                    Column(
                      children: [
                        Container(
                          width: 54,
                          height: 54,
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8)),
                          child: _QrCodeWidget(data: card.cmuNumber, size: 48),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Numéro CMU masqué par défaut avec toggle
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Flexible(
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Flexible(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text('N° CMU',
                                    style: TextStyle(
                                        fontSize: 7, color: Colors.white60)),
                                Text(
                                  _obscureCmu
                                      ? _formatMaskedCmu(card.cmuNumber)
                                      : card.cmuNumber,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Colors.white,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.5),
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            icon: Icon(
                              _obscureCmu
                                  ? Icons.visibility_off_rounded
                                  : Icons.visibility_rounded,
                              size: 16,
                              color: Colors.white70,
                            ),
                            onPressed: () =>
                                setState(() => _obscureCmu = !_obscureCmu),
                            tooltip: _obscureCmu ? 'Afficher' : 'Masquer',
                            padding: const EdgeInsets.all(4),
                            constraints: const BoxConstraints(),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        const Text('EXPIRATION',
                            style:
                                TextStyle(fontSize: 7, color: Colors.white60)),
                        Text(card.formattedExpiryDate,
                            style: const TextStyle(
                                fontSize: 9,
                                color: Colors.white70,
                                fontWeight: FontWeight.w600)),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
          // Logo CNAM
          Positioned(
            bottom: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6)),
              child: const Text('CNAM',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white)),
            ),
          ),
        ],
      ),
    );
  }
}

class _CardField extends StatelessWidget {
  final String label;
  final String value;
  final bool large;
  const _CardField(
      {required this.label, required this.value, this.large = false});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 6,
                color: Colors.white54,
                letterSpacing: 0.3)),
        Text(value,
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: large ? 11 : 9,
                color: Colors.white,
                fontWeight: large ? FontWeight.w700 : FontWeight.w500),
            overflow: TextOverflow.ellipsis,
            maxLines: 1),
      ],
    );
  }
}

// QR Code simulé (dessin géométrique)
class _QrCodeWidget extends StatelessWidget {
  final String data;
  final double size;
  const _QrCodeWidget({required this.data, this.size = 120});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: _QrPainter(data: data)),
    );
  }
}

class _QrPainter extends CustomPainter {
  final String data;
  _QrPainter({required this.data});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.black
      ..style = PaintingStyle.fill;
    final bg = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), bg);

    final cell = size.width / 21;
    final rng = math.Random(data.hashCode);

    // Coins QR (patterns fixes)
    _drawCorner(canvas, paint, 0, 0, cell);
    _drawCorner(canvas, paint, 14, 0, cell);
    _drawCorner(canvas, paint, 0, 14, cell);

    // Modules aléatoires (simulés selon data)
    for (int i = 0; i < 21; i++) {
      for (int j = 0; j < 21; j++) {
        if (_isCornerArea(i, j)) continue;
        if (rng.nextBool()) {
          canvas.drawRect(
              Rect.fromLTWH(i * cell + 0.5, j * cell + 0.5, cell - 1, cell - 1),
              paint);
        }
      }
    }
  }

  void _drawCorner(
      Canvas canvas, Paint paint, double x, double y, double cell) {
    final p = paint;
    final w = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    canvas.drawRect(Rect.fromLTWH(x * cell, y * cell, 7 * cell, 7 * cell), p);
    canvas.drawRect(
        Rect.fromLTWH((x + 1) * cell, (y + 1) * cell, 5 * cell, 5 * cell), w);
    canvas.drawRect(
        Rect.fromLTWH((x + 2) * cell, (y + 2) * cell, 3 * cell, 3 * cell), p);
  }

  bool _isCornerArea(int i, int j) {
    if (i < 9 && j < 9) return true;
    if (i > 11 && j < 9) return true;
    if (i < 9 && j > 11) return true;
    return false;
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Motif de sécurité de la carte
class _CardPatternPainter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return CustomPaint(painter: _PatternPainter());
  }
}

class _PatternPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white.withValues(alpha: 0.04)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    for (int i = 0; i < 20; i++) {
      final x = (i * size.width / 20);
      canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      canvas.drawLine(Offset(0, x), Offset(size.width, x), paint);
    }

    // Éléphant stylisé (cercles)
    final circlePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.05)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(Offset(size.width * 0.7, size.height * 0.5),
        size.width * 0.3, circlePaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final bool fullWidth;
  const _ActionButton(
      {required this.icon,
      required this.label,
      required this.color,
      required this.onTap,
      this.fullWidth = false});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: fullWidth ? double.infinity : null,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 18),
            const SizedBox(width: 6),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontFamily: 'Poppins',
                  color: color,
                  fontWeight: FontWeight.w600,
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ShareOption extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _ShareOption(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1), shape: BoxShape.circle),
          child: Icon(icon, color: color, size: 24),
        ),
        const SizedBox(height: 6),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: AppColors.textSecondary)),
      ],
    );
  }
}

class _InfoSection extends StatelessWidget {
  final CmuCard card;
  const _InfoSection({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Informations personnelles',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 14)),
          const SizedBox(height: 14),
          _InfoRow(
              icon: Icons.badge_rounded,
              label: 'N° CMU',
              value: card.cmuNumber,
              copyable: true),
          _InfoRow(
              icon: Icons.person_rounded,
              label: 'Nom complet',
              value: card.fullName),
          _InfoRow(
              icon: Icons.work_rounded,
              label: 'Profession',
              value: card.profession),
          _InfoRow(
              icon: Icons.location_city_rounded,
              label: 'Commune / Ville',
              value: '${card.commune}, ${card.city}'),
          _InfoRow(
              icon: Icons.cake_rounded,
              label: 'Date de naissance',
              value: card.formattedBirthDate),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool copyable;
  const _InfoRow(
      {required this.icon,
      required this.label,
      required this.value,
      this.copyable = false});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          Icon(icon, size: 16, color: const Color(0xFF185FA5)),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: AppColors.textSecondary)),
                Text(value,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          if (copyable)
            GestureDetector(
              onTap: () {
                Clipboard.setData(ClipboardData(text: value));
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                      content: Text('Numéro copié'),
                      behavior: SnackBarBehavior.floating,
                      duration: Duration(seconds: 2)),
                );
              },
              child: const Icon(Icons.copy_rounded,
                  size: 16, color: Color(0xFF185FA5)),
            ),
        ],
      ),
    );
  }
}

class _StatusSection extends StatelessWidget {
  final CmuCard card;
  const _StatusSection({required this.card});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: card.isActive && !card.isExpired
            ? AppColors.success.withValues(alpha: 0.08)
            : AppColors.error.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
            color: (card.isActive && !card.isExpired
                    ? AppColors.success
                    : AppColors.error)
                .withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: (card.isActive && !card.isExpired
                      ? AppColors.success
                      : AppColors.error)
                  .withValues(alpha: 0.15),
              shape: BoxShape.circle,
            ),
            child: Icon(
              card.isActive && !card.isExpired
                  ? Icons.verified_rounded
                  : Icons.cancel_rounded,
              color: card.isActive && !card.isExpired
                  ? AppColors.success
                  : AppColors.error,
              size: 24,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  card.isActive && !card.isExpired
                      ? 'Couverture active'
                      : 'Couverture expirée',
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    color: card.isActive && !card.isExpired
                        ? AppColors.success
                        : AppColors.error,
                    fontSize: 14,
                  ),
                ),
                Text(
                  card.isActive && !card.isExpired
                      ? 'Valide jusqu\'au ${card.formattedExpiryDate}'
                      : 'Expirée le ${card.formattedExpiryDate}',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 2: Comparateur de coûts ──────────────────────────────────────────────

class _CostComparisonTab extends StatefulWidget {
  const _CostComparisonTab();

  @override
  State<_CostComparisonTab> createState() => _CostComparisonTabState();
}

class _CostComparisonTabState extends State<_CostComparisonTab> {
  String _selectedCategory = 'Tous';

  @override
  Widget build(BuildContext context) {
    final cmu = context.watch<CmuProvider>();
    final categories = [
      'Tous',
      'Consultation',
      'Hospitalisation',
      'Médicaments',
      'Examens',
      'Maternité'
    ];
    final filtered = _selectedCategory == 'Tous'
        ? cmu.costComparisons
        : cmu.costComparisons
            .where((c) => c.category == _selectedCategory)
            .toList();

    final totalSavings = filtered.fold(0.0, (sum, c) => sum + c.savings);
    final totalWithout = filtered.fold(0.0, (sum, c) => sum + c.withoutCmu);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bandeau économies
          _SavingsBanner(
              totalSavings: cmu.totalSavings,
              savingsByCategory: cmu.savingsByCategory),
          const SizedBox(height: 16),
          // Filtres catégorie
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: categories
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 11,
                                  color: _selectedCategory == cat
                                      ? Colors.white
                                      : AppColors.textPrimary,
                                  fontWeight: _selectedCategory == cat
                                      ? FontWeight.w600
                                      : FontWeight.normal)),
                          selected: _selectedCategory == cat,
                          onSelected: (_) =>
                              setState(() => _selectedCategory = cat),
                          selectedColor: const Color(0xFF185FA5),
                          backgroundColor: AppColors.backgroundGrey,
                          checkmarkColor: Colors.white,
                          side: BorderSide.none,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Résumé filtré
          if (_selectedCategory != 'Tous')
            Container(
              margin: const EdgeInsets.only(bottom: 16),
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: const Color(0xFF185FA5).withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Expanded(
                      child: Column(children: [
                    const Text('Sans CMU',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                    Text('${totalWithout.toStringAsFixed(0)} F',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.error)),
                  ])),
                  Container(
                      width: 1, height: 40, color: AppColors.backgroundGrey),
                  Expanded(
                      child: Column(children: [
                    const Text('Avec CMU',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                    Text(
                        '${(totalWithout - totalSavings).toStringAsFixed(0)} F',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: AppColors.success)),
                  ])),
                  Container(
                      width: 1, height: 40, color: AppColors.backgroundGrey),
                  Expanded(
                      child: Column(children: [
                    const Text('Économies',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                    Text('${totalSavings.toStringAsFixed(0)} F',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                            color: Color(0xFF185FA5))),
                  ])),
                ],
              ),
            ),
          // Liste comparaisons
          ...filtered.map((c) => _CostCard(comparison: c)),
        ],
      ),
    );
  }
}

class _SavingsBanner extends StatelessWidget {
  final double totalSavings;
  final Map<String, double> savingsByCategory;
  const _SavingsBanner(
      {required this.totalSavings, required this.savingsByCategory});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF185FA5), Color(0xFF1A7A5A)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(Icons.savings_rounded, color: Colors.white, size: 24),
              SizedBox(width: 10),
              Text('Économies grâce à votre CMU',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 13)),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            '${totalSavings.toStringAsFixed(0)} F CFA',
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: Colors.white),
          ),
          const Text('économisés sur ces soins courants',
              style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 11, color: Colors.white70)),
          const SizedBox(height: 14),
          // Mini graphique par catégorie
          ...savingsByCategory.entries.map((e) {
            final pct = totalSavings > 0 ? e.value / totalSavings : 0.0;
            return Padding(
              padding: const EdgeInsets.only(bottom: 6),
              child: Row(
                children: [
                  SizedBox(
                      width: 80,
                      child: Text(e.key,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              color: Colors.white70),
                          overflow: TextOverflow.ellipsis)),
                  const SizedBox(width: 8),
                  Expanded(
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: pct,
                        backgroundColor: Colors.white.withValues(alpha: 0.2),
                        valueColor:
                            const AlwaysStoppedAnimation<Color>(Colors.white),
                        minHeight: 6,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text('${e.value.toStringAsFixed(0)} F',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: Colors.white,
                          fontWeight: FontWeight.w600)),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _CostCard extends StatelessWidget {
  final CostComparison comparison;
  const _CostCard({required this.comparison});

  @override
  Widget build(BuildContext context) {
    final savePct = comparison.savingsPercent;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05),
              blurRadius: 8,
              offset: const Offset(0, 3))
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(comparison.careType,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text(comparison.description,
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 11,
                            color: AppColors.textSecondary)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: AppColors.success.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text('-${savePct.toStringAsFixed(0)}%',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        color: AppColors.success,
                        fontWeight: FontWeight.w700,
                        fontSize: 12)),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Sans CMU',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                    Text('${comparison.withoutCmu.toStringAsFixed(0)} F',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.error)),
                  ],
                ),
              ),
              const Icon(Icons.arrow_forward_rounded,
                  color: AppColors.textLight),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Avec CMU',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                    Text(
                      comparison.withCmu == 0
                          ? 'GRATUIT'
                          : '${comparison.withCmu.toStringAsFixed(0)} F',
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: comparison.withCmu == 0
                              ? AppColors.success
                              : const Color(0xFF185FA5)),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const Text('Vous économisez',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.textSecondary)),
                    Text('${comparison.savings.toStringAsFixed(0)} F',
                        style: const TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                            color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: comparison.withCmu / comparison.withoutCmu,
              backgroundColor: AppColors.success.withValues(alpha: 0.2),
              valueColor:
                  const AlwaysStoppedAnimation<Color>(Color(0xFF185FA5)),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 3: Suivi de santé ────────────────────────────────────────────────────

class _HealthTrackingTab extends StatefulWidget {
  const _HealthTrackingTab();

  @override
  State<_HealthTrackingTab> createState() => _HealthTrackingTabState();
}

class _HealthTrackingTabState extends State<_HealthTrackingTab> {
  HealthMetricType _selectedType = HealthMetricType.bloodPressure;

  final _typeConfigs = {
    HealthMetricType.bloodPressure: const _MetricConfig(
        'Tension', Icons.monitor_heart_rounded, Color(0xFF185FA5), 'mmHg'),
    HealthMetricType.bloodSugar: const _MetricConfig(
        'Glycémie', Icons.water_drop_rounded, Color(0xFFE91E63), 'g/L'),
    HealthMetricType.heartRate: const _MetricConfig(
        'Cardiaque', Icons.favorite_rounded, Color(0xFFF44336), 'bpm'),
    HealthMetricType.weight: const _MetricConfig(
        'Poids', Icons.monitor_weight_rounded, Color(0xFF9C27B0), 'kg'),
    HealthMetricType.oxygenSaturation: const _MetricConfig(
        'Saturation O2', Icons.air_rounded, Color(0xFF00BCD4), '%'),
  };

  @override
  Widget build(BuildContext context) {
    final cmu = context.watch<CmuProvider>();
    final config = _typeConfigs[_selectedType]!;
    final metrics = cmu.getMetricsByType(_selectedType);
    final latest = cmu.getLatestMetric(_selectedType);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Résumé santé rapide
          _HealthSummaryRow(cmu: cmu),
          const SizedBox(height: 16),
          // Sélecteur de métrique
          SizedBox(
            height: 80,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: _typeConfigs.entries.map((e) {
                final lm = cmu.getLatestMetric(e.key);
                return GestureDetector(
                  onTap: () => setState(() => _selectedType = e.key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    width: 100,
                    margin: const EdgeInsets.only(right: 10),
                    padding:
                        const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
                    decoration: BoxDecoration(
                      color:
                          _selectedType == e.key ? e.value.color : Colors.white,
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                            color: e.value.color.withValues(
                                alpha: _selectedType == e.key ? 0.3 : 0.05),
                            blurRadius: 8,
                            offset: const Offset(0, 3))
                      ],
                    ),
                    child: Column(
                      children: [
                        Icon(e.value.icon,
                            color: _selectedType == e.key
                                ? Colors.white
                                : e.value.color,
                            size: 22),
                        const SizedBox(height: 4),
                        Text(e.value.label,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 10,
                                color: _selectedType == e.key
                                    ? Colors.white
                                    : AppColors.textPrimary,
                                fontWeight: FontWeight.w600),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis),
                        if (lm != null)
                          Text('${lm.displayValue} ${e.value.unit}',
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 9,
                                  color: _selectedType == e.key
                                      ? Colors.white70
                                      : AppColors.textSecondary)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 16),
          // Valeur actuelle
          if (latest != null) _CurrentValueCard(metric: latest, config: config),
          const SizedBox(height: 16),
          // Graphique
          if (metrics.isNotEmpty)
            _MetricChart(metrics: metrics, config: config),
          const SizedBox(height: 16),
          // Historique
          const Text('Historique',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 10),
          ...metrics.reversed
              .take(7)
              .map((m) => _MetricHistoryRow(metric: m, config: config)),
          const SizedBox(height: 16),
          // Bouton ajouter mesure
          ElevatedButton.icon(
            onPressed: () => _showAddMetricDialog(context, _selectedType),
            style: ElevatedButton.styleFrom(
              backgroundColor: config.color,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14)),
              minimumSize: const Size.fromHeight(50),
            ),
            icon: const Icon(Icons.add_rounded, color: Colors.white),
            label: const Text('Ajouter une mesure',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    color: Colors.white,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  void _showAddMetricDialog(BuildContext context, HealthMetricType type) {
    final ctrl1 = TextEditingController();
    final ctrl2 = TextEditingController();
    final config = _typeConfigs[type]!;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => Container(
        padding: EdgeInsets.fromLTRB(
            24, 24, 24, MediaQuery.of(context).viewInsets.bottom + 24),
        decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24))),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(children: [
              Icon(config.icon, color: config.color),
              const SizedBox(width: 8),
              Text('Ajouter ${config.label}',
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontWeight: FontWeight.w700,
                      fontSize: 16)),
            ]),
            const SizedBox(height: 20),
            if (type == HealthMetricType.bloodPressure) ...[
              TextField(
                controller: ctrl1,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Systolique (mmHg)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: ctrl2,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                    labelText: 'Diastolique (mmHg)',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12))),
              ),
            ] else
              TextField(
                controller: ctrl1,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                decoration: InputDecoration(
                  labelText: '${config.label} (${config.unit})',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: () {
                final val = double.tryParse(ctrl1.text);
                if (val != null) {
                  context.read<CmuProvider>().addHealthMetric(HealthMetric(
                        id: 'hm_${DateTime.now().millisecondsSinceEpoch}',
                        type: type,
                        value: val,
                        value2: type == HealthMetricType.bloodPressure
                            ? double.tryParse(ctrl2.text)
                            : null,
                        unit: config.unit,
                        recordedAt: DateTime.now(),
                      ));
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                        content: Text('Mesure enregistrée'),
                        behavior: SnackBarBehavior.floating),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: config.color,
                minimumSize: const Size.fromHeight(48),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
              child: const Text('Enregistrer',
                  style: TextStyle(
                      fontFamily: 'Poppins',
                      color: Colors.white,
                      fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}

class _MetricConfig {
  final String label;
  final IconData icon;
  final Color color;
  final String unit;
  const _MetricConfig(this.label, this.icon, this.color, this.unit);
}

class _HealthSummaryRow extends StatelessWidget {
  final CmuProvider cmu;
  const _HealthSummaryRow({required this.cmu});

  @override
  Widget build(BuildContext context) {
    final summary = cmu.getHealthSummary();
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
            colors: [Color(0xFF185FA5), Color(0xFF1A7A5A)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _SumItem(
              label: 'Tension',
              value:
                  '${summary['systolic']!.toInt()}/${summary['diastolic']!.toInt()}',
              unit: 'mmHg',
              icon: Icons.monitor_heart_rounded),
          Container(
              width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _SumItem(
              label: 'Glycémie',
              value: summary['bloodSugar']!.toStringAsFixed(2),
              unit: 'g/L',
              icon: Icons.water_drop_rounded),
          Container(
              width: 1, height: 40, color: Colors.white.withValues(alpha: 0.3)),
          _SumItem(
              label: 'Rythme',
              value: '${summary['heartRate']!.toInt()}',
              unit: 'bpm',
              icon: Icons.favorite_rounded),
        ],
      ),
    );
  }
}

class _SumItem extends StatelessWidget {
  final String label;
  final String value;
  final String unit;
  final IconData icon;
  const _SumItem(
      {required this.label,
      required this.value,
      required this.unit,
      required this.icon});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: Colors.white70, size: 16),
        const SizedBox(height: 4),
        Text(value,
            style: const TextStyle(
                fontFamily: 'Poppins',
                fontWeight: FontWeight.w700,
                color: Colors.white,
                fontSize: 15)),
        Text(unit,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 9, color: Colors.white60)),
        Text(label,
            style: const TextStyle(
                fontFamily: 'Poppins', fontSize: 9, color: Colors.white70)),
      ],
    );
  }
}

class _CurrentValueCard extends StatelessWidget {
  final HealthMetric metric;
  final _MetricConfig config;
  const _CurrentValueCard({required this.metric, required this.config});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: config.color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: config.color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(14),
            decoration:
                BoxDecoration(color: config.color, shape: BoxShape.circle),
            child: Icon(config.icon, color: Colors.white, size: 26),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Dernière mesure',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: config.color)),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(metric.displayValue,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 32,
                            fontWeight: FontWeight.w800,
                            color: config.color)),
                    const SizedBox(width: 4),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 5),
                      child: Text(config.unit,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              color: config.color.withValues(alpha: 0.7))),
                    ),
                  ],
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                      color: config.color.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(20)),
                  child: Text(metric.statusLabel,
                      style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: config.color)),
                ),
              ],
            ),
          ),
          Text(
            '${metric.recordedAt.hour.toString().padLeft(2, '0')}:${metric.recordedAt.minute.toString().padLeft(2, '0')}',
            style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 11,
                color: config.color.withValues(alpha: 0.7)),
          ),
        ],
      ),
    );
  }
}

class _MetricChart extends StatelessWidget {
  final List<HealthMetric> metrics;
  final _MetricConfig config;
  const _MetricChart({required this.metrics, required this.config});

  @override
  Widget build(BuildContext context) {
    final last7 =
        metrics.length > 7 ? metrics.sublist(metrics.length - 7) : metrics;
    final maxVal = last7.map((m) => m.value).reduce(math.max) * 1.1;
    final minVal = last7.map((m) => m.value).reduce(math.min) * 0.9;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, 3))
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Évolution - 7 derniers jours',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 13,
                  color: config.color)),
          const SizedBox(height: 12),
          SizedBox(
            height: 100,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: last7.asMap().entries.map((e) {
                final pct = maxVal > minVal
                    ? (e.value.value - minVal) / (maxVal - minVal)
                    : 0.5;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(e.value.displayValue,
                          style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 8,
                              color: config.color,
                              fontWeight: FontWeight.w600)),
                      const SizedBox(height: 3),
                      AnimatedContainer(
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOut,
                        width: 22,
                        height: (pct * 70).clamp(8, 70).toDouble(),
                        decoration: BoxDecoration(
                          color: config.color,
                          borderRadius: const BorderRadius.vertical(
                              top: Radius.circular(4)),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                          '${e.value.recordedAt.day}/${e.value.recordedAt.month}',
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 7,
                              color: AppColors.textLight)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}

class _MetricHistoryRow extends StatelessWidget {
  final HealthMetric metric;
  final _MetricConfig config;
  const _MetricHistoryRow({required this.metric, required this.config});

  @override
  Widget build(BuildContext context) {
    final d = metric.recordedAt;
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 4)
          ]),
      child: Row(
        children: [
          Container(
              width: 8,
              height: 8,
              decoration:
                  BoxDecoration(color: config.color, shape: BoxShape.circle)),
          const SizedBox(width: 12),
          Text(
              '${d.day.toString().padLeft(2, '0')}/${d.month.toString().padLeft(2, '0')} ${d.hour.toString().padLeft(2, '0')}:${d.minute.toString().padLeft(2, '0')}',
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 12,
                  color: AppColors.textSecondary)),
          const Spacer(),
          Flexible(
            child: Text('${metric.displayValue} ${config.unit}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: config.color)),
          ),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
                color: config.color.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8)),
            child: Text(metric.statusLabel,
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    color: config.color,
                    fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }
}

// ─── Tab 4: Couverture CMU ────────────────────────────────────────────────────

class _CoverageTab extends StatefulWidget {
  const _CoverageTab();

  @override
  State<_CoverageTab> createState() => _CoverageTabState();
}

class _CoverageTabState extends State<_CoverageTab> {
  String _selectedCat = 'Tous';
  int _expandedFaq = -1;
  final _msgCtrl = TextEditingController();

  final _faqs = [
    {
      'q': 'Comment utiliser ma carte CMU ?',
      'a':
          'Présentez votre carte CMU (physique ou numérique) lors de vos consultations, hospitalisations ou à la pharmacie. Le professionnel de santé vérifie votre numéro CMU et applique directement le taux de remboursement.'
    },
    {
      'q': 'Quels soins sont couverts par la CMU ?',
      'a':
          'La CMU couvre les consultations chez le généraliste et le spécialiste, les hospitalisations, les médicaments essentiels, les examens de laboratoire, l\'imagerie médicale, et les soins de maternité à 100%.'
    },
    {
      'q': 'Comment se faire rembourser ?',
      'a':
          'Le remboursement est direct : le professionnel facture la CMU directement. Si vous avez avancé des frais, soumettez vos factures via l\'application ou au bureau CNAM le plus proche avec votre carte CMU.'
    },
    {
      'q': 'Ma carte a expiré, que faire ?',
      'a':
          'Rendez-vous au bureau CNAM avec une pièce d\'identité et votre ancienne carte. Le renouvellement est gratuit si vous êtes à jour de cotisation. Vous pouvez aussi initier le renouvellement via l\'application.'
    },
    {
      'q': 'Puis-je ajouter des ayants droit ?',
      'a':
          'Oui, vous pouvez ajouter votre conjoint(e) et vos enfants à votre couverture CMU. Rendez-vous au bureau CNAM avec les documents d\'état civil de chaque ayant droit.'
    },
    {
      'q': 'Que faire en cas d\'urgence médicale ?',
      'a':
          'En cas d\'urgence, présentez-vous aux urgences d\'un hôpital public avec votre carte CMU. Les soins d\'urgence sont couverts à 100%. Le SAMU est accessible au 185 et est gratuit.'
    },
  ];

  @override
  Widget build(BuildContext context) {
    final cmu = context.watch<CmuProvider>();
    final cats = [
      'Tous',
      'Consultations',
      'Hospitalisation',
      'Médicaments',
      'Examens',
      'Maternité',
      'Urgences'
    ];
    final filtered = _selectedCat == 'Tous'
        ? cmu.benefits
        : cmu.benefits.where((b) => b.category == _selectedCat).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Bandeau couverture
          _CoverageBanner(),
          const SizedBox(height: 16),
          // Titre prestations
          const Text('Mes prestations',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 10),
          // Filtres
          SizedBox(
            height: 36,
            child: ListView(
              scrollDirection: Axis.horizontal,
              children: cats
                  .map((cat) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: FilterChip(
                          label: Text(cat,
                              style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  color: _selectedCat == cat
                                      ? Colors.white
                                      : AppColors.textPrimary)),
                          selected: _selectedCat == cat,
                          onSelected: (_) => setState(() => _selectedCat = cat),
                          selectedColor: const Color(0xFF185FA5),
                          backgroundColor: AppColors.backgroundGrey,
                          checkmarkColor: Colors.white,
                          side: BorderSide.none,
                        ),
                      ))
                  .toList(),
            ),
          ),
          const SizedBox(height: 12),
          // Liste des prestations
          ...filtered.map((b) => _BenefitCard(benefit: b)),
          const SizedBox(height: 16),
          // FAQ
          const Text('Questions fréquentes',
              style: TextStyle(
                  fontFamily: 'Poppins',
                  fontWeight: FontWeight.w700,
                  fontSize: 15)),
          const SizedBox(height: 10),
          ...List.generate(
              _faqs.length,
              (i) => _FaqItem(
                    question: _faqs[i]['q']!,
                    answer: _faqs[i]['a']!,
                    isExpanded: _expandedFaq == i,
                    onTap: () => setState(
                        () => _expandedFaq = _expandedFaq == i ? -1 : i),
                  )),
          const SizedBox(height: 16),
          // Chat conseiller
          _ChatAdviserWidget(controller: _msgCtrl),
          const SizedBox(height: 16),
          // Mes demandes
          if (cmu.requests.isNotEmpty) ...[
            const Text('Mes demandes',
                style: TextStyle(
                    fontFamily: 'Poppins',
                    fontWeight: FontWeight.w700,
                    fontSize: 15)),
            const SizedBox(height: 10),
            ...cmu.requests.map((r) => _RequestCard(request: r)),
          ],
        ],
      ),
    );
  }
}

class _CoverageBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFF185FA5),
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Row(
        children: [
          Icon(Icons.shield_rounded, color: Colors.white, size: 40),
          SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Votre couverture CMU',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white,
                        fontWeight: FontWeight.w700,
                        fontSize: 14)),
                Text('10 catégories de soins couvertes',
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        color: Colors.white70,
                        fontSize: 11)),
                SizedBox(height: 6),
                Row(
                  children: [
                    _CovBadge('70-100%', 'remboursement'),
                    SizedBox(width: 8),
                    _CovBadge('CMU active', 'validité 2026'),
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

class _CovBadge extends StatelessWidget {
  final String value;
  final String label;
  const _CovBadge(this.value, this.label);

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.2),
          borderRadius: BorderRadius.circular(8)),
      child: Column(
        children: [
          Text(value,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 10,
                  color: Colors.white,
                  fontWeight: FontWeight.w700)),
          Text(label,
              style: const TextStyle(
                  fontFamily: 'Poppins', fontSize: 8, color: Colors.white60)),
        ],
      ),
    );
  }
}

class _BenefitCard extends StatelessWidget {
  final CmuBenefit benefit;
  const _BenefitCard({required this.benefit});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.04), blurRadius: 8)
          ]),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
                color: const Color(0xFF185FA5).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12)),
            child: Center(
                child: Text('${benefit.coveragePercent.toInt()}%',
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF185FA5),
                        fontSize: 14))),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                        child: Text(benefit.title,
                            style: const TextStyle(
                                fontFamily: 'Poppins',
                                fontWeight: FontWeight.w700,
                                fontSize: 13))),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 7, vertical: 2),
                      decoration: BoxDecoration(
                          color: AppColors.primaryUltraLight,
                          borderRadius: BorderRadius.circular(8)),
                      child: Text(benefit.category,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 9,
                              color: AppColors.primary)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(benefit.description,
                    style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 11,
                        color: AppColors.textSecondary)),
                if (benefit.maxAmount != null) ...[
                  const SizedBox(height: 3),
                  Text(
                      'Plafond: ${benefit.maxAmount!.toStringAsFixed(0)} F CFA',
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: AppColors.success,
                          fontWeight: FontWeight.w600)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final String question;
  final String answer;
  final bool isExpanded;
  final VoidCallback onTap;
  const _FaqItem(
      {required this.question,
      required this.answer,
      required this.isExpanded,
      required this.onTap});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)
          ]),
      child: Column(
        children: [
          InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(14),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  const Icon(Icons.help_outline_rounded,
                      color: Color(0xFF185FA5), size: 18),
                  const SizedBox(width: 10),
                  Expanded(
                      child: Text(question,
                          style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 13))),
                  Icon(
                      isExpanded
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      color: AppColors.textSecondary),
                ],
              ),
            ),
          ),
          if (isExpanded)
            Padding(
              padding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
              child: Text(answer,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 12,
                      color: AppColors.textSecondary,
                      height: 1.6)),
            ),
        ],
      ),
    );
  }
}

class _ChatAdviserWidget extends StatefulWidget {
  final TextEditingController controller;
  const _ChatAdviserWidget({required this.controller});

  @override
  State<_ChatAdviserWidget> createState() => _ChatAdviserWidgetState();
}

class _ChatAdviserWidgetState extends State<_ChatAdviserWidget> {
  final List<Map<String, String>> _messages = [
    {
      'role': 'adviser',
      'text':
          'Bonjour ! Je suis votre conseiller CMU. Comment puis-je vous aider ?'
    },
  ];
  bool _isTyping = false;

  void _send() {
    final text = widget.controller.text.trim();
    if (text.isEmpty) return;
    setState(() {
      _messages.add({'role': 'user', 'text': text});
      _isTyping = true;
    });
    widget.controller.clear();

    Future.delayed(const Duration(seconds: 2), () {
      if (!mounted) return;
      final responses = [
        'Je comprends votre demande. Pour toute question de remboursement, vous pouvez soumettre une demande via l\'onglet "Mes demandes".',
        'Votre couverture CMU est active jusqu\'en 2026. Vous bénéficiez de 10 catégories de soins couverts.',
        'Je vais transférer votre demande à un conseiller humain. Vous recevrez une réponse dans 24h.',
        'Pour les urgences médicales, appelez le SAMU au 185. Votre CMU couvre 100% des soins d\'urgence.',
      ];
      setState(() {
        _messages.add({
          'role': 'adviser',
          'text': responses[DateTime.now().second % responses.length]
        });
        _isTyping = false;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.05), blurRadius: 10)
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                    color: const Color(0xFF185FA5).withValues(alpha: 0.1),
                    shape: BoxShape.circle),
                child: const Icon(Icons.support_agent_rounded,
                    color: Color(0xFF185FA5), size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Conseiller CMU',
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: FontWeight.w700,
                            fontSize: 13)),
                    Text('En ligne · Répond en quelques minutes',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 10,
                            color: AppColors.success)),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Container(
            height: 150,
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
                color: AppColors.backgroundLight,
                borderRadius: BorderRadius.circular(12)),
            child: ListView(
              children: [
                ..._messages.map((m) => Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        mainAxisAlignment: m['role'] == 'user'
                            ? MainAxisAlignment.end
                            : MainAxisAlignment.start,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 230),
                            padding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: m['role'] == 'user'
                                  ? const Color(0xFF185FA5)
                                  : Colors.white,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(m['text']!,
                                style: TextStyle(
                                    fontFamily: 'Poppins',
                                    fontSize: 11,
                                    color: m['role'] == 'user'
                                        ? Colors.white
                                        : AppColors.textPrimary)),
                          ),
                        ],
                      ),
                    )),
                if (_isTyping)
                  const Padding(
                    padding: EdgeInsets.only(bottom: 8),
                    child: Row(children: [
                      SizedBox(
                        width: 40,
                        height: 20,
                        child: _TypingDots(),
                      ),
                    ]),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  controller: widget.controller,
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Posez votre question...',
                    hintStyle: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textLight),
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.backgroundGrey)),
                    enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                            const BorderSide(color: AppColors.backgroundGrey)),
                    contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 10),
                    isDense: true,
                  ),
                  onSubmitted: (_) => _send(),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: _send,
                child: Container(
                  padding: const EdgeInsets.all(10),
                  decoration: const BoxDecoration(
                      color: Color(0xFF185FA5), shape: BoxShape.circle),
                  child: const Icon(Icons.send_rounded,
                      color: Colors.white, size: 18),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _TypingDots extends StatefulWidget {
  const _TypingDots();

  @override
  State<_TypingDots> createState() => _TypingDotsState();
}

class _TypingDotsState extends State<_TypingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 900))
      ..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(3, (i) {
            final opacity =
                math.sin((_ctrl.value * math.pi * 2) - (i * 0.5)) * 0.5 + 0.5;
            return Container(
              margin: const EdgeInsets.only(right: 3),
              width: 7,
              height: 7,
              decoration: BoxDecoration(
                color: const Color(0xFF185FA5).withValues(alpha: opacity),
                shape: BoxShape.circle,
              ),
            );
          }),
        );
      },
    );
  }
}

class _RequestCard extends StatelessWidget {
  final CmuRequest request;
  const _RequestCard({required this.request});

  Color get _statusColor {
    switch (request.status) {
      case CmuRequestStatus.pending:
        return AppColors.warning;
      case CmuRequestStatus.inProgress:
        return AppColors.info;
      case CmuRequestStatus.resolved:
        return AppColors.success;
      case CmuRequestStatus.rejected:
        return AppColors.error;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
                color: Colors.black.withValues(alpha: 0.03), blurRadius: 6)
          ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                  child: Text(request.type,
                      style: const TextStyle(
                          fontFamily: 'Poppins',
                          fontWeight: FontWeight.w700,
                          fontSize: 13))),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                    color: _statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20)),
                child: Text(request.statusLabel,
                    style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 10,
                        color: _statusColor,
                        fontWeight: FontWeight.w700)),
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(request.description,
              style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 11,
                  color: AppColors.textSecondary)),
          if (request.response != null) ...[
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                  color: AppColors.success.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10)),
              child: Text(request.response!,
                  style: const TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: AppColors.success)),
            ),
          ],
        ],
      ),
    );
  }
}
