import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/pharmacie_provider.dart';
import '../../data/models/pharmacie_model.dart';

class InscriptionPharmacieScreen extends StatefulWidget {
  const InscriptionPharmacieScreen({super.key});
  @override
  State<InscriptionPharmacieScreen> createState() => _InscriptionPharmacieScreenState();
}

class _InscriptionPharmacieScreenState extends State<InscriptionPharmacieScreen> {
  final _pageCtrl = PageController();
  int _page = 0;

  // Étape 1 – Pharmacie
  final _nomPharmacieCtrl = TextEditingController();
  final _opciCtrl = TextEditingController();
  final _licenceCtrl = TextEditingController();
  final _adresseCtrl = TextEditingController();
  String _commune = 'Cocody';

  // Étape 2 – Titulaire
  final _nomCtrl = TextEditingController();
  final _prenomCtrl = TextEditingController();
  final _telCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  bool _estDeGarde = false;
  final Map<String, String> _horaires = {
    'Lundi': '08h00 - 20h00', 'Mardi': '08h00 - 20h00',
    'Mercredi': '08h00 - 20h00', 'Jeudi': '08h00 - 20h00',
    'Vendredi': '08h00 - 20h00', 'Samedi': '09h00 - 18h00',
    'Dimanche': 'Fermé',
  };

  // Étape 3 – Sécurité
  final _pwdCtrl = TextEditingController();
  final _confirmPwdCtrl = TextEditingController();
  bool _obscurePwd = true;
  bool _obscureConfirm = true;
  bool _accepteConditions = false;
  bool _photoUploaded = false;
  bool _docUploaded = false;

  static const List<String> _communes = [
    'Abobo','Adjamé','Attécoubé','Cocody','Koumassi','Marcory',
    'Plateau','Port-Bouët','Treichville','Yopougon','Songon',
    'Bingerville','Anyama','Bassam','Bouaké','San-Pédro','Daloa',
    'Korhogo','Man','Abengourou',
  ];

  @override
  void dispose() {
    _pageCtrl.dispose();
    _nomPharmacieCtrl.dispose(); _opciCtrl.dispose(); _licenceCtrl.dispose();
    _adresseCtrl.dispose(); _nomCtrl.dispose(); _prenomCtrl.dispose();
    _telCtrl.dispose(); _emailCtrl.dispose();
    _pwdCtrl.dispose(); _confirmPwdCtrl.dispose();
    super.dispose();
  }

