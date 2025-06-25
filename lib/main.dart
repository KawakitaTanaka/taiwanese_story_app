import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'story_list_page.dart';
import 'favorites_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final prefs = await SharedPreferences.getInstance();
  final isDark = prefs.getBool('darkMode') ?? false;
  runApp(MyApp(isDark: isDark));
}

class MyApp extends StatefulWidget {
  final bool isDark;
  MyApp({required this.isDark});
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  late bool _isDark;
  @override
  void initState() {
    super.initState();
    _isDark = widget.isDark;
  }

  void _toggleTheme() async {
    setState(() => _isDark = !_isDark);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('darkMode', _isDark);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: '台語童話故事 App',
      theme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.light,
      ),
      darkTheme: ThemeData(
        primarySwatch: Colors.teal,
        brightness: Brightness.dark,
      ),
      themeMode: _isDark ? ThemeMode.dark : ThemeMode.light,
      initialRoute: '/',
      routes: {
        '/': (_) => StoryListPage(
          isDarkMode: _isDark,
          onToggleTheme: _toggleTheme,
        ),
        '/favorites': (_) => FavoritesPage(
          isDarkMode: _isDark,
          onToggleTheme: _toggleTheme,
        ),
      },
    );
  }
}
