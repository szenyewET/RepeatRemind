import 'package:flutter/material.dart';

import '../models/category.dart';

/// Maps each [Category] to a display label and a Material icon.
const _categoryMeta = {
  Category.car: (label: 'Car', icon: Icons.directions_car),
  Category.home: (label: 'Home', icon: Icons.home),
  Category.pet: (label: 'Pet', icon: Icons.pets),
  Category.health: (label: 'Health', icon: Icons.favorite),
  Category.garden: (label: 'Garden', icon: Icons.yard),
  Category.other: (label: 'Other', icon: Icons.more_horiz),
};

String categoryLabel(Category category) => _categoryMeta[category]!.label;
IconData categoryIcon(Category category) => _categoryMeta[category]!.icon;

class CategoryIcon extends StatelessWidget {
  final Category category;
  final bool selected;

  const CategoryIcon({
    super.key,
    required this.category,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    final meta = _categoryMeta[category]!;
    final colorScheme = Theme.of(context).colorScheme;

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(
          meta.icon,
          color: selected ? colorScheme.primary : colorScheme.onSurfaceVariant,
          size: 28,
        ),
        const SizedBox(height: 4),
        Text(
          meta.label,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
                color: selected
                    ? colorScheme.primary
                    : colorScheme.onSurfaceVariant,
                fontWeight:
                    selected ? FontWeight.bold : FontWeight.normal,
              ),
        ),
      ],
    );
  }
}