  void _next() {
    if (_page < 2) {
      _pageCtrl.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _page++);
    } else {
      _inscrire();
    }
  }

  void _back() {
    if (_page > 0) {
      _pageCtrl.previousPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
      setState(() => _page--);
    } else {
      Navigator.pop(context);
    }
  }

  Future<void> _inscrire() async {
    if (!_accepteConditions) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Veuillez accepter les conditions d\'utilisation'),
        backgroundColor: Color(0xFFE74C3C),
      ));
      return;
    }
    if (_pwdCtrl.text != _confirmPwdCtrl.text) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Les mots de passe ne correspondent pas'),
        backgroundColor: Color(0xFFE74C3C),
      ));
      return;
    }

    final pharmacie = PharmacieModel(
      id: 'pharma_${DateTime.now().millisecondsSinceEpoch}',
      nomPharmacie: _nomPharmacieCtrl.text.trim(),
      nomTitulaire: _nomCtrl.text.trim().toUpperCase(),
      prenomTitulaire: _prenomCtrl.text.trim(),
      numeroOrdreOPCI: _opciCtrl.text.trim(),
      numeroLicenceExploitation: _licenceCtrl.text.trim(),
      commune: _commune,
      adresseComplete: _adresseCtrl.text.trim(),
      telephone: _telCtrl.text.trim(),
      email: _emailCtrl.text.trim(),
      motDePasse: _pwdCtrl.text,
      horaires: Map.from(_horaires),
      estDeGarde: _estDeGarde,
      createdAt: DateTime.now(),
    );

    final ok = await context.read<PharmacieProvider>().inscrire(pharmacie);
    if (ok && mounted) {
      _showSuccessDialog();
    }
  }

  void _showSuccessDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: const BoxDecoration(
                color: PharmacieColors.primaryUltraLight,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check_circle_rounded,
                  color: PharmacieColors.primary, size: 48),
            ),
            const SizedBox(height: 20),
            const Text('Inscription réussie !',
                style: TextStyle(fontFamily: 'Poppins', fontSize: 18,
                    fontWeight: FontWeight.bold, color: Color(0xFF1A2340))),
            const SizedBox(height: 10),
            const Text(
              'Votre compte pharmacie a été créé. Votre dossier est en cours de vérification par notre équipe.',
              textAlign: TextAlign.center,
              style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                  color: Color(0xFF7A8BA0), height: 1.5),
            ),
          ],
        ),
        actions: [
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                Navigator.pushReplacementNamed(context, '/pharmacie/dashboard');
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: PharmacieColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: const Text('Accéder au tableau de bord',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<PharmacieProvider>();
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8F1),
      body: SafeArea(
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
              decoration: const BoxDecoration(
                gradient: PharmacieColors.gradient,
                borderRadius: BorderRadius.vertical(bottom: Radius.circular(28)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      GestureDetector(
                        onTap: _back,
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
                      const SizedBox(width: 12),
                      const Text('Inscription Pharmacie',
                          style: TextStyle(fontFamily: 'Poppins', fontSize: 16,
                              fontWeight: FontWeight.w700, color: Colors.white)),
                    ],
                  ),
                  const SizedBox(height: 16),
                  // Stepper indicator
                  Row(
                    children: List.generate(3, (i) {
                      final done = i < _page;
                      final active = i == _page;
                      return Expanded(
                        child: Row(
                          children: [
                            Expanded(
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 300),
                                height: 4,
                                decoration: BoxDecoration(
                                  color: (done || active) ? Colors.white
                                      : Colors.white.withValues(alpha: 0.3),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            if (i < 2) const SizedBox(width: 6),
                          ],
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(_stepLabel(0), style: _stepStyle(0)),
                      Text(_stepLabel(1), style: _stepStyle(1)),
                      Text(_stepLabel(2), style: _stepStyle(2)),
                    ],
                  ),
                ],
              ),
            ),

            // Pages
            Expanded(
              child: PageView(
                controller: _pageCtrl,
                physics: const NeverScrollableScrollPhysics(),
                children: [
                  _PagePharmacie(
                    nomCtrl: _nomPharmacieCtrl, opciCtrl: _opciCtrl,
                    licenceCtrl: _licenceCtrl, adresseCtrl: _adresseCtrl,
                    commune: _commune,
                    onCommuneChanged: (v) => setState(() => _commune = v),
                    communes: _communes,
                  ),
                  _PageTitulaire(
                    nomCtrl: _nomCtrl, prenomCtrl: _prenomCtrl,
                    telCtrl: _telCtrl, emailCtrl: _emailCtrl,
                    estDeGarde: _estDeGarde,
                    onGardeChanged: (v) => setState(() => _estDeGarde = v),
                    horaires: _horaires,
                    onHoraireChanged: (jour, val) => setState(() => _horaires[jour] = val),
                  ),
                  _PageSecurite(
                    pwdCtrl: _pwdCtrl, confirmCtrl: _confirmPwdCtrl,
                    obscurePwd: _obscurePwd, obscureConfirm: _obscureConfirm,
                    onTogglePwd: () => setState(() => _obscurePwd = !_obscurePwd),
                    onToggleConfirm: () => setState(() => _obscureConfirm = !_obscureConfirm),
                    photoUploaded: _photoUploaded,
                    docUploaded: _docUploaded,
                    onUploadPhoto: () => setState(() => _photoUploaded = true),
                    onUploadDoc: () => setState(() => _docUploaded = true),
                    accepteConditions: _accepteConditions,
                    onConditionsChanged: (v) => setState(() => _accepteConditions = v),
                  ),
                ],
              ),
            ),

            // Bouton suivant
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: provider.isLoading ? null : _next,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: PharmacieColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    elevation: 0,
                  ),
                  child: provider.isLoading
                      ? const SizedBox(height: 20, width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white))
                      : Text(
                          _page < 2 ? 'Suivant →' : 'Créer mon compte',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 15,
                              fontWeight: FontWeight.w700),
                        ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _stepLabel(int i) {
    switch (i) {
      case 0: return 'Pharmacie';
      case 1: return 'Titulaire';
      default: return 'Sécurité';
    }
  }

  TextStyle _stepStyle(int i) {
    final active = i == _page;
    return TextStyle(
      fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.w600,
      color: active ? Colors.white : Colors.white.withValues(alpha: 0.5),
    );
  }
}

// ─── Page 1: Infos Pharmacie ──────────────────────────────────────────────────
class _PagePharmacie extends StatelessWidget {
  final TextEditingController nomCtrl, opciCtrl, licenceCtrl, adresseCtrl;
  final String commune;
  final ValueChanged<String> onCommuneChanged;
  final List<String> communes;

  const _PagePharmacie({
    required this.nomCtrl, required this.opciCtrl,
    required this.licenceCtrl, required this.adresseCtrl,
    required this.commune, required this.onCommuneChanged,
    required this.communes,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Informations de la pharmacie', Icons.store_rounded),
          const SizedBox(height: 16),
          _Field(label: 'Nom de la pharmacie', hint: 'Pharmacie Centrale de Cocody',
              controller: nomCtrl, icon: Icons.local_pharmacy_rounded),
          const SizedBox(height: 14),
          _Field(label: 'N° Ordre OPCI (5 chiffres)', hint: '12345',
              controller: opciCtrl, icon: Icons.badge_rounded,
              keyboardType: TextInputType.number, maxLength: 5),
          const SizedBox(height: 14),
          _Field(label: 'N° Licence d\'exploitation', hint: 'LIC-2024-XXXX',
              controller: licenceCtrl, icon: Icons.verified_rounded),
          const SizedBox(height: 14),
          _DropdownField(
            label: 'Commune', value: commune,
            items: communes, icon: Icons.location_on_rounded,
            onChanged: onCommuneChanged,
          ),
          const SizedBox(height: 14),
          _Field(label: 'Adresse complète', hint: 'Rue, quartier, repère...',
              controller: adresseCtrl, icon: Icons.place_rounded, maxLines: 2),
        ],
      ),
    );
  }
}

