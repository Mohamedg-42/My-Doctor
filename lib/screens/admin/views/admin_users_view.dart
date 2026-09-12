import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:intl/intl.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/database_service.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  final _db = DatabaseService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _roleFilter = 'all'; // 'all', 'patient', 'doctor', 'admin'
  String _statusFilter = 'all'; // 'all', 'active', 'pending', 'suspended'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final allUsers = _db.getAllUsers();

    final filtered = allUsers.where((u) {
      if (_roleFilter != 'all' && u.role != _roleFilter) return false;
      if (_statusFilter != 'all' && u.status != _statusFilter) return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = '${u.firstName} ${u.lastName}'.toLowerCase().contains(q);
        final matchPhone = u.phone.toLowerCase().contains(q);
        final matchEmail = u.email.toLowerCase().contains(q);
        final matchCmu = (u.cmuNumber ?? '').toLowerCase().contains(q);
        return matchName || matchPhone || matchEmail || matchCmu;
      }
      return true;
    }).toList();

    return Column(
      children: [
        // ── Barre de recherche et filtres ────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Champ de recherche
              Container(
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.surfaceSubtle,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderSubtle),
                ),
                child: TextField(
                  controller: _searchCtrl,
                  onChanged: (v) => setState(() => _searchQuery = v.trim()),
                  style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
                  decoration: InputDecoration(
                    hintText: 'Rechercher par nom, téléphone, email, CMU...',
                    hintStyle: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textMuted),
                    prefixIcon: const Icon(LucideIcons.search, size: 18, color: AppColors.textMuted),
                    suffixIcon: _searchQuery.isNotEmpty
                        ? IconButton(
                            icon: const Icon(LucideIcons.x, size: 16),
                            onPressed: () {
                              _searchCtrl.clear();
                              setState(() => _searchQuery = '');
                            },
                          )
                        : null,
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(vertical: 11),
                  ),
                ),
              ),

              const SizedBox(height: 10),

              // Filtres par rôle
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Rôle :', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Tous', 'all', _roleFilter, (val) => setState(() => _roleFilter = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('Patients', 'patient', _roleFilter, (val) => setState(() => _roleFilter = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('Médecins', 'doctor', _roleFilter, (val) => setState(() => _roleFilter = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('Admins', 'admin', _roleFilter, (val) => setState(() => _roleFilter = val)),
                  ],
                ),
              ),

              const SizedBox(height: 6),

              // Filtres par statut
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    const Text('Statut :', style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary)),
                    const SizedBox(width: 8),
                    _buildFilterChip('Tous', 'all', _statusFilter, (val) => setState(() => _statusFilter = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('Actifs', 'active', _statusFilter, (val) => setState(() => _statusFilter = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('En attente', 'pending', _statusFilter, (val) => setState(() => _statusFilter = val)),
                    const SizedBox(width: 6),
                    _buildFilterChip('Suspendus', 'suspended', _statusFilter, (val) => setState(() => _statusFilter = val)),
                  ],
                ),
              ),
            ],
          ),
        ),

        // ── Compteur de résultats ─────────────────────────────────────────
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          color: AppColors.surfaceSubtle,
          child: Text(
            '${filtered.length} utilisateur(s) trouvé(s)',
            style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
          ),
        ),

        // ── Liste des utilisateurs ────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.user_x, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucun utilisateur correspondant',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 10),
                  itemBuilder: (_, i) => _UserCard(
                    user: filtered[i],
                    onStatusChanged: () => setState(() {}),
                  ),
                ),
        ),
      ],
    );
  }

  Widget _buildFilterChip(String label, String value, String current, Function(String) onSelect) {
    final isSelected = value == current;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (_) => onSelect(value),
      selectedColor: AppColors.brandBlue,
      labelStyle: TextStyle(
        fontFamily: 'Poppins',
        fontSize: 11,
        fontWeight: isSelected ? FontWeight.w700 : FontWeight.normal,
        color: isSelected ? Colors.white : AppColors.textSecondary,
      ),
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: isSelected ? AppColors.brandBlue : AppColors.borderSubtle),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 0),
      visualDensity: VisualDensity.compact,
    );
  }
}

class _UserCard extends StatelessWidget {
  final DbUser user;
  final VoidCallback onStatusChanged;

  const _UserCard({required this.user, required this.onStatusChanged});

