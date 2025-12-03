import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class AppTheme {
  // 🎨 CONFIGURATION: Change these for your next app
  // Changed from deepPurple to a refreshing teal/blue.
  static const Color _seedColor = Colors.deepPurple; // Teal Blue

  // New specific status colors
  //static get expenseColor => const Color(0xFFE53935); // Bright Red/Coral
  static get expenseColor => Colors.pink; // Bright Red/Coral
  //static get incomeColor => const Color(0xFF4CAF50); // Standard Green
  static get incomeColor => Colors.green; // Standard Green
  static get actionColor => const Color(0xFFFFC107); // Amber/Yellow for required actions

  // ---------------------------------------------------------------------------
  // ☀️ LIGHT THEME
  // ---------------------------------------------------------------------------
  static ThemeData get light {
    return ThemeData(
      useMaterial3: true,
      colorScheme: ColorScheme.fromSeed(
        seedColor: _seedColor,
        brightness: Brightness.light,
      ),

      // ✅ CHANGED: Using Google Fonts (Roboto)
      textTheme: GoogleFonts.interTextTheme().copyWith(
        // Use 'Inter' or 'Lato' - excellent for screens
        bodyMedium: GoogleFonts.inter(
          fontFeatures: [const FontFeature.tabularFigures()], // ALIGNS NUMBERS!
          color: Colors.black87,
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: _seedColor, // Brand color for headers
        ),
      ),

      // Standardize Input Fields (TextFormFields)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.grey[50],
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey[300]!),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: _seedColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Colors.grey),
        prefixIconColor: Colors.grey[600],
      ),

      // Standardize Buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _seedColor,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // Standardize App Bar
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(color: Colors.black87),
        titleTextStyle: TextStyle(
          color: Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  // ---------------------------------------------------------------------------
  // 🌙 DARK THEME
  // ---------------------------------------------------------------------------
  static ThemeData get dark {
    // 1. Base Colors: Define the "Dark Grey" palette
    const Color bgDark = Color(0xFF121212); // Standard Material Dark Bg
    const Color surfaceDark = Color(0xFF1E1E1E); // Slightly lighter for Cards
    const Color inputDark = Color(0xFF2C2C2C); // Even lighter for Input fields

    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: _seedColor, // Keeps branding, but M3 auto-adjusts brightness
      brightness: Brightness.dark,
      surface: surfaceDark,
      // Error color in dark mode should be salmon/pink, not bright red
      error: const Color(0xFFCF6679), 
    );

    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: bgDark, // Critical for consistent look

      // 2. TYPOGRAPHY: Must match Light Mode's quality
      textTheme: GoogleFonts.interTextTheme(ThemeData.dark().textTheme).copyWith(
        bodyMedium: GoogleFonts.inter(
          fontFeatures: [const FontFeature.tabularFigures()], // KEEP ALIGNMENT
          color: Colors.white.withOpacity(0.87), // Standard high-emphasis text
        ),
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: baseColorScheme.primary, // Use the softer, pastel purple
        ),
      ),

      // 3. CARDS: Floating Islands
      // In dark mode, shadows are less visible, so we rely on color difference
      cardTheme: CardThemeData(
        color: surfaceDark,
        elevation: 4,
        shadowColor: Colors.black.withOpacity(0.5), // Darker, stronger shadow
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),

      // 4. INPUT FIELDS: "Cutouts" in the surface
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: inputDark, // Lightest grey to invite interaction
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        
        // Idle Border (Subtle)
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: Colors.grey[800]!),
        ),
        
        // Focused Border (Glow effect)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseColorScheme.primary, width: 2),
        ),
        
        labelStyle: TextStyle(color: Colors.grey[400]),
        prefixIconColor: Colors.grey[500],
      ),

      // 5. BUTTONS: Consistent with Light Mode but adjusted for glare
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColorScheme.primary, // Pastel Purple
          foregroundColor: baseColorScheme.onPrimary, // Black or dark text usually
          elevation: 2,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // 6. APP BAR: Blend with background
      appBarTheme: AppBarTheme(
        backgroundColor: bgDark,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.white),
        titleTextStyle: GoogleFonts.inter(
          color: Colors.white, 
          fontSize: 20, 
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}