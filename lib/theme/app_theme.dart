import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class ThemeConfig {
  final String baseTheme;
  final String accentColor;

  ThemeConfig({required this.baseTheme, required this.accentColor});

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ThemeConfig &&
          runtimeType == other.runtimeType &&
          baseTheme == other.baseTheme &&
          accentColor == other.accentColor;

  @override
  int get hashCode => baseTheme.hashCode ^ accentColor.hashCode;
}

class AppTheme {
  static ThemeData getTheme(ThemeConfig config) {
    Color primary;
    switch (config.accentColor) {
      case 'gold': primary = const Color(0xFFEBC137); break;
      case 'green': primary = const Color(0xFF43A047); break;
      case 'red': primary = const Color(0xFFE53935); break;
      case 'blue':
      default: primary = Colors.blueAccent; break;
    }

    Color scaffoldBg;
    Color surfaceColor;
    Brightness brightness;

    switch (config.baseTheme) {
      case 'light':
        brightness = Brightness.light;
        scaffoldBg = const Color(0xFFF0F2F5); 
        surfaceColor = Colors.white;          
        break;
      case 'oled':
        brightness = Brightness.dark;
        scaffoldBg = Colors.black;            
        surfaceColor = const Color(0xFF121212);
        break;
      case 'dark':
      default:
        brightness = Brightness.dark;
        scaffoldBg = const Color(0xFF0D1117); 
        surfaceColor = const Color(0xFF161B22);
        break;
    }

    final isLight = brightness == Brightness.light;
    final useBlackTextOnPrimary = config.accentColor == 'gold';

    return ThemeData(
      brightness: brightness,
      primaryColor: primary,
      scaffoldBackgroundColor: scaffoldBg,
      useMaterial3: true,
      
      pageTransitionsTheme: const PageTransitionsTheme(
        builders: {
          TargetPlatform.android: FadeUpwardsPageTransitionsBuilder(),
          TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
        },
      ),

      textTheme: GoogleFonts.interTextTheme(
        isLight ? ThemeData.light().textTheme : ThemeData.dark().textTheme
      ),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primary,
        brightness: brightness,
        primary: primary,
        surface: surfaceColor,
        onSurface: isLight ? Colors.black87 : Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: primary,
        foregroundColor: useBlackTextOnPrimary ? Colors.black : Colors.white,
        elevation: 0,
        iconTheme: IconThemeData(
          color: useBlackTextOnPrimary ? Colors.black : Colors.white,
        ),
        titleTextStyle: GoogleFonts.inter(
          fontSize: 20,
          fontWeight: FontWeight.bold,
          color: useBlackTextOnPrimary ? Colors.black : Colors.white,
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: useBlackTextOnPrimary ? Colors.black : Colors.white,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: isLight ? Colors.grey[600] : Colors.grey[400],
        textColor: isLight ? Colors.black87 : Colors.white,
        subtitleTextStyle: TextStyle(
          color: isLight ? Colors.grey[600] : Colors.grey[400], 
          fontSize: 13
        ),
      ),
      dividerColor: isLight ? Colors.black12 : Colors.white10,
    );
  }
}