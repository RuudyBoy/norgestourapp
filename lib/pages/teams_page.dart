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

        final teams = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: teams.length,
          itemBuilder: (context, index) {
            final data = teams[index].data() as Map<String, dynamic>;
            final teamName = data['name'] ?? 'Ukjent Lag';
            final players = data['players'] as List<dynamic>? ?? [];

            String subtitleText = players.isEmpty ? "Ingen spillere registrert" : players.join(" & ");

            return Card(
              elevation: 2,
              margin: const EdgeInsets.only(bottom: 12),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: const Color(0xFF0A1931),
                  child: Text(
                    teamName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
                title: Text(teamName, style: const TextStyle(fontWeight: FontWeight.bold)),
                subtitle: Text(subtitleText),
                trailing: const Icon(Icons.chevron_right),
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