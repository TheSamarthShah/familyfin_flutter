import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// 1. DEFINE THE APP TYPES
enum FoundationAppType { 
  finance, // Deep Purple (Original)
  ally     // Slate Blue (New Planner)
}

class AppTheme {
  // ===========================================================================
  // 🎨 CONFIGURATION (The Magic Switch)
  // ===========================================================================
  
  // Call this method in your main.dart to get the correct theme
  static ThemeData getTheme({
    required FoundationAppType type, 
    required Brightness brightness
  }) {
    // 1. Pick the Seed Color based on the App
    final seedColor = type == FoundationAppType.finance 
        ? Colors.deepPurple  // Finance Identity
        : const Color(0xFF3B82F6); // Ally Identity (Blue)

    return _buildTheme(seedColor, brightness);
  }

  // ===========================================================================
  // 🌈 SEMANTIC COLORS (Shared Helpers)
  // ===========================================================================
  // Use these in your UI code like: AppTheme.expenseColor
  
  static const Color expenseColor = Colors.pink;   // Bright Red/Pink
  static const Color incomeColor = Colors.green;   // Standard Green
  static const Color actionColor = Color(0xFFFFC107); // Amber (Warnings/Stars)
  static const Color allyAccent = Color(0xFF0F172A);  // Slate 900 (Strong headers)

  // ===========================================================================
  // 🏗 CORE THEME BUILDER (Private)
  // ===========================================================================
  static ThemeData _buildTheme(Color seedColor, Brightness brightness) {
    final isDark = brightness == Brightness.dark;

    // 1. Define Base Colors
    // Dark Mode: Custom "Dark Grey" palette (Not pitch black)
    const Color bgDark = Color(0xFF121212);
    const Color surfaceDark = Color(0xFF1E1E1E);
    const Color inputDark = Color(0xFF2C2C2C);
    
    // Light Mode: Standard off-white
    const Color bgLight = Colors.white;
    const Color surfaceLight = Colors.white;
    final Color inputLight = Colors.grey[50]!;

    final baseColorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
      surface: isDark ? surfaceDark : surfaceLight,
      error: isDark ? const Color(0xFFCF6679) : Colors.red,
    );

    // 2. BUILD THEME DATA
    return ThemeData(
      useMaterial3: true,
      colorScheme: baseColorScheme,
      scaffoldBackgroundColor: isDark ? bgDark : bgLight,

      // A. TYPOGRAPHY (Google Fonts Inter)
      textTheme: GoogleFonts.interTextTheme(
        isDark ? ThemeData.dark().textTheme : ThemeData.light().textTheme
      ).copyWith(
        // Body: Readable, Tabular Figures for numbers
        bodyMedium: GoogleFonts.inter(
          fontFeatures: [const FontFeature.tabularFigures()], 
          color: isDark ? Colors.white.withOpacity(0.87) : Colors.black87,
        ),
        // Titles: Colored by the Brand (Purple for Finance, Blue for Ally)
        titleLarge: GoogleFonts.inter(
          fontWeight: FontWeight.bold,
          color: isDark ? baseColorScheme.primary : seedColor, 
        ),
      ),

      // B. CARDS (Floating Islands)
      cardTheme: CardThemeData(
        color: isDark ? surfaceDark : surfaceLight,
        elevation: isDark ? 4 : 2, // Higher elevation in dark mode for visibility
        shadowColor: Colors.black.withOpacity(isDark ? 0.5 : 0.1),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        margin: EdgeInsets.zero,
      ),

      // C. INPUT FIELDS (Consistent "Cutout" Look)
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? inputDark : inputLight,
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        
        // Idle Border
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? Colors.grey[800]! : Colors.grey[300]!
          ),
        ),
        
        // Focused Border (Brand Color Glow)
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: baseColorScheme.primary, width: 2),
        ),
        
        labelStyle: TextStyle(color: isDark ? Colors.grey[400] : Colors.grey),
        prefixIconColor: isDark ? Colors.grey[500] : Colors.grey[600],
      ),

      // D. BUTTONS (Pill Shape)
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: baseColorScheme.primary,
          foregroundColor: baseColorScheme.onPrimary,
          elevation: isDark ? 2 : 0,
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.bold),
        ),
      ),

      // E. APP BAR (Clean & Simple)
      appBarTheme: AppBarTheme(
        backgroundColor: isDark ? bgDark : bgLight,
        elevation: 0,
        centerTitle: true,
        iconTheme: IconThemeData(
          color: isDark ? Colors.white : Colors.black87
        ),
        titleTextStyle: GoogleFonts.inter(
          color: isDark ? Colors.white : Colors.black87,
          fontSize: 20,
          fontWeight: FontWeight.bold
        ),
      ),
    );
  }
}