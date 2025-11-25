import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'match_stats_page.dart'; // <--- VIKTIG: Husk denne importen!

class MatchesPage extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;

  const MatchesPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: Text("Kamper - $tournamentName"),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        // Vi henter kamper som tilhører denne turneringen
        stream: FirebaseFirestore.instance
            .collection('matches')
            .where('tournament_id', isEqualTo: tournamentId)
            .snapshots(),
            
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
            return const Center(
              child: Text("Ingen kamper satt opp enda."),
            );
          }

          final matches = snapshot.data!.docs;

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: matches.length,
            itemBuilder: (context, index) {
              final data = matches[index].data() as Map<String, dynamic>;
              
              // Hent data (med fallback verdier)
              final status = data['status'] ?? 'scheduled';
              final homeScore = data['home_score'] ?? 0;
              final awayScore = data['away_score'] ?? 0;
              final court = data['court'] ?? 'Bane ?';
              
              // Vi henter navnene slik at vi kan sende dem til Stats-siden
              final teamAName = data['team_a_name'] ?? 'Lag A';
              final teamBName = data['team_b_name'] ?? 'Lag B';

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  // --- HER ER NAVIGASJONEN TIL STATS ---
                  onTap: () {
                    if (status == 'scheduled') {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(content: Text("Kampen har ikke startet enda."))
                      );
                    } else {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchStatsPage(
                            matchId: matches[index].id,
                            teamAName: teamAName,
                            teamBName: teamBName,
                          ),
                        ),
                      );
                    }
                  },
                  // -------------------------------------

                  contentPadding: const EdgeInsets.all(16.0),
                  title: Column(
                    children: [
                      // Topprad: Status og Bane
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: status == 'live' ? Colors.red : Colors.grey[300],
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              status.toUpperCase(),
                              style: TextStyle(
                                color: status == 'live' ? Colors.white : Colors.black,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          Text(court, style: TextStyle(color: Colors.grey[600], fontSize: 12)),
                        ],
                      ),
                      const Divider(height: 24),
                      
                      // Kamp-rad: Lag A - Score - Lag B
                      Row(
                        children: [
                          // Hjemmelag
                          Expanded(
                            child: Text(
                              teamAName, // Viser nå navnet
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          
                          // Score
                          Container(
                            margin: const EdgeInsets.symmetric(horizontal: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            decoration: BoxDecoration(
                              color: Colors.grey[100],
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(color: Colors.grey[300]!),
                            ),
                            child: Text(
                              "$homeScore - $awayScore",
                              style: const TextStyle(
                                fontSize: 20, 
                                fontWeight: FontWeight.bold
                              ),
                            ),
                          ),

                          // Bortelag
                          Expanded(
                            child: Text(
                              teamBName, 
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                      
                      // Liten tekst i bunn som hinter om at man kan trykke
                      if (status != 'scheduled')
                        Padding(
                          padding: const EdgeInsets.only(top: 12.0),
                          child: Text(
                            "Trykk for kampfakta", 
                            style: TextStyle(fontSize: 12, color: Colors.blue[700], fontStyle: FontStyle.italic)
                          ),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}