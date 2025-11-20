import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- 1. NYTT: Importer Firebase-pakkene ---
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart'; // Denne filen ble laget av 'flutterfire configure'

// Import all your screen files
import 'pages/home_page.dart'; // Sjekk at mappen din heter 'pages' eller 'screens'
import 'pages/fantasy_page.dart';
import 'pages/tours_page.dart';
import 'pages/settings_page.dart';

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
      theme: ThemeData(
        primarySwatch: Colors.blue,
        visualDensity: VisualDensity.adaptivePlatformDensity,
      ),
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

  static const List<Widget> _pages = <Widget>[
    HomePage(),
    FantasyPage(),
    ToursPage(),
    SettingsPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _pages[_selectedIndex],
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.sports_esports),
            label: 'Fantasy',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.map),
            label: 'Tours',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.settings),
            label: 'Settings',
          ),
        ],
        currentIndex: _selectedIndex,
        onTap: _onItemTapped,
        type: BottomNavigationBarType.fixed,
        backgroundColor: const Color(0xFF0A1931),
        selectedItemColor: Colors.white,
        unselectedItemColor: Colors.white70,
      ),
    );
  }
}