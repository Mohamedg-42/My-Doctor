import 'package:flutter/material.dart';
import '../../data/models/ordonnance_model.dart';

class StatutBadgeWidget extends StatelessWidget {
  final StatutOrdonnance statut;
  final bool compact;

  const StatutBadgeWidget({super.key, required this.statut, this.compact = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: compact ? 8 : 12,
        vertical: compact ? 3 : 5,
      ),
      decoration: BoxDecoration(
        color: statut.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: statut.color.withValues(alpha: 0.35), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(statut.icon, size: compact ? 11 : 13, color: statut.color),
          SizedBox(width: compact ? 4 : 5),
          Flexible(
            child: Text(
              statut.label,
              style: TextStyle(
                fontFamily: 'Poppins',
                fontSize: compact ? 10 : 11,
                fontWeight: FontWeight.w700,
                color: statut.color,
                letterSpacing: 0.3,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}
