import 'package:budget/colors.dart';
import 'package:budget/struct/settings.dart';
import 'package:budget/widgets/tappable.dart';
import 'package:budget/widgets/textWidgets.dart';
import 'package:flutter/material.dart';

class HouseholdFeatureCard extends StatelessWidget {
  const HouseholdFeatureCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.onTap,
    super.key,
  });

  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cardColor = dynamicPastel(context, color,
        amountLight: 0.7, amountDark: 0.5);

    return Tappable(
      onTap: onTap,
      borderRadius: 18,
      color: cardColor,
      child: Padding(
        padding: const EdgeInsetsDirectional.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: color.withOpacity(
                    Theme.of(context).brightness == Brightness.dark
                        ? 0.25
                        : 0.18),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsetsDirectional.all(10),
              child: Icon(icon, color: color, size: 26),
            ),
            const SizedBox(height: 14),
            TextFont(
              text: title,
              fontWeight: FontWeight.bold,
              fontSize: 16,
            ),
            const SizedBox(height: 4),
            TextFont(
              text: description,
              fontSize: 13,
              textColor: getColor(context, "textLight"),
              maxLines: 2,
            ),
          ],
        ),
      ),
    );
  }
}
