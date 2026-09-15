// ════════════════════════════════════════════════════════════
//  edit_profile_screen.dart
//  HELLO DOC - Compléter & Modifier mon profil patient
//  Design moderne et épuré avec Lucide Icons
// ════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/ivory_coast_locations.dart';
import '../../models/user_model.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _lastNameCtrl;
  late TextEditingController _firstNameCtrl;
  late TextEditingController _phoneCtrl;
  late TextEditingController _birthDateCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _communeCtrl;
  late TextEditingController _professionCtrl;
  late TextEditingController _cmuCtrl;

  DateTime? _selectedBirthDate;
  String? _selectedGender;
  String _selectedCity = 'Abidjan';
  String _selectedCommune = 'Cocody';
  bool _isLoading = false;
  String? _profileImageBase64;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().currentUser;
    _lastNameCtrl = TextEditingController(text: user?.lastName ?? '');
    _firstNameCtrl = TextEditingController(
      text: (user?.firstName != null && user!.firstName != 'Patient') ? user.firstName : '',
    );
    _phoneCtrl = TextEditingController(text: user?.phone ?? '');
    final initialCity = user?.city ?? 'Abidjan';
    _selectedCity = IvoryCoastLocations.cities.contains(initialCity) ? initialCity : 'Abidjan';
    _cityCtrl = TextEditingController(text: _selectedCity);

    final availableCommunes = IvoryCoastLocations.getCommunes(_selectedCity);
    final initialCommune = user?.commune;
    if (initialCommune != null && availableCommunes.contains(initialCommune)) {
      _selectedCommune = initialCommune;
    } else {
      _selectedCommune = availableCommunes.first;
    }
    _communeCtrl = TextEditingController(text: _selectedCommune);

    _professionCtrl = TextEditingController(text: user?.profession ?? '');
    _cmuCtrl = TextEditingController(text: user?.cmuNumber ?? '');

    _selectedBirthDate = user?.birthDate;
    if (_selectedBirthDate == null && user?.id != null) {
      final dbUser = DatabaseService().getUserById(user!.id);
      if (dbUser?.birthDate != null) {
        _selectedBirthDate = UserModel.parseFlexibleDate(dbUser!.birthDate);
      }
    }
    String birthDateStr = '';
    if (_selectedBirthDate != null) {
      birthDateStr =
          '${_selectedBirthDate!.day.toString().padLeft(2, '0')}/${_selectedBirthDate!.month.toString().padLeft(2, '0')}/${_selectedBirthDate!.year}';
    }
    _birthDateCtrl = TextEditingController(text: birthDateStr);

    _selectedGender = user?.gender;
    _profileImageBase64 = user?.avatarBase64;
  }

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _phoneCtrl.dispose();
    _birthDateCtrl.dispose();
    _cityCtrl.dispose();
    _communeCtrl.dispose();
    _professionCtrl.dispose();
    _cmuCtrl.dispose();
    super.dispose();
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

  Future<void> _pickProfileImage() async {
    try {
      final ImagePicker picker = ImagePicker();
      final XFile? image = await picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );

      if (image != null) {
        final bytes = await image.readAsBytes();
        setState(() {
          _profileImageBase64 = base64Encode(bytes);
        });
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur lors de la sélection de l\'image: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    }
  }

  Future<void> _selectBirthDate() async {
    try {
      final now = DateTime.now();
      DateTime initial = _selectedBirthDate ?? DateTime(now.year - 25, 1, 1);
      final firstDate = DateTime(1900);
      final lastDate = now;

      if (initial.isBefore(firstDate)) initial = firstDate;
      if (initial.isAfter(lastDate)) initial = lastDate;

      final picked = await showDatePicker(
        context: context,
        initialDate: initial,
        firstDate: firstDate,
        lastDate: lastDate,
        helpText: 'SÉLECTIONNEZ VOTRE DATE DE NAISSANCE',
        cancelText: 'ANNULER',
        confirmText: 'VALIDER',
        builder: (context, child) {
          return Theme(
            data: Theme.of(context).copyWith(
              colorScheme: const ColorScheme.light(
                primary: AppColors.primary,
                onPrimary: Colors.white,
                onSurface: AppColors.textPrimary,
              ),
            ),
            child: child!,
          );
        },
      );

      if (picked != null && mounted) {
        setState(() {
          _selectedBirthDate = picked;
          _birthDateCtrl.text =
              '${picked!.day.toString().padLeft(2, '0')}/${picked!.month.toString().padLeft(2, '0')}/${picked!.year}';
        });
      }
    } catch (e) {
      debugPrint('Erreur sélection date de naissance: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Utilisateur non connecté');
      }

      final db = DatabaseService();

      final dateToSave =
          _selectedBirthDate ?? UserModel.parseFlexibleDate(_birthDateCtrl.text);
      final String? birthDateStr = dateToSave != null
          ? '${dateToSave.day.toString().padLeft(2, '0')}/${dateToSave.month.toString().padLeft(2, '0')}/${dateToSave.year}'
          : (_birthDateCtrl.text.trim().isNotEmpty ? _birthDateCtrl.text.trim() : null);

      // Mise à jour des informations patient
      await db.updateUserProfile(
        userId: userId,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        commune: _communeCtrl.text.trim(),
        profession: _professionCtrl.text.trim(),
        cmuNumber: _cmuCtrl.text.trim().isNotEmpty ? _cmuCtrl.text.trim() : null,
        birthDate: birthDateStr,
        gender: _selectedGender,
        avatarBase64: _profileImageBase64,
      );

      // Rafraîchir le profil dans AuthProvider
      await auth.refreshCurrentUser();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Row(
              children: [
                Icon(LucideIcons.circle_check, color: Colors.white, size: 20),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Profil enregistré avec succès !',
                    style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erreur: $e'),
            backgroundColor: AppColors.error,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Mon Profil Patient',
          style: TextStyle(
            fontFamily: 'Poppins',
            fontWeight: FontWeight.w600,
            fontSize: 18,
          ),
        ),
        leading: IconButton(
          icon: const Icon(LucideIcons.chevron_left),
          onPressed: () => Navigator.pop(context),
        ),
        backgroundColor: AppColors.primary,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ─── Photo de profil ─────────────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfileImage,
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 110,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.primaryGradient,
                              boxShadow: [
                                BoxShadow(
                                  color: AppColors.primary.withValues(alpha: 0.25),
                                  blurRadius: 16,
                                  offset: const Offset(0, 6),
                                ),
                              ],
                              border: Border.all(color: Colors.white, width: 3),
                            ),
                            child: ClipOval(
                              child: _profileImageBase64 != null
                                  ? Image.memory(
                                      base64Decode(_profileImageBase64!),
                                      fit: BoxFit.cover,
                                      width: 110,
                                      height: 110,
                                    )
                                  : Center(
                                      child: Text(
                                        _lastNameCtrl.text.isNotEmpty
                                            ? _lastNameCtrl.text[0].toUpperCase()
                                            : 'P',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 36,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: 2,
                            right: 2,
                            child: Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: AppColors.primary,
                                shape: BoxShape.circle,
                                border: Border.all(color: Colors.white, width: 2),
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.15),
                                    blurRadius: 6,
                                  ),
                                ],
                              ),
                              child: const Icon(LucideIcons.camera, size: 16, color: Colors.white),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      'Touchez pour ajouter ou modifier votre photo',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 28),

              // ─── Section Identité ─────────────────────────────────────────
              _buildSectionTitle('Identité & État Civil'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Nom
                    TextFormField(
                      controller: _lastNameCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Nom de famille *',
                        hintText: 'Ex: KOUASSI',
                        prefixIcon: const Icon(LucideIcons.user, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir votre nom' : null,
                    ),
                    const SizedBox(height: 16),

                    // Prénom
                    TextFormField(
                      controller: _firstNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Prénom(s) *',
                        hintText: 'Ex: Jean-Marc',
                        prefixIcon: const Icon(LucideIcons.user_round, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Veuillez saisir votre prénom' : null,
                    ),
                    const SizedBox(height: 16),

                    // Genre (Civilité)
                    const Text(
                      'Civilité / Genre *',
                      style: TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedGender = 'M'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedGender == 'M'
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.backgroundLight,
                                border: Border.all(
                                  color: _selectedGender == 'M' ? AppColors.primary : AppColors.borderSubtle,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.user,
                                    size: 18,
                                    color: _selectedGender == 'M' ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Homme (M)',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: _selectedGender == 'M' ? FontWeight.w600 : FontWeight.normal,
                                      color: _selectedGender == 'M' ? AppColors.primary : AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedGender = 'F'),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              decoration: BoxDecoration(
                                color: _selectedGender == 'F'
                                    ? AppColors.primary.withValues(alpha: 0.12)
                                    : AppColors.backgroundLight,
                                border: Border.all(
                                  color: _selectedGender == 'F' ? AppColors.primary : AppColors.borderSubtle,
                                  width: 1.5,
                                ),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(
                                    LucideIcons.user_round,
                                    size: 18,
                                    color: _selectedGender == 'F' ? AppColors.primary : AppColors.textSecondary,
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    'Femme (F)',
                                    style: TextStyle(
                                      fontFamily: 'Poppins',
                                      fontWeight: _selectedGender == 'F' ? FontWeight.w600 : FontWeight.normal,
                                      color: _selectedGender == 'F' ? AppColors.primary : AppColors.textPrimary,
                                      fontSize: 13,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Date de naissance
                    TextFormField(
                      controller: _birthDateCtrl,
                      readOnly: true,
                      onTap: _selectBirthDate,
                      decoration: InputDecoration(
                        labelText: 'Date de naissance',
                        hintText: 'JJ/MM/AAAA',
                        prefixIcon: const Icon(LucideIcons.calendar, size: 20, color: AppColors.primary),
                        suffixIcon: const Icon(LucideIcons.calendar_days, size: 18, color: AppColors.textSecondary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Section Coordonnées & Localisation ───────────────────────
              _buildSectionTitle('Coordonnées & Résidence'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Téléphone
                    TextFormField(
                      controller: _phoneCtrl,
                      keyboardType: TextInputType.phone,
                      decoration: InputDecoration(
                        labelText: 'Numéro de téléphone *',
                        prefixIcon: const Icon(LucideIcons.phone, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Numéro de téléphone requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Ville
                    DropdownButtonFormField<String>(
                      value: IvoryCoastLocations.cities.contains(_selectedCity) ? _selectedCity : IvoryCoastLocations.cities.first,
                      isExpanded: true,
                      icon: const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.primary),
                      decoration: InputDecoration(
                        labelText: 'Ville de résidence',
                        prefixIcon: const Icon(LucideIcons.map_pin, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: IvoryCoastLocations.cities.map((city) {
                        return DropdownMenuItem<String>(
                          value: city,
                          child: Text(
                            city,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onCityChanged,
                    ),
                    const SizedBox(height: 16),

                    // Commune / Quartier
                    DropdownButtonFormField<String>(
                      value: IvoryCoastLocations.getCommunes(_selectedCity).contains(_selectedCommune)
                          ? _selectedCommune
                          : IvoryCoastLocations.getCommunes(_selectedCity).first,
                      isExpanded: true,
                      icon: const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.primary),
                      decoration: InputDecoration(
                        labelText: 'Commune / Quartier',
                        prefixIcon: const Icon(LucideIcons.building, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      items: IvoryCoastLocations.getCommunes(_selectedCity).map((commune) {
                        return DropdownMenuItem<String>(
                          value: commune,
                          child: Text(
                            commune,
                            style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
                            overflow: TextOverflow.ellipsis,
                          ),
                        );
                      }).toList(),
                      onChanged: _onCommuneChanged,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Section Informations Médicales & CMU ─────────────────────
              _buildSectionTitle('Informations Complémentaires'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 3),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    // Profession
                    TextFormField(
                      controller: _professionCtrl,
                      decoration: InputDecoration(
                        labelText: 'Profession',
                        hintText: 'Ex: Enseignant, Cadre, Étudiant...',
                        prefixIcon: const Icon(LucideIcons.briefcase, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Numéro CMU
                    TextFormField(
                      controller: _cmuCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Numéro CMU (Couverture Maladie Universelle)',
                        hintText: 'Ex: CMU-CI12345678',
                        prefixIcon: const Icon(LucideIcons.id_card, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                        helperText: 'Facilite la prise en charge de vos consultations',
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 32),

              // ─── Bouton de sauvegarde ─────────────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 54,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _saveChanges,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    elevation: 3,
                    shadowColor: AppColors.primary.withValues(alpha: 0.35),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isLoading
                      ? const SizedBox(
                          height: 22,
                          width: 22,
                          child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(LucideIcons.check, size: 20, color: Colors.white),
                            SizedBox(width: 10),
                            Text(
                              'Enregistrer les informations',
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: const TextStyle(
        fontFamily: 'Poppins',
        fontSize: 15,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
    );
  }
}
