// ════════════════════════════════════════════════════════════
//  login_screen.dart
//  My Doctor - Écran de Connexion Unifié (Patient & Médecin)
//  Design épuré fidèle à la maquette officielle
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/common/app_logo.dart';

class LoginScreen extends StatefulWidget {
  final UserRole initialRole;
  final bool isDemoMode;

  const LoginScreen({
    super.key,
    this.initialRole = UserRole.patient,
    this.isDemoMode = false,
  });

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _identifierCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();

  late UserRole _selectedRole;
  bool _obscurePass = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedRole = widget.initialRole == UserRole.doctor
        ? UserRole.doctor
        : UserRole.patient;
  }

  @override
  void dispose() {
    _identifierCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final auth = context.read<AuthProvider>();
    final identifier = _identifierCtrl.text.trim();
    final password = _passwordCtrl.text.trim();

    bool success = false;

    if (_selectedRole == UserRole.doctor) {
      success = await auth.loginDoctor(
        identifier: identifier,
        password: password,
      );
    } else {
      success = await auth.loginPatient(
        identifier: identifier,
        password: password,
      );
    }

    if (!mounted) return;
    setState(() => _isLoading = false);

    if (success) {
      if (auth.isAdmin) {
        Navigator.pushNamedAndRemoveUntil(context, '/admin', (route) => false);
      } else if (_selectedRole == UserRole.doctor) {
        Navigator.pushNamedAndRemoveUntil(context, '/doctor/home', (route) => false);
      } else {
        Navigator.pushNamedAndRemoveUntil(context, '/patient/home', (route) => false);
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            auth.errorMessage ?? 'Identifiant ou mot de passe incorrect',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _showForgotPasswordModal() {
    final resetCtrl = TextEditingController();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: MediaQuery.of(ctx).viewInsets.bottom + 24,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE2E8F0),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Mot de passe oublié ?',
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppColors.brandNavy,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Entrez votre adresse e-mail ou numéro de téléphone pour recevoir les instructions de réinitialisation.',
                style: TextStyle(
                  fontSize: 14,
                  color: AppColors.textSecondary,
                  height: 1.4,
                ),
              ),
              const SizedBox(height: 20),
              Container(
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFE2E8F0), width: 1.2),
                ),
                child: TextField(
                  controller: resetCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    hintText: 'Téléphone ou e-mail',
                    hintStyle: TextStyle(
                      color: Color(0xFF94A3B8),
                      fontSize: 14.5,
                      fontWeight: FontWeight.w400,
                    ),
                    prefixIcon: Icon(
                      LucideIcons.mail,
                      color: Color(0xFF94A3B8),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () {
                    final target = resetCtrl.text.trim();
                    Navigator.pop(ctx);
                    if (target.isNotEmpty) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('Instructions envoyées à $target'),
                          backgroundColor: AppColors.brandBlue,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandBlue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'Envoyer',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
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
      backgroundColor: Colors.white,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minHeight: MediaQuery.of(context).size.height -
                  MediaQuery.of(context).padding.top -
                  MediaQuery.of(context).padding.bottom,
            ),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  // ═══════════════════════════════════════════════════════════
                  // SECTION SUPÉRIEURE : LOGO + TITRE + TOGGLE + FORMULAIRE
                  // ═══════════════════════════════════════════════════════════
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      const SizedBox(height: 20),

                      // Logo Officiel My Doctor (sans capsule de fond)
                      const Center(
                        child: AppLogo(
                          height: 124,
                          showCard: false,
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Titre "Connexion"
                      const Text(
                        'Connexion',
                        style: TextStyle(
                          fontSize: 25,
                          fontWeight: FontWeight.w600,
                          color: AppColors.brandBlue,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 26),

                      // ── Commutateur de profil (Pill Toggle) ─────────────────
                      Center(
                        child: Container(
                          constraints: const BoxConstraints(maxWidth: 270),
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9),
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Row(
                            children: [
                              _buildRoleTab(
                                role: UserRole.patient,
                                label: 'Patient',
                                isSelected: _selectedRole == UserRole.patient,
                              ),
                              _buildRoleTab(
                                role: UserRole.doctor,
                                label: 'Médecin',
                                isSelected: _selectedRole == UserRole.doctor,
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 28),

                      // ── Champ 1 : Téléphone ou e-mail ──────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: TextFormField(
                          controller: _identifierCtrl,
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: const InputDecoration(
                            hintText: 'Téléphone ou e-mail',
                            hintStyle: TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: Icon(
                              LucideIcons.mail,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Veuillez saisir votre numéro ou e-mail';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Champ 2 : Mot de passe ─────────────────────────────
                      Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFFF8FAFC),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: const Color(0xFFE2E8F0),
                            width: 1.2,
                          ),
                        ),
                        child: TextFormField(
                          controller: _passwordCtrl,
                          obscureText: _obscurePass,
                          textInputAction: TextInputAction.done,
                          onFieldSubmitted: (_) => _handleLogin(),
                          style: const TextStyle(
                            fontSize: 15,
                            color: AppColors.textPrimary,
                            fontWeight: FontWeight.w500,
                          ),
                          decoration: InputDecoration(
                            hintText: 'Mot de passe',
                            hintStyle: const TextStyle(
                              color: Color(0xFF94A3B8),
                              fontSize: 14.5,
                              fontWeight: FontWeight.w400,
                            ),
                            prefixIcon: const Icon(
                              LucideIcons.lock,
                              color: Color(0xFF94A3B8),
                              size: 20,
                            ),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _obscurePass
                                    ? LucideIcons.eye
                                    : LucideIcons.eye_off,
                                color: const Color(0xFF94A3B8),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() => _obscurePass = !_obscurePass);
                              },
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                          ),
                          validator: (v) {
                            if (v == null || v.trim().isEmpty) {
                              return 'Veuillez saisir votre mot de passe';
                            }
                            return null;
                          },
                        ),
                      ),
                      const SizedBox(height: 10),

                      // ── Lien "Mot de passe oublié ?" ───────────────────────
                      Align(
                        alignment: Alignment.centerRight,
                        child: GestureDetector(
                          onTap: _showForgotPasswordModal,
                          behavior: HitTestBehavior.opaque,
                          child: const Padding(
                            padding: EdgeInsets.symmetric(vertical: 4, horizontal: 2),
                            child: Text(
                              'Mot de passe oublié ?',
                              style: TextStyle(
                                color: AppColors.brandBlue,
                                fontSize: 13.5,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // ── Bouton 1 : Se connecter → ───────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleLogin,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.brandBlue,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            shadowColor: Colors.transparent,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    valueColor: AlwaysStoppedAnimation<Color>(
                                      Colors.white,
                                    ),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Flexible(
                                      child: Text(
                                        'Se connecter',
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w600,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                                    SizedBox(width: 8),
                                    Icon(
                                      LucideIcons.arrow_right,
                                      size: 18,
                                      color: Colors.white,
                                    ),
                                  ],
                                ),
                        ),
                      ),
                      const SizedBox(height: 14),

                      // ── Bouton 2 : Créer un compte ─────────────────────────
                      SizedBox(
                        width: double.infinity,
                        height: 52,
                        child: OutlinedButton(
                          onPressed: () {
                            if (_selectedRole == UserRole.doctor) {
                              Navigator.pushNamed(context, '/auth/doctor/register');
                            } else {
                              Navigator.pushNamed(context, '/auth/patient/register');
                            }
                          },
                          style: OutlinedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppColors.brandBlue,
                            side: const BorderSide(
                              color: AppColors.brandBlue,
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(28),
                            ),
                          ),
                          child: const Text(
                            'Créer un compte',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                              color: AppColors.brandBlue,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // Accès rapide discret console administrateur
                      Center(
                        child: TextButton(
                          onPressed: () {
                            Navigator.pushNamed(context, '/admin/login');
                          },
                          style: TextButton.styleFrom(
                            visualDensity: VisualDensity.compact,
                            foregroundColor: const Color(0xFFCBD5E1),
                          ),
                          child: const Text(
                            'Administration',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w400,
                              color: Color(0xFF94A3B8),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),

                  // ═══════════════════════════════════════════════════════════
                  // SECTION INFÉRIEURE : LIGNE ONDE ECG DÉCORATIVE
                  // ═══════════════════════════════════════════════════════════
                  const Padding(
                    padding: EdgeInsets.only(top: 16, bottom: 20),
                    child: Center(
                      child: EcgPulseDivider(),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Onglet du commutateur Patient / Médecin
  Widget _buildRoleTab({
    required UserRole role,
    required String label,
    required bool isSelected,
  }) {
    final bool isPatient = role == UserRole.patient;

    return Expanded(
      child: GestureDetector(
        onTap: () {
          if (_selectedRole != role) {
            setState(() => _selectedRole = role);
          }
        },
        behavior: HitTestBehavior.opaque,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeInOut,
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.brandBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(26),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: AppColors.brandBlue.withValues(alpha: 0.28),
                      blurRadius: 8,
                      offset: const Offset(0, 2),
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (isPatient)
                Icon(
                  Icons.person,
                  size: 18,
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                )
              else
                DoctorSilhouetteIcon(
                  color: isSelected ? Colors.white : const Color(0xFF64748B),
                  accentColor: isSelected
                      ? AppColors.brandBlue
                      : const Color(0xFFF1F5F9),
                  size: 18,
                ),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                    color: isSelected ? Colors.white : const Color(0xFF64748B),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Widget vectoriel pour l'icône médecin avec silhouette et stéthoscope stylisé
class DoctorSilhouetteIcon extends StatelessWidget {
  final Color color;
  final Color accentColor;
  final double size;

  const DoctorSilhouetteIcon({
    super.key,
    required this.color,
    required this.accentColor,
    this.size = 18,
  });

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      size: Size(size, size),
      painter: _DoctorSilhouettePainter(
        color: color,
        accentColor: accentColor,
      ),
    );
  }
}

class _DoctorSilhouettePainter extends CustomPainter {
  final Color color;
  final Color accentColor;

  _DoctorSilhouettePainter({required this.color, required this.accentColor});

  @override
  void paint(Canvas canvas, Size size) {
    final scale = size.width / 20.0;
    canvas.scale(scale, scale);

    final fillPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    // Tête
    canvas.drawCircle(const Offset(10, 4.8), 3.2, fillPaint);

    // Torse et épaules
    final bodyPath = Path()
      ..moveTo(3.0, 18.0)
      ..cubicTo(3.0, 13.8, 6.2, 11.2, 9.2, 10.8)
      ..lineTo(10.8, 10.8)
      ..cubicTo(13.8, 11.2, 17.0, 13.8, 17.0, 18.0)
      ..close();
    canvas.drawPath(bodyPath, fillPaint);

    // Stéthoscope drapé autour du cou
    final stethPaint = Paint()
      ..color = accentColor
      ..strokeWidth = 1.3
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final stethLoop = Path()
      ..moveTo(7.5, 10.5)
      ..cubicTo(7.5, 14.2, 9.0, 15.2, 10.0, 15.2)
      ..cubicTo(11.0, 15.2, 12.5, 14.2, 12.5, 10.5);
    canvas.drawPath(stethLoop, stethPaint);

    // Tubulure vers le pavillon
    final tubePath = Path()
      ..moveTo(10.0, 15.2)
      ..lineTo(11.2, 16.5);
    canvas.drawPath(tubePath, stethPaint);

    // Pavillon du stéthoscope (cloche)
    final chestpiecePaint = Paint()
      ..color = accentColor
      ..style = PaintingStyle.fill;
    canvas.drawCircle(const Offset(11.8, 17.0), 1.2, chestpiecePaint);
  }

  @override
  bool shouldRepaint(covariant _DoctorSilhouettePainter oldDelegate) =>
      oldDelegate.color != color || oldDelegate.accentColor != accentColor;
}

/// Widget vectoriel dessinant l'onde ECG cardiaque turquoise avec estompage horizontal
class EcgPulseDivider extends StatelessWidget {
  const EcgPulseDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 180,
      height: 32,
      child: CustomPaint(
        painter: _EcgPainter(),
      ),
    );
  }
}

class _EcgPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double midY = size.height / 2;
    final double w = size.width;

    // 1. Ligne horizontale estompée à gauche
    final paintLeftLine = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0x00E2E8F0),
          Color(0xFFE2E8F0),
        ],
      ).createShader(Rect.fromLTWH(0, midY - 1, w * 0.38, 2))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(0, midY), Offset(w * 0.38, midY), paintLeftLine);

    // 2. Ligne horizontale estompée à droite
    final paintRightLine = Paint()
      ..shader = const LinearGradient(
        colors: [
          Color(0xFFE2E8F0),
          Color(0x00E2E8F0),
        ],
      ).createShader(Rect.fromLTWH(w * 0.62, midY - 1, w * 0.38, 2))
      ..strokeWidth = 1.2
      ..style = PaintingStyle.stroke;

    canvas.drawLine(Offset(w * 0.62, midY), Offset(w, midY), paintRightLine);

    // 3. Onde cardiaque ECG centrale en turquoise signature
    final ecgPaint = Paint()
      ..color = const Color(0xFF00C9A7) // Turquoise vibrant My Doctor
      ..strokeWidth = 1.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final path = Path();
    // Début de l'onde ECG
    path.moveTo(w * 0.37, midY);
    path.lineTo(w * 0.43, midY);
    // Petite onde P
    path.lineTo(w * 0.45, midY - 3);
    path.lineTo(w * 0.47, midY);
    // Creux Q
    path.lineTo(w * 0.485, midY + 4);
    // Pic R haut
    path.lineTo(w * 0.505, midY - 14);
    // Descente profonde S
    path.lineTo(w * 0.525, midY + 12);
    // Rebond
    path.lineTo(w * 0.54, midY - 4);
    path.lineTo(w * 0.555, midY);
    // Onde T
    path.lineTo(w * 0.58, midY - 4);
    path.lineTo(w * 0.60, midY);
    // Fin vers la ligne droite
    path.lineTo(w * 0.63, midY);

    canvas.drawPath(path, ecgPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
