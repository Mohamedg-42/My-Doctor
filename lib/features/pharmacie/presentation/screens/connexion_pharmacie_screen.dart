import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pharmacie_provider.dart';
import '../../data/models/pharmacie_model.dart';

class ConnexionPharmacieScreen extends StatefulWidget {
  const ConnexionPharmacieScreen({super.key});

  @override
  State<ConnexionPharmacieScreen> createState() => _ConnexionPharmacieScreenState();
}

class _ConnexionPharmacieScreenState extends State<ConnexionPharmacieScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    super.dispose();
  }

  Future<void> _connecter() async {
    if (!_formKey.currentState!.validate()) return;
    final provider = context.read<PharmacieProvider>();
    final ok = await provider.connecter(
      email: _emailCtrl.text.trim(),
      motDePasse: _passwordCtrl.text,
    );
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/pharmacie/dashboard');
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(provider.errorMessage ?? 'Erreur de connexion'),
          backgroundColor: const Color(0xFFE74C3C),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _demoRapide() async {
    final provider = context.read<PharmacieProvider>();
    final ok = await provider.connexionDemoDirecte();
    if (ok && mounted) {
      Navigator.pushReplacementNamed(context, '/pharmacie/dashboard');
    }
  }

  void _remplirDemo() {
    setState(() {
      _emailCtrl.text = 'pharmacie.centrale.cocody@gmail.com';
      _passwordCtrl.text = 'pharma2025';
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacieProvider>();

    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              // ── Header vert pharmacie ──────────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(24, 32, 24, 36),
                decoration: const BoxDecoration(
                  gradient: PharmacieColors.gradient,
                  borderRadius: BorderRadius.vertical(bottom: Radius.circular(36)),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        GestureDetector(
                          onTap: () => Navigator.pop(context),
                          child: Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(10),
                            ),
                            child: const Icon(Icons.arrow_back_rounded,
                                color: Colors.white, size: 20),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),
                    Container(
                      width: 80,
                      height: 80,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.3), width: 2),
                      ),
                      child: const Icon(Icons.local_pharmacy_rounded,
                          color: Colors.white, size: 40),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Espace Pharmacien',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Connectez-vous à votre tableau de bord',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),

              Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    // ── Bannière démo ────────────────────────────────────────
                    _DemoBanner(onRemplir: _remplirDemo, onDirect: _demoRapide),
                    const SizedBox(height: 24),

                    // ── Formulaire ───────────────────────────────────────────
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          _ChampTexte(
                            label: 'Email ou téléphone',
                            hint: 'pharmacie@example.com',
                            controller: _emailCtrl,
                            prefixIcon: Icons.alternate_email_rounded,
                            keyboardType: TextInputType.emailAddress,
                            validator: (v) => (v == null || v.isEmpty)
                                ? 'Champ obligatoire' : null,
                          ),
                          const SizedBox(height: 16),
                          _ChampTexte(
                            label: 'Mot de passe',
                            hint: '••••••••',
                            controller: _passwordCtrl,
                            prefixIcon: Icons.lock_outline_rounded,
                            obscure: _obscure,
                            suffixIcon: IconButton(
                              icon: Icon(_obscure
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                                  color: Colors.grey.shade500, size: 20),
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                            validator: (v) => (v == null || v.length < 6)
                                ? 'Minimum 6 caractères' : null,
                          ),
                        ],
                      ),
                    ),

                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton(
                        onPressed: () {},
                        child: const Text(
                          'Mot de passe oublié ?',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 12,
                            color: PharmacieColors.primary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // ── Bouton connexion ─────────────────────────────────────
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: provider.isLoading ? null : _connecter,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: PharmacieColors.primary,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(16)),
                          elevation: 0,
                        ),
                        child: provider.isLoading
                            ? const SizedBox(
                                height: 20, width: 20,
                                child: CircularProgressIndicator(
                                    strokeWidth: 2.5, color: Colors.white))
                            : const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.local_pharmacy_rounded, size: 18),
                                  SizedBox(width: 8),
                                  Text(
                                    'Se connecter — Espace Pharmacie',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // ── Inscription ──────────────────────────────────────────
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          'Pas encore de compte ? ',
                          style: TextStyle(
                            fontFamily: 'Poppins', fontSize: 13,
                            color: Color(0xFF7A8BA0),
                          ),
                        ),
                        GestureDetector(
                          onTap: () => Navigator.pushNamed(
                              context, '/pharmacie/inscription'),
                          child: const Text(
                            'S\'inscrire',
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: PharmacieColors.primary,
                            ),
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
      ),
    );
  }
}

// ─── Bannière démo ────────────────────────────────────────────────────────────
class _DemoBanner extends StatelessWidget {
  final VoidCallback onRemplir;
  final VoidCallback onDirect;
  const _DemoBanner({required this.onRemplir, required this.onDirect});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: PharmacieColors.primaryUltraLight,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: PharmacieColors.primary.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: PharmacieColors.primary,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: const Icon(Icons.flash_on_rounded, color: Colors.white, size: 14),
              ),
              const SizedBox(width: 8),
              const Text(
                'Accès Démo — Pharmacie Centrale',
                style: TextStyle(
                  fontFamily: 'Poppins', fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: PharmacieColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            '📧 pharmacie.centrale.cocody@gmail.com\n🔑 pharma2025',
            style: TextStyle(fontFamily: 'Poppins', fontSize: 11, color: Color(0xFF2E7D32)),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: OutlinedButton(
                  onPressed: onRemplir,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: PharmacieColors.primary,
                    side: const BorderSide(color: PharmacieColors.primary),
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                  ),
                  child: const Text('Remplir',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                          fontWeight: FontWeight.w600)),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: ElevatedButton.icon(
                  onPressed: onDirect,
                  icon: const Icon(Icons.bolt_rounded, size: 14),
                  label: const Text('Connexion directe',
                      style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                          fontWeight: FontWeight.w700)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmacieColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10)),
                    elevation: 0,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Champ texte réutilisable ─────────────────────────────────────────────────
class _ChampTexte extends StatelessWidget {
  final String label;
  final String hint;
  final TextEditingController controller;
  final IconData prefixIcon;
  final TextInputType? keyboardType;
  final bool obscure;
  final Widget? suffixIcon;
  final String? Function(String?)? validator;

  const _ChampTexte({
    required this.label,
    required this.hint,
    required this.controller,
    required this.prefixIcon,
    this.keyboardType,
    this.obscure = false,
    this.suffixIcon,
    this.validator,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(
          fontFamily: 'Poppins', fontSize: 12,
          fontWeight: FontWeight.w600, color: Color(0xFF1A2340),
        )),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          obscureText: obscure,
          keyboardType: keyboardType,
          validator: validator,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                color: Color(0xFFB0BEC5)),
            prefixIcon: Icon(prefixIcon, color: PharmacieColors.primary, size: 20),
            suffixIcon: suffixIcon,
            filled: true,
            fillColor: Colors.white,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide(color: Colors.grey.shade200),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: PharmacieColors.primary, width: 1.5),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: Color(0xFFE74C3C)),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}
