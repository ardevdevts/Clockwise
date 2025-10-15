import 'package:flutter/material.dart';
import 'colors.dart';

final ThemeData themeDark = ThemeData(
  brightness: Brightness.dark,
  fontFamily: 'Sora',
  
  scaffoldBackgroundColor: AppColors.background,
  colorScheme: const ColorScheme.dark(
    primary: AppColors.accentBlue,
    secondary: AppColors.accentTeal,
    surface: AppColors.surface,
    error: AppColors.error,
  ),
  cardColor: AppColors.surface,
  dividerColor: AppColors.border,
  textTheme: const TextTheme(
    bodyLarge: TextStyle(color: AppColors.textPrimary, fontWeight: FontWeight.w400, fontSize: 16),
    bodyMedium: TextStyle(color: AppColors.textSecondary, fontWeight: FontWeight.w500, fontSize: 14),
    labelSmall: TextStyle(color: AppColors.textMuted, fontWeight: FontWeight.w600, fontSize: 12),
  ),
  iconTheme: const IconThemeData(color: AppColors.textSecondary),
  appBarTheme: const AppBarTheme(
    backgroundColor: AppColors.background,
    foregroundColor: AppColors.textPrimary,
    elevation: 0,
  ),
  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ButtonStyle(
      backgroundColor: WidgetStatePropertyAll(AppColors.buttonBackground),
      foregroundColor: WidgetStatePropertyAll(AppColors.buttonText),
      overlayColor: WidgetStatePropertyAll(AppColors.gray500),
    ),
  ),
);
