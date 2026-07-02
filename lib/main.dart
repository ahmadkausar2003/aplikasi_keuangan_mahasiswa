import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'presentation/providers/theme_provider.dart';
import 'presentation/screens/main_screen.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Mengatur warna status bar agar menyatu dengan aplikasi
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      systemNavigationBarColor: Colors.transparent,
    ),
  );

  runApp(
    // ProviderScope wajib ada di akar aplikasi agar Riverpod bisa bekerja
    const ProviderScope(
      child: SmartStudentFinanceApp(),
    ),
  );
}

class SmartStudentFinanceApp extends ConsumerWidget {
  const SmartStudentFinanceApp({super.key});

  // --- PALET WARNA UTAMA ---
  // Emerald Green yang modern, segar, dan kontrasnya tinggi
  static const Color primaryEmerald = Color(0xFF10B981); 
  
  // Warna Latar & Kartu (Light Mode - Bright & Crisp)
  static const Color backgroundLight = Color(0xFFF8F9FA); // Sedikit lebih cerah/hangat dari off-white biasa
  static const Color surfaceLight = Colors.white; // Pure White untuk kartu agar pop-up
  
  // Warna Latar & Kartu (Dark Mode - Matte & Deep)
  static const Color backgroundDark = Color(0xFF121212); // Standar OLED Matte Dark
  static const Color surfaceDark = Color(0xFF1E1E1E); // Elevated Matte Gray untuk kartu

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mendengarkan perubahan tema dari themeProvider
    final themeMode = ref.watch(themeProvider);

    return MaterialApp(
      title: 'SmartStudent Finance',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      
      // ==========================================
      // PENGATURAN TEMA TERANG (LIGHT MODE)
      // ==========================================
      theme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundLight,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryEmerald,
          primary: primaryEmerald,
          surface: surfaceLight,
          brightness: Brightness.light,
          // Menyesuaikan warna onSurface agar teks hitamnya elegan
          onSurface: const Color(0xFF1A1A1A), 
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundLight,
          surfaceTintColor: Colors.transparent, // Mencegah warna berubah saat di-scroll
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFF1A1A1A)),
          titleTextStyle: TextStyle(
            color: Color(0xFF1A1A1A),
            fontSize: 20,
            fontWeight: FontWeight.w700, // Sedikit lebih tebal untuk kesan kokoh
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceLight,
          elevation: 0, // Neumorphism ringan ditangani di Container masing-masing widget
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24), // Melengkung lebih halus (premium)
            side: const BorderSide(color: Color(0xFFF1F5F9), width: 1.5), // Border sangat tipis
          ),
        ),
        fontFamily: 'Roboto', // Bisa diganti 'Poppins' atau 'Inter' jika Anda mau
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: Color(0xFF1A1A1A), letterSpacing: -1.0),
          titleLarge: TextStyle(fontWeight: FontWeight.w700, color: Color(0xFF1A1A1A), letterSpacing: -0.5),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFF1A1A1A)),
          bodyLarge: TextStyle(color: Color(0xFF475569)), // Teks body abu-abu gelap
          bodyMedium: TextStyle(color: Color(0xFF64748B)),
        ),
        // Membuat animasi sentuhan (Ripple) lebih halus
        splashFactory: InkSparkle.splashFactory,
      ),

      // ==========================================
      // PENGATURAN TEMA GELAP (DARK MODE)
      // ==========================================
      darkTheme: ThemeData(
        useMaterial3: true,
        scaffoldBackgroundColor: backgroundDark,
        colorScheme: ColorScheme.fromSeed(
          seedColor: primaryEmerald,
          primary: primaryEmerald,
          surface: surfaceDark,
          brightness: Brightness.dark,
          onSurface: const Color(0xFFF8FAFC), // Putih keabu-abuan agar tidak menyilaukan
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: backgroundDark,
          surfaceTintColor: Colors.transparent,
          elevation: 0,
          centerTitle: true,
          iconTheme: IconThemeData(color: Color(0xFFF8FAFC)),
          titleTextStyle: TextStyle(
            color: Color(0xFFF8FAFC),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.5,
          ),
        ),
        cardTheme: CardThemeData(
          color: surfaceDark,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
            side: const BorderSide(color: Color(0xFF2D2D2D), width: 1), // Garis pembatas gelap elegan
          ),
        ),
        fontFamily: 'Roboto',
        textTheme: const TextTheme(
          headlineLarge: TextStyle(fontWeight: FontWeight.w800, color: Colors.white, letterSpacing: -1.0),
          titleLarge: TextStyle(fontWeight: FontWeight.w700, color: Colors.white, letterSpacing: -0.5),
          titleMedium: TextStyle(fontWeight: FontWeight.w600, color: Color(0xFFF8FAFC)),
          bodyLarge: TextStyle(color: Color(0xFFCBD5E1)),
          bodyMedium: TextStyle(color: Color(0xFF94A3B8)),
        ),
        splashFactory: InkSparkle.splashFactory,
      ),
      
      home: const MainScreen(),
    );
  }
}