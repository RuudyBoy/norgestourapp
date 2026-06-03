import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stats_logic.dart';

class MatchStatsPage extends StatelessWidget {
  final String matchId;
  final String teamAName;
  final String teamBName;

  const MatchStatsPage({
    super.key,
    required this.matchId,
    required this.teamAName,
    required this.teamBName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from background if possible
      appBar: AppBar(
        title: const Text("KAMPFAKTA", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .collection('events')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) {
            return const Center(child: Text("Ingen data enda."));
          }

          final eventsList = docs.map((d) => d.data() as Map<String, dynamic>).toList();
          final statsMap = calculateMatchStats(eventsList);
          
          final players = statsMap.values.toList();
          players.sort((a, b) {
            if (a.teamName == teamAName && b.teamName != teamAName) return -1;
            if (a.teamName != teamAName && b.teamName == teamAName) return 1;
            return b.totalPoints.compareTo(a.totalPoints);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text("$teamAName vs $teamBName", 
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w900, color: Colors.white)
                ),
                const SizedBox(height: 20),
                
                // Legend / Forklaring (Viktig når vi bruker forkortelser)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    "SO = Sideout Poeng  |  MOT = Mottaksfeil",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

                _buildStatsTable(players),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsTable(List<PlayerMatchStats> players) {
    return Column(
      children: players.map((p) {
        bool isTeamA = p.teamName == teamAName;
        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF1E1E1E),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isTeamA ? Colors.blueAccent.withOpacity(0.5) : Colors.redAccent.withOpacity(0.5),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 8,
                offset: const Offset(0, 4),
              )
            ],
          ),
          child: Row(
            children: [
                // Info
                Expanded(
                  flex: 3,
                  child: Row(
                    children: [
                      if (p.imageUrl.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundImage: NetworkImage(p.imageUrl),
                            backgroundColor: Colors.white10,
                          ),
                        )
                      else
                        Padding(
                          padding: const EdgeInsets.only(right: 8.0),
                          child: CircleAvatar(
                            radius: 16,
                            backgroundColor: Colors.white10,
                            child: Text(
                              p.playerName.isEmpty ? "?" : p.playerName.substring(0, 1).toUpperCase(),
                              style: const TextStyle(color: Colors.white70, fontSize: 12, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.playerName,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: Colors.white),
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              p.teamName,
                              style: TextStyle(fontSize: 12, color: Colors.grey[400]),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              // Stats
              Expanded(
                flex: 5,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _buildMiniStat("TOT", p.totalPoints.toString(), color: const Color(0xFF1DD05D)),
                    _buildMiniStat("ANG", "${p.kills}/${p.attackErrors}", color: Colors.white),
                    _buildMiniStat("SO", "${p.sideoutPoints}", color: Colors.white),
                    _buildMiniStat("LEGG", p.settingEfficiency, color: Colors.white),
                    _buildMiniStat("MOT", "${p.receptionErrors}", color: p.receptionErrors > 0 ? const Color(0xFFFF3B30) : Colors.grey[500]!),
                  ],
                ),
              )
            ],
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniStat(String label, String value, {required Color color}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: color,
            fontSize: 15,
            fontWeight: FontWeight.w900,
          ),
        ),
      ],
    );
  }
}