import 'package:cloud_firestore/cloud_firestore.dart';
import '../stats_logic.dart';
import 'models.dart';

// Dynamically fetch and compute fantasy players from Firestore
Future<List<FantasyPlayer>> fetchFantasyPlayers() async {
  // 1. Fetch registered players from Firestore
  final playersSnapshot = await FirebaseFirestore.instance.collection('players').get();
  
  // 2. Fetch all matches to calculate statistics from live events
  final matchesSnapshot = await FirebaseFirestore.instance.collection('matches').get();
  
  Map<String, PlayerMatchStats> totalStatsMap = {};

  final allEventSnapshots = await Future.wait(
    matchesSnapshot.docs.map((m) => m.reference.collection('events').get()),
  );

  for (final eventsSnapshot in allEventSnapshots) {
    if (eventsSnapshot.docs.isEmpty) continue;

    final typedList = eventsSnapshot.docs.map((d) => d.data()).toList();
    final matchStats = calculateMatchStats(typedList);

    matchStats.players.forEach((playerName, s) {
      final key = playerName.trim().toLowerCase();
      if (!totalStatsMap.containsKey(key)) {
        totalStatsMap[key] = PlayerMatchStats(
          playerName: playerName,
          teamName: s.teamName,
        );
      }
      final total = totalStatsMap[key]!;
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

  // 3. Build FantasyPlayer models for all players in the database
  List<FantasyPlayer> fantasyPlayers = [];
  
  for (var doc in playersSnapshot.docs) {
    final data = doc.data();
    final firstName = data['first_name'] ?? '';
    final lastName = data['last_name'] ?? '';
    final name = "$firstName $lastName".trim();
    final team = data['club'] ?? 'Ukjent Klubb';
    final imageUrl = data['image_url'] ?? '';
    
    // Match against performance stats (case-insensitive and trimmed)
    final statsKey = name.toLowerCase();
    final stats = totalStatsMap[statsKey];
    
    final int kills = stats?.kills ?? 0;
    final int blocks = stats?.blocks ?? 0;
    final int aces = stats?.aces ?? 0;
    final int sets = stats?.setAssists ?? 0;
    
    // Reasonable estimates for digs & receives if not tracked explicitly in events
    final int digs = (blocks * 0.5 + kills * 0.2).round(); 
    final int receives = (aces * 0.8).round();
    
    final int totalPoints = kills + blocks + aces;
    
    // Calculate a dynamic price: starts at $6.0m and increases with performance points
    final double price = (6.0 + totalPoints * 0.15).clamp(5.0, 15.0);
    
    fantasyPlayers.add(
      FantasyPlayer(
        id: doc.id,
        name: name,
        team: team,
        price: double.parse(price.toStringAsFixed(1)),
        totalPoints: totalPoints,
        imageUrl: imageUrl,
        blocks: blocks,
        digs: digs,
        attacks: kills,
        sets: sets,
        receives: receives,
        aces: aces,
      ),
    );
  }
  
  // Sort players by total points descending as the default order
  fantasyPlayers.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
  
  return fantasyPlayers;
}
