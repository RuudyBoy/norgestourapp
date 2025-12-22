import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stats_logic.dart'; 
import 'stats_details_page.dart'; // Husk å lage/oppdatere denne filen (se under)

class TournamentStatsPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentStatsPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<TournamentStatsPage> createState() => _TournamentStatsPageState();
}

class _TournamentStatsPageState extends State<TournamentStatsPage> {
  late Future<List<PlayerMatchStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _calculateTournamentStats();
  }

  // Henter og slår sammen stats (Samme logikk som før)
  Future<List<PlayerMatchStats>> _calculateTournamentStats() async {
    final matchesSnapshot = await FirebaseFirestore.instance
        .collection('matches')
        .where('tournament_id', isEqualTo: widget.tournamentId)
        .get();

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
      });
    }
    return totalStatsMap.values.toList();
  }

@override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Hall of Fame - ${widget.tournamentName}"),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: FutureBuilder<List<PlayerMatchStats>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            // Vi må også ha RefreshIndicator her, så man kan oppdatere hvis det var tomt først
            return RefreshIndicator(
              onRefresh: _refreshStats,
              child: ListView( // Bruker ListView her for at man skal kunne dra ned
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text("Ingen stats registrert enda.")),
                ],
              ),
            );
          }

          final allPlayers = snapshot.data!;

          // ... (Din sorterings-kode her: pointsList, sideoutList osv.) ...
          // ... (Lim inn sorterings-blokken vi lagde sist her) ...
          
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


          // HER ER ENDRINGEN:
          return RefreshIndicator(
            onRefresh: _refreshStats, // Kaller funksjonen under
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Viktig for at den skal kunne dras
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
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
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Legg til denne funksjonen nederst i klassen din:
  Future<void> _refreshStats() async {
    setState(() {
      // Dette trigger en ny henting av data
      _statsFuture = _calculateTournamentStats();
    });
    // Vi venter på at den skal bli ferdig
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
}

// --- WIDGET FOR KORTENE (INGEN ENDRINGER HER, BARE KOPIER) ---
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(color: Colors.black.withOpacity(0.08), blurRadius: 15, offset: const Offset(0, 5))
          ],
        ),
        child: Column(
          children: [
            // HEADER
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 15),
              decoration: BoxDecoration(
                color: color,
                borderRadius: const BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: Colors.white),
                  const SizedBox(width: 10),
                  Text(title, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16)),
                  const Spacer(),
                  const Icon(Icons.arrow_forward_ios, color: Colors.white70, size: 16),
                ],
              ),
            ),

            // VINNER (STOR)
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 35,
                    backgroundColor: color.withOpacity(0.1),
                    child: Text(
                      winner.playerName.isEmpty ? "?" : winner.playerName.substring(0, 1).toUpperCase(),
                      style: TextStyle(fontSize: 30, fontWeight: FontWeight.bold, color: color),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Text(winner.playerName, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  Text(winner.teamName, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                  const SizedBox(height: 5),
                  Text(
                    valueFormatter(winner),
                    style: TextStyle(fontSize: 24, fontWeight: FontWeight.w900, color: color),
                  ),
                ],
              ),
            ),

            // RUNNERS UP
            if (runnersUp.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: Colors.grey[50],
                  borderRadius: const BorderRadius.only(bottomLeft: Radius.circular(20), bottomRight: Radius.circular(20)),
                  border: Border(top: BorderSide(color: Colors.grey[200]!)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  children: runnersUp.asMap().entries.map((entry) {
                    final index = entry.key + 2; 
                    final player = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 6),
                      child: Row(
                        children: [
                          Text("$index.", style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                          const SizedBox(width: 10),
                          Expanded(child: Text(player.playerName, style: const TextStyle(fontWeight: FontWeight.w500))),
                          Text(valueFormatter(player), style: const TextStyle(fontWeight: FontWeight.bold)),
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