import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tour_detail_page.dart'; // For navigasjon til turnering
import 'player_detail_page.dart'; // For navigasjon til spiller

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        // Background image
        decoration: const BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/4.png'),
            fit: BoxFit.cover,
          ),
        ),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              
              // 1. HEADER / LOGO
              Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 250),
                  child: Image.asset(
                    'assets/images/logo.png',
                    height: 200,
                    fit: BoxFit.cover,
                  ),
                ),
              ),

              const SizedBox(height: 24),

              // 
              // --- SEKSJON 1: POPULÆRE SPILLERE (Horisontal) ---
              // 
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Mest populære spillere',
                  style: TextStyle(
                    fontSize: 22, 
                    fontWeight: FontWeight.bold, 
                    color: Colors.white,
                  ),
                ),
              ),
              
              const SizedBox(height: 12),

              // StreamBuilder for spillere
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('players').limit(5).snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()));

                  final players = snapshot.data!.docs;

                  return SizedBox(
                    height: 180, // Høyde på spillerkort-listen
                    child: ListView.builder(
                      scrollDirection: Axis.horizontal,
                      itemCount: players.length,
                      itemBuilder: (context, index) {
                        final data = players[index].data() as Map<String, dynamic>;
                        final name = "${data['first_name']} ${data['last_name']}";
                        final position = data['position'] ?? '';
                        final imageUrl = data['image_url'] ?? '';

                        return Container(
                          width: 140,
                          margin: EdgeInsets.only(left: 16, right: index == players.length - 1 ? 16 : 0),
                          child: Card(
                            elevation: 3,
                            child: InkWell(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) => PlayerDetailPage(
                                      playerId: players[index].id,
                                      playerData: data,
                                    ),
                                  ),
                                );
                              },
                              child: Column(
                                children: [
                                  const SizedBox(height: 12),
                                  CircleAvatar(
                                    radius: 40,
                                    backgroundColor: Colors.grey[200],
                                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                                    child: imageUrl.isEmpty ? const Icon(Icons.person, size: 40) : null,
                                  ),
                                  const SizedBox(height: 10),
                                  Text(
                                    name,
                                    textAlign: TextAlign.center,
                                    maxLines: 2,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    position,
                                    style: TextStyle(color: Colors.grey[600], fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  );
                },
              ),

              const SizedBox(height: 40),

              // 
              // --- SEKSJON 2: TURNERINGER (Vertikal) ---
              // 
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Turneringer for sesongen',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white, 
                  ),
                ),
              ),

              const SizedBox(height: 12),
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('tournaments').orderBy('start_date').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());
                  
                  final tournaments = snapshot.data!.docs;

                  if (tournaments.isEmpty) {
                     return const Padding(padding: EdgeInsets.all(16), child: Text("Ingen turneringer funnet.", style: TextStyle(color: Colors.white)));
                  }

                  return Column(
                    children: tournaments.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = data['name'] ?? 'Ukjent navn';
                      final date = data['start_date'] ?? 'Dato kommer'; 
                      final location = data['location'] ?? '';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                             backgroundColor: Colors.blue[50],
                             child: const Icon(Icons.emoji_events, color: Colors.blue),
                          ),
                          title: Text(name, style: const TextStyle(fontWeight: FontWeight.bold)),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                                Text(date.toString()),
                                if (location.isNotEmpty) 
                                  Row(children: [
                                     const Icon(Icons.location_on, size: 14, color: Colors.grey), 
                                     const SizedBox(width: 4),
                                     Text(location, style: const TextStyle(fontSize: 12))
                                  ]),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                             Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => TournamentDetailsPage(
                                    tournamentId: doc.id,
                                    data: data,
                                  ),
                                ),
                              );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),    
              
              const SizedBox(height: 40),

              // 
              // --- SEKSJON 3: ALLE SPILLERE (Vertikal) ---
              // 
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Alle spillere',
                  style: TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
              ),

              const SizedBox(height: 12),

              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('players').orderBy('last_name').snapshots(),
                builder: (context, snapshot) {
                  if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

                  final allPlayers = snapshot.data!.docs;

                  if (allPlayers.isEmpty) {
                    return const Padding(
                      padding: EdgeInsets.all(16),
                      child: Text(
                        "Ingen spillere funnet.",
                        style: TextStyle(color: Colors.white),
                      ),
                    );
                  }

                  return Column(
                    children: allPlayers.map((doc) {
                      final data = doc.data() as Map<String, dynamic>;
                      final name = "${data['first_name']} ${data['last_name']}";
                      final position = data['position'] ?? '';
                      final imageUrl = data['image_url'] ?? '';
                      final team = data['team'] ?? '';

                      return Card(
                        elevation: 2,
                        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 5),
                        child: ListTile(
                          leading: CircleAvatar(
                            radius: 25,
                            backgroundColor: Colors.grey[200],
                            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty ? const Icon(Icons.person) : null,
                          ),
                          title: Text(
                            name,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (position.isNotEmpty) Text(position),
                              if (team.isNotEmpty)
                                Text(
                                  team,
                                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                                ),
                            ],
                          ),
                          trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => PlayerDetailPage(
                                  playerId: doc.id,
                                  playerData: data,
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
              ),

              const SizedBox(height: 40),

              // 
              // --- SEKSJON 4: SISTE NYTT (Valgfritt, krever 'news' collection) ---
              // 
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.0),
                child: Text(
                  'Siste Nytt',
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
              const SizedBox(height: 12),
              
              StreamBuilder<QuerySnapshot>(
                stream: FirebaseFirestore.instance.collection('news').limit(3).snapshots(),
                builder: (context, snapshot) {
                   // Viser ingenting hvis 'news' ikke finnes eller er tom
                   if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

                   return Column(
                     children: snapshot.data!.docs.map((doc) {
                        final data = doc.data() as Map<String, dynamic>;
                        return Card(
                          margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                          child: ListTile(
                             contentPadding: const EdgeInsets.all(10),
                             leading: Container(
                               width: 60, height: 60, color: Colors.grey[300],
                               child: data['image_url'] != null 
                                  ? Image.network(data['image_url'], fit: BoxFit.cover)
                                  : const Icon(Icons.article),
                             ),
                             title: Text(data['title'] ?? 'Nyhet', style: const TextStyle(fontWeight: FontWeight.bold)),
                             subtitle: Text(data['summary'] ?? 'Les mer...', maxLines: 2, overflow: TextOverflow.ellipsis),
                          ),
                        );
                     }).toList(),
                   );
                },
              ),

              const SizedBox(height: 40), // Bunn-padding
            ], 
          ),
        ),
      ),
    );
  }
}