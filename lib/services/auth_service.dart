import 'package:shared_preferences/shared_preferences.dart';
import '../models/user.dart';
import 'database_service.dart';

class AuthService {
  static final AuthService instance = AuthService._init();
  AuthService._init();

  static const String _userIdKey = 'user_id';
  static const String _usernameKey = 'username';
  static const String _nameKey = 'name';
  static const String _rememberMeKey = 'remember_me';
  static const String _savedUsernameKey = 'saved_username';
  static const String _savedPasswordKey = 'saved_password';

  User? _currentUser;
  bool _rememberMe = false;

  User? get currentUser => _currentUser;
  bool get rememberMe => _rememberMe;

  Future<void> init() async {
    final prefs = await SharedPreferences.getInstance();
    _rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    
    final userId = prefs.getInt(_userIdKey);
    final username = prefs.getString(_usernameKey);
    final name = prefs.getString(_nameKey);

    if (userId != null && username != null && name != null) {
      _currentUser = User(
        id: userId,
        username: username,
        password: '',
        name: name,
        createdAt: DateTime.now(),
      );
    }
  }

  Future<Map<String, String>?> getSavedCredentials() async {
    final prefs = await SharedPreferences.getInstance();
    final rememberMe = prefs.getBool(_rememberMeKey) ?? false;
    
    if (rememberMe) {
      final username = prefs.getString(_savedUsernameKey);
      final password = prefs.getString(_savedPasswordKey);
      
      if (username != null && password != null) {
        return {'username': username, 'password': password};
      }
    }
    return null;
  }

  Future<void> setRememberMe(bool value) async {
    _rememberMe = value;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_rememberMeKey, value);
    
    if (!value) {
      await prefs.remove(_savedUsernameKey);
      await prefs.remove(_savedPasswordKey);
    }
  }

  Future<bool> register(String username, String password, String name) async {
    final existingUser = await DatabaseService.instance.getUserByUsername(username);
    if (existingUser != null) {
      return false;
    }

    final user = User(
      username: username,
      password: password,
      name: name,
      createdAt: DateTime.now(),
    );

    final createdUser = await DatabaseService.instance.createUser(user);
    if (createdUser != null) {
      await _saveUserToPrefs(createdUser);
      _currentUser = createdUser;
      return true;
    }
    return false;
  }

  Future<bool> login(String username, String password, {bool rememberMe = false}) async {
    final user = await DatabaseService.instance.login(username, password);
    if (user != null) {
      await _saveUserToPrefs(user);
      _currentUser = user;
      
      if (rememberMe) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(_savedUsernameKey, username);
        await prefs.setString(_savedPasswordKey, password);
        await prefs.setBool(_rememberMeKey, true);
        _rememberMe = true;
      }
      
      return true;
    }
    return false;
  }

  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_userIdKey);
    await prefs.remove(_usernameKey);
    await prefs.remove(_nameKey);
    _currentUser = null;
  }

  Future<void> _saveUserToPrefs(User user) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_userIdKey, user.id!);
    await prefs.setString(_usernameKey, user.username);
    await prefs.setString(_nameKey, user.name);
  }

  bool get isLoggedIn => _currentUser != null;
}
