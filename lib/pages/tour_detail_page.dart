import 'package:flutter/material.dart';
import 'teams_page.dart'; // Sjekk at stien er riktig
import 'matches_page.dart'; // Sjekk at stien er riktig
import 'tournament_stats_page.dart'; // Sjekk at stien er riktig

class TournamentDetailsPage extends StatelessWidget {
  // We request two things: The Database ID and the Data Map for display
  final String tournamentId;
  final Map<String, dynamic> data;

  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    // Extract info safely from the passed data map
    final name = data['name'] ?? 'Ukjent Turnering';
    final date = data['start_date']?.toString() ?? 'Dato kommer'; 
    final imageUrl = data['image_url'] ?? 'https://via.placeholder.com/500x300';

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text(name), 
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            
            // --- HEADER IMAGE WITH TITLE + DATE (Dynamic Data) ---
            Stack(
              alignment: Alignment.bottomLeft,
              children: [
                Image.network(
                  imageUrl,
                  height: 220,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return Container(
                      height: 220,
                      color: Colors.grey[300],
                      child: const Icon(Icons.broken_image, color: Colors.grey, size: 60),
                    );
                  },
                ),
                // Dark gradient for text readability
                Container(
                  height: 220,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.black.withOpacity(0.8),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 26,
                          fontWeight: FontWeight.bold,
                          shadows: [
                            Shadow(
                              blurRadius: 6.0,
                              color: Colors.black,
                              offset: Offset(2.0, 2.0),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        date,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          shadows: [
                            Shadow(
                              blurRadius: 4.0,
                              color: Colors.black,
                              offset: Offset(1.0, 1.0),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // --- 2x2 MENU GRID (Static Navigation Buttons) ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20.0),
              child: GridView.count(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                crossAxisCount: 2,
                crossAxisSpacing: 20,
                mainAxisSpacing: 20,
                childAspectRatio: 1.6,
                children: [
                  _buildMenuButton(
                    title: 'Teams',
                    icon: Icons.groups,
                    color: Colors.blueAccent,
                    onTap: () {
                      // NAVIGER TIL TEAMS PAGE
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => TeamsPage(
                            tournamentId: tournamentId, // Vi sender ID-en videre!
                            tournamentName: data['name'] ?? 'Turnering',
                          ),
                        ),
                      );
                    },
                  ),
                  _buildMenuButton(
  title: 'Stats',
  icon: Icons.bar_chart,
  color: Colors.orangeAccent,
  onTap: () {
    // NAVIGER TIL STATS PAGE
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => TournamentStatsPage(
          tournamentId: tournamentId, // Sender ID-en videre, akkurat som på Teams
          tournamentName: data['name'] ?? 'Turnering',
        ),
      ),
    );
  },
),
                  
                  
                  _buildMenuButton(
                    title: 'Results',
                    icon: Icons.emoji_events,
                    color: Colors.green,
                    onTap: () {
                      // Future: Navigate to Results page
                    },
                  ),
                  _buildMenuButton(
                    title: 'Matches',
                    icon: Icons.calendar_month,
                    color: Colors.purpleAccent,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchesPage(
                            tournamentId: tournamentId,
                            tournamentName: name,
                          ),
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // --- HELPER: MENU BUTTONS ---
  Widget _buildMenuButton({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeOut,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.scale(
            scale: 0.9 + (0.1 * value),
            child: Material(
              color: Colors.white,
              elevation: 3,
              borderRadius: BorderRadius.circular(16),
              child: InkWell(
                onTap: onTap,
                borderRadius: BorderRadius.circular(16),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [
                        Colors.white,
                        Colors.grey[50]!,
                      ],
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: color.withOpacity(0.15),
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: color.withOpacity(0.2),
                                blurRadius: 8,
                                offset: const Offset(0, 2),
                              ),
                            ],
                          ),
                          child: Icon(
                            icon,
                            size: 28,
                            color: color,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          title,
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF0A1931),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}