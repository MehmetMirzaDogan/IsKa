import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum AppThemeMode {
  light,
  dark,
  tokyoDark,
}

class ThemeService extends ChangeNotifier {
  static final ThemeService instance = ThemeService._init();
  ThemeService._init();

  static const String _themeKey = 'app_theme';
  static const String _accentColorKey = 'accent_color';

  AppThemeMode _themeMode = AppThemeMode.light;
  int _accentColorIndex = 0;

  AppThemeMode get themeMode => _themeMode;
  int get accentColorIndex => _accentColorIndex;

  static const List<AccentColorPalette> accentPalettes = [
    AccentColorPalette(
      name: 'Mavi',
      light: Color(0xFF1976D2),
      dark: Color(0xFF64B5F6),
      tokyo: Color(0xFF7AA2F7),
    ),
    AccentColorPalette(
      name: 'Yeşil',
      light: Color(0xFF388E3C),
      dark: Color(0xFF81C784),
      tokyo: Color(0xFF9ECE6A),
    ),
    AccentColorPalette(
      name: 'Mor',
      light: Color(0xFF7B1FA2),
      dark: Color(0xFFBA68C8),
      tokyo: Color(0xFFBB9AF7),
    ),
    AccentColorPalette(
      name: 'Turuncu',
      light: Color(0xFFE65100),
      dark: Color(0xFFFFB74D),
      tokyo: Color(0xFFFF9E64),
    ),
    AccentColorPalette(
      name: 'Kırmızı',
      light: Color(0xFFD32F2F),
      dark: Color(0xFFE57373),
      tokyo: Color(0xFFF7768E),
    ),
    AccentColorPalette(
      name: 'Cyan',
      light: Color(0xFF0097A7),
      dark: Color(0xFF4DD0E1),
      tokyo: Color(0xFF7DCFFF),
    ),
    AccentColorPalette(
      name: 'Pembe',
      light: Color(0xFFC2185B),
      dark: Color(0xFFF06292),
      tokyo: Color(0xFFFF007C),
    ),
    AccentColorPalette(
      name: 'Amber',
      light: Color(0xFFFFA000),
      dark: Color(0xFFFFD54F),
      tokyo: Color(0xFFE0AF68),
    ),
  ];

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    final themeIndex = prefs.getInt(_themeKey) ?? 0;
    _themeMode = AppThemeMode.values[themeIndex.clamp(0, AppThemeMode.values.length - 1)];
    _accentColorIndex = prefs.getInt(_accentColorKey) ?? 0;
    _accentColorIndex = _accentColorIndex.clamp(0, accentPalettes.length - 1);
    notifyListeners();
  }

  Future<void> setThemeMode(AppThemeMode mode) async {
    _themeMode = mode;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_themeKey, mode.index);
    notifyListeners();
  }

  Future<void> setAccentColor(int index) async {
    _accentColorIndex = index.clamp(0, accentPalettes.length - 1);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_accentColorKey, _accentColorIndex);
    notifyListeners();
  }

  Color get currentAccentColor {
    final palette = accentPalettes[_accentColorIndex];
    switch (_themeMode) {
      case AppThemeMode.light:
        return palette.light;
      case AppThemeMode.dark:
        return palette.dark;
      case AppThemeMode.tokyoDark:
        return palette.tokyo;
    }
  }

  AccentColorPalette get currentPalette => accentPalettes[_accentColorIndex];

  ThemeData get currentTheme {
    switch (_themeMode) {
      case AppThemeMode.light:
        return _buildLightTheme();
      case AppThemeMode.dark:
        return _buildDarkTheme();
      case AppThemeMode.tokyoDark:
        return _buildTokyoDarkTheme();
    }
  }

  ThemeData _buildLightTheme() {
    final accent = accentPalettes[_accentColorIndex].light;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: accent,
        secondary: accent,
        surface: Colors.white,
        error: Colors.red.shade700,
      ),
      scaffoldBackgroundColor: const Color(0xFFF5F5F5),
      appBarTheme: AppBarTheme(
        backgroundColor: accent,
        foregroundColor: Colors.white,
        elevation: 2,
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 2,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.white,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.white,
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent.withOpacity(0.5);
          return Colors.grey.withOpacity(0.3);
        }),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        inputDecorationTheme: InputDecorationTheme(
          focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: accent),
          ),
        ),
      ),
    );
  }

  ThemeData _buildDarkTheme() {
    final accent = accentPalettes[_accentColorIndex].dark;
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: const Color(0xFF1E1E1E),
        error: Colors.red.shade300,
      ),
      scaffoldBackgroundColor: const Color(0xFF121212),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF1E1E1E),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF2D2D2D),
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: Colors.black,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: Colors.black,
        ),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: Color(0xFF2D2D2D),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: Colors.grey.shade600),
        ),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return Colors.grey;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent.withOpacity(0.5);
          return Colors.grey.withOpacity(0.3);
        }),
      ),
    );
  }

  ThemeData _buildTokyoDarkTheme() {
    final accent = accentPalettes[_accentColorIndex].tokyo;
    const tokyoBg = Color(0xFF1A1B26);
    const tokyoSurface = Color(0xFF24283B);
    const tokyoText = Color(0xFFC0CAF5);
    const tokyoSubtext = Color(0xFF565F89);
    
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: accent,
        secondary: accent,
        surface: tokyoSurface,
        onSurface: tokyoText,
        error: const Color(0xFFF7768E),
      ),
      scaffoldBackgroundColor: tokyoBg,
      appBarTheme: AppBarTheme(
        backgroundColor: tokyoSurface,
        foregroundColor: tokyoText,
        elevation: 0,
      ),
      cardTheme: CardThemeData(
        color: tokyoSurface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: tokyoSubtext.withOpacity(0.3)),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: accent,
        foregroundColor: tokyoBg,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: accent,
          foregroundColor: tokyoBg,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: accent),
      ),
      dialogTheme: const DialogThemeData(
        backgroundColor: tokyoSurface,
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: tokyoSurface,
        contentTextStyle: const TextStyle(color: tokyoText),
      ),
      inputDecorationTheme: InputDecorationTheme(
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: accent, width: 2),
        ),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: tokyoSubtext),
        ),
        labelStyle: TextStyle(color: tokyoSubtext),
        hintStyle: TextStyle(color: tokyoSubtext),
      ),
      iconTheme: IconThemeData(color: tokyoText),
      listTileTheme: ListTileThemeData(
        textColor: tokyoText,
        iconColor: accent,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent;
          return tokyoSubtext;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return accent.withOpacity(0.5);
          return tokyoSubtext.withOpacity(0.3);
        }),
      ),
      dividerTheme: DividerThemeData(color: tokyoSubtext.withOpacity(0.3)),
      textTheme: const TextTheme(
        bodyLarge: TextStyle(color: tokyoText),
        bodyMedium: TextStyle(color: tokyoText),
        bodySmall: TextStyle(color: tokyoSubtext),
        titleLarge: TextStyle(color: tokyoText),
        titleMedium: TextStyle(color: tokyoText),
        titleSmall: TextStyle(color: tokyoText),
        labelLarge: TextStyle(color: tokyoText),
        labelMedium: TextStyle(color: tokyoSubtext),
        labelSmall: TextStyle(color: tokyoSubtext),
      ),
    );
  }

  String get themeModeName {
    switch (_themeMode) {
      case AppThemeMode.light:
        return 'Aydınlık';
      case AppThemeMode.dark:
        return 'Karanlık';
      case AppThemeMode.tokyoDark:
        return 'Tokyo Night';
    }
  }

  IconData get themeModeIcon {
    switch (_themeMode) {
      case AppThemeMode.light:
        return Icons.light_mode;
      case AppThemeMode.dark:
        return Icons.dark_mode;
      case AppThemeMode.tokyoDark:
        return Icons.nightlight_round;
    }
  }
}

class AccentColorPalette {
  final String name;
  final Color light;
  final Color dark;
  final Color tokyo;

  const AccentColorPalette({
    required this.name,
    required this.light,
    required this.dark,
    required this.tokyo,
  });

  Color getColor(AppThemeMode mode) {
    switch (mode) {
      case AppThemeMode.light:
        return light;
      case AppThemeMode.dark:
        return dark;
      case AppThemeMode.tokyoDark:
        return tokyo;
    }
  }
}
