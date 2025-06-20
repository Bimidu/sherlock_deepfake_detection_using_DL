/**
 * Sherlock - AI-Powered Deepfake Video Detection App
 * 
 * Theme configuration using Material 3 design system.
 * Provides consistent light and dark themes with custom colors
 * and typography for the entire application.
 */

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'constants.dart';

class AppThemes {
  // Color Palette
  static const Color primaryColor = Color(0xFF6750A4);
  static const Color primaryContainer = Color(0xFFEADDFF);
  static const Color secondary = Color(0xFF625B71);
  static const Color secondaryContainer = Color(0xFFE8DEF8);
  static const Color tertiary = Color(0xFF7D5260);
  static const Color tertiaryContainer = Color(0xFFFFD8E4);
  
  // Surface Colors
  static const Color surface = Color(0xFFFEF7FF);
  static const Color surfaceVariant = Color(0xFFE7E0EC);
  static const Color background = Color(0xFFFEF7FF);
  
  // Semantic Colors
  static const Color success = Color(0xFF2E7D32);
  static const Color warning = Color(0xFFEF6C00);
  static const Color error = Color(0xFFD32F2F);
  static const Color info = Color(0xFF1976D2);
  
  // Text Colors
  static const Color onPrimary = Color(0xFFFFFFFF);
  static const Color onPrimaryContainer = Color(0xFF21005D);
  static const Color onSecondary = Color(0xFFFFFFFF);
  static const Color onSecondaryContainer = Color(0xFF1D192B);
  static const Color onSurface = Color(0xFF1C1B1F);
  static const Color onSurfaceVariant = Color(0xFF49454F);

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      
      // Color Scheme
      colorScheme: const ColorScheme.light(
        primary: primaryColor,
        primaryContainer: primaryContainer,
        secondary: secondary,
        secondaryContainer: secondaryContainer,
        tertiary: tertiary,
        tertiaryContainer: tertiaryContainer,
        surface: surface,
        surfaceVariant: surfaceVariant,
        background: background,
        error: error,
        onPrimary: onPrimary,
        onPrimaryContainer: onPrimaryContainer,
        onSecondary: onSecondary,
        onSecondaryContainer: onSecondaryContainer,
        onSurface: onSurface,
        onSurfaceVariant: onSurfaceVariant,
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: surface,
        foregroundColor: onSurface,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: onSurface,
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryColor,
          foregroundColor: onPrimary,
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: primaryColor,
          side: const BorderSide(color: primaryColor),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      
      // Text Button Theme
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primaryColor,
          padding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        color: surface,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surfaceVariant,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primaryColor, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: error, width: 1),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
      
      // Progress Indicator Theme
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: primaryColor,
        linearTrackColor: surfaceVariant,
        circularTrackColor: surfaceVariant,
      ),
      
      // Floating Action Button Theme
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: primaryColor,
        foregroundColor: onPrimary,
        elevation: 6,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(16)),
        ),
      ),
      
      // Bottom Navigation Bar Theme
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primaryColor,
        unselectedItemColor: onSurfaceVariant,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
      ),
      
      // Divider Theme
      dividerTheme: const DividerThemeData(
        color: surfaceVariant,
        thickness: 1,
        space: 16,
      ),
    );
  }

  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      
      // Color Scheme
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFFD0BCFF),
        primaryContainer: Color(0xFF4F378B),
        secondary: Color(0xFFCBC2DB),
        secondaryContainer: Color(0xFF4A4458),
        tertiary: Color(0xFFEFB8C8),
        tertiaryContainer: Color(0xFF633B48),
        surface: Color(0xFF1C1B1F),
        surfaceVariant: Color(0xFF49454F),
        background: Color(0xFF1C1B1F),
        error: Color(0xFFFFB4AB),
        onPrimary: Color(0xFF371E73),
        onPrimaryContainer: Color(0xFFEADDFF),
        onSecondary: Color(0xFF332D41),
        onSecondaryContainer: Color(0xFFE8DEF8),
        onSurface: Color(0xFFE6E1E5),
        onSurfaceVariant: Color(0xFFCAC4D0),
      ),
      
      // App Bar Theme
      appBarTheme: const AppBarTheme(
        backgroundColor: Color(0xFF1C1B1F),
        foregroundColor: Color(0xFFE6E1E5),
        elevation: 0,
        centerTitle: true,
        titleTextStyle: TextStyle(
          fontSize: 22,
          fontWeight: FontWeight.w500,
          color: Color(0xFFE6E1E5),
        ),
      ),
      
      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFD0BCFF),
          foregroundColor: const Color(0xFF371E73),
          padding: const EdgeInsets.symmetric(
            horizontal: 24,
            vertical: 12,
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          elevation: 2,
        ),
      ),
      
      // Card Theme
      cardTheme: const CardThemeData(
        color: Color(0xFF1C1B1F),
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.all(Radius.circular(12)),
        ),
      ),
      
      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF49454F),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: Color(0xFFD0BCFF), 
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 12,
        ),
      ),
    );
  }

  /// Custom color extensions for semantic colors
  static const Map<String, Color> semanticColors = {
    'success': success,
    'warning': warning,
    'error': error,
    'info': info,
  };

  /// Get confidence color based on value
  static Color getConfidenceColor(double confidence) {
    if (confidence >= 0.8) {
      return success;
    } else if (confidence >= 0.6) {
      return warning;
    } else {
      return error;
    }
  }

  /// Get result color based on detection result
  static Color getResultColor(String result) {
    switch (result.toLowerCase()) {
      case 'real':
        return success;
      case 'fake':
      case 'ai-generated':
        return error;
      default:
        return warning;
    }
  }
}

/// Custom colors for specific use cases
class AppColors {
  // Success colors
  static const success = Color(0xFF4CAF50);
  static const successLight = Color(0xFFE8F5E8);
  static const successDark = Color(0xFF2E7D32);

  // Warning colors
  static const warning = Color(0xFFFF9800);
  static const warningLight = Color(0xFFFFF3E0);
  static const warningDark = Color(0xFFE65100);

  // Info colors
  static const info = Color(0xFF2196F3);
  static const infoLight = Color(0xFFE3F2FD);
  static const infoDark = Color(0xFF0D47A1);

  // Confidence level colors
  static const highConfidence = Color(0xFF4CAF50);
  static const mediumConfidence = Color(0xFFFF9800);
  static const lowConfidence = Color(0xFFF44336);

  // Prediction colors
  static const realPrediction = Color(0xFF4CAF50);
  static const fakePrediction = Color(0xFFF44336);

  // Neutral colors
  static const neutral100 = Color(0xFFF5F5F5);
  static const neutral200 = Color(0xFFEEEEEE);
  static const neutral300 = Color(0xFFE0E0E0);
  static const neutral400 = Color(0xFFBDBDBD);
  static const neutral500 = Color(0xFF9E9E9E);
  static const neutral600 = Color(0xFF757575);
  static const neutral700 = Color(0xFF616161);
  static const neutral800 = Color(0xFF424242);
  static const neutral900 = Color(0xFF212121);
}

/// Custom text styles for specific components
class AppTextStyles {
  static const headline = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const subheadline = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    height: 1.3,
  );

  static const body = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.4,
  );

  static const caption = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.3,
  );

  static const button = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
  );

  static const confidence = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );

  static const prediction = TextStyle(
    fontSize: 20,
    fontWeight: FontWeight.bold,
    height: 1.2,
  );
} 