// ─── Page 2: Titulaire ────────────────────────────────────────────────────────
class _PageTitulaire extends StatelessWidget {
  final TextEditingController nomCtrl, prenomCtrl, telCtrl, emailCtrl;
  final bool estDeGarde;
  final ValueChanged<bool> onGardeChanged;
  final Map<String, String> horaires;
  final void Function(String, String) onHoraireChanged;

  const _PageTitulaire({
    required this.nomCtrl, required this.prenomCtrl,
    required this.telCtrl, required this.emailCtrl,
    required this.estDeGarde, required this.onGardeChanged,
    required this.horaires, required this.onHoraireChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Informations du titulaire', Icons.person_rounded),
          const SizedBox(height: 16),
          _Field(label: 'Nom', hint: 'KOUAMÉ', controller: nomCtrl,
              icon: Icons.person_outline_rounded),
          const SizedBox(height: 14),
          _Field(label: 'Prénom(s)', hint: 'Adjoua', controller: prenomCtrl,
              icon: Icons.person_2_outlined),
          const SizedBox(height: 14),
          _Field(label: 'Téléphone (+225)', hint: '+225 07 XX XX XX XX',
              controller: telCtrl, icon: Icons.phone_rounded,
              keyboardType: TextInputType.phone),
          const SizedBox(height: 14),
          _Field(label: 'Email professionnel', hint: 'pharmacie@example.com',
              controller: emailCtrl, icon: Icons.email_outlined,
              keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 20),

          // Pharmacie de garde
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: SwitchListTile(
              title: const Text('Pharmacie de garde',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 13,
                      fontWeight: FontWeight.w600, color: Color(0xFF1A2340))),
              subtitle: const Text('Disponible 24h/24',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 11,
                      color: Color(0xFF7A8BA0))),
              value: estDeGarde,
              onChanged: onGardeChanged,
              activeThumbColor: PharmacieColors.primary,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),

