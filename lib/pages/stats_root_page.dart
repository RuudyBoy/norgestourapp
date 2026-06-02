import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'stats_logic.dart'; 
import 'stats_details_page.dart';
import 'players_list_page.dart';
import '../widgets/profile_avatar_widget.dart';

class StatsRootPage extends StatefulWidget {
  const StatsRootPage({super.key});

  @override
  State<StatsRootPage> createState() => _StatsRootPageState();
}

class _StatsRootPageState extends State<StatsRootPage> {
  late Future<List<PlayerMatchStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _calculateAllTimeStats();
  }

  Future<List<PlayerMatchStats>> _calculateAllTimeStats() async {
    // Fetches all matches for overall stats
    final matchesSnapshot = await FirebaseFirestore.instance.collection('matches').get();

    Map<String, PlayerMatchStats> totalStatsMap = {};

    for (var matchDoc in matchesSnapshot.docs) {
      final eventsSnapshot = await matchDoc.reference.collection('events').get();
      if (eventsSnapshot.docs.isEmpty) continue;

      final eventsList = eventsSnapshot.docs.map((d) => d.data()).toList();
      final typedList = eventsList.cast<Map<String, dynamic>>();
      final matchStats = calculateMatchStats(typedList);

      matchStats.forEach((playerName, s) {
        if (!totalStatsMap.containsKey(playerName)) {
          totalStatsMap[playerName] = PlayerMatchStats(
            playerName: playerName, 
            teamName: s.teamName
          );
        }
        final total = totalStatsMap[playerName]!;
        total.kills += s.kills;
        total.attackErrors += s.attackErrors;
        total.blocks += s.blocks;
        total.aces += s.aces;
        total.serviceErrors += s.serviceErrors;
        total.receptionErrors += s.receptionErrors;
        total.sideoutPoints += s.sideoutPoints;
        total.setAssists += s.setAssists;
        total.setAttempts += s.setAttempts;
        
        // Merge detail maps
        s.killDetails.forEach((k, v) => total.killDetails[k] = (total.killDetails[k] ?? 0) + v);
        s.aceDetails.forEach((k, v) => total.aceDetails[k] = (total.aceDetails[k] ?? 0) + v);
        s.attackErrorDetails.forEach((k, v) => total.attackErrorDetails[k] = (total.attackErrorDetails[k] ?? 0) + v);
      });
    }
    return totalStatsMap.values.toList();
  }

  Future<void> _refreshStats() async {
    setState(() {
      _statsFuture = _calculateAllTimeStats();
    });
    await _statsFuture;
  }

  void _navigateToDetails(BuildContext context, List<PlayerMatchStats> players, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsDetailsPage(allPlayers: players, initialSort: category),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: Text(
          'STATISTICS',
          style: GoogleFonts.montserrat(
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
        actions: const [
          ProfileAvatarWidget(),
        ],
      ),
      body: FutureBuilder<List<PlayerMatchStats>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30)));
          }

          List<PlayerMatchStats> allPlayers = [];
          bool isDummy = false;

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
             allPlayers = [
               PlayerMatchStats(playerName: "Spiller En", teamName: "Team A")..kills=15..sideoutPoints=15..blocks=5..aces=5,
               PlayerMatchStats(playerName: "Spiller To", teamName: "Team B")..kills=10..sideoutPoints=12..blocks=8..aces=2,
               PlayerMatchStats(playerName: "Spiller Tre", teamName: "Team A")..kills=6..sideoutPoints=10..blocks=4..aces=8,
               PlayerMatchStats(playerName: "Spiller Fire", teamName: "Team C")..kills=9..sideoutPoints=8..blocks=2..aces=4..setAssists=40..setAttempts=50,
             ];
             isDummy = true;
          } else {
             allPlayers = snapshot.data!;
          }

          final pointsList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
          final sideoutList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.sideoutPoints.compareTo(a.sideoutPoints));
          final blocksList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.blocks.compareTo(a.blocks));
          final settersList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) {
               double aPct = a.setAttempts == 0 ? 0 : (a.setAssists / a.setAttempts);
               double bPct = b.setAttempts == 0 ? 0 : (b.setAssists / b.setAttempts);
               return bPct.compareTo(aPct);
            });
          final serverList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.aces.compareTo(a.aces));

          return RefreshIndicator(
            onRefresh: _refreshStats,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (isDummy)
                    Container(
                      margin: const EdgeInsets.only(bottom: 16),
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.orange.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.orange),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.info_outline, color: Colors.orange),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              "Ingen data funnet. Viser eksempeldata for layout.",
                              style: GoogleFonts.inter(color: Colors.white, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),

                  GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const PlayersListPage()),
                      );
                    },
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [Color(0xFF2C2C2E), Color(0xFF1C1C1E)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white12),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 10,
                            offset: const Offset(0, 4),
                          )
                        ],
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 20),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3B30).withOpacity(0.2),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.groups_rounded, color: Color(0xFFFF3B30), size: 28),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'ALL PLAYERS',
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.w900,
                                    fontSize: 18,
                                    color: Colors.white,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Se alle registrerte spillere og profiler',
                                  style: GoogleFonts.inter(
                                    fontSize: 12,
                                    color: Colors.grey[400],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 18),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  StatsCategoryCard(
                    title: "Toppscorer",
                    icon: Icons.emoji_events,
                    color: Colors.orange,
                    players: pointsList,
                    valueFormatter: (p) => "${p.totalPoints} p",
                    onTap: () => _navigateToDetails(context, allPlayers, "Toppscorer"),
                  ),
                  const SizedBox(height: 20),
                  
                  StatsCategoryCard(
                    title: "Sideout-maskin",
                    icon: Icons.compare_arrows,
                    color: Colors.blueAccent,
                    players: sideoutList,
                    valueFormatter: (p) => "${p.sideoutPoints} p",
                    onTap: () => _navigateToDetails(context, allPlayers, "Sideout"),
                  ),
                  const SizedBox(height: 20),

                  StatsCategoryCard(
                    title: "Blokk-monster",
                    icon: Icons.front_hand,
                    color: Colors.redAccent,
                    players: blocksList,
                    valueFormatter: (p) => "${p.blocks} blk",
                    onTap: () => _navigateToDetails(context, allPlayers, "Blokk"),
                  ),
                  const SizedBox(height: 20),

                  StatsCategoryCard(
                    title: "Legge-maestro",
                    icon: Icons.sports_volleyball,
                    color: Colors.green,
                    players: settersList,
                    valueFormatter: (p) => p.settingEfficiency,
                    onTap: () => _navigateToDetails(context, allPlayers, "Legging"),
                  ),
                  const SizedBox(height: 20),

                  StatsCategoryCard(
                    title: "Serve-Konge",
                    icon: Icons.flash_on,
                    color: Colors.deepPurple,
                    players: serverList,
                    valueFormatter: (p) => "${p.aces} ess",
                    onTap: () => _navigateToDetails(context, allPlayers, "Serve"),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

class StatsCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color color;
  final List<PlayerMatchStats> players;
  final String Function(PlayerMatchStats) valueFormatter;
  final VoidCallback onTap;

  const StatsCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.color,
    required this.players,
    required this.valueFormatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();

    final winner = players[0];
    final runnersUp = players.length > 1 ? players.sublist(1, players.length > 5 ? 5 : players.length) : [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: Colors.white10),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.5), 
              blurRadius: 10, 
              offset: const Offset(0, 4)
            )
          ],
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.2),
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(16), topRight: Radius.circular(16)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: color),
                  const SizedBox(width: 10),
                  Text(
                    title, 
                    style: GoogleFonts.montserrat(
                      color: Colors.white, 
                      fontWeight: FontWeight.bold, 
                      fontSize: 16
                    )
                  ),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                ],
              ),
            ),

            // VINNER (STOR)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: color.withOpacity(0.2),
                    child: Text(
                      winner.playerName.isEmpty ? "?" : winner.playerName.substring(0, 1).toUpperCase(),
                      style: GoogleFonts.montserrat(fontSize: 32, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    winner.playerName, 
                    style: GoogleFonts.inter(
                      fontSize: 20, 
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    )
                  ),
                  if (winner.teamName.isNotEmpty)
                    Text(
                      winner.teamName, 
                      style: GoogleFonts.inter(color: Colors.grey[400], fontSize: 13)
                    ),
                  const SizedBox(height: 8),
                  Text(
                    valueFormatter(winner),
                    style: GoogleFonts.montserrat(
                      fontSize: 26, 
                      fontWeight: FontWeight.w900, 
                      color: color
                    ),
                  ),
                ],
              ),
            ),

            // RUNNERS UP
            if (runnersUp.isNotEmpty)
              Container(
                decoration: const BoxDecoration(
                  color: Color(0xFF161616),
                  borderRadius: BorderRadius.only(bottomLeft: Radius.circular(16), bottomRight: Radius.circular(16)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Column(
                  children: runnersUp.asMap().entries.map((entry) {
                    final index = entry.key + 2; 
                    final player = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 24,
                            child: Text(
                              "$index.", 
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, color: Colors.grey[500])
                            ),
                          ),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              player.playerName, 
                              style: GoogleFonts.inter(
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[300],
                              )
                            )
                          ),
                          Text(
                            valueFormatter(player), 
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              color: Colors.white
                            )
                          ),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
