// lib/screens/admin/views/admin_users_view.dart
//
// Vue unifiée transversale de tous les comptes (patients, médecins, administrateurs).

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/theme/app_theme.dart';
import '../../../services/database_service.dart';
import '../components/admin_empty_state.dart';

class AdminUsersView extends StatefulWidget {
  const AdminUsersView({super.key});

  @override
  State<AdminUsersView> createState() => _AdminUsersViewState();
}

class _AdminUsersViewState extends State<AdminUsersView> {
  String _searchQuery = '';
  String _roleFilter = 'Tous'; // 'Tous', 'patient', 'doctor', 'admin'
  String _statusFilter = 'Tous'; // 'Tous', 'active', 'pending', 'suspended'
  final TextEditingController _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _toggleUserStatus(DbUser user) async {
    final allUsers = DatabaseService().getAllUsers();
    final adminCount = allUsers.where((u) => u.role == 'admin' && u.status == 'active').length;

    // Règle de sécurité : empêcher la suspension du dernier administrateur actif
    if (user.role == 'admin' && user.status == 'active' && adminCount <= 1) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Action refusée : Impossible de suspendre le dernier compte administrateur actif.'),
          backgroundColor: AppColors.error,
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final willSuspend = user.status == 'active';
    final action = willSuspend ? 'Suspendre' : 'Réactiver';

    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('$action le compte ${user.role.toUpperCase()}'),
        content: Text(
          willSuspend
              ? 'Voulez-vous suspendre le compte de ${user.fullName} (${user.phone}) ?'
              : 'Voulez-vous réactiver le compte de ${user.fullName} ?',
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Annuler')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: willSuspend ? AppColors.error : AppColors.brandBlue,
              foregroundColor: Colors.white,
            ),
            child: Text(action),
          ),
        ],
      ),
    );

    if (confirm != true || !mounted) return;

    try {
      final newStatus = willSuspend ? 'suspended' : 'active';
      await DatabaseService().updateUserStatus(user.id, newStatus);
      if (!mounted) return;

      setState(() {});
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Statut de ${user.fullName} mis à jour ($newStatus).'),
          backgroundColor: willSuspend ? AppColors.error : AppColors.success,
          behavior: SnackBarBehavior.floating,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erreur : $e'), backgroundColor: AppColors.error),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final allUsers = DatabaseService().getAllUsers();

    final filtered = allUsers.where((u) {
      final matchesRole = _roleFilter == 'Tous' || u.role == _roleFilter;
      final matchesStatus = _statusFilter == 'Tous' || u.status == _statusFilter;

      final q = _searchQuery.toLowerCase();
      final matchesQuery = q.isEmpty ||
          u.lastName.toLowerCase().contains(q) ||
          u.firstName.toLowerCase().contains(q) ||
          u.phone.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q);

      return matchesRole && matchesStatus && matchesQuery;
    }).toList();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 46,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: TextField(
              controller: _searchCtrl,
              onChanged: (v) => setState(() => _searchQuery = v),
              style: const TextStyle(fontFamily: 'Poppins', fontSize: 13),
              decoration: InputDecoration(
                hintText: 'Rechercher par nom, téléphone, e-mail...',
                hintStyle: TextStyle(fontFamily: 'Poppins', fontSize: 12, color: Colors.grey.shade400),
                prefixIcon: const Icon(LucideIcons.search, size: 18, color: Colors.grey),
                suffixIcon: _searchQuery.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear, size: 16),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() => _searchQuery = '');
                        },
                      )
                    : null,
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(vertical: 12),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButton<String>(
                    value: _roleFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Tous', child: Text('Tous les rôles')),
                      DropdownMenuItem(value: 'patient', child: Text('Patients')),
                      DropdownMenuItem(value: 'doctor', child: Text('Médecins')),
                      DropdownMenuItem(value: 'admin', child: Text('Administrateurs')),
                    ],
                    onChanged: (v) => setState(() => _roleFilter = v ?? 'Tous'),
                  ),
                ),
                const SizedBox(width: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.grey.shade200),
                  ),
                  child: DropdownButton<String>(
                    value: _statusFilter,
                    underline: const SizedBox(),
                    items: const [
                      DropdownMenuItem(value: 'Tous', child: Text('Tous statuts')),
                      DropdownMenuItem(value: 'active', child: Text('Actifs')),
                      DropdownMenuItem(value: 'pending', child: Text('En attente')),
                      DropdownMenuItem(value: 'suspended', child: Text('Suspendus')),
                    ],
                    onChanged: (v) => setState(() => _statusFilter = v ?? 'Tous'),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 20),

          Expanded(
            child: filtered.isEmpty
                ? const AdminEmptyState(
                    icon: LucideIcons.users,
                    title: 'Aucun utilisateur trouvé',
                    message: 'Aucun compte ne correspond à ces critères.',
                  )
                : ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, i) {
                      final u = filtered[i];

                      Color roleColor = AppColors.brandTurquoise;
                      String roleLabel = 'PATIENT';
                      if (u.role == 'doctor') {
                        roleColor = AppColors.brandBlue;
                        roleLabel = 'MÉDECIN';
                      } else if (u.role == 'admin') {
                        roleColor = const Color(0xFF0F172A);
                        roleLabel = 'ADMIN';
                      }

                      Color statusColor = AppColors.success;
                      String statusLabel = 'Actif';
                      if (u.status == 'pending') {
                        statusColor = const Color(0xFFEA580C);
                        statusLabel = 'En attente';
                      } else if (u.status == 'suspended') {
                        statusColor = AppColors.error;
                        statusLabel = 'Suspendu';
                      }

                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: Colors.grey.shade200),
                        ),
                        child: Row(
                          children: [
                            CircleAvatar(
                              radius: 20,
                              backgroundColor: roleColor.withValues(alpha: 0.12),
                              child: Text(
                                u.firstName.isNotEmpty ? u.firstName[0].toUpperCase() : 'U',
                                style: TextStyle(fontWeight: FontWeight.bold, color: roleColor),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    children: [
                                      Flexible(
                                        child: Text(
                                          u.fullName,
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: roleColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          roleLabel,
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: roleColor),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: statusColor.withValues(alpha: 0.1),
                                          borderRadius: BorderRadius.circular(4),
                                        ),
                                        child: Text(
                                          statusLabel,
                                          style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: statusColor),
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    '${u.phone} • ${u.email} • ID : ${u.id}',
                                    style: TextStyle(fontSize: 11, color: Colors.grey.shade600),
                                  ),
                                ],
                              ),
                            ),
                            IconButton(
                              icon: Icon(
                                u.status == 'suspended' ? LucideIcons.user_check : LucideIcons.ban,
                                size: 18,
                                color: u.status == 'suspended' ? AppColors.success : AppColors.error,
                              ),
                              tooltip: u.status == 'suspended' ? 'Réactiver' : 'Suspendre',
                              onPressed: () => _toggleUserStatus(u),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
