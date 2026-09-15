// ════════════════════════════════════════════════════════════
//  edit_profile_screen.dart (Doctor)
//  HELLO DOC - Compléter & Modifier mon profil praticien
//  Design moderne et professionnel avec Lucide Icons
// ════════════════════════════════════════════════════════════

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/app_theme.dart';
import '../../core/constants/ivory_coast_locations.dart';
import '../../providers/auth_provider.dart';
import '../../services/database_service.dart';
import '../../constants/medical_specialties.dart';

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
  late TextEditingController _emailCtrl;
  late TextEditingController _orderNumberCtrl;
  late TextEditingController _cityCtrl;
  late TextEditingController _communeCtrl;
  String _selectedCity = 'Abidjan';
  String _selectedCommune = 'Cocody';
  late TextEditingController _experienceCtrl;
  late TextEditingController _priceCtrl;
  late TextEditingController _bioCtrl;

  String? _selectedSpecialty;
  String? _profilePhotoBase64;
  bool _isAvailable = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    final auth = context.read<AuthProvider>();
    final doctor = auth.doctorProfile;
    final user = auth.currentUser;

    _lastNameCtrl = TextEditingController(text: doctor?.lastName ?? user?.lastName ?? '');
    _firstNameCtrl = TextEditingController(text: doctor?.firstName ?? user?.firstName ?? '');
    _phoneCtrl = TextEditingController(text: doctor?.phone ?? user?.phone ?? '');
    _emailCtrl = TextEditingController(text: doctor?.email ?? user?.email ?? '');
    _orderNumberCtrl = TextEditingController(text: doctor?.orderNumber ?? '');
    
    final initialCity = doctor?.city ?? user?.city ?? 'Abidjan';
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

    _experienceCtrl = TextEditingController(text: (doctor?.experienceYears != null && doctor!.experienceYears > 0) ? doctor.experienceYears.toString() : '');
    _priceCtrl = TextEditingController(text: doctor != null ? doctor.consultationPrice.toStringAsFixed(0) : '15000');
    _bioCtrl = TextEditingController(text: doctor?.bio ?? '');

    _selectedSpecialty = doctor?.specialty;
    _profilePhotoBase64 = doctor?.avatarBase64 ?? user?.avatarBase64;
    _isAvailable = doctor?.isAvailable ?? true;
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

  @override
  void dispose() {
    _lastNameCtrl.dispose();
    _firstNameCtrl.dispose();
    _phoneCtrl.dispose();
    _emailCtrl.dispose();
    _orderNumberCtrl.dispose();
    _cityCtrl.dispose();
    _communeCtrl.dispose();
    _experienceCtrl.dispose();
    _priceCtrl.dispose();
    _bioCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickProfilePhoto() async {
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
          _profilePhotoBase64 = base64Encode(bytes);
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
                      const Text(
                        'Sélectionner une spécialité',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
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
      setState(() {
        _selectedSpecialty = selected;
      });
    }
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedSpecialty == null || _selectedSpecialty!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Veuillez sélectionner une spécialité médicale'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isLoading = true);

    try {
      final auth = context.read<AuthProvider>();
      final userId = auth.currentUser?.id;

      if (userId == null) {
        throw Exception('Médecin non connecté');
      }

      final db = DatabaseService();

      // Sauvegarde des informations praticien
      await db.updateUserProfile(
        userId: userId,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        city: _cityCtrl.text.trim(),
        commune: _communeCtrl.text.trim(),
        specialty: _selectedSpecialty,
        orderNumber: _orderNumberCtrl.text.trim(),
        bio: _bioCtrl.text.trim(),
        experienceYears: int.tryParse(_experienceCtrl.text.trim()),
        consultationPrice: double.tryParse(_priceCtrl.text.trim()),
        avatarBase64: _profilePhotoBase64,
      );

      // Rafraîchir l'utilisateur et le profil médecin
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
                    'Profil praticien mis à jour avec succès !',
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
            content: Text('Erreur lors de l\'enregistrement: $e'),
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
          'Mon Profil Praticien',
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
              // ─── Photo Professionnelle ──────────────────────────────────
              Center(
                child: Column(
                  children: [
                    GestureDetector(
                      onTap: _pickProfilePhoto,
                      child: Stack(
                        children: [
                          Container(
                            width: 110,
                            height: 125,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(18),
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
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(15),
                              child: _profilePhotoBase64 != null
                                  ? Image.memory(
                                      base64Decode(_profilePhotoBase64!),
                                      fit: BoxFit.cover,
                                      width: 110,
                                      height: 125,
                                    )
                                  : Center(
                                      child: Text(
                                        _lastNameCtrl.text.isNotEmpty
                                            ? _lastNameCtrl.text[0].toUpperCase()
                                            : 'D',
                                        style: const TextStyle(
                                          fontFamily: 'Poppins',
                                          fontSize: 38,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                        ),
                                      ),
                                    ),
                            ),
                          ),
                          Positioned(
                            bottom: -2,
                            right: -2,
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
                      'Photo professionnelle de profil',
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

              // ─── Identité Médicale ────────────────────────────────────────
              _buildSectionTitle('Identité & Spécialité Médicale'),
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
                    // Nom
                    TextFormField(
                      controller: _lastNameCtrl,
                      textCapitalization: TextCapitalization.characters,
                      decoration: InputDecoration(
                        labelText: 'Nom de famille *',
                        hintText: 'Ex: KOFFI',
                        prefixIcon: const Icon(LucideIcons.user, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Nom requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Prénom
                    TextFormField(
                      controller: _firstNameCtrl,
                      textCapitalization: TextCapitalization.words,
                      decoration: InputDecoration(
                        labelText: 'Prénom(s) *',
                        hintText: 'Ex: Marc-Antoine',
                        prefixIcon: const Icon(LucideIcons.user_round, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Prénom requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Spécialité
                    InkWell(
                      onTap: _selectSpecialtyModal,
                      borderRadius: BorderRadius.circular(12),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                        decoration: BoxDecoration(
                          border: Border.all(color: Colors.grey.shade400),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            const Icon(LucideIcons.stethoscope, size: 20, color: AppColors.primary),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                _selectedSpecialty != null && _selectedSpecialty!.isNotEmpty
                                    ? _selectedSpecialty!
                                    : 'Sélectionner votre spécialité *',
                                style: TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 15,
                                  color: _selectedSpecialty != null ? AppColors.textPrimary : AppColors.textMuted,
                                ),
                              ),
                            ),
                            const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.textSecondary),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Numéro d'ordre
                    TextFormField(
                      controller: _orderNumberCtrl,
                      keyboardType: TextInputType.number,
                      inputFormatters: [
                        FilteringTextInputFormatter.digitsOnly,
                        LengthLimitingTextInputFormatter(5),
                      ],
                      decoration: InputDecoration(
                        labelText: 'N° d\'Ordre National des Médecins *',
                        hintText: 'Ex: 12345 (5 chiffres)',
                        prefixIcon: const Icon(LucideIcons.id_card, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().length != 5)
                          ? 'Le numéro d\'ordre doit comporter 5 chiffres'
                          : null,
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Coordonnées d'Exercice ───────────────────────────────────
              _buildSectionTitle('Coordonnées Professionnelles & Cabinet'),
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
                        labelText: 'Téléphone professionnel *',
                        prefixIcon: const Icon(LucideIcons.phone, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                      validator: (v) => (v == null || v.trim().isEmpty) ? 'Téléphone requis' : null,
                    ),
                    const SizedBox(height: 16),

                    // Email
                    TextFormField(
                      controller: _emailCtrl,
                      keyboardType: TextInputType.emailAddress,
                      decoration: InputDecoration(
                        labelText: 'Email professionnel',
                        prefixIcon: const Icon(LucideIcons.mail, size: 20, color: AppColors.primary),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Ville
                    DropdownButtonFormField<String>(
                      value: IvoryCoastLocations.cities.contains(_selectedCity) ? _selectedCity : IvoryCoastLocations.cities.first,
                      isExpanded: true,
                      icon: const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.primary),
                      decoration: InputDecoration(
                        labelText: 'Ville d\'exercice',
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

                    // Commune
                    DropdownButtonFormField<String>(
                      value: IvoryCoastLocations.getCommunes(_selectedCity).contains(_selectedCommune)
                          ? _selectedCommune
                          : IvoryCoastLocations.getCommunes(_selectedCity).first,
                      isExpanded: true,
                      icon: const Icon(LucideIcons.chevron_down, size: 18, color: AppColors.primary),
                      decoration: InputDecoration(
                        labelText: 'Commune / Quartier du cabinet',
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

              // ─── Tarifs & Pratique ────────────────────────────────────────
              _buildSectionTitle('Tarifs & Expérience'),
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
                    Row(
                      children: [
                        // Années d'expérience
                        Expanded(
                          child: TextFormField(
                            controller: _experienceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [
                              FilteringTextInputFormatter.digitsOnly,
                              LengthLimitingTextInputFormatter(2),
                            ],
                            decoration: InputDecoration(
                              labelText: 'Expérience (ans)',
                              hintText: 'Ex: 8',
                              prefixIcon: const Icon(LucideIcons.briefcase, size: 18, color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 14),

                        // Prix consultation
                        Expanded(
                          child: TextFormField(
                            controller: _priceCtrl,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            decoration: InputDecoration(
                              labelText: 'Tarif (F CFA)',
                              hintText: '15000',
                              prefixIcon: const Icon(LucideIcons.coins, size: 18, color: AppColors.primary),
                              border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                              contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Bio
                    TextFormField(
                      controller: _bioCtrl,
                      maxLines: 4,
                      maxLength: 400,
                      decoration: InputDecoration(
                        labelText: 'Biographie & Expertise médicale',
                        hintText: 'Présentez vos diplômes, votre approche et vos domaines d\'expertise...',
                        alignLabelWithHint: true,
                        prefixIcon: const Padding(
                          padding: EdgeInsets.only(bottom: 50),
                          child: Icon(LucideIcons.file_text, size: 20, color: AppColors.primary),
                        ),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ─── Disponibilité ────────────────────────────────────────────
              _buildSectionTitle('Disponibilité pour les consultations'),
              const SizedBox(height: 12),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
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
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: _isAvailable ? AppColors.successBg : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        _isAvailable ? LucideIcons.circle_check : LucideIcons.circle_slash,
                        color: _isAvailable ? AppColors.success : Colors.grey,
                        size: 22,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _isAvailable ? 'Disponible pour RDV' : 'Indisponible',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          Text(
                            _isAvailable
                                ? 'Les patients peuvent solliciter des consultations'
                                : 'Agenda temporairement fermé aux nouveaux RDV',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 11,
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Switch(
                      value: _isAvailable,
                      activeThumbColor: AppColors.primary,
                      onChanged: (val) => setState(() => _isAvailable = val),
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
                  onPressed: _isLoading ? null : _saveProfile,
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
                              'Enregistrer mon profil praticien',
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
