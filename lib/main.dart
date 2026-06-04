import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- 1. NYTT: Importer Firebase-pakkene ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Denne filen ble laget av 'flutterfire configure'

// Import all your screen files
import 'pages/home_page.dart'; // Sjekk at mappen din heter 'pages' eller 'screens'
import 'pages/fantasy_page.dart';
import 'pages/tours_page.dart';
import 'pages/stats_root_page.dart';
import 'theme/app_theme.dart';

// --- 2. NYTT: Gjør main-funksjonen 'async' ---
void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // --- 3. NYTT: Start Firebase-motoren ---
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    systemNavigationBarColor: Color(0xFF0A1931),
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: ThemeMode.system,
      home: const MainPage(),
    );
  }
}

class MainPage extends StatefulWidget {
  const MainPage({super.key});

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  int _selectedIndex = 0;

  List<Widget> get _pages => [
    HomePage(onTabSelected: _onItemTapped),
    const FantasyPage(),
    const ToursPage(),
    const StatsRootPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: IndexedStack(
        index: _selectedIndex,
        children: _pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: BottomNavigationBar(
          items: const <BottomNavigationBarItem>[
            BottomNavigationBarItem(
              icon: Icon(Icons.home),
              label: 'Hjem',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.sports_volleyball),
              label: 'Fantasy',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.flag),
              label: 'Tours',
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.bar_chart),
              label: 'Statistikk',
            ),
          ],
          currentIndex: _selectedIndex,
          onTap: _onItemTapped,
        ),
      ),
    );
  }
}