import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:norges_tour_app/logic/stats_logic.dart';
import 'package:norges_tour_app/pages/fantasy/models.dart';

// Henter alle spillere fra Firestore og regner ut fantasy-statistikken deres
// fra hendelsene i alle kamper (samme utregning som statistikksidene).
Future<List<FantasyPlayer>> fetchFantasyPlayers() async {
  // 1. Hent registrerte spillere fra Firestore
  final playersSnapshot = await FirebaseFirestore.instance.collection('players').get();
  
  // 2. Hent alle kamper for å regne ut statistikk fra hendelsene
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
      total.technicalErrors += s.technicalErrors;
      total.digs += s.digs;
      total.perfectReceptions += s.perfectReceptions;
      total.goodReceptions += s.goodReceptions;
      total.servesInPlay += s.servesInPlay;
    });
  }

  // 3. Lag FantasyPlayer for alle spillerne i databasen
  List<FantasyPlayer> fantasyPlayers = [];
  
  for (var doc in playersSnapshot.docs) {
    final data = doc.data();
    final firstName = data['first_name'] ?? '';
    final lastName = data['last_name'] ?? '';
    final name = "$firstName $lastName".trim();
    final team = data['club'] ?? 'Ukjent Klubb';
    final imageUrl = data['image_url'] ?? '';
    
    // Koble til statistikken (uavhengig av store/små bokstaver og mellomrom)
    final statsKey = name.toLowerCase();
    final stats = totalStatsMap[statsKey];
    
    final int kills = stats?.kills ?? 0;
    final int blocks = stats?.blocks ?? 0;
    final int aces = stats?.aces ?? 0;
    final int sets = stats?.setAssists ?? 0;
    
    // Anslag for forsvar og mottak når de ikke logges som egne hendelser
    final int digs = (blocks * 0.5 + kills * 0.2).round(); 
    final int receives = (aces * 0.8).round();
    
    final int totalPoints = kills + blocks + aces;
    
    // Dynamisk pris: starter på 6,0 mill. og øker med prestasjonspoeng
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
        stats: stats,
      ),
    );
  }
  
  // Sorter spillerne etter totalpoeng, høyest først
  fantasyPlayers.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
  
  return fantasyPlayers;
}
