import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import 'app_colors.dart';

class AppTextStyles {
  static TextStyle hero(double size) => GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w900,
        color: AppColors.white,
        letterSpacing: 1.2,
      );

  static TextStyle button(double size, {Color color = AppColors.white}) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w800,
        color: color,
        letterSpacing: 0.8,
      );

  static TextStyle label(double size, {Color color = AppColors.white}) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w700,
        color: color,
      );

  static TextStyle body(double size, {Color color = AppColors.white}) =>
      GoogleFonts.poppins(
        fontSize: size,
        fontWeight: FontWeight.w600,
        color: color,
        height: 1.3,
      );

  static BoxDecoration buttonDecoration({Color background = AppColors.orange}) {
    return BoxDecoration(
      color: background,
      borderRadius: BorderRadius.circular(24),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33FFB638),
          blurRadius: 24,
          offset: Offset(0, 10),
        ),
      ],
      border: Border.all(
        color: AppColors.white.withOpacity(0.2),
        width: 3,
      ),
    );
  }
}

