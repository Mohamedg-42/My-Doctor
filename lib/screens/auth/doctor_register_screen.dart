// ════════════════════════════════════════════════════════════
//  doctor_register_screen.dart
//  MédiLink Care - Inscription Médecin Complète (Identité & Profil Professionnel)
//  Flux en 3 étapes :
//    1. Identité & Coordonnées (Nom, Prénom, Tél, Email, Ville, Commune)
//    2. Profil Professionnel (Spécialité, N° d'Ordre, Expérience, Tarif, Bio)
//    3. Sécurité & Mot de passe
//  Conforme aux champs de la page profil médecin & règles anti-overflow
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/ivory_coast_locations.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../constants/medical_specialties.dart';
import '../../widgets/common/app_logo.dart';

class DoctorRegisterScreen extends StatefulWidget {
  const DoctorRegisterScreen({super.key});

  @override
  State<DoctorRegisterScreen> createState() => _DoctorRegisterScreenState();
}

class _DoctorRegisterScreenState extends State<DoctorRegisterScreen> {
  final _pageController = PageController();
  int _currentPage = 0;

  // Form keys
  final _formKey1 = GlobalKey<FormState>();
  final _formKey2 = GlobalKey<FormState>();
  final _formKey3 = GlobalKey<FormState>();

  // Contrôleurs - Étape 1 : Identité & Coordonnées
  final _lastNameCtrl = TextEditingController();
  final _firstNameCtrl = TextEditingController();
  final _phoneCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _cityCtrl = TextEditingController(text: 'Abidjan');
  final _communeCtrl = TextEditingController(text: 'Cocody');
  String _selectedCity = 'Abidjan';
  String _selectedCommune = 'Cocody';

  // Contrôleurs - Étape 2 : Profil Professionnel
  String? _selectedSpecialty = 'Médecine Générale';
  final _orderNumberCtrl = TextEditingController();
  final _experienceCtrl = TextEditingController(text: '5');
  final _priceCtrl = TextEditingController(text: '15000');
  final _bioCtrl = TextEditingController();

  // Contrôleurs - Étape 3 : Sécurité
  final _passCtrl = TextEditingController();
  final _confirmPassCtrl = TextEditingController();

