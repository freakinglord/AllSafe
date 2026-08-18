import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'state/safe_state.dart';
import 'screens/home_screen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SafeState(),
      child: const AllSafeApp(),
    ),
  );
}

class AllSafeApp extends StatelessWidget {
  const AllSafeApp({super.key});

  @override
  Widget build(BuildContext context) {
    final isDark = context.select<SafeState, bool>((s) => s.isDark);
    return MaterialApp(
      title: 'AllSafe',
      debugShowCheckedModeBanner: false,
      theme: _buildTheme(Brightness.light),
      darkTheme: _buildTheme(Brightness.dark),
      themeMode: isDark ? ThemeMode.dark : ThemeMode.light,
      home: const HomeScreen(),
    );
  }

  ThemeData _buildTheme(Brightness brightness) {
    final isLight = brightness == Brightness.light;
    final blue = isLight ? const Color(0xFF2B4D8C) : const Color(0xFF4A79C4);
    final bg = isLight ? const Color(0xFFF0F0F0) : const Color(0xFF0D1117);
    final surface = isLight ? const Color(0xFFFFFFFF) : const Color(0xFF161C24);
    final border = isLight ? const Color(0xFFDDDDDD) : const Color(0xFF20293A);
    final textPrimary = isLight ? const Color(0xFF0D0D0D) : const Color(0xFFE8EEF6);
    final textMuted = isLight ? const Color(0xFF666666) : const Color(0xFF6B7A8D);
    final snackBarBg = isLight ? const Color(0xFFE5E5EA) : const Color(0xFF1A2233);
    final errorColor = isLight ? const Color(0xFFFF3B30) : const Color(0xFFFF453A);

    return ThemeData(
      brightness: brightness,
      scaffoldBackgroundColor: bg,
      colorScheme: isLight
          ? ColorScheme.light(primary: blue, surface: surface, onSurface: textPrimary, onPrimary: Colors.white)
          : ColorScheme.dark(primary: blue, surface: surface, onSurface: textPrimary, onPrimary: Colors.white),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        titleTextStyle: TextStyle(
          color: textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.w600,
          letterSpacing: 0.5,
        ),
        iconTheme: IconThemeData(color: textMuted),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: blue,
          foregroundColor: Colors.white,
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5, fontSize: 15),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: blue,
          side: BorderSide(color: blue),
          minimumSize: const Size.fromHeight(48),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          textStyle: const TextStyle(fontWeight: FontWeight.w600, letterSpacing: 0.5, fontSize: 15),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: blue,
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
        enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: border)),
        focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: blue, width: 1.5)),
        errorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: errorColor)),
        focusedErrorBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: BorderSide(color: errorColor, width: 1.5)),
        labelStyle: TextStyle(color: textMuted, fontSize: 14),
        hintStyle: TextStyle(color: textMuted, fontSize: 14),
        errorStyle: TextStyle(color: errorColor, fontSize: 12),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: blue,
        foregroundColor: Colors.white,
        elevation: 2,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(14))),
      ),
      listTileTheme: ListTileThemeData(
        tileColor: Colors.transparent,
        textColor: textPrimary,
        subtitleTextStyle: TextStyle(color: textMuted, fontSize: 13),
        minLeadingWidth: 0,
      ),
      dividerTheme: DividerThemeData(color: border, thickness: 1, space: 1),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: snackBarBg,
        contentTextStyle: TextStyle(color: textPrimary, fontSize: 14),
        behavior: SnackBarBehavior.floating,
        shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(8))),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        titleTextStyle: TextStyle(color: textPrimary, fontSize: 17, fontWeight: FontWeight.w600),
        contentTextStyle: TextStyle(color: textMuted, fontSize: 14, height: 1.5),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: blue),
      iconTheme: IconThemeData(color: textMuted, size: 20),
      textTheme: TextTheme(
        bodyLarge: TextStyle(color: textPrimary, fontSize: 16, height: 1.5),
        bodyMedium: TextStyle(color: textPrimary, fontSize: 14, height: 1.5),
        bodySmall: TextStyle(color: textMuted, fontSize: 12),
        headlineMedium: TextStyle(color: textPrimary, fontSize: 24, fontWeight: FontWeight.bold),
        titleMedium: TextStyle(color: textPrimary, fontSize: 16, fontWeight: FontWeight.w600),
        labelSmall: TextStyle(color: textMuted, fontSize: 11, letterSpacing: 1.0, fontWeight: FontWeight.w500),
      ),
    );
  }
}
