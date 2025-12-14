import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../services/theme_service.dart';
import 'home_screen.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _nameController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    setState(() => _isLoading = true);

    final success = await AuthService.instance.register(
      _usernameController.text.trim(),
      _passwordController.text,
      _nameController.text.trim(),
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (success) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeScreen()),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Bu kullanıcı adı zaten kullanılıyor!'),
          backgroundColor: Theme.of(context).colorScheme.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;
    final themeMode = ThemeService.instance.themeMode;
    final isDark = theme.brightness == Brightness.dark;
    
    List<Color> gradientColors;
    Color cardColor;
    Color textColor;
    Color subtitleColor;
    
    switch (themeMode) {
      case AppThemeMode.light:
        gradientColors = [
          colorScheme.primary.withOpacity(0.8),
          colorScheme.primary,
        ];
        cardColor = Colors.white;
        textColor = Colors.white;
        subtitleColor = Colors.white70;
        break;
      case AppThemeMode.dark:
        gradientColors = [
          const Color(0xFF1E1E1E),
          const Color(0xFF121212),
        ];
        cardColor = const Color(0xFF2D2D2D);
        textColor = Colors.white;
        subtitleColor = Colors.white70;
        break;
      case AppThemeMode.tokyoDark:
        gradientColors = [
          const Color(0xFF24283B),
          const Color(0xFF1A1B26),
        ];
        cardColor = const Color(0xFF24283B);
        textColor = const Color(0xFFC0CAF5);
        subtitleColor = const Color(0xFF565F89);
        break;
    }
    
    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: gradientColors,
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 120,
                        height: 120,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Kayıt Ol',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: isDark ? textColor : Colors.white,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Yeni bir hesap oluşturun',
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? subtitleColor : Colors.white70,
                      ),
                    ),
                    const SizedBox(height: 32),
                    Card(
                      elevation: isDark ? 0 : 8,
                      color: cardColor,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                        side: isDark
                            ? BorderSide(color: colorScheme.primary.withOpacity(0.3))
                            : BorderSide.none,
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          children: [
                            TextFormField(
                              controller: _nameController,
                              decoration: InputDecoration(
                                labelText: 'Ad Soyad',
                                prefixIcon: Icon(Icons.badge, color: colorScheme.primary),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.name,
                              textCapitalization: TextCapitalization.words,
                              enableSuggestions: true,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Ad soyad gerekli';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _usernameController,
                              decoration: InputDecoration(
                                labelText: 'Kullanıcı Adı',
                                prefixIcon: Icon(Icons.person, color: colorScheme.primary),
                                border: const OutlineInputBorder(),
                              ),
                              keyboardType: TextInputType.text,
                              enableSuggestions: false,
                              autocorrect: false,
                              textInputAction: TextInputAction.next,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Kullanıcı adı gerekli';
                                }
                                if (value.length < 3) {
                                  return 'Kullanıcı adı en az 3 karakter olmalı';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 16),
                            TextFormField(
                              controller: _passwordController,
                              decoration: InputDecoration(
                                labelText: 'Şifre',
                                prefixIcon: Icon(Icons.lock, color: colorScheme.primary),
                                border: const OutlineInputBorder(),
                              ),
                              obscureText: true,
                              keyboardType: TextInputType.visiblePassword,
                              enableSuggestions: false,
                              autocorrect: false,
                              textInputAction: TextInputAction.done,
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Şifre gerekli';
                                }
                                if (value.length < 6) {
                                  return 'Şifre en az 6 karakter olmalı';
                                }
                                return null;
                              },
                            ),
                            const SizedBox(height: 24),
                            SizedBox(
                              width: double.infinity,
                              height: 50,
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _register,
                                child: _isLoading
                                    ? SizedBox(
                                        height: 20,
                                        width: 20,
                                        child: CircularProgressIndicator(
                                          strokeWidth: 2,
                                          color: isDark ? colorScheme.primary : Colors.white,
                                        ),
                                      )
                                    : const Text(
                                        'Kayıt Ol',
                                        style: TextStyle(fontSize: 16),
                                      ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: () {
                        Navigator.of(context).pop();
                      },
                      child: Text(
                        'Zaten hesabınız var mı? Giriş Yapın',
                        style: TextStyle(
                          color: isDark ? colorScheme.primary : Colors.white,
                          fontSize: 16,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
