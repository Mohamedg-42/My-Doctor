// ════════════════════════════════════════════════════════════
//  help_faq_screen.dart
//  HELLO DOC - Aide & Questions fréquentes
// ════════════════════════════════════════════════════════════

import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class HelpFaqScreen extends StatefulWidget {
  const HelpFaqScreen({super.key});

  @override
  State<HelpFaqScreen> createState() => _HelpFaqScreenState();
}

class _HelpFaqScreenState extends State<HelpFaqScreen> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _selectedCategory = 'Toutes';

  final List<String> _categories = [
    'Toutes',
    'Compte',
    'Rendez-vous',
    'Paiement',
    'Téléconsultation',
    'Dossier médical',
  ];

  final List<Map<String, dynamic>> _faqs = [
    {
      'category': 'Compte',
      'question': 'Comment créer un compte ?',
      'answer':
          'Pour créer un compte, cliquez sur "S\'inscrire" sur l\'écran d\'accueil. Remplissez vos informations personnelles (nom, prénom, téléphone, email) et choisissez un mot de passe sécurisé. Vous recevrez un code de vérification par SMS.',
    },
    {
      'category': 'Compte',
      'question': 'J\'ai oublié mon mot de passe',
      'answer':
          'Cliquez sur "Mot de passe oublié" sur l\'écran de connexion. Entrez votre numéro de téléphone ou email. Vous recevrez un code de réinitialisation pour créer un nouveau mot de passe.',
    },
    {
      'category': 'Rendez-vous',
      'question': 'Comment prendre un rendez-vous ?',
      'answer':
          'Recherchez un médecin dans l\'onglet "Médecins", consultez son profil et ses disponibilités, puis sélectionnez un créneau horaire qui vous convient. Confirmez votre rendez-vous et vous recevrez une notification de confirmation.',
    },
    {
      'category': 'Rendez-vous',
      'question': 'Puis-je annuler ou reporter un rendez-vous ?',
      'answer':
          'Oui, vous pouvez annuler ou reporter un rendez-vous jusqu\'à 2 heures avant l\'heure prévue. Accédez à "Mes rendez-vous", sélectionnez le rendez-vous et choisissez "Annuler" ou "Reporter".',
    },
    {
      'category': 'Paiement',
      'question': 'Quels moyens de paiement sont acceptés ?',
      'answer':
          'Nous acceptons les paiements par Mobile Money (Orange Money, MTN Money, Moov Money), carte bancaire (Visa, Mastercard) et paiement en espèces au cabinet du médecin.',
    },
    {
      'category': 'Paiement',
      'question': 'Puis-je obtenir un remboursement ?',
      'answer':
          'Les remboursements sont possibles en cas d\'annulation par le médecin ou d\'impossibilité technique. Pour toute demande de remboursement, contactez notre service client avec votre numéro de rendez-vous.',
    },
    {
      'category': 'Téléconsultation',
      'question': 'Comment fonctionne la téléconsultation ?',
      'answer':
          'Réservez une consultation en ligne, payez en ligne, et à l\'heure du rendez-vous, cliquez sur "Rejoindre la consultation" dans l\'application. Assurez-vous d\'avoir une bonne connexion Internet et activez votre caméra et microphone.',
    },
    {
      'category': 'Téléconsultation',
      'question': 'Problèmes techniques pendant la consultation',
      'answer':
          'Vérifiez votre connexion Internet, redémarrez l\'application, ou contactez le support technique. Si le problème persiste, le rendez-vous sera reporté sans frais supplémentaires.',
    },
    {
      'category': 'Dossier médical',
      'question': 'Comment ajouter mes antécédents médicaux ?',
      'answer':
          'Accédez à "Profil" > "Dossier médical" > "Antécédents". Cliquez sur "+" pour ajouter vos antécédents, allergies, vaccinations et traitements en cours. Ces informations seront visibles par vos médecins.',
    },
    {
      'category': 'Dossier médical',
      'question': 'Mes données médicales sont-elles sécurisées ?',
      'answer':
          'Oui, toutes vos données sont cryptées et stockées de manière sécurisée. Seuls vous et les médecins que vous consultez peuvent y accéder. Nous respectons les normes RGPD et HIPAA pour la protection des données de santé.',
    },
  ];

  List<Map<String, dynamic>> get _filteredFaqs {
    return _faqs.where((faq) {
      bool categoryMatch = _selectedCategory == 'Toutes' || faq['category'] == _selectedCategory;
      bool searchMatch = _searchCtrl.text.isEmpty ||
          faq['question'].toString().toLowerCase().contains(_searchCtrl.text.toLowerCase()) ||
          faq['answer'].toString().toLowerCase().contains(_searchCtrl.text.toLowerCase());
      return categoryMatch && searchMatch;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        title: const Text(
          'Aide & FAQ',
          style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0xFF185FA5),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          // Barre de recherche
          Container(
            padding: const EdgeInsets.all(16),
            color: Colors.white,
            child: TextField(
              controller: _searchCtrl,
              onChanged: (_) => setState(() {}),
              decoration: InputDecoration(
                hintText: 'Rechercher une question...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() {});
                        },
                      )
                    : null,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: AppColors.backgroundLight,
              ),
            ),
          ),

          // Filtres par catégorie
          Container(
            height: 50,
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              itemCount: _categories.length,
              itemBuilder: (context, index) {
                final category = _categories[index];
                final isSelected = category == _selectedCategory;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: FilterChip(
                    label: Text(category),
                    selected: isSelected,
                    onSelected: (_) {
                      setState(() => _selectedCategory = category);
                    },
                    backgroundColor: Colors.white,
                    selectedColor: AppColors.primary.withValues(alpha: 0.2),
                    checkmarkColor: AppColors.primary,
                    labelStyle: TextStyle(
                      color: isSelected ? AppColors.primary : AppColors.textSecondary,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: isSelected ? AppColors.primary : Colors.grey[300]!,
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          const SizedBox(height: 8),

          // Liste des questions
          Expanded(
            child: _filteredFaqs.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.search_off, size: 64, color: Colors.grey[400]),
                        const SizedBox(height: 16),
                        Text(
                          'Aucune question trouvée',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _filteredFaqs.length,
                    itemBuilder: (context, index) {
                      final faq = _filteredFaqs[index];
                      return _FaqItem(
                        category: faq['category'],
                        question: faq['question'],
                        answer: faq['answer'],
                      );
                    },
                  ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.pushNamed(context, '/patient/contact-support');
        },
        backgroundColor: AppColors.primary,
        icon: const Icon(Icons.chat),
        label: const Text('Contacter le support'),
      ),
    );
  }
}

class _FaqItem extends StatefulWidget {
  final String category;
  final String question;
  final String answer;

  const _FaqItem({
    required this.category,
    required this.question,
    required this.answer,
  });

  @override
  State<_FaqItem> createState() => _FaqItemState();
}

class _FaqItemState extends State<_FaqItem> {
  bool _isExpanded = false;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.help_outline, color: AppColors.primary, size: 20),
          ),
          title: Text(
            widget.question,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 4),
            child: Text(
              widget.category,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.primary.withValues(alpha: 0.7),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          trailing: Icon(
            _isExpanded ? Icons.expand_less : Icons.expand_more,
            color: AppColors.primary,
          ),
          onExpansionChanged: (expanded) {
            setState(() => _isExpanded = expanded);
          },
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Divider(),
                  const SizedBox(height: 8),
                  Text(
                    widget.answer,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: AppColors.textLight,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text(
                        'Cela vous a-t-il aidé ?',
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(width: 12),
                      IconButton(
                        icon: const Icon(Icons.thumb_up_outlined, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Merci pour votre retour !')),
                          );
                        },
                        color: AppColors.success,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        icon: const Icon(Icons.thumb_down_outlined, size: 18),
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Désolé, contactez le support pour plus d\'aide'),
                            ),
                          );
                        },
                        color: AppColors.error,
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
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
}
