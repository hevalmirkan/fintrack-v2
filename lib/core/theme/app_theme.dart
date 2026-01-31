import 'package:flutter/material.dart';

/// =====================================================
/// FINTRACK DUAL THEME SYSTEM — v1.0 REFACTORED
/// =====================================================
/// Dark "Carbon" + Light "Warm Paper"
/// Frosted gradient hero cards with glow effects.
/// =====================================================

class AppTheme {
  // ================== SHARED ACCENT ==================
  static const Color tealAccent = Color(0xFF00BFA5);
  static const Color positive = Color(0xFF00C853);
  static const Color negative = Color(0xFFFF5252);
  static const Color warning = Color(0xFFFFB74D);

  // ================== DARK THEME ("Carbon") ==================
  static final ThemeData darkTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.dark,
    scaffoldBackgroundColor: const Color(0xFF121212),
    cardColor: const Color(0xFF1E1E1E),
    primaryColor: tealAccent,
    colorScheme: const ColorScheme.dark(
      primary: tealAccent,
      secondary: Color(0xFF78909C),
      surface: Color(0xFF1E1E1E),
      error: negative,
      onPrimary: Colors.white,
      onSurface: Color(0xFFB0B0B0),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Colors.transparent,
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Colors.white),
    ),
    cardTheme: CardThemeData(
      color: const Color(0xFF1E1E1E),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.white.withOpacity(0.08)),
      ),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: const Color(0xFF2C2C2C),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: tealAccent, width: 1.5),
      ),
      hintStyle: TextStyle(color: Colors.grey.shade600),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: tealAccent,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: tealAccent,
      foregroundColor: Colors.white,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Color(0xFF1E1E1E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF2C2C2C),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: DividerThemeData(color: Colors.white.withOpacity(0.08)),
  );

  // ================== LIGHT THEME ("Warm Paper") ==================
  static final ThemeData lightTheme = ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    scaffoldBackgroundColor: const Color(0xFFF2F4F7),
    cardColor: Colors.white,
    primaryColor: const Color(0xFF263238),
    colorScheme: const ColorScheme.light(
      primary: Color(0xFF263238),
      secondary: tealAccent,
      surface: Colors.white,
      error: negative,
      onPrimary: Colors.white,
      onSurface: Color(0xFF37474F),
    ),
    appBarTheme: const AppBarTheme(
      backgroundColor: Color(0xFFF2F4F7),
      elevation: 0,
      centerTitle: false,
      titleTextStyle: TextStyle(
        color: Color(0xFF263238),
        fontSize: 20,
        fontWeight: FontWeight.bold,
      ),
      iconTheme: IconThemeData(color: Color(0xFF263238)),
    ),
    cardTheme: CardThemeData(
      color: Colors.white,
      elevation: 2,
      shadowColor: Colors.black12,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0E0E0)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFF263238), width: 1.5),
      ),
      hintStyle: TextStyle(color: Colors.grey.shade500),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: const Color(0xFF263238),
        foregroundColor: Colors.white,
        elevation: 2,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    ),
    floatingActionButtonTheme: const FloatingActionButtonThemeData(
      backgroundColor: Color(0xFF263238),
      foregroundColor: Colors.white,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: const Color(0xFF263238),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dividerTheme: const DividerThemeData(color: Color(0xFFE0E0E0)),
  );

  // ================== FROSTED HERO CARD GRADIENTS ==================

  /// Dark theme hero gradient (Charcoal Blue to Dark Slate)
  static const LinearGradient heroDarkGradient = LinearGradient(
    colors: [Color(0xFF1F2833), Color(0xFF141E30)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Light theme hero gradient (Royal Blue to Deep Blue)
  static const LinearGradient heroLightGradient = LinearGradient(
    colors: [Color(0xFF1E3C72), Color(0xFF2A5298)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  /// Get hero card decoration with frosted glass effect
  static BoxDecoration heroCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      gradient: isDark ? heroDarkGradient : heroLightGradient,
      borderRadius: BorderRadius.circular(24),
      border: Border.all(
        color: Colors.white.withOpacity(0.15),
        width: 1.5,
      ),
      boxShadow: [
        BoxShadow(
          color:
              (isDark ? tealAccent : const Color(0xFF1E3C72)).withOpacity(0.3),
          blurRadius: 20,
          offset: const Offset(0, 10),
        ),
      ],
    );
  }

  /// Simple surface card (flat, no hero effect)
  static BoxDecoration surfaceCard(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? const Color(0xFF1E1E1E) : Colors.white,
      borderRadius: BorderRadius.circular(16),
      border: isDark ? Border.all(color: Colors.white.withOpacity(0.08)) : null,
      boxShadow: isDark
          ? null
          : [
              BoxShadow(
                color: Colors.black.withOpacity(0.05),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
    );
  }
}
