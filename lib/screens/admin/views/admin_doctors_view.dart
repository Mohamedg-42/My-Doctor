import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:provider/provider.dart';
import '../../../core/theme/app_theme.dart';
import '../../../providers/treating_request_provider.dart';
import '../../../services/database_service.dart';

class AdminDoctorsView extends StatefulWidget {
  const AdminDoctorsView({super.key});

  @override
  State<AdminDoctorsView> createState() => _AdminDoctorsViewState();
}

class _AdminDoctorsViewState extends State<AdminDoctorsView> {
  final _db = DatabaseService();
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  String _statusFilter = 'all'; // 'all', 'pending', 'active'

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final trProvider = context.watch<TreatingRequestProvider>();
    final allDoctors = _db.getAllDoctors(onlyActive: false);

    final filtered = allDoctors.where((d) {
      if (_statusFilter == 'pending' && d.status != 'pending') return false;
      if (_statusFilter == 'active' && d.status != 'active') return false;
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchName = '${d.firstName} ${d.lastName}'.toLowerCase().contains(q);
        final matchSpec = (d.specialty ?? '').toLowerCase().contains(q);
        final matchOrder = (d.orderNumber ?? '').toLowerCase().contains(q);
        final matchPhone = d.phone.toLowerCase().contains(q);
        return matchName || matchSpec || matchOrder || matchPhone;
      }
      return true;
    }).toList();

    final pendingCount = allDoctors.where((d) => d.status == 'pending').length;

    return Column(
      children: [
        // ── Barre de recherche et filtres ────────────────────────────────
        Container(
          color: Colors.white,
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 10),
          child: Column(
            children: [
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
                    hintText: 'Rechercher médecin, spécialité, N° ordre...',
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
              Row(
                children: [
                  _buildTabPill('Tous (${allDoctors.length})', 'all'),
                  const SizedBox(width: 8),
                  _buildTabPill('En attente ($pendingCount)', 'pending', isPending: pendingCount > 0),
                  const SizedBox(width: 8),
                  _buildTabPill('Validés (${allDoctors.length - pendingCount})', 'active'),
                ],
              ),
            ],
          ),
        ),

        // ── Liste des médecins ────────────────────────────────────────────
        Expanded(
          child: filtered.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(LucideIcons.stethoscope, size: 48, color: AppColors.textMuted.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      const Text(
                        'Aucun médecin trouvé',
                        style: TextStyle(fontFamily: 'Poppins', fontSize: 14, fontWeight: FontWeight.w600, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, i) {
                    final doc = filtered[i];
                    final requests = trProvider.requestsForDoctor(doc.id);
                    return _DoctorAdminCard(
                      doctor: doc,
                      requestsCount: requests.length,
                      acceptedRequestsCount: requests.where((r) => r.isAccepted).length,
                      onUpdated: () => setState(() {}),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildTabPill(String label, String value, {bool isPending = false}) {
    final isSelected = _statusFilter == value;
    return InkWell(
      onTap: () => setState(() => _statusFilter = value),
      borderRadius: BorderRadius.circular(20),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? (isPending ? AppColors.warning : AppColors.brandTurquoise)
              : AppColors.surfaceSubtle,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isSelected
                ? Colors.transparent
                : (isPending ? AppColors.warning.withValues(alpha: 0.4) : AppColors.borderSubtle),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'Poppins',
            fontSize: 11,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
            color: isSelected ? Colors.white : (isPending ? AppColors.warning : AppColors.textSecondary),
          ),
        ),
      ),
    );
  }
}

class _DoctorAdminCard extends StatelessWidget {
  final DbUser doctor;
  final int requestsCount;
  final int acceptedRequestsCount;
  final VoidCallback onUpdated;

  const _DoctorAdminCard({
    required this.doctor,
    required this.requestsCount,
    required this.acceptedRequestsCount,
    required this.onUpdated,
  });

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
    final isPending = doctor.status == 'pending';
    final isActive = doctor.status == 'active';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isPending ? AppColors.warning.withValues(alpha: 0.4) : AppColors.borderSubtle,
          width: isPending ? 1.5 : 1.0,
        ),
        boxShadow: [
          BoxShadow(
            color: isPending ? AppColors.warning.withValues(alpha: 0.06) : Colors.black.withValues(alpha: 0.02),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                radius: 24,
                backgroundColor: AppColors.brandTurquoise.withValues(alpha: 0.12),
                child: const Icon(LucideIcons.stethoscope, color: AppColors.brandTurquoise, size: 24),
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
                            'Dr. ${doctor.firstName} ${doctor.lastName}',
                            style: const TextStyle(
                              fontFamily: 'Poppins',
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isPending
                                ? AppColors.warning.withValues(alpha: 0.12)
                                : (isActive ? AppColors.success.withValues(alpha: 0.12) : AppColors.error.withValues(alpha: 0.12)),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            isPending ? 'En attente' : (isActive ? 'Validé' : 'Suspendu'),
                            style: TextStyle(
                              fontFamily: 'Poppins',
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: isPending ? AppColors.warning : (isActive ? AppColors.success : AppColors.error),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 2),
                    Text(
                      doctor.specialty != null && doctor.specialty!.isNotEmpty
                          ? doctor.specialty!
                          : 'Médecin Généraliste',
                      style: const TextStyle(
                        fontFamily: 'Poppins',
                        fontSize: 12,
                        color: AppColors.brandTurquoise,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(LucideIcons.badge_check, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          'N° Ordre : ${doctor.orderNumber ?? 'Non renseigné'}',
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
                        ),
                        const SizedBox(width: 12),
                        const Icon(LucideIcons.phone, size: 12, color: AppColors.textMuted),
                        const SizedBox(width: 4),
                        Text(
                          doctor.phone,
                          style: const TextStyle(fontFamily: 'Poppins', fontSize: 11, color: AppColors.textSecondary),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),
          const Divider(height: 1, color: AppColors.borderSubtle),
          const SizedBox(height: 10),

          // Métriques du médecin & Bouton d'action
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  _statBadge(LucideIcons.inbox, '$requestsCount demande(s)'),
                  const SizedBox(width: 8),
                  _statBadge(LucideIcons.check_check, '$acceptedRequestsCount acceptée(s)'),
                ],
              ),
              if (isPending)
                ElevatedButton.icon(
                  onPressed: () async {
                    if (!await _confirm(context, 'Valider ce médecin ?', 'Le compte sera visible comme actif après validation.')) return;
                    await DatabaseService().updateUserStatus(doctor.id, 'active');
                    onUpdated();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Row(
                            children: [
                              const Icon(LucideIcons.circle_check, color: Colors.white, size: 18),
                              const SizedBox(width: 8),
                              Text('Dr. ${doctor.lastName} a été validé avec succès !'),
                            ],
                          ),
                          backgroundColor: AppColors.success,
                          behavior: SnackBarBehavior.floating,
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      );
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.brandTurquoise,
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(LucideIcons.shield_check, color: Colors.white, size: 16),
                  label: const Text('Valider', style: TextStyle(fontFamily: 'Poppins', color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold)),
                )
              else
                PopupMenuButton<String>(
                  icon: const Icon(Icons.more_horiz, size: 18, color: AppColors.textMuted),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  onSelected: (action) async {
                    final db = DatabaseService();
                    if (action == 'suspend') {
                      if (!await _confirm(context, 'Suspendre ce médecin ?', 'Le médecin ne pourra plus se connecter tant que son compte restera suspendu.')) return;
                      await db.updateUserStatus(doctor.id, 'suspended');
                      onUpdated();
                    } else if (action == 'activate') {
                      await db.updateUserStatus(doctor.id, 'active');
                      onUpdated();
                    }
                  },
                  itemBuilder: (_) => [
                    if (isActive)
                      const PopupMenuItem(
                        value: 'suspend',
                        child: Row(children: [Icon(LucideIcons.ban, size: 16, color: AppColors.error), SizedBox(width: 8), Text('Suspendre le médecin')]),
                      )
                    else
                      const PopupMenuItem(
                        value: 'activate',
                        child: Row(children: [Icon(LucideIcons.circle_check, size: 16, color: AppColors.success), SizedBox(width: 8), Text('Réactiver')]),
                      ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _statBadge(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.surfaceSubtle,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: [
          Icon(icon, size: 12, color: AppColors.textMuted),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontFamily: 'Poppins', fontSize: 10, color: AppColors.textSecondary, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }
}