  Future<bool> _confirm(BuildContext context, String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (dialogContext) => AlertDialog(
            title: Text(title, style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700)),
            content: Text(message, style: const TextStyle(fontFamily: 'Poppins', fontSize: 13)),
            actions: [
              TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('Annuler')),
              FilledButton(onPressed: () => Navigator.pop(dialogContext, true), child: const Text('Confirmer')),
            ],
          ),
        ) ??
        false;
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = DateFormat('dd/MM/yyyy HH:mm').format(user.createdAt);
    final isPatient = user.role == 'patient';
    final isDoctor = user.role == 'doctor';
    final isAdmin = user.role == 'admin';

    Color roleColor;
    String roleLabel;
    if (isAdmin) {
      roleColor = AppColors.brandNavy;
      roleLabel = 'ADMINISTRATEUR';
    } else if (isDoctor) {
      roleColor = AppColors.brandTurquoise;
      roleLabel = 'MÉDECIN';
    } else {
      roleColor = AppColors.brandBlue;
      roleLabel = 'PATIENT';
    }

    Color statusColor;
    String statusLabel;
    if (user.status == 'active') {
      statusColor = AppColors.success;
      statusLabel = 'Actif';
    } else if (user.status == 'pending') {
      statusColor = AppColors.warning;
      statusLabel = 'En attente';
    } else {
      statusColor = AppColors.error;
      statusLabel = 'Suspendu';
    }

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.borderSubtle),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.02),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 22,
                backgroundColor: roleColor.withValues(alpha: 0.12),
                child: Text(
                  user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : 'U',
                  style: TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.bold, color: roleColor, fontSize: 16),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            '${user.lastName.toUpperCase()} ${user.firstName}',
                            style: const TextStyle(fontFamily: 'Poppins', fontWeight: FontWeight.w700, fontSize: 14, color: AppColors.textPrimary),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(color: roleColor.withValues(alpha: 0.1), borderRadius: BorderRadius.circular(6)),
                          child: Text(roleLabel, style: TextStyle(fontFamily: 'Poppins', fontSize: 10, fontWeight: FontWeight.bold, color: roleColor)),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        const Icon(LucideIcons.phone, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(user.phone, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary)),
                        if (user.email.isNotEmpty) ...[
                          const SizedBox(width: 10),
                          const Icon(LucideIcons.mail, size: 12, color: AppColors.textMuted),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(user.email, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textSecondary), overflow: TextOverflow.ellipsis),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 8),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(width: 7, height: 7, decoration: BoxDecoration(color: statusColor, shape: BoxShape.circle)),
                      const SizedBox(width: 6),
                      Text(statusLabel, style: TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.w600, color: statusColor)),
                    ],
                  ),
                  Text('Inscrit le $dateStr', style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textMuted)),
                ],
              ),
              PopupMenuButton<String>(
                icon: const Icon(Icons.more_vert, size: 18, color: AppColors.textMuted),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                onSelected: (action) async {
                  final db = DatabaseService();
                  if (action == 'activate') {
                    if (!await _confirm(context, 'Activer ce compte ?', 'L’utilisateur pourra de nouveau accéder à son espace.')) return;
                    await db.updateUserStatus(user.id, 'active');
                    onStatusChanged();
                  } else if (action == 'suspend') {
                    if (!await _confirm(context, 'Suspendre ce compte ?', 'L’utilisateur ne pourra plus se connecter tant que son compte est suspendu.')) return;
                    await db.updateUserStatus(user.id, 'suspended');
                    onStatusChanged();
                  } else if (action == 'details') {
                    _showUserDetails(context);
                  }
                },
                itemBuilder: (_) => [
                  const PopupMenuItem(
                    value: 'details',
                    child: Row(children: [Icon(LucideIcons.eye, size: 16), SizedBox(width: 8), Text('Voir détails')]),
                  ),
                  if (user.status != 'active')
                    const PopupMenuItem(
                      value: 'activate',
                      child: Row(children: [Icon(LucideIcons.circle_check, size: 16, color: AppColors.success), SizedBox(width: 8), Text('Activer le compte')]),
                    ),
                  if (user.status != 'suspended' && user.role != 'admin')
                    const PopupMenuItem(
                      value: 'suspend',
                      child: Row(children: [Icon(LucideIcons.ban, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Suspendre le compte')]),
                    ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  void _showUserDetails(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Row(
          children: [
            const Icon(LucideIcons.user, color: AppColors.brandBlue, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                '${user.lastName.toUpperCase()} ${user.firstName}',
                style: const TextStyle(fontFamily: 'Poppins', fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _detailRow('ID', user.id),
              _detailRow('Rôle', user.role.toUpperCase()),
              _detailRow('Statut', user.status),
              _detailRow('Téléphone', user.phone),
              _detailRow('Email', user.email.isNotEmpty ? user.email : 'Non renseigné'),
              if (user.cmuNumber != null) _detailRow('Numéro CMU', user.cmuNumber!),
              if (user.specialty != null && user.specialty!.isNotEmpty) _detailRow('Spécialité', user.specialty!),
              if (user.orderNumber != null && user.orderNumber!.isNotEmpty) _detailRow('N° Ordre', user.orderNumber!),
              if (user.birthDate != null) _detailRow('Date de naissance', user.birthDate!),
              if (user.city != null) _detailRow('Ville', user.city!),
              if (user.commune != null) _detailRow('Commune', user.commune!),
              _detailRow('Créé le', DateFormat('dd/MM/yyyy HH:mm:ss').format(user.createdAt)),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Fermer', style: TextStyle(fontFamily: 'Poppins', color: AppColors.brandBlue)),
          ),
        ],
      ),
    );
  }

  Widget _detailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(value, style: const TextStyle(fontFamily: 'Poppins', fontSize: 12, color: AppColors.textPrimary)),
          ),
        ],
      ),
    );
  }
}
