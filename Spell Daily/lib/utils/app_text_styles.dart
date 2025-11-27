import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../utils/app_colors.dart';

/// Centralized text styles aligned with the visual system brief.
class AppTextStyles {
  AppTextStyles._();

  static TextStyle get logoStyle => GoogleFonts.roboto(
        fontSize: 48,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: AppColors.white,
      );

  static TextStyle get headline => GoogleFonts.roboto(
        fontSize: 24,
        fontWeight: FontWeight.w700,
        color: AppColors.white,
      );

  static TextStyle get body => GoogleFonts.roboto(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: AppColors.textLightPurple,
      );

  static TextStyle get buttonStyle => GoogleFonts.roboto(
        fontSize: 18,
        fontWeight: FontWeight.w900,
        letterSpacing: 2,
        color: AppColors.white,
      );

  static TextStyle get codeInput => GoogleFonts.roboto(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        letterSpacing: 5,
        color: AppColors.white,
      );
}
