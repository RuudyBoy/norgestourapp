import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'league_logic.dart';

class FantasyLeaguesView extends StatefulWidget {
  final List<FantasyPlayer> players;
  const FantasyLeaguesView({super.key, required this.players});

  @override
  State<FantasyLeaguesView> createState() => _FantasyLeaguesViewState();
}

class _FantasyLeaguesViewState extends State<FantasyLeaguesView> {
  bool _isGlobalTab = true;
  bool _isLoading = true;
  List<LeaderboardEntry> _globalLeaderboard = [];
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    _globalLeaderboard = await LeagueLogic.getGlobalLeaderboard(widget.players);
    if (mounted) {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {

    return Column(
      children: [
        // League Header (Global vs Private)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              GestureDetector(
                onTap: () => setState(() => _isGlobalTab = true),
                child: _buildLeagueTab('Global', _isGlobalTab),
              ),
              const SizedBox(width: 16),
              GestureDetector(
                onTap: () => setState(() => _isGlobalTab = false),
                child: _buildLeagueTab('Mine Ligaer', !_isGlobalTab),
              ),
            ],
          ),
        ),

        if (!_isGlobalTab)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implementere opprettelse av liga
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kommer snart!')));
                  },
                  icon: const Icon(Icons.add),
                  label: const Text('Lag Liga'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                  ),
                ),
                ElevatedButton.icon(
                  onPressed: () {
                    // TODO: Implementere join liga
                    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Kommer snart!')));
                  },
                  icon: const Icon(Icons.group_add),
                  label: const Text('Bli med'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1E3A8A),
                    foregroundColor: Colors.white,
                  ),
                ),
              ],
            ),
          ),

        // Leaderboard Table
        Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF1E3A8A),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.2),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: Column(
              children: [
                // Table Header
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      const SizedBox(width: 40, child: Text('Rank', style: TextStyle(color: Colors.white70))),
                      const Expanded(child: Text('Team', style: TextStyle(color: Colors.white70))),
                      const Text('Points', style: TextStyle(color: Colors.white70)),
                    ],
                  ),
                ),
                const Divider(color: Colors.white24, height: 1),
                
                // Table Rows
                Expanded(
                  child: _isLoading 
                    ? const Center(child: CircularProgressIndicator(color: Color(0xFF00FFCC)))
                    : (!_isGlobalTab) 
                      ? const Center(child: Text('Du er ikke med i noen private ligaer ennå.', style: TextStyle(color: Colors.white70)))
                      : ListView.separated(
                    itemCount: _globalLeaderboard.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, index) {
                      final entry = _globalLeaderboard[index];
                      final isCurrentUser = entry.userId == _currentUserId;
                      final rank = index + 1;

                      return Container(
                        color: isCurrentUser ? const Color(0xFF00FFCC).withValues(alpha: 0.1) : Colors.transparent,
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '$rank',
                                style: TextStyle(
                                  color: rank <= 3 ? const Color(0xFF00FFCC) : Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 16,
                                ),
                              ),
                            ),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    entry.teamName,
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    entry.managerName,
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${entry.totalPoints}',
                              style: const TextStyle(
                                color: Color(0xFF00FFCC),
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLeagueTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
      decoration: BoxDecoration(
        color: isSelected ? const Color(0xFF00FFCC).withValues(alpha: 0.2) : Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isSelected ? const Color(0xFF00FFCC) : Colors.white24,
        ),
      ),
      child: Text(
        title,
        style: TextStyle(
          color: isSelected ? const Color(0xFF00FFCC) : Colors.white70,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}
