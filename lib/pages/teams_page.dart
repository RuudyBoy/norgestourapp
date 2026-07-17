import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamsPage extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;
  final bool isEmbedded;

  const TeamsPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = StreamBuilder<QuerySnapshot>(
      // MAGIEN SKJER HER:
      // Vi ber Firebase om lagene, MEN kun de som har riktig tournament_id
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('tournament_id', isEqualTo: tournamentId)
          .snapshots(),
          
      builder: (context, snapshot) {
        // 1. Laster...
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        // 2. Feil...
        if (snapshot.hasError) {
          return Center(child: Text("Feil: ${snapshot.error}"));
        }

        // 3. Ingen lag funnet...
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(Icons.group_off, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text("Ingen lag er påmeldt enda."),
              ],
            ),
          );
        }

        final teams = snapshot.data!.docs.toList()
          ..sort((a, b) {
            final ad = a.data() as Map<String, dynamic>;
            final bd = b.data() as Map<String, dynamic>;
            
            final seedA = ad['seed'] as int? ?? 9999;
            final seedB = bd['seed'] as int? ?? 9999;
            if (seedA != seedB) return seedA.compareTo(seedB);

            // Admin skriver 'team_points'; eldre data kan ha 'combined_ranking'
            final rankA = (ad['team_points'] ?? ad['combined_ranking'] ?? 0) as num;
            final rankB = (bd['team_points'] ?? bd['combined_ranking'] ?? 0) as num;
            return rankB.compareTo(rankA); // descending
          });

        final isDark = Theme.of(context).brightness == Brightness.dark;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final data = teams[index].data() as Map<String, dynamic>;
            final teamName = data['team_name'] ?? data['name'] ?? 'Ukjent Lag';
            final p1 = data['player1_name'] ?? data['player_1_name'] ?? '';
            final p2 = data['player2_name'] ?? data['player_2_name'] ?? '';
            final players = [if (p1.isNotEmpty) p1, if (p2.isNotEmpty) p2];
            
            final seed = data['seed'] as int?;
            final pts = data['team_points'] ?? data['combined_ranking'] ?? data['ranking_points'] ?? 0;

            String subtitleText = players.isEmpty ? "Ingen spillere registrert" : players.join(" & ");

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              color: isDark ? const Color(0xFF162544) : Colors.white,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: seed != null ? const Color(0xFFE85D4E) : const Color(0xFF0A1931),
                  child: Text(
                    seed != null ? "$seed" : "-",
                    style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ),
                title: Text(teamName, style: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black87)),
                subtitle: Text(subtitleText, style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                trailing: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text("$pts", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: isDark ? Colors.white : Colors.black87)),
                    Text("PTS", style: TextStyle(fontSize: 10, color: isDark ? Colors.white54 : Colors.black54)),
                  ],
                ),
              ),
            );
          },
        );
      },
    );

    if (isEmbedded) return content;

    return Scaffold(
      appBar: AppBar(
        title: Text("Lag - $tournamentName"),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }
}