// lib/screens/auth/cover_screen.dart
//
// Page de garde : image de l'équipe pendant 2,5 secondes,
// puis redirection automatique vers :
//   • le Welcome screen  (si non connecté)
//   • le Home patient/médecin (si déjà connecté)

import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class CoverScreen extends StatefulWidget {
  const CoverScreen({super.key});

  @override
  State<CoverScreen> createState() => _CoverScreenState();
}

class _CoverScreenState extends State<CoverScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _ctrl;
  late Animation<double> _fade;
  bool _navigated = false;
  Timer? _timer;

  @override
  void initState() {
    super.initState();

    // Barre de statut transparente — effet plein écran
    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    // Fondu entrant en 400 ms
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fade = CurvedAnimation(parent: _ctrl, curve: Curves.easeIn);
    _ctrl.forward();

    // Navigation rapide après 600ms
    _timer = Timer(const Duration(milliseconds: 600), _goNext);
  }

  void _goNext() {
    _timer?.cancel();
    if (_navigated || !mounted) return;
    _navigated = true;

    final auth = context.read<AuthProvider>();

    if (auth.isAuthenticated) {
      if (auth.isDoctor) {
        Navigator.pushReplacementNamed(context, '/doctor/home');
      } else {
        Navigator.pushReplacementNamed(context, '/patient/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/welcome');
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: GestureDetector(
        onTap: _goNext, // tap pour sauter
        child: FadeTransition(
          opacity: _fade,
          child: SizedBox(
            width: size.width,
            height: size.height,
            child: Image.asset(
              'assets/images/team_cover.jpg',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) => Container(color: Colors.black),
            ),
          ),
        ),
      ),
    );
  }
}
