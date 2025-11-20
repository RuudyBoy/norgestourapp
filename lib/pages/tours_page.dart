import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart'; // 1. For å hente data
import '/pages/tour_detail_page.dart'; // 2. For å navigere (sjekk mappenavnet ditt!)

class ToursPage extends StatelessWidget {
  const ToursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('Turneringer'),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // --- HEADER IMAGE (Beholdt designet ditt) ---
          Stack(
            alignment: Alignment.center,
            children: [
              Image.network(
                'https://images.unsplash.com/photo-1559164342-b31f433a0b17?q=80&w=2070&auto=format&fit=crop',
                height: 200,
                width: double.infinity,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return Container(
                    height: 200,
                    color: Colors.grey[800],
                    child: const Icon(Icons.golf_course, color: Colors.grey, size: 60),
                  );
                },
              ),
              Container(
                height: 200,
                decoration: BoxDecoration(
                  color: Colors.black.withOpacity(0.5),
                ),
              ),
              const Text(
                'Norges Tour 2025',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  shadows: [
                    Shadow(
                      blurRadius: 8.0,
                      color: Colors.black,
                      offset: Offset(2.0, 2.0),
                    ),
                  ],
                ),
              ),
            ],
          ),

          // --- LISTE OVER TURNERINGER FRA FIREBASE ---
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
              builder: (context, snapshot) {
                // Venter på data...
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }

                // Hvis feil...
                if (snapshot.hasError) {
                  return const Center(child: Text("Noe gikk galt."));
                }

                // Hvis tomt...
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return const Center(child: Text("Ingen turneringer funnet."));
                }

                final tournaments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.all(16.0),
                  itemCount: tournaments.length,
                  itemBuilder: (context, index) {
                    final doc = tournaments[index];
                    final data = doc.data() as Map<String, dynamic>;

                    // Hent felter trygt
                    final name = data['name'] ?? 'Ukjent Navn';
                    final date = data['start_date']?.toString() ?? 'Dato kommer';
                    final imageUrl = data['image_url'] ?? 'https://via.placeholder.com/400x200';

                    return _buildTourCard(context, doc.id, data, name, date, imageUrl);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // En hjelpefunksjon som bygger kortet med Hover- og Klikk-effekt
  Widget _buildTourCard(
    BuildContext context, 
    String id, 
    Map<String, dynamic> data, 
    String name, 
    String date, 
    String imageUrl
  ) {
    // Vi fjerner GestureDetector og bruker Card som ytterste element
    return Card(
      margin: const EdgeInsets.only(bottom: 20.0),
      elevation: 4,
      // VIKTIG: Dette gjør at klikk-effekten (ripple) holder seg inni de runde hjørnene
      clipBehavior: Clip.antiAlias, 
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15.0),
      ),
      
      // InkWell gir deg automatisk Hover-effekt (på web) og Splash (på mobil)
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => TournamentDetailsPage(
                tournamentId: id,
                data: data,
              ),
            ),
          );
        },
        // Valgfritt: Du kan velge farge på hover/klikk her
        hoverColor: Colors.blue.withOpacity(0.1), 
        splashColor: Colors.blue.withOpacity(0.2),
        
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Bildet (Vi trenger ikke ClipRRect lenger fordi Card clipper for oss!)
            Image.network(
              imageUrl,
              height: 150,
              fit: BoxFit.cover,
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 150,
                  color: Colors.grey[300],
                  child: const Icon(Icons.broken_image, color: Colors.grey, size: 50),
                );
              },
            ),
            Padding(
              padding: const EdgeInsets.all(15.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: const TextStyle(
                      fontSize: 20.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 16.0, color: Colors.grey),
                      const SizedBox(width: 8.0),
                      Text(
                        date,
                        style: const TextStyle(fontSize: 16.0, color: Colors.grey),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}