          const SizedBox(height: 20),
          const _SectionTitle('Horaires d\'ouverture', Icons.schedule_rounded),
          const SizedBox(height: 12),
          ...horaires.entries.map((e) => _HoraireRow(
            jour: e.key, horaire: e.value,
            onChanged: (v) => onHoraireChanged(e.key, v),
          )),
        ],
      ),
    );
  }
}

class _HoraireRow extends StatelessWidget {
  final String jour, horaire;
  final ValueChanged<String> onChanged;
  const _HoraireRow({required this.jour, required this.horaire, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    final options = ['Fermé','07h00 - 20h00','08h00 - 20h00',
        '08h00 - 21h00','07h30 - 22h00','09h00 - 18h00','24h/24'];
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          SizedBox(width: 80,
            child: Text(jour, style: const TextStyle(fontFamily: 'Poppins',
                fontSize: 12, fontWeight: FontWeight.w600, color: Color(0xFF1A2340)))),
          const SizedBox(width: 8),
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: DropdownButton<String>(
                value: options.contains(horaire) ? horaire : options[2],
                isExpanded: true, underline: const SizedBox(),
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
                    color: Color(0xFF1A2340)),
                items: options.map((o) => DropdownMenuItem(value: o,
                    child: Text(o))).toList(),
                onChanged: (v) => onChanged(v ?? horaire),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Page 3: Sécurité & Documents ────────────────────────────────────────────
class _PageSecurite extends StatelessWidget {
  final TextEditingController pwdCtrl, confirmCtrl;
  final bool obscurePwd, obscureConfirm, photoUploaded, docUploaded, accepteConditions;
  final VoidCallback onTogglePwd, onToggleConfirm, onUploadPhoto, onUploadDoc;
  final ValueChanged<bool> onConditionsChanged;

  const _PageSecurite({
    required this.pwdCtrl, required this.confirmCtrl,
    required this.obscurePwd, required this.obscureConfirm,
    required this.onTogglePwd, required this.onToggleConfirm,
    required this.photoUploaded, required this.docUploaded,
    required this.onUploadPhoto, required this.onUploadDoc,
    required this.accepteConditions, required this.onConditionsChanged,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _SectionTitle('Documents justificatifs', Icons.folder_open_rounded),
          const SizedBox(height: 12),
          _UploadTile(
            label: 'Photo façade de la pharmacie',
            icon: Icons.store_mall_directory_rounded,
            uploaded: photoUploaded, onTap: onUploadPhoto,
          ),
          const SizedBox(height: 10),
          _UploadTile(
            label: 'Document OPCI / Licence',
            icon: Icons.description_rounded,
            uploaded: docUploaded, onTap: onUploadDoc,
          ),
          const SizedBox(height: 24),

          const _SectionTitle('Sécurité du compte', Icons.lock_rounded),
          const SizedBox(height: 16),
          _PasswordField(label: 'Mot de passe', controller: pwdCtrl,
              obscure: obscurePwd, onToggle: onTogglePwd),
          const SizedBox(height: 14),
          _PasswordField(label: 'Confirmer le mot de passe', controller: confirmCtrl,
              obscure: obscureConfirm, onToggle: onToggleConfirm),
          const SizedBox(height: 20),

          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: CheckboxListTile(
              title: const Text('J\'accepte les conditions d\'utilisation et la politique de confidentialité',
                  style: TextStyle(fontFamily: 'Poppins', fontSize: 12,
                      color: Color(0xFF1A2340))),
              value: accepteConditions,
              onChanged: (v) => onConditionsChanged(v ?? false),
              activeColor: PharmacieColors.primary,
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
        ],
      ),
    );
  }
}

class _UploadTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool uploaded;
  final VoidCallback onTap;
  const _UploadTile({required this.label, required this.icon,
      required this.uploaded, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: uploaded ? PharmacieColors.primaryUltraLight : Colors.white,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: uploaded ? PharmacieColors.primary : Colors.grey.shade200,
            width: uploaded ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: uploaded
                    ? PharmacieColors.primary
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(uploaded ? Icons.check_rounded : icon,
                  color: uploaded ? Colors.white : Colors.grey.shade500, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(label,
                  style: TextStyle(
                    fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600,
                    color: uploaded ? PharmacieColors.primary : const Color(0xFF1A2340),
                  )),
            ),
            Icon(
              uploaded ? Icons.check_circle_rounded : Icons.upload_file_rounded,
              color: uploaded ? PharmacieColors.primary : Colors.grey.shade400,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _PasswordField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final bool obscure;
  final VoidCallback onToggle;
  const _PasswordField({required this.label, required this.controller,
      required this.obscure, required this.onToggle});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
            fontWeight: FontWeight.w600, color: Color(0xFF1A2340))),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller, obscureText: obscure,
          style: const TextStyle(fontFamily: 'Poppins', fontSize: 14),
          decoration: InputDecoration(
            hintText: '••••••••',
            hintStyle: const TextStyle(fontFamily: 'Poppins', color: Color(0xFFB0BEC5)),
            prefixIcon: const Icon(Icons.lock_outline_rounded,
                color: PharmacieColors.primary, size: 20),
            suffixIcon: IconButton(
              icon: Icon(obscure ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: Colors.grey.shade500, size: 20),
              onPressed: onToggle,
            ),
            filled: true, fillColor: Colors.white,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide(color: Colors.grey.shade200)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: PharmacieColors.primary, width: 1.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
        ),
      ],
    );
  }
}

