import 'package:flutter/material.dart';

abstract final class AppColors {
  static const primary = Color(0xFF1976D2);
  static const primaryContainer = Color(0xFFBBDEFB);

  // Prioridades de incidentes
  static const priorityUrgent = Color(0xFFD32F2F);
  static const priorityHigh = Color(0xFFF57C00);
  static const priorityMedium = Color(0xFFFBC02D);
  static const priorityLow = Color(0xFF388E3C);

  // Estados de incidente
  static const statusReceived = Color(0xFF78909C);
  static const statusScheduled = Color(0xFF1976D2);
  static const statusInProgress = Color(0xFFF57C00);
  static const statusSolved = Color(0xFF388E3C);
}
