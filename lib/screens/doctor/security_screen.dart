import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/auth_provider.dart';

class SecurityScreen extends StatefulWidget {
  const SecurityScreen({super.key});

  @override
  State<SecurityScreen> createState() => _SecurityScreenState();
}

class _SecurityScreenState extends State<SecurityScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPasswordCtrl = TextEditingController();
  final _newPasswordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();

  bool _obscureCurrentPassword = true;
  bool _obscureNewPassword = true;
  bool _obscureConfirmPassword = true;
  bool _twoFactorEnabled = false;
  bool _isLoading = false;

  @override
  void dispose() {
    _currentPasswordCtrl.dispose();
    _newPasswordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  Future<void> _handlePasswordChange() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    final authProvider = context.read<AuthProvider>();
    final currentUser = authProvider.currentUser;

    if (currentUser == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Utilisateur non connecté'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // Simuler la vérification du mot de passe actuel
    // Dans une vraie app, on ferait un appel API pour vérifier le mot de passe
    // Pour cette démo, on simule une vérification
    await Future.delayed(const Duration(milliseconds: 500));
    
    // Vérification simulée : on accepte n'importe quel mot de passe non vide
    // Dans une vraie app, authProvider aurait une méthode verifyPassword() qui appelle l'API
    final isPasswordValid = _currentPasswordCtrl.text.isNotEmpty;
    
    if (!isPasswordValid) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('❌ Mot de passe actuel incorrect'),
            backgroundColor: Colors.red,
          ),
        );
      }
      setState(() => _isLoading = false);
      return;
    }

    // Simuler changement de mot de passe (dans une vraie app, on appellerait authProvider.changePassword())
    await Future.delayed(const Duration(milliseconds: 500));

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('✅ Mot de passe modifié avec succès !'),
          backgroundColor: Colors.green,
        ),
      );

      // Nettoyer les champs
      _currentPasswordCtrl.clear();
      _newPasswordCtrl.clear();
      _confirmPasswordCtrl.clear();
    }

    setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('Sécurité'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Section: Changer le mot de passe
              _buildSectionCard(
                title: 'Changer le mot de passe',
                icon: Icons.lock_outline,
                children: [
                  const SizedBox(height: 16),
                  
                  // Mot de passe actuel
                  TextFormField(
                    controller: _currentPasswordCtrl,
                    obscureText: _obscureCurrentPassword,
                    decoration: InputDecoration(
                      labelText: 'Mot de passe actuel',
                      hintText: 'Entrez votre mot de passe actuel',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureCurrentPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureCurrentPassword = !_obscureCurrentPassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer votre mot de passe actuel';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Nouveau mot de passe
                  TextFormField(
                    controller: _newPasswordCtrl,
                    obscureText: _obscureNewPassword,
                    decoration: InputDecoration(
                      labelText: 'Nouveau mot de passe',
                      hintText: 'Minimum 6 caractères',
                      prefixIcon: const Icon(Icons.lock),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureNewPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureNewPassword = !_obscureNewPassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez entrer un nouveau mot de passe';
                      }
                      if (value.length < 6) {
                        return 'Le mot de passe doit contenir au moins 6 caractères';
                      }
                      if (value == _currentPasswordCtrl.text) {
                        return 'Le nouveau mot de passe doit être différent';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Confirmer nouveau mot de passe
                  TextFormField(
                    controller: _confirmPasswordCtrl,
                    obscureText: _obscureConfirmPassword,
                    decoration: InputDecoration(
                      labelText: 'Confirmer le mot de passe',
                      hintText: 'Retapez le nouveau mot de passe',
                      prefixIcon: const Icon(Icons.lock_outline),
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
                        ),
                        onPressed: () {
                          setState(() => _obscureConfirmPassword = !_obscureConfirmPassword);
                        },
                      ),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Veuillez confirmer le mot de passe';
                      }
                      if (value != _newPasswordCtrl.text) {
                        return 'Les mots de passe ne correspondent pas';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 20),

                  // Bouton Enregistrer
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _isLoading ? null : _handlePasswordChange,
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
                          : const Text(
                              'Enregistrer le mot de passe',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 20),

              // Section: Authentification à deux facteurs (2FA)
              _buildSectionCard(
                title: 'Authentification à deux facteurs (2FA)',
                icon: Icons.security,
                children: [
                  const SizedBox(height: 12),
                  
                  // Info 2FA
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Ajoutez une couche de sécurité supplémentaire en activant la vérification en deux étapes.',
                            style: TextStyle(
                              fontSize: 13,
                              color: Colors.blue[900],
                              height: 1.4,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Toggle 2FA
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: Colors.grey[300]!),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.phonelink_lock,
                          color: _twoFactorEnabled ? const Color(0xFF4DD0E1) : Colors.grey[600],
                          size: 28,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                _twoFactorEnabled ? 'Activée' : 'Désactivée',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: _twoFactorEnabled ? Colors.green[700] : Colors.grey[800],
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _twoFactorEnabled
                                    ? 'Authentification par SMS activée'
                                    : 'Activer la vérification par SMS',
                                style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _twoFactorEnabled,
                          onChanged: (value) {
                            setState(() => _twoFactorEnabled = value);
                            
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  value
                                      ? '✅ 2FA activée avec succès'
                                      : '⚠️ 2FA désactivée',
                                ),
                                backgroundColor: value ? Colors.green : Colors.orange,
                              ),
                            );
                          },
                          activeThumbColor: const Color(0xFF4DD0E1),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),

                  // Explication 2FA
                  if (_twoFactorEnabled)
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.green[50],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.green[200]!),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Icon(Icons.check_circle_outline, color: Colors.green[700], size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'Un code de vérification sera envoyé à votre numéro de téléphone à chaque connexion.',
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.green[900],
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),

              const SizedBox(height: 20),

              // Section: Informations supplémentaires
              _buildSectionCard(
                title: 'Conseils de sécurité',
                icon: Icons.tips_and_updates_outlined,
                children: [
                  const SizedBox(height: 12),
                  _buildSecurityTip(
                    icon: Icons.password,
                    text: 'Utilisez un mot de passe fort avec lettres, chiffres et symboles',
                  ),
                  const SizedBox(height: 10),
                  _buildSecurityTip(
                    icon: Icons.update,
                    text: 'Changez votre mot de passe régulièrement (tous les 3 mois)',
                  ),
                  const SizedBox(height: 10),
                  _buildSecurityTip(
                    icon: Icons.no_accounts,
                    text: 'Ne partagez jamais vos identifiants avec qui que ce soit',
                  ),
                  const SizedBox(height: 10),
                  _buildSecurityTip(
                    icon: Icons.smartphone,
                    text: 'Activez la 2FA pour une sécurité maximale',
                  ),
                ],
              ),

              const SizedBox(height: 30),
            ],
          ),
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

  Widget _buildSecurityTip({required IconData icon, required String text}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: Colors.grey[700]),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[800],
              height: 1.4,
            ),
          ),
        ),
      ],
    );
  }
}
