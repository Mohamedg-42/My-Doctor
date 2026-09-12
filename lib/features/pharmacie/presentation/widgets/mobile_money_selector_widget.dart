import 'package:flutter/material.dart';
import '../../data/models/paiement_mobile_model.dart';

class MobileMoneySelectorWidget extends StatefulWidget {
  final OperateurMobileMoney? selected;
  final ValueChanged<OperateurMobileMoney> onSelected;

  const MobileMoneySelectorWidget({
    super.key,
    this.selected,
    required this.onSelected,
  });

  @override
  State<MobileMoneySelectorWidget> createState() => _MobileMoneySelectorWidgetState();
}

class _MobileMoneySelectorWidgetState extends State<MobileMoneySelectorWidget> {
  OperateurMobileMoney? _selected;

  @override
  void initState() {
    super.initState();
    _selected = widget.selected;
  }

  @override
  Widget build(BuildContext context) {
    const operateurs = OperateurMobileMoney.values;
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.6,
      children: operateurs.map((op) => _OperateurCard(
        operateur: op,
        isSelected: _selected == op,
        onTap: () {
          setState(() => _selected = op);
          widget.onSelected(op);
        },
      )).toList(),
    );
  }
}

class _OperateurCard extends StatelessWidget {
  final OperateurMobileMoney operateur;
  final bool isSelected;
  final VoidCallback onTap;

  const _OperateurCard({
    required this.operateur,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      decoration: BoxDecoration(
        color: isSelected ? operateur.couleur : Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isSelected ? operateur.couleur : Colors.grey.shade200,
          width: isSelected ? 2.5 : 1.5,
        ),
        boxShadow: isSelected ? [
          BoxShadow(
            color: operateur.couleur.withValues(alpha: 0.35),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ] : [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? Colors.white.withValues(alpha: 0.2)
                          : operateur.couleur.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      operateur.icone,
                      color: isSelected ? Colors.white : operateur.couleur,
                      size: 20,
                    ),
                  ),
                  if (isSelected)
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.check_rounded,
                        color: operateur.couleur,
                        size: 13,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  operateur.nom,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: isSelected ? Colors.white : const Color(0xFF1A2340),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  operateur.prefixe,
                  style: TextStyle(
                    fontFamily: 'Poppins',
                    fontSize: 9,
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.7)
                        : Colors.grey.shade500,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
