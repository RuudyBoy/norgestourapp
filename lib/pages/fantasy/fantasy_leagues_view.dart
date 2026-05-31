import 'package:flutter/material.dart';

class FantasyLeaguesView extends StatelessWidget {
  const FantasyLeaguesView({super.key});

  @override
  Widget build(BuildContext context) {
    // Mock leaderboard data
    final List<Map<String, dynamic>> leaderboard = [
      {'rank': 1, 'name': 'Sand Kings', 'manager': 'Ola Nordmann', 'points': 845},
      {'rank': 2, 'name': 'Block Busters', 'manager': 'Kari Nilsen', 'points': 812},
      {'rank': 3, 'name': 'Spike Squad', 'manager': 'Per Hansen', 'points': 790},
      {'rank': 4, 'name': 'Net Ninjas', 'manager': 'Jens Mygge', 'points': 755},
      {'rank': 5, 'name': 'Dig It', 'manager': 'Lise Berg', 'points': 720},
      {'rank': 6, 'name': 'Ace High', 'manager': 'Tom Tomm', 'points': 690},
    ];

    return Column(
      children: [
        // League Header (Global vs Private)
        Container(
          padding: const EdgeInsets.symmetric(vertical: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _buildLeagueTab('Global', true),
              const SizedBox(width: 16),
              _buildLeagueTab('My Friends', false),
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
                  child: ListView.separated(
                    itemCount: leaderboard.length,
                    separatorBuilder: (context, index) => const Divider(color: Colors.white12, height: 1),
                    itemBuilder: (context, index) {
                      final team = leaderboard[index];
                      final isCurrentUser = team['manager'] == 'Jens Mygge'; // Fake current user logic

                      return Container(
                        color: isCurrentUser ? const Color(0xFF00FFCC).withValues(alpha: 0.1) : Colors.transparent,
                        padding: const EdgeInsets.all(16.0),
                        child: Row(
                          children: [
                            SizedBox(
                              width: 40,
                              child: Text(
                                '${team['rank']}',
                                style: TextStyle(
                                  color: team['rank'] <= 3 ? const Color(0xFF00FFCC) : Colors.white,
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
                                    team['name'],
                                    style: const TextStyle(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                  Text(
                                    team['manager'],
                                    style: TextStyle(
                                      color: Colors.white.withValues(alpha: 0.6),
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              '${team['points']}',
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
