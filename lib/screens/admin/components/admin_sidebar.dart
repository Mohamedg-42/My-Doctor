// lib/screens/admin/components/admin_sidebar.dart
//
// Barre latérale de navigation de la console administrateur My Doctor.

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import '../../../core/theme/app_theme.dart';

class AdminSidebarItem {
  final int index;
  final String title;
  final IconData icon;
  final int? badgeCount;
  final Color? badgeColor;

  const AdminSidebarItem({
    required this.index,
    required this.title,
    required this.icon,
    this.badgeCount,
    this.badgeColor,
  });
}

class AdminSidebar extends StatelessWidget {
  final int selectedIndex;
  final ValueChanged<int> onSelectTab;
  final Map<int, int>? badgeCounts;
  final bool isDrawer;

  const AdminSidebar({
    super.key,
    required this.selectedIndex,
    required this.onSelectTab,
    this.badgeCounts,
    this.isDrawer = false,
  });

  static const List<AdminSidebarItem> items = [
    AdminSidebarItem(
      index: 0,
      title: 'Vue d\'ensemble',
      icon: LucideIcons.layout_dashboard,
    ),
    AdminSidebarItem(
      index: 1,
      title: 'Cartes patient & CMU',
      icon: LucideIcons.id_card,
    ),
    AdminSidebarItem(
      index: 2,
      title: 'Finances & Retraits',
      icon: LucideIcons.wallet,
    ),
    AdminSidebarItem(
      index: 3,
      title: 'Gestion des médecins',
      icon: LucideIcons.stethoscope,
    ),
    AdminSidebarItem(
      index: 4,
      title: 'Gestion des patients',
      icon: LucideIcons.users,
    ),
    AdminSidebarItem(
      index: 5,
      title: 'Rendez-vous',
      icon: LucideIcons.calendar,
    ),
    AdminSidebarItem(
      index: 6,
      title: 'Demandes traitant',
      icon: LucideIcons.user_check,
    ),
    AdminSidebarItem(
      index: 7,
      title: 'Conversations & Audit',
      icon: LucideIcons.messages_square,
    ),
    AdminSidebarItem(
      index: 8,
      title: 'Configuration système',
      icon: LucideIcons.settings,
    ),
    AdminSidebarItem(
      index: 9,
      title: 'Utilisateurs globaux',
      icon: LucideIcons.users_round,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 260,
      color: const Color(0xFF0F172A), // Bleu nuit sécurisé
      child: Column(
        children: [
          // Logo & Titre
          Container(
            padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    gradient: AppColors.primaryGradient,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Center(
                    child: Icon(LucideIcons.activity, color: Colors.white, size: 22),
                  ),
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'MY DOCTOR',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                          letterSpacing: 0.5,
                        ),
                      ),
                      Text(
                        'Portail Admin • v2.0',
                        style: TextStyle(
                          fontFamily: 'Poppins',
                          fontSize: 10,
                          color: AppColors.brandTurquoise,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // Liste des sections
          Expanded(
            child: ListView.separated(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
              itemCount: items.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, i) {
                final item = items[i];
                final isSelected = selectedIndex == item.index;
                final badgeCount = badgeCounts?[item.index];

                return Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(12),
                    onTap: () => onSelectTab(item.index),
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 150),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                      decoration: BoxDecoration(
                        color: isSelected
                            ? AppColors.brandBlue.withValues(alpha: 0.22)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(12),
                        border: isSelected
                            ? Border.all(
                                color: AppColors.brandBlue.withValues(alpha: 0.5),
                                width: 1,
                              )
                            : null,
                      ),
                      child: Row(
                        children: [
                          Icon(
                            item.icon,
                            size: 19,
                            color: isSelected ? AppColors.brandBlue : Colors.white60,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              item.title,
                              style: TextStyle(
                                fontFamily: 'Poppins',
                                fontSize: 13,
                                fontWeight:
                                    isSelected ? FontWeight.w700 : FontWeight.w500,
                                color: isSelected ? Colors.white : Colors.white70,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          if (badgeCount != null && badgeCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 7, vertical: 2),
                              decoration: BoxDecoration(
                                color: item.index == 2
                                    ? AppColors.brandCoral
                                    : (item.index == 3 || item.index == 6
                                        ? const Color(0xFFEA580C)
                                        : AppColors.brandBlue),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                '$badgeCount',
                                style: const TextStyle(
                                  fontFamily: 'Poppins',
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          // Pied de page sidebar
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.white.withValues(alpha: 0.08)),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 8,
                  height: 8,
                  decoration: const BoxDecoration(
                    color: Color(0xFF10B981), // Vert en ligne
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                const Expanded(
                  child: Text(
                    'Serveur opérationnel',
                    style: TextStyle(
                      fontFamily: 'Poppins',
                      fontSize: 11,
                      color: Colors.white60,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
