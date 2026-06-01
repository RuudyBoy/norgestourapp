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
        backgroundColor: const Color(0xFF121212), // Deep black background
        appBar: AppBar(
          title: const Text(
            'FANTASY SQUAD',
            style: TextStyle(
              fontWeight: FontWeight.w900,
              fontStyle: FontStyle.italic,
              letterSpacing: 1.5,
            ),
          ),
          backgroundColor: const Color(0xFF121212),
          foregroundColor: Colors.white,
          elevation: 0,
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