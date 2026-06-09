import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TeamsPage extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;

  const TeamsPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Lag - $tournamentName"),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
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

          // 4. Vis listen
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: teams.length,
            itemBuilder: (context, index) {
              final data = teams[index].data() as Map<String, dynamic>;
              
              // Hent ut info (husk at vi ikke har hentet spillernavn ennå, kun lagnavn)
              final teamName = data['team_name'] ?? 'Ukjent Lag';
              
              // Vi kan legge til logikk for å hente spillernavn senere
              // f.eks. player1_id og player2_id

              return Card(
                elevation: 2,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: Colors.blueAccent.withValues(alpha: 0.1),
                    child: const Icon(Icons.people, color: Colors.blueAccent),
                  ),
                  title: Text(
                    teamName,
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
                  ),
                  subtitle: const Text("Spillere kommer her..."), // Placeholder
                  trailing: const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.grey),
                  onTap: () {
                    // Her kan vi gå til en "Lag-profil" senere
                  },
                ),
              );
            },
          );
        },
      ),
    );
  }
}