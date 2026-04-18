import 'package:flutter/material.dart';
import '../../core/utils/helpers.dart';

/// A filterable chip widget for sport selection.
class SportChip extends StatelessWidget {
  final String sport;
  final bool isSelected;
  final VoidCallback onTap;

  const SportChip({
    super.key,
    required this.sport,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final color = Helpers.sportColor(sport);

    return AnimatedContainer(
      duration: const Duration(milliseconds: 200),
      curve: Curves.easeInOut,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: isSelected ? color.withAlpha(40) : Colors.transparent,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? color : Theme.of(context).colorScheme.outline.withAlpha(60),
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Helpers.sportIcon(sport),
                  size: 18,
                  color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withAlpha(150),
                ),
                const SizedBox(width: 6),
                Text(
                  sport,
                  style: TextStyle(
                    color: isSelected ? color : Theme.of(context).colorScheme.onSurface.withAlpha(200),
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
