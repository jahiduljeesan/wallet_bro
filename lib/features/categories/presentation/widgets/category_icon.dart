import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/category_provider.dart';

class CategoryIcon extends StatelessWidget {
  final String categoryName;
  final bool isExpense;
  final double size;
  final Color? color;

  const CategoryIcon({
    super.key,
    required this.categoryName,
    required this.isExpense,
    this.size = 24.0,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final categories = Provider.of<CategoryProvider>(context).categories;
    
    // Find category matching categoryName case-insensitively
    final cat = categories.firstWhere(
      (c) => c.name.toLowerCase() == categoryName.toLowerCase(),
      orElse: () => categories.firstWhere(
        (c) => c.id == categoryName, // Try exact ID match too
        orElse: () => categories.firstWhere(
          (c) => c.name.toLowerCase() == 'others',
          orElse: () => categories.first,
        ),
      ),
    );

    // If category has a custom image path
    if (cat.iconPath != null) {
      if (cat.iconPath!.startsWith('assets/')) {
        return Image.asset(
          cat.iconPath!,
          width: size,
          height: size,
          fit: BoxFit.contain,
        );
      } else {
        final file = File(cat.iconPath!);
        if (file.existsSync()) {
          return ClipRRect(
            borderRadius: BorderRadius.circular(size * 0.2),
            child: Image.file(
              file,
              width: size,
              height: size,
              fit: BoxFit.cover,
            ),
          );
        }
      }
    }

    // Else if category has a Material Icon codePoint
    if (cat.iconCodePoint != null) {
      return Icon(
        getIconDataFromCodePoint(cat.iconCodePoint!),
        size: size,
        color: color ?? Theme.of(context).colorScheme.primary,
      );
    }

    // Fallback if everything else fails
    return Icon(
      isExpense ? Icons.arrow_outward_rounded : Icons.arrow_downward_rounded,
      size: size,
      color: color ?? (isExpense ? Colors.redAccent : Colors.green),
    );
  }
}

IconData getIconDataFromCodePoint(int codePoint) {
  if (codePoint == Icons.restaurant.codePoint) return Icons.restaurant;
  if (codePoint == Icons.receipt_long.codePoint) return Icons.receipt_long;
  if (codePoint == Icons.home.codePoint) return Icons.home;
  if (codePoint == Icons.medical_services.codePoint) return Icons.medical_services;
  if (codePoint == Icons.school.codePoint) return Icons.school;
  if (codePoint == Icons.flight.codePoint) return Icons.flight;
  if (codePoint == Icons.shopping_bag.codePoint) return Icons.shopping_bag;
  if (codePoint == Icons.face.codePoint) return Icons.face;
  if (codePoint == Icons.movie.codePoint) return Icons.movie;
  if (codePoint == Icons.directions_car.codePoint) return Icons.directions_car;
  if (codePoint == Icons.card_giftcard.codePoint) return Icons.card_giftcard;
  if (codePoint == Icons.subscriptions.codePoint) return Icons.subscriptions;
  if (codePoint == Icons.volunteer_activism.codePoint) return Icons.volunteer_activism;
  if (codePoint == Icons.payment.codePoint) return Icons.payment;
  if (codePoint == Icons.pets.codePoint) return Icons.pets;
  if (codePoint == Icons.fitness_center.codePoint) return Icons.fitness_center;
  if (codePoint == Icons.sports_esports.codePoint) return Icons.sports_esports;
  if (codePoint == Icons.work.codePoint) return Icons.work;
  if (codePoint == Icons.more_horiz.codePoint) return Icons.more_horiz;
  
  return Icons.help_outline;
}

