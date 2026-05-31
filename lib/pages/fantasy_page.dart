import 'package:flutter/material.dart';
import 'fantasy/models.dart';
import 'fantasy/fantasy_squad_view.dart';
import 'fantasy/fantasy_leagues_view.dart';
import 'fantasy/fantasy_player_selection.dart';

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

  void _openPlayerSelection(String role) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FantasyPlayerSelection(
          role: role,
          currentSelectedPlayers: selectedPlayers,
          onSelect: (playerId) {
            setState(() {
              selectedPlayers[role] = playerId;
            });
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        backgroundColor: const Color(0xFF0A1931), // Deep dark blue background
        appBar: AppBar(
          title: const Text(
            'Fantasy Tour',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: const Color(0xFF0A1931),
          foregroundColor: Colors.white,
          elevation: 0,
          bottom: const TabBar(
            indicatorColor: Color(0xFF00FFCC), // Neon cyan accent
            labelColor: Color(0xFF00FFCC),
            unselectedLabelColor: Colors.white70,
            tabs: [
              Tab(icon: Icon(Icons.sports_volleyball), text: 'My Squad'),
              Tab(icon: Icon(Icons.leaderboard), text: 'Leagues'),
            ],
          ),
        ),
        body: TabBarView(
          children: [
            // Tab 1: Squad View (Pitch)
            FantasySquadView(
              selectedPlayers: selectedPlayers,
              onRoleTap: _openPlayerSelection,
            ),
            
            // Tab 2: Leagues
            const FantasyLeaguesView(),
          ],
        ),
      ),
    );
  }
}