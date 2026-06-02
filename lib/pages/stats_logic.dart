// lib/stats_logic.dart

class PlayerMatchStats {
  String playerName;
  String teamName;
  
  int kills = 0;
  int attackErrors = 0;
  int blocks = 0;
  int aces = 0;
  int serviceErrors = 0;
  int receptionErrors = 0;
  int setAssists = 0;
  int setAttempts = 0;
  int sideoutPoints = 0; 

  // NYTT: Kart for å lagre detaljer (f.eks. {"Hardtangrep: Linje": 3, "Blokk ut": 2})
  Map<String, int> killDetails = {};
  Map<String, int> aceDetails = {};
  Map<String, int> attackErrorDetails = {};
  
  PlayerMatchStats({required this.playerName, required this.teamName});

  int get totalPoints => kills + blocks + aces;
  
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
    String action = event['action'] ?? '';
    String phase = event['phase'] ?? '';
    String? subType = event['sub_type']; // Henter den nye detaljen

    if (!statsMap.containsKey(pKey)) {
      statsMap[pKey] = PlayerMatchStats(playerName: pKey, teamName: team);
    }

    final stats = statsMap[pKey]!;

    switch (action) {
      case 'Kill':
        stats.kills++;
        if (phase == 'Sideout') stats.sideoutPoints++;
        // Lagre detalj
        if (subType != null) {
          stats.killDetails[subType] = (stats.killDetails[subType] ?? 0) + 1;
        }
        break;
        
      case 'Attack Error':
        stats.attackErrors++;
        if (subType != null) {
          stats.attackErrorDetails[subType] = (stats.attackErrorDetails[subType] ?? 0) + 1;
        }
        break;
        
      case 'Ace':
        stats.aces++;
        if (subType != null) {
          stats.aceDetails[subType] = (stats.aceDetails[subType] ?? 0) + 1;
        }
        break;

      case 'Block': stats.blocks++; break;
      case 'Service Error': stats.serviceErrors++; break;
      case 'Reception Error': stats.receptionErrors++; break;
      case 'Set Assist': stats.setAssists++; break;
      case 'Set Attempt': stats.setAttempts++; break;
    }
  }
  return statsMap;
}