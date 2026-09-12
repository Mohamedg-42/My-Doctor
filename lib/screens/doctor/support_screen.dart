import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class SupportScreen extends StatefulWidget {
  const SupportScreen({super.key});

  @override
  State<SupportScreen> createState() => _SupportScreenState();
}

class _SupportScreenState extends State<SupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _subjectCtrl = TextEditingController();
  final _messageCtrl = TextEditingController();

  bool _isLoading = false;
  String _selectedCategory = 'Technique';

  final List<String> _categories = [
    'Technique',
    'Compte',
    'Abonnement',
    'Paiement',
    'Autre',
  ];

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _subjectCtrl.dispose();
    _messageCtrl.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    // Simuler l'envoi du message
    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Message envoyé avec succès ! Nous vous répondrons sous 24h.'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 4),
        ),
      );

      // Nettoyer les champs
      _nameCtrl.clear();
      _emailCtrl.clear();
      _subjectCtrl.clear();
      _messageCtrl.clear();
      setState(() => _selectedCategory = 'Technique');
    }

    setState(() => _isLoading = false);
  }

  Future<void> _launchPhone() async {
    final uri = Uri.parse('tel:+2250708090807');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir l\'application téléphone')),
        );
      }
    }
  }

  Future<void> _launchEmail() async {
    final uri = Uri.parse('mailto:support@medilink.ci');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir l\'application email')),
        );
      }
    }
  }

  Future<void> _launchWhatsApp() async {
    final uri = Uri.parse('https://wa.me/2250708090807');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Impossible d\'ouvrir WhatsApp')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Support'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Section: Contacts rapides
            _buildSectionCard(
              title: 'Contacts rapides',
              icon: Icons.contact_support,
              children: [
                const SizedBox(height: 16),
                
                // Téléphone
                _buildContactTile(
                  icon: Icons.phone,
                  iconColor: Colors.green,
                  title: 'Téléphone',
                  subtitle: '+225 07 08 09 08 07',
                  onTap: _launchPhone,
                ),
                const SizedBox(height: 12),

                // Email
                _buildContactTile(
                  icon: Icons.email,
                  iconColor: Colors.blue,
                  title: 'Email',
                  subtitle: 'support@medilink.ci',
                  onTap: _launchEmail,
                ),
                const SizedBox(height: 12),

                // WhatsApp
                _buildContactTile(
                  icon: Icons.chat,
                  iconColor: Colors.teal,
                  title: 'WhatsApp',
                  subtitle: 'Chat en direct',
                  onTap: _launchWhatsApp,
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section: FAQ
            _buildSectionCard(
              title: 'Questions fréquentes (FAQ)',
              icon: Icons.help_outline,
              children: [
                const SizedBox(height: 16),
                
                _buildFAQItem(
                  question: 'Comment activer mon compte médecin ?',
                  answer: 'Après votre inscription, notre équipe vérifie vos documents dans un délai de 24-48h. Vous recevrez un email de confirmation une fois votre compte activé.',
                ),
                
                _buildFAQItem(
                  question: 'Comment gérer mes créneaux de disponibilité ?',
                  answer: 'Allez dans Profil > Gérer les créneaux. Vous pouvez définir vos horaires pour chaque jour de la semaine et bloquer des créneaux spécifiques.',
                ),
                
                _buildFAQItem(
                  question: 'Comment fonctionne l\'abonnement ?',
                  answer: 'L\'abonnement vous permet d\'accepter des demandes de médecin traitant. Formule mensuelle : 10 000 F/mois, Formule annuelle : 100 000 F/an (-17%).',
                ),
                
                _buildFAQItem(
                  question: 'Que faire si je ne reçois pas les notifications ?',
                  answer: 'Vérifiez que les notifications sont activées dans les paramètres de votre téléphone. Allez dans Paramètres > Applications > MédiLink > Notifications.',
                ),
                
                _buildFAQItem(
                  question: 'Comment modifier mes informations personnelles ?',
                  answer: 'Allez dans Profil > Modifier le profil. Vous pouvez modifier votre bio, tarifs, coordonnées et photo de profil.',
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section: Formulaire de contact
            _buildSectionCard(
              title: 'Envoyer un message',
              icon: Icons.message,
              children: [
                const SizedBox(height: 16),
                
                Form(
                  key: _formKey,
                  child: Column(
                    children: [
                      // Nom
                      TextFormField(
                        controller: _nameCtrl,
                        decoration: InputDecoration(
                          labelText: 'Nom complet',
                          hintText: 'Dr. Jean Dupont',
                          prefixIcon: const Icon(Icons.person_outline),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre nom';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Email
                      TextFormField(
                        controller: _emailCtrl,
                        keyboardType: TextInputType.emailAddress,
                        decoration: InputDecoration(
                          labelText: 'Email',
                          hintText: 'exemple@email.com',
                          prefixIcon: const Icon(Icons.email_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre email';
                          }
                          if (!value.contains('@')) {
                            return 'Email invalide';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Catégorie
                      DropdownButtonFormField<String>(
                        initialValue: _selectedCategory,
                        decoration: InputDecoration(
                          labelText: 'Catégorie',
                          prefixIcon: const Icon(Icons.category_outlined),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: _categories.map((category) {
                          return DropdownMenuItem(
                            value: category,
                            child: Text(category),
                          );
                        }).toList(),
                        onChanged: (value) {
                          if (value != null) {
                            setState(() => _selectedCategory = value);
                          }
                        },
                      ),
                      const SizedBox(height: 16),

                      // Sujet
                      TextFormField(
                        controller: _subjectCtrl,
                        decoration: InputDecoration(
                          labelText: 'Sujet',
                          hintText: 'Résumez votre demande',
                          prefixIcon: const Icon(Icons.subject),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer le sujet';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Message
                      TextFormField(
                        controller: _messageCtrl,
                        maxLines: 5,
                        maxLength: 500,
                        decoration: InputDecoration(
                          labelText: 'Message',
                          hintText: 'Décrivez votre problème ou question en détail...',
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 80),
                            child: Icon(Icons.message_outlined),
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          alignLabelWithHint: true,
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Veuillez entrer votre message';
                          }
                          if (value.length < 10) {
                            return 'Le message doit contenir au moins 10 caractères';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 20),

                      // Bouton Envoyer
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleSubmit,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFF4DD0E1),
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                                  ),
                                )
                              : const Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(Icons.send, size: 20),
                                    SizedBox(width: 8),
                                    Text(
                                      'Envoyer le message',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 20),

            // Section: Horaires d'assistance
            _buildSectionCard(
              title: 'Horaires d\'assistance',
              icon: Icons.schedule,
              children: [
                const SizedBox(height: 16),
                
                _buildScheduleTile(
                  day: 'Lundi - Vendredi',
                  hours: '8h00 - 18h00',
                  icon: Icons.work_outline,
                ),
                const SizedBox(height: 12),
                
                _buildScheduleTile(
                  day: 'Samedi',
                  hours: '9h00 - 14h00',
                  icon: Icons.weekend,
                ),
                const SizedBox(height: 12),
                
                _buildScheduleTile(
                  day: 'Dimanche',
                  hours: 'Fermé',
                  icon: Icons.close,
                  isOff: true,
                ),
                
                const SizedBox(height: 16),
                
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber[50],
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.amber[200]!),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.info_outline, color: Colors.amber[800], size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'En dehors de ces horaires, vous pouvez nous envoyer un message et nous vous répondrons dès que possible.',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.amber[900],
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 30),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    required IconData icon,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: const Color(0xFF4DD0E1), size: 24),
              const SizedBox(width: 12),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          ...children,
        ],
      ),
    );
  }

  Widget _buildContactTile({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(icon, color: iconColor, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 14,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: Colors.grey[400]),
          ],
        ),
      ),
    );
  }

  Widget _buildFAQItem({
    required String question,
    required String answer,
  }) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 0, vertical: 4),
        childrenPadding: const EdgeInsets.only(bottom: 12),
        title: Text(
          question,
          style: const TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              answer,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[700],
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScheduleTile({
    required String day,
    required String hours,
    required IconData icon,
    bool isOff = false,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isOff ? Colors.grey[50] : Colors.green[50],
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: isOff ? Colors.grey[300]! : Colors.green[200]!,
        ),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: isOff ? Colors.grey[600] : Colors.green[700],
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              day,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: isOff ? Colors.grey[700] : Colors.black87,
              ),
            ),
          ),
          Text(
            hours,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: isOff ? Colors.grey[600] : Colors.green[800],
            ),
          ),
        ],
      ),
    );
  }
}
