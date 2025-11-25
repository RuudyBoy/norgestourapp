// lib/stats_logic.dart

class PlayerMatchStats {
  String playerName;
  String teamName;
  
  // Poeng-stats
  int kills = 0;
  int attackErrors = 0;
  int blocks = 0;
  int aces = 0;
  int serviceErrors = 0;
  
  // Mottak
  int receptionErrors = 0;

  // Legging
  int setAssists = 0; // Bra legg (førte til kill)
  int setAttempts = 0; // Totale legg

  // Sideout (Poeng tatt på mottak)
  int sideoutPoints = 0; 
  
  PlayerMatchStats({required this.playerName, required this.teamName});

  int get totalPoints => kills + blocks + aces;
  
  // Beregn legge-effektivitet i prosent
  String get settingEfficiency {
    if (setAttempts == 0) return "-";
    int pct = ((setAssists / setAttempts) * 100).round();
    return "$pct%";
  }
}

Map<String, PlayerMatchStats> calculateMatchStats(List<Map<String, dynamic>> events) {
  Map<String, PlayerMatchStats> statsMap = {};

  for (var event in events) {
    String pKey = event['player_name'] ?? 'Ukjent';
    String team = event['team'] ?? '';
    String action = event['action'];
    String phase = event['phase'] ?? ''; // Sideout eller Break Point

    if (!statsMap.containsKey(pKey)) {
      statsMap[pKey] = PlayerMatchStats(playerName: pKey, teamName: team);
    }

    final stats = statsMap[pKey]!;

    // --- 1. TELL HANDLINGER ---
    switch (action) {
      case 'Kill':
        stats.kills++;
        // Hvis dette var i Sideout-fasen, tell det som et Sideout-poeng
        if (phase == 'Sideout') stats.sideoutPoints++;
        break;
        
      case 'Attack Error':
        stats.attackErrors++;
        break;
        
      case 'Block':
        stats.blocks++;
        // Blokker i sideout-fase er sjeldne (da må motstander ha kontret), men vi teller dem
        if (phase == 'Sideout') stats.sideoutPoints++; 
        break;
        
      case 'Ace':
        stats.aces++;
        // Ess skjer alltid i Break Point-fase (egen serve)
        break;
        
      case 'Service Error':
        stats.serviceErrors++;
        break;
        
      case 'Reception Error':
        stats.receptionErrors++;
        break;

      // NYTT: Legging
      case 'Set Assist':
        stats.setAssists++;
        break;
      case 'Set Attempt':
        stats.setAttempts++;
        break;
    }
  }
  return statsMap;
}