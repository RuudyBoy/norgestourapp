import 'package:flutter/material.dart';
import 'fantasy/models.dart';
import 'fantasy/fantasy_squad_view.dart';
import 'fantasy/fantasy_leagues_view.dart';
import 'fantasy/fantasy_player_selection.dart';
import 'fantasy/mock_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_page.dart';
import '../widgets/profile_avatar_widget.dart';
import 'fantasy/league_logic.dart';

class FantasyPage extends StatefulWidget {
  const FantasyPage({super.key});

  @override
  State<FantasyPage> createState() => _FantasyPageState();
}

class _FantasyPageState extends State<FantasyPage> {
  // Map to keep track of the selected player for each role
  Map<String, String?> selectedPlayers = {
    FantasyRole.block: null,
    FantasyRole.defense: null,
    FantasyRole.attack: null,
    FantasyRole.set: null,
    FantasyRole.receive: null,
    FantasyRole.serve: null,
  };

  late Future<List<FantasyPlayer>> _playersFuture;
  late Future<Map<String, double>> _ownershipFuture;
  String? _linkedPlayerId;

  Future<List<dynamic>>? _combinedFuture;
  String? _currentUserId;

  @override
  void initState() {
    super.initState();
    _playersFuture = fetchFantasyPlayers();
  }

  void _openPlayerSelection(String role, List<FantasyPlayer> players, Map<String, double> ownershipPercentages) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FantasyPlayerSelection(
          role: role,
          currentSelectedPlayers: selectedPlayers,
          players: players,
          ownershipPercentages: ownershipPercentages,
          linkedPlayerId: _linkedPlayerId,
          onSelect: (playerId) async {
            setState(() {
              selectedPlayers[role] = playerId;
            });
            final user = FirebaseAuth.instance.currentUser;
            if (user != null) {
              await FirebaseFirestore.instance
                  .collection('users')
                  .doc(user.uid)
                  .collection('fantasy')
                  .doc('squad')
                  .set(selectedPlayers, SetOptions(merge: true));
            }
          },
        ),
      ),
    );
  }

  Future<void> _loadSquad(String uid) async {
    final doc = await FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .collection('fantasy')
        .doc('squad')
        .get();
    if (doc.exists) {
      final data = doc.data()!;
      for (var key in selectedPlayers.keys) {
        if (data.containsKey(key)) {
          selectedPlayers[key] = data[key] as String?;
        }
      }
    }
  }

  Future<void> _loadUserData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _linkedPlayerId = data['linkedPlayerId'] as String?;
    }
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: Colors.transparent, // Gjør bakgrunnen transparent for å vise bildet
        appBar: AppBar(
          title: const Text(
            'FANTASY SQUAD',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.white,
          elevation: 0,
          leadingWidth: 80,
          leading: Padding(
            padding: const EdgeInsets.only(left: 16.0),
            child: Image.asset('assets/images/spikedunk_logo.png', fit: BoxFit.contain),
          ),
          actions: const [ProfileAvatarWidget()],
          bottom: const TabBar(
            indicatorColor: Color(0xFFFF3B30), // Striking red accent
            labelColor: Color(0xFFFF3B30),
            unselectedLabelColor: Colors.white54,
            tabs: [
              Tab(icon: Icon(Icons.sports_volleyball), text: 'My Squad'),
              Tab(icon: Icon(Icons.leaderboard), text: 'Leagues'),
            ],
          ),
        ),
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator());
            }
            if (!authSnapshot.hasData) {
              return Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.lock, size: 64, color: Colors.grey),
                    const SizedBox(height: 16),
                    const Text('Logg inn for å spille Fantasy', style: TextStyle(color: Colors.white, fontSize: 18)),
                    const SizedBox(height: 24),
                    ElevatedButton(
                      onPressed: () {
                        Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage()));
                      },
                      style: ElevatedButton.styleFrom(backgroundColor: const Color(0xFFFF3B30)),
                      child: const Text('Gå til innlogging', style: TextStyle(color: Colors.white)),
                    )
                  ],
                ),
              );
            }
            
            // Bruker er logget inn
            final user = authSnapshot.data!;
            if (_currentUserId != user.uid) {
              _currentUserId = user.uid;
              _ownershipFuture = LeagueLogic.getPlayerOwnershipPercentages();
              _combinedFuture = Future.wait([
                _playersFuture,
                _loadSquad(user.uid),
                _loadUserData(user.uid),
                _ownershipFuture,
              ]);
            }

            return FutureBuilder<List<dynamic>>(
              future: _combinedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Center(
                    child: Text(
                      'Feil ved innlasting: ${snapshot.error}',
                      style: const TextStyle(color: Colors.white),
                    ),
                  );
                }
                
                // _playersFuture er første element i Future.wait arrayen
                final players = (snapshot.data?[0] as List<FantasyPlayer>?) ?? [];
                final ownershipPercentages = (snapshot.data?[3] as Map<String, double>?) ?? {};
                
                return TabBarView(
                  children: [
                    FantasySquadView(
                      selectedPlayers: selectedPlayers,
                      players: players,
                      linkedPlayerId: _linkedPlayerId,
                      onRoleTap: (role) => _openPlayerSelection(role, players, ownershipPercentages),
                    ),
                    FantasyLeaguesView(players: players),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}