// ─── Widgets partagés ─────────────────────────────────────────────────────────
class _SectionTitle extends StatelessWidget {
  final String title;
  final IconData icon;
  const _SectionTitle(this.title, this.icon);

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(
        padding: const EdgeInsets.all(7),
        decoration: BoxDecoration(
          color: PharmacieColors.primaryUltraLight,
          borderRadius: BorderRadius.circular(9),
        ),
        child: Icon(icon, color: PharmacieColors.primary, size: 16),
      ),
      const SizedBox(width: 10),
      Text(title, style: const TextStyle(fontFamily: 'Poppins', fontSize: 14,
          fontWeight: FontWeight.w700, color: Color(0xFF1A2340))),
    ]);
  }
}

class _Field extends StatelessWidget {
  final String label, hint;
  final TextEditingController controller;
  final IconData icon;
  final TextInputType? keyboardType;
  final int? maxLength, maxLines;
  const _Field({required this.label, required this.hint,
      required this.controller, required this.icon,
      this.keyboardType, this.maxLength, this.maxLines});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
          fontWeight: FontWeight.w600, color: Color(0xFF1A2340))),
      const SizedBox(height: 6),
      TextFormField(
        controller: controller, keyboardType: keyboardType,
        maxLength: maxLength, maxLines: maxLines ?? 1,
        style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
        decoration: InputDecoration(
          hintText: hint, counterText: '',
          hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
              color: Color(0xFFB0BEC5)),
          prefixIcon: Icon(icon, color: PharmacieColors.primary, size: 20),
          filled: true, fillColor: Colors.white,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.grey.shade200)),
          focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: PharmacieColors.primary, width: 1.5)),
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        ),
      ),
    ]);
  }
}

class _DropdownField extends StatelessWidget {
  final String label, value;
  final List<String> items;
  final IconData icon;
  final ValueChanged<String> onChanged;
  const _DropdownField({required this.label, required this.value,
      required this.items, required this.icon, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12,
          fontWeight: FontWeight.w600, color: Color(0xFF1A2340))),
      const SizedBox(height: 6),
      Container(
        padding: const EdgeInsets.symmetric(horizontal: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey.shade200),
        ),
        child: Row(children: [
          Icon(icon, color: PharmacieColors.primary, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: DropdownButton<String>(
              value: value, isExpanded: true, underline: const SizedBox(),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13,
                  color: Color(0xFF1A2340)),
              items: items.map((i) => DropdownMenuItem(value: i, child: Text(i))).toList(),
              onChanged: (v) => onChanged(v ?? value),
            ),
          ),
        ]),
      ),
    ]);
  }
}
