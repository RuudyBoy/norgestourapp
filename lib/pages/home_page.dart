import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fantasy_page.dart';
import 'tours_page.dart';
import 'tournament_stats_page.dart';
import 'match_stats_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212), // Deep black background
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildLiveMatches(context),
              const SizedBox(height: 10),
              _buildCards(context),
              const SizedBox(height: 30),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 30),
      // Optional subtle texture/gradient for the header
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            const Color(0xFF1E1E1E), // Dark grey
            const Color(0xFF121212), // Fades into the black background
          ],
        ),
      ),
      child: Center(
        child: Image.asset(
          'assets/images/spikedunk_logo.png', // User's attached SpikeDunk logo
          height: 120,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) => RichText(
            textAlign: TextAlign.center,
            text: TextSpan(
              children: [
                TextSpan(
                  text: 'SPIKE\n',
                  style: GoogleFonts.montserrat(
                    fontSize: 48,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    shadows: [
                      Shadow(color: Colors.white.withOpacity(0.5), blurRadius: 10),
                    ],
                  ),
                ),
                TextSpan(
                  text: 'DUNK',
                  style: GoogleFonts.montserrat(
                    fontSize: 54,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: const Color(0xFFFF3B30), // Red
                    shadows: [
                      const Shadow(
                        color: Color(0xFF1D4ED8), // Blue 3D shadow effect
                        offset: Offset(4, 4),
                        blurRadius: 2,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveMatches(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'live')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink(); // Hide if no live matches
        }

        final matches = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    "LIVE NÅ",
                    style: GoogleFonts.montserrat(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                      letterSpacing: 1.2,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(
              height: 140,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final data = matches[index].data() as Map<String, dynamic>;
                  final matchId = matches[index].id;
                  final teamA = data['team_a_name'] ?? 'Lag A';
                  final teamB = data['team_b_name'] ?? 'Lag B';
                  final scoreA = data['home_score'] ?? 0;
                  final scoreB = data['away_score'] ?? 0;
                  final set = data['current_set'] ?? 1;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchStatsPage(
                            matchId: matchId,
                            teamAName: teamA,
                            teamBName: teamB,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 260,
                      margin: const EdgeInsets.symmetric(horizontal: 4.0),
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1E1E1E),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.red.withOpacity(0.5), width: 1.5),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.red.withOpacity(0.1),
                            blurRadius: 8,
                            spreadRadius: 2,
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text("Sett $set", style: const TextStyle(color: Colors.grey, fontSize: 12, fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(teamA, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              Text("$scoreA", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            ],
                          ),
                          const Divider(color: Colors.grey, height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(child: Text(teamB, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold), overflow: TextOverflow.ellipsis)),
                              Text("$scoreB", style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w900)),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildActionCard(
            context: context,
            title: "FANTASY",
            subtitle: "BUILD YOUR DREAM TEAM",
            description:
                "Select players, manage your budget, and compete against others globally based on real-world performance.",
            buttonText: "GO TO FANTASY",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FantasyPage()),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildActionCard(
            context: context,
            title: "STATISTICS",
            subtitle: "SEASON STATS & RANKINGS",
            description:
                "Deep dive into player statistics, match history, and comprehensive seasonal data.",
            buttonText: "VIEW STATS",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TournamentStatsPage(
                  tournamentId: 'nt-season',
                  tournamentName: 'Årets NT sesong',
                )),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildActionCard(
            context: context,
            title: "TOURNAMENTS",
            subtitle: "FIXTURES & RESULTS",
            description:
                "Keep track of upcoming tours, live matches, and final results for the entire season.",
            buttonText: "VIEW TOURS",
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ToursPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required String buttonText,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: const Color(0xFF1E1E1E), // Dark grey card
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white12, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.5),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Content
          Padding(
            padding: const EdgeInsets.only(left: 120.0, top: 24, bottom: 24, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.montserrat(
                    fontSize: 28,
                    fontWeight: FontWeight.w900,
                    fontStyle: FontStyle.italic,
                    color: Colors.white,
                    letterSpacing: 1.2,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey[400],
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 4,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                    color: Colors.grey[500],
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(8),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFF3B30), // Striking red button
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3B30).withOpacity(0.3),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.montserrat(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Image placeholder on the left
          Positioned(
            left: 16,
            top: 24,
            bottom: 24,
            width: 90,
            child: Container(
              decoration: BoxDecoration(
                color: const Color(0xFF121212),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.white10, width: 1),
              ),
              child: Center(
                child: Icon(
                  Icons.sports_volleyball,
                  color: Colors.grey[800],
                  size: 40,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}