  bool _obscurePass = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _selectedCity = _cityCtrl.text.isNotEmpty ? _cityCtrl.text : 'Abidjan';
    _selectedCommune = _communeCtrl.text.isNotEmpty ? _communeCtrl.text : 'Cocody';
    _firstNameCtrl.addListener(_capitalizeFirstName);
    _lastNameCtrl.addListener(_capitalizeLastName);
  }

  void _onCityChanged(String? newCity) {
    if (newCity == null) return;
    setState(() {
      _selectedCity = newCity;
      _cityCtrl.text = newCity;
      final availableCommunes = IvoryCoastLocations.getCommunes(newCity);
      if (!availableCommunes.contains(_selectedCommune)) {
        _selectedCommune = availableCommunes.first;
        _communeCtrl.text = _selectedCommune;
      }
    });
  }

  void _onCommuneChanged(String? newCommune) {
    if (newCommune == null) return;
    setState(() {
      _selectedCommune = newCommune;
      _communeCtrl.text = newCommune;
    });
  }

  void _capitalizeFirstName() {
    final text = _firstNameCtrl.text;
    if (text.isNotEmpty) {
      final capitalized = _capitalizeEachWord(text);
      if (capitalized != text) {
        _firstNameCtrl.value = TextEditingValue(
          text: capitalized,
          selection: TextSelection.collapsed(offset: capitalized.length),
        );
      }
    }
  }

  void _capitalizeLastName() {
    final text = _lastNameCtrl.text;
    if (text.isNotEmpty) {
      final capitalized = text.toUpperCase();
      if (capitalized != text) {
        _lastNameCtrl.value = TextEditingValue(
          text: capitalized,
          selection: TextSelection.collapsed(offset: capitalized.length),
        );
      }
    }
  }

  String _capitalizeEachWord(String text) {
    if (text.isEmpty) return text;
    return text.split(' ').map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).join(' ');
  }

  @override
  void dispose() {
    _pageController.dispose();
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _cityCtrl.dispose();
    _communeCtrl.dispose();
    _orderNumberCtrl.dispose();
    _experienceCtrl.dispose();
    _priceCtrl.dispose();
    _bioCtrl.dispose();
    _passCtrl.dispose();
    _confirmPassCtrl.dispose();
    super.dispose();
  }

  void _nextPage() {
    if (_currentPage == 0) {
      if (!_validatePage1()) return;
      _pageController.animateToPage(
        1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else if (_currentPage == 1) {
      if (!_validatePage2()) return;
      _pageController.animateToPage(
        2,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      _handleRegister();
    }
  }

  void _previousPage() {
    if (_currentPage > 0) {
      _pageController.animateToPage(
        _currentPage - 1,
        duration: const Duration(milliseconds: 350),
        curve: Curves.easeInOutCubic,
      );
    } else {
      Navigator.pop(context);
    }
  }

  bool _validatePage1() {
    if (!_formKey1.currentState!.validate()) return false;
    return true;
  }

  bool _validatePage2() {
    if (!_formKey2.currentState!.validate()) return false;

    if (_selectedSpecialty == null || _selectedSpecialty!.isEmpty) {
      _showError('Veuillez sélectionner une spécialité médicale');
      return false;
    }

    final order = _orderNumberCtrl.text.trim();
    if (order.isNotEmpty && order.length != 5) {
      _showError('Le numéro d\'Ordre des Médecins doit comporter 5 chiffres');
      return false;
    }

    return true;
  }

  bool _validatePage3() {
    if (!_formKey3.currentState!.validate()) return false;
    return true;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(LucideIcons.circle_alert, color: Colors.white, size: 20),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                message,
                style: const TextStyle(fontFamily: 'Poppins'),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: AppColors.error,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  Future<void> _selectSpecialtyModal() async {
    final searchCtrl = TextEditingController();
    List<String> filteredList = List.from(MedicalSpecialties.specialties);

    final selected = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return Container(
            height: MediaQuery.of(context).size.height * 0.75,
            decoration: const BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
            ),
            child: Column(
              children: [
                Container(
                  margin: const EdgeInsets.only(top: 12, bottom: 8),
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      const Icon(LucideIcons.stethoscope, color: AppColors.primary, size: 22),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Sélectionner une spécialité',
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.textPrimary,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.close),
                        onPressed: () => Navigator.pop(context),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: searchCtrl,
                    decoration: InputDecoration(
                      hintText: 'Rechercher une spécialité...',
                      prefixIcon: const Icon(LucideIcons.search, size: 18),
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    ),
                    onChanged: (val) {
                      setModalState(() {
                        filteredList = MedicalSpecialties.specialties
                            .where((s) => s.toLowerCase().contains(val.toLowerCase()))
                            .toList();
                      });
                    },
                  ),
                ),
                const SizedBox(height: 10),
                Expanded(
                  child: ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    itemCount: filteredList.length,
                    separatorBuilder: (_, __) => const Divider(height: 1),
                    itemBuilder: (ctx, i) {
                      final item = filteredList[i];
                      final isSelected = item == _selectedSpecialty;
                      return ListTile(
                        contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        title: Text(
                          item,
                          style: TextStyle(
                            fontFamily: 'Poppins',
                            fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                            color: isSelected ? AppColors.primary : AppColors.textPrimary,
                          ),
                        ),
                        trailing: isSelected
                            ? const Icon(LucideIcons.circle_check, color: AppColors.primary, size: 20)
                            : null,
                        onTap: () => Navigator.pop(ctx, item),
                      );
                    },
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );

    if (selected != null) {
      setState(() => _selectedSpecialty = selected);
    }
  }

  Future<void> _handleRegister() async {
    if (!_validatePage3()) return;

    setState(() => _isLoading = true);

    try {
      final db = DatabaseService();
      final fullPhone = '+225${_phoneCtrl.text.trim()}';
      final emailText = _emailCtrl.text.trim();

      // Enregistrement avec toutes les informations du profil praticien
      final user = await db.registerDoctor(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: fullPhone,
        password: _passCtrl.text.trim(),
        email: emailText.isNotEmpty ? emailText : null,
        specialty: _selectedSpecialty ?? 'Médecine Générale',
        orderNumber: _orderNumberCtrl.text.trim().isNotEmpty ? _orderNumberCtrl.text.trim() : '00000',
        city: _cityCtrl.text.trim().isNotEmpty ? _cityCtrl.text.trim() : 'Abidjan',
        commune: _communeCtrl.text.trim().isNotEmpty ? _communeCtrl.text.trim() : 'Cocody',
        experienceYears: int.tryParse(_experienceCtrl.text.trim()) ?? 0,
        consultationPrice: double.tryParse(_priceCtrl.text.trim()) ?? 15000,
        bio: _bioCtrl.text.trim().isNotEmpty ? _bioCtrl.text.trim() : 'Médecin spécialiste en ${_selectedSpecialty ?? "Médecine Générale"}.',
        status: 'pending',
      );

      if (user == null) {
        if (!mounted) return;
        _showError('Ce numéro de téléphone est déjà utilisé par un autre compte.');
        setState(() => _isLoading = false);
        return;
      }

      if (!mounted) return;

      // Connexion automatique immédiate
      final auth = Provider.of<AuthProvider>(context, listen: false);
      final loggedIn = await auth.loginDoctor(
        identifier: fullPhone,
        password: _passCtrl.text.trim(),
      );

      if (!mounted) return;

      if (loggedIn) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          '/doctor/home',
          (route) => false,
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Row(
              children: [
                const Icon(LucideIcons.circle_check, color: Colors.white, size: 20),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Bienvenue Dr. ${_lastNameCtrl.text.trim()} ! Votre profil est complet.',
                    style: const TextStyle(fontFamily: 'Poppins'),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            backgroundColor: const Color(0xFF0D9488),
            duration: const Duration(seconds: 5),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      } else {
        Navigator.pushReplacementNamed(context, '/auth/welcome');
      }
    } catch (e) {
      if (!mounted) return;
      _showError('Erreur lors de l\'inscription : $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            // ── Header avec gradient et logo ──────────────────────────
            _buildHeader(),

            // ── Indicateur de progression (3 étapes) ─────────────────
            _buildProgressIndicator(),

            // ── Formulaire à 3 pages ─────────────────────────────────
            Expanded(
              child: PageView(
                controller: _pageController,
                physics: const NeverScrollableScrollPhysics(),
                onPageChanged: (index) => setState(() => _currentPage = index),
                children: [
                  _buildPage1Identity(),
                  _buildPage2Professional(),
                  _buildPage3Security(),
                ],
              ),
            ),

            // ── Boutons de navigation ────────────────────────────────
            _buildNavigationButtons(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: const BoxDecoration(
        gradient: AppColors.primaryGradient,
      ),
      child: Row(
        children: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(8),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                LucideIcons.arrow_left,
                color: AppColors.primary,
                size: 18,
              ),
            ),
            onPressed: _previousPage,
          ),
          const Spacer(),
          const AppLogo(
            height: 46,
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 6),
          ),
          const Spacer(),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildProgressIndicator() {
    final titles = ['Identité & Contact', 'Pratique & Spécialité', 'Sécurité & Accès'];
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Étape ${_currentPage + 1} sur 3',
                style: const TextStyle(
                  fontFamily: 'Poppins',
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primary,
                ),
              ),
              Expanded(
                child: Text(
                  titles[_currentPage],
                  textAlign: TextAlign.right,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Row(
            children: List.generate(3, (index) {
              final isActive = index <= _currentPage;
              return Expanded(
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  height: 5,
                  margin: EdgeInsets.only(right: index < 2 ? 8 : 0),
                  decoration: BoxDecoration(
                    color: isActive ? AppColors.primary : Colors.grey.shade200,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 1 : IDENTITÉ & COORDONNÉES
  // ══════════════════════════════════════════════════════════
  Widget _buildPage1Identity() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey1,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Identité & Coordonnées',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Renseignez vos coordonnées de base pour créer votre compte praticien certifié.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Nom de famille
            _buildInputField(
              controller: _lastNameCtrl,
              label: 'Nom de famille *',
              hint: 'Ex: KOUASSI',
              icon: LucideIcons.user,
              capitalization: TextCapitalization.characters,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez entrer votre nom' : null,
            ),
            const SizedBox(height: 16),

            // Prénom(s)
            _buildInputField(
              controller: _firstNameCtrl,
              label: 'Prénom(s) *',
              hint: 'Ex: Jean-Marc',
              icon: LucideIcons.user_check,
              capitalization: TextCapitalization.words,
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez entrer votre prénom' : null,
            ),
            const SizedBox(height: 16),

            // Numéro de téléphone (+225)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Numéro de téléphone *',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                TextFormField(
                  controller: _phoneCtrl,
                  keyboardType: TextInputType.phone,
                  inputFormatters: [
                    FilteringTextInputFormatter.digitsOnly,
                    LengthLimitingTextInputFormatter(10),
                  ],
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.textPrimary, letterSpacing: 1.1),
                  decoration: InputDecoration(
                    prefixIconConstraints: const BoxConstraints(minWidth: 70, minHeight: 0),
                    prefixIcon: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      alignment: Alignment.centerLeft,
                      width: 70,
                      child: const Text('+225', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
                    ),
                    hintText: '07 00 00 00 00',
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Veuillez saisir votre numéro';
                    if (v.trim().length != 10) return 'Le numéro doit comporter 10 chiffres';
                    return null;
                  },
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Email professionnel
            _buildInputField(
              controller: _emailCtrl,
              label: 'Email professionnel',
              hint: 'docteur@exemple.ci',
              icon: LucideIcons.mail,
              keyboardType: TextInputType.emailAddress,
              validator: (v) {
                if (v != null && v.trim().isNotEmpty) {
                  if (!v.contains('@') || !v.contains('.')) return 'Adresse email invalide';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Ville d'exercice (Liste déroulante)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Ville *',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: IvoryCoastLocations.cities.contains(_selectedCity) ? _selectedCity : IvoryCoastLocations.cities.first,
                  isExpanded: true,
                  icon: const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.primary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.map_pin, color: AppColors.primary, size: 20),
                    hintText: 'Sélectionnez votre ville',
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: IvoryCoastLocations.cities.map((city) {
                    return DropdownMenuItem<String>(
                      value: city,
                      child: Text(
                        city,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _onCityChanged,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Commune / Quartier (Liste déroulante)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Commune *',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                ),
                const SizedBox(height: 6),
                DropdownButtonFormField<String>(
                  value: IvoryCoastLocations.getCommunes(_selectedCity).contains(_selectedCommune)
                      ? _selectedCommune
                      : IvoryCoastLocations.getCommunes(_selectedCity).first,
                  isExpanded: true,
                  icon: const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.primary),
                  decoration: InputDecoration(
                    prefixIcon: const Icon(LucideIcons.navigation, color: AppColors.primary, size: 20),
                    hintText: 'Sélectionnez votre commune',
                    filled: true,
                    fillColor: AppColors.backgroundGrey,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                  ),
                  items: IvoryCoastLocations.getCommunes(_selectedCity).map((commune) {
                    return DropdownMenuItem<String>(
                      value: commune,
                      child: Text(
                        commune,
                        style: const TextStyle(fontFamily: 'Poppins', fontSize: 14, color: AppColors.textPrimary),
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: _onCommuneChanged,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'Requis' : null,
                ),
              ],
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 2 : PRATIQUE & SPÉCIALITÉ MÉDICALE
  // ══════════════════════════════════════════════════════════
  Widget _buildPage2Professional() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey2,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Profil Professionnel',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Ces informations permettent aux patients de vous trouver selon leur besoin.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Sélecteur de spécialité médicale
            const Text(
              'Spécialité médicale *',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            GestureDetector(
              onTap: _selectSpecialtyModal,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.backgroundGrey,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(LucideIcons.stethoscope, size: 18, color: AppColors.primary),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        _selectedSpecialty ?? 'Sélectionner une spécialité',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 14,
                          fontWeight: _selectedSpecialty != null ? FontWeight.w600 : FontWeight.normal,
                          color: _selectedSpecialty != null ? AppColors.textPrimary : AppColors.textLight,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.textLight),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),

            // Numéro d'Ordre des Médecins
            _buildInputField(
              controller: _orderNumberCtrl,
              label: 'Numéro d\'Ordre des Médecins (5 chiffres)',
              hint: 'Ex: 12345',
              icon: LucideIcons.badge_check,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(5),
              ],
            ),
            const SizedBox(height: 16),

            // Expérience & Tarif
            Row(
              children: [
                Expanded(
                  child: _buildInputField(
                    controller: _experienceCtrl,
                    label: 'Années d\'expérience',
                    hint: 'Ex: 5',
                    icon: LucideIcons.award,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildInputField(
                    controller: _priceCtrl,
                    label: 'Tarif consultation (F CFA)',
                    hint: 'Ex: 15000',
                    icon: LucideIcons.banknote,
                    keyboardType: TextInputType.number,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Présentation / Bio
            const Text(
              'Présentation / Biographie',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _bioCtrl,
              maxLines: 3,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Décrivez brièvement votre expérience, hôpital de rattachement ou approche clinique...',
                hintStyle: TextStyle(color: AppColors.textLight.withValues(alpha: 0.6), fontSize: 12),
                filled: true,
                fillColor: AppColors.backgroundGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ══════════════════════════════════════════════════════════
  // PAGE 3 : SÉCURITÉ & ACCÈS
  // ══════════════════════════════════════════════════════════
  Widget _buildPage3Security() {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 24),
      child: Form(
        key: _formKey3,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sécurité & Mot de passe',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Définissez votre mot de passe pour accéder à votre espace praticien.',
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: 12,
                color: Colors.grey.shade600,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),

            // Récapitulatif Praticien
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: AppColors.primary.withValues(alpha: 0.05),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: AppColors.primary.withValues(alpha: 0.15)),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: const BoxDecoration(color: AppColors.primary, shape: BoxShape.circle),
                    child: const Icon(LucideIcons.stethoscope, color: Colors.white, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Dr. ${_lastNameCtrl.text.trim()} ${_firstNameCtrl.text.trim()}',
                          style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, fontSize: 14, color: AppColors.textPrimary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_selectedSpecialty ?? "Médecine"} • ${_communeCtrl.text.trim()}, ${_cityCtrl.text.trim()} • ${_priceCtrl.text.trim()} F CFA',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Mot de passe
            const Text(
              'Mot de passe *',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _passCtrl,
              obscureText: _obscurePass,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Mot de passe (min. 6 caractères)',
                filled: true,
                fillColor: AppColors.backgroundGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: const Icon(LucideIcons.lock, size: 18, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(_obscurePass ? LucideIcons.eye_off : LucideIcons.eye, color: AppColors.textLight, size: 18),
                  onPressed: () => setState(() => _obscurePass = !_obscurePass),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Veuillez saisir un mot de passe';
                if (v.trim().length < 6) return 'Le mot de passe doit comporter au moins 6 caractères';
                return null;
              },
            ),
            const SizedBox(height: 16),

            // Confirmation mot de passe
            const Text(
              'Confirmer le mot de passe *',
              style: TextStyle(fontFamily: 'Poppins', fontSize: 13, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
            ),
            const SizedBox(height: 6),
            TextFormField(
              controller: _confirmPassCtrl,
              obscureText: _obscureConfirm,
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
              decoration: InputDecoration(
                hintText: 'Répétez le mot de passe',
                filled: true,
                fillColor: AppColors.backgroundGrey,
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                prefixIcon: const Icon(LucideIcons.shield_check, size: 18, color: AppColors.textSecondary),
                suffixIcon: IconButton(
                  icon: Icon(_obscureConfirm ? LucideIcons.eye_off : LucideIcons.eye, color: AppColors.textLight, size: 18),
                  onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                ),
              ),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Veuillez confirmer votre mot de passe';
                if (v.trim() != _passCtrl.text.trim()) return 'Les mots de passe ne correspondent pas';
                return null;
              },
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ─── BOUTONS DE NAVIGATION ──────────────────────────────────────────
  Widget _buildNavigationButtons() {
    final isLastPage = _currentPage == 2;

    return Container(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 20),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: Row(
        children: [
          if (_currentPage > 0) ...[
            Expanded(
              child: SizedBox(
                height: 52,
                child: OutlinedButton(
                  onPressed: _previousPage,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.primary, width: 1.5),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                  child: const Text(
                    'Précédent',
                    style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.primary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
          ],
          Expanded(
            flex: _currentPage > 0 ? 1 : 2,
            child: SizedBox(
              height: 52,
              child: ElevatedButton(
                onPressed: _isLoading ? null : _nextPage,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  elevation: 0,
                ),
                child: _isLoading
                    ? const SizedBox(height: 22, width: 22, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Flexible(
                            child: Text(
                              isLastPage ? 'Créer mon compte' : 'Continuer',
                              style: const TextStyle(fontFamily: 'Poppins', fontSize: 15, fontWeight: FontWeight.w600, color: Colors.white),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Icon(isLastPage ? LucideIcons.circle_check : LucideIcons.arrow_right, color: Colors.white, size: 18),
                        ],
                      ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    TextCapitalization capitalization = TextCapitalization.none,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontFamily: 'Poppins',
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          textCapitalization: capitalization,
          inputFormatters: inputFormatters,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
              color: AppColors.textLight.withValues(alpha: 0.6),
              fontSize: 13,
            ),
            filled: true,
            fillColor: AppColors.backgroundGrey,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: BorderSide.none,
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
            prefixIcon: Icon(icon, size: 18, color: AppColors.textSecondary),
          ),
          validator: validator,
        ),
      ],
    );
  }
}
