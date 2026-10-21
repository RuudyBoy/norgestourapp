import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

// --- 1. NYTT: Importer Firebase-pakkene ---
import 'package:firebase_core/firebase_core.dart';
import 'package:norges_tour_app/firebase_options.dart';

// Import all your screen files
import 'package:norges_tour_app/pages/home/home_page.dart';
import 'package:norges_tour_app/pages/fantasy/fantasy_page.dart';
import 'package:norges_tour_app/pages/tours/tours_page.dart';
import 'package:norges_tour_app/pages/stats/stats_root_page.dart';
import 'package:norges_tour_app/pages/splash_page.dart';
import 'package:norges_tour_app/theme/app_theme.dart';

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
      builder: (context, child) {
        return Container(
          decoration: const BoxDecoration(
            image: DecorationImage(
              image: AssetImage('assets/images/hero_bg.png'),
              fit: BoxFit.cover,
            ),
          ),
          child: child,
        );
      },
      home: const _AppRoot(),
    );
  }
}

// ── App root: shows splash once, then main ────────────────────────────────────

class _AppRoot extends StatefulWidget {
  const _AppRoot();

  @override
  State<_AppRoot> createState() => _AppRootState();
}

class _AppRootState extends State<_AppRoot> {
  bool _splashDone = false;

  void _onGetStarted() {
    setState(() => _splashDone = true);
  }

  @override
  Widget build(BuildContext context) {
    if (!_splashDone) {
      return SplashPage(onGetStarted: _onGetStarted);
    }
    return const MainPage();
  }
}

// ─────────────────────────────────────────────────────────────────────────────

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
