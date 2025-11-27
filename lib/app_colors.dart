import 'package:flutter/material.dart';

class AppColors {
  static const Color purple = Color(0xFF5E17EB);
  static const Color orange = Color(0xFFFFB638);
  static const Color white = Color(0xFFFFFFFF);
  static const Color lightPurple = Color(0xFFBEA1F7);
  static const Color darkPurple = Color(0xFF3A007F);
  static const Color successGreen = Color(0xFF34C759);

  static const LinearGradient orangeWave = LinearGradient(
    colors: [Color(0xFFFFC764), orange],
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
  );

  static const LinearGradient purpleGradient = LinearGradient(
    colors: [purple, darkPurple],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}

