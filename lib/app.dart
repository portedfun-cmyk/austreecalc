import 'package:flutter/material.dart';
import 'widgets/main_screen.dart';

class AusTreeCalcApp extends StatelessWidget {
  const AusTreeCalcApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'AusTreeCalc – Advanced Tree Stability Modeller',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF0f0f1a),
        colorScheme: ColorScheme.dark(
          surface: const Color(0xFF1a1a2e),
          primary: const Color(0xFF6366f1),
          secondary: const Color(0xFF22d3ee),
          tertiary: const Color(0xFF4ade80),
          error: const Color(0xFFef4444),
          onSurface: Colors.white,
          outline: Colors.white.withOpacity(0.1),
        ),
        cardTheme: CardThemeData(
          color: const Color(0xFF1a1a2e),
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
            side: BorderSide(color: Colors.white.withOpacity(0.08)),
          ),
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: Color(0xFF0f0f1a),
          foregroundColor: Colors.white,
          elevation: 0,
          centerTitle: false,
          titleTextStyle: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
            color: Colors.white,
          ),
        ),
        inputDecorationTheme: InputDecorationTheme(
          filled: true,
          fillColor: Colors.white.withOpacity(0.05),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: const BorderSide(color: Color(0xFF6366f1), width: 2),
          ),
          labelStyle: TextStyle(color: Colors.white.withOpacity(0.7)),
          hintStyle: TextStyle(color: Colors.white.withOpacity(0.3)),
        ),
        sliderTheme: SliderThemeData(
          activeTrackColor: const Color(0xFF6366f1),
          inactiveTrackColor: Colors.white.withOpacity(0.1),
          thumbColor: const Color(0xFF6366f1),
          overlayColor: const Color(0xFF6366f1).withOpacity(0.2),
        ),
        chipTheme: ChipThemeData(
          backgroundColor: Colors.white.withOpacity(0.05),
          selectedColor: const Color(0xFF6366f1).withOpacity(0.3),
          labelStyle: const TextStyle(color: Colors.white),
          side: BorderSide(color: Colors.white.withOpacity(0.1)),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
        ),
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF6366f1),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            textStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15),
          ),
        ),
        textButtonTheme: TextButtonThemeData(
          style: TextButton.styleFrom(
            foregroundColor: const Color(0xFF6366f1),
          ),
        ),
        dropdownMenuTheme: DropdownMenuThemeData(
          inputDecorationTheme: InputDecorationTheme(
            filled: true,
            fillColor: Colors.white.withOpacity(0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: Colors.white.withOpacity(0.1)),
            ),
          ),
        ),
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          headlineMedium: TextStyle(fontWeight: FontWeight.w700, letterSpacing: -0.5),
          titleLarge: TextStyle(fontWeight: FontWeight.w600, fontSize: 20, letterSpacing: -0.3),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
          bodyLarge: TextStyle(fontSize: 15),
          bodyMedium: TextStyle(fontSize: 14),
        ),
        dividerTheme: DividerThemeData(
          color: Colors.white.withOpacity(0.08),
        ),
        checkboxTheme: CheckboxThemeData(
          fillColor: WidgetStateProperty.resolveWith((states) {
            if (states.contains(WidgetState.selected)) {
              return const Color(0xFF6366f1);
            }
            return Colors.transparent;
          }),
          side: BorderSide(color: Colors.white.withOpacity(0.3)),
        ),
      ),
      home: const AusTreeCalcMainScreen(),
    );
  }
}
