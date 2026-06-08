// lib/stats_logic.dart

class PlayerMatchStats {
  String playerName;
  String teamName;
  String imageUrl;
  
  int kills = 0;
  int attackErrors = 0;
  int blocks = 0;
  int aces = 0;
  int serviceErrors = 0;
  int receptionErrors = 0;
  int setAssists = 0;
  int setAttempts = 0;
  int sideoutPoints = 0;
  int technicalErrors = 0;

  Map<String, int> killDetails = {};
  Map<String, int> aceDetails = {};
  Map<String, int> attackErrorDetails = {};
  
  PlayerMatchStats({required this.playerName, required this.teamName, this.imageUrl = ''});

  int get totalPoints => kills + blocks + aces;
  int get overgangsPoeng => (killDetails['Forsvar'] ?? 0) + (killDetails['Blokktrekk'] ?? 0);
  
  String get settingEfficiency {
    if (setAttempts == 0) return "-";
    int pct = ((setAssists / setAttempts) * 100).round();
    return "$pct%";
  }

  String get receptionEfficiency {
    int totalReceptions = sideoutPoints + receptionErrors;
    if (totalReceptions == 0) return "-";
    int pct = ((sideoutPoints / totalReceptions) * 100).round();
    return "$pct%";
  }
}

class TeamMatchStats {
  String teamName;
  int attackPoints = 0;
  int blockPoints = 0;
  int servePoints = 0;
  int opponentErrors = 0;
  int sideoutPoints = 0;
  int overgangsPoeng = 0;
  
  TeamMatchStats(this.teamName);
}

class MatchStatsResult {
  final Map<String, PlayerMatchStats> players;
  final Map<String, TeamMatchStats> teams;
  MatchStatsResult(this.players, this.teams);
}

MatchStatsResult calculateMatchStats(List<Map<String, dynamic>> events) {
  Map<String, PlayerMatchStats> playerMap = {};
  Map<String, TeamMatchStats> teamMap = {};

  for (var event in events) {
    String team = event['team'] ?? '';
    if (team.isNotEmpty && !teamMap.containsKey(team)) {
      teamMap[team] = TeamMatchStats(team);
    }

    String pKey = event['player_name'] ?? 'Ukjent';
    String action = event['action'] ?? '';
    String phase = event['phase'] ?? '';
    String? subType = event['sub_type']; 

    // Handle team-wide opponent errors
    if (action == 'Opponent Error') {
      if (team.isNotEmpty) teamMap[team]!.opponentErrors++;
      continue; // Opponent error is not assigned to a player
    }

    // Ignorer "Lag" for å unngå en fiktiv spiller (just in case)
    if (pKey == 'Lag' || pKey.toLowerCase() == 'lag') continue;

    if (!playerMap.containsKey(pKey)) {
      playerMap[pKey] = PlayerMatchStats(
        playerName: pKey, 
        teamName: team, 
        imageUrl: event['image_url'] ?? event['image'] ?? event['photoUrl'] ?? event['photo_url'] ?? event['picture'] ?? ''
      );
    }

    final stats = playerMap[pKey]!;
    final tStats = teamMap[team];

    switch (action) {
      case 'Kill':
        stats.kills++;
        if (tStats != null) tStats.attackPoints++;
        if (phase == 'Sideout') {
          stats.sideoutPoints++;
          if (tStats != null) tStats.sideoutPoints++;
        }
        if (subType != null) {
          stats.killDetails[subType] = (stats.killDetails[subType] ?? 0) + 1;
          if (tStats != null && (subType == 'Forsvar' || subType == 'Blokktrekk')) {
            tStats.overgangsPoeng++;
          }
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
        if (tStats != null) tStats.servePoints++;
        if (subType != null) {
          stats.aceDetails[subType] = (stats.aceDetails[subType] ?? 0) + 1;
        }
        break;

      case 'Block': 
        stats.blocks++; 
        if (tStats != null) tStats.blockPoints++;
        break;
      case 'Service Error': stats.serviceErrors++; break;
      case 'Reception Error': stats.receptionErrors++; break;
      case 'Set Assist': stats.setAssists++; break;
      case 'Set Attempt': stats.setAttempts++; break;
      case 'Technical Error': stats.technicalErrors++; break;
    }
  }
  return MatchStatsResult(playerMap, teamMap);
}