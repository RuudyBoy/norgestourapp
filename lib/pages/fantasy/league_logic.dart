import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'models.dart';
import 'fantasy_point_matrix.dart';

class LeaderboardEntry {
  final String userId;
  final String teamName;
  final String managerName;
  final int totalPoints;

  LeaderboardEntry({
    required this.userId,
    required this.teamName,
    required this.managerName,
    required this.totalPoints,
  });
}

class LeagueLogic {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Calculates total points for a given squad. Squad-dokumentet er keyet på
  // rolle → spillerId, så hver spiller scores rollelåst for sin slot.
  static int _calculateSquadPoints(Map<String, dynamic> squadData, List<FantasyPlayer> allPlayers) {
    int total = 0;
    for (var entry in squadData.entries) {
      final playerId = entry.value;
      if (playerId != null && playerId is String) {
        final matches = allPlayers.where((p) => p.id == playerId);
        if (matches.isNotEmpty) {
          total += calculatePlayerPoints(matches.first.stats, entry.key);
        }
      }
    }
    return total;
  }

  // Fetches global leaderboard using a Collection Group query
  static Future<List<LeaderboardEntry>> getGlobalLeaderboard(List<FantasyPlayer> allPlayers) async {
    List<LeaderboardEntry> leaderboard = [];
    
    try {
      // Note: This requires a Collection Group index on 'fantasy' collection in Firebase Console
      final squadsQuery = await _firestore.collectionGroup('fantasy').get();
      
      // Filter manually to only get the 'squad' documents
      final squadDocs = squadsQuery.docs.where((doc) => doc.id == 'squad').toList();

      for (var squadDoc in squadDocs) {
        // The parent of the 'fantasy' subcollection is the user document
        final userDocRef = squadDoc.reference.parent.parent;
        if (userDocRef == null) continue;

        final userDoc = await userDocRef.get();
        if (!userDoc.exists) continue;

        final userData = userDoc.data() as Map<String, dynamic>;
        final String teamName = userData['teamName'] ?? 'Ukjent Lag';
        final String managerName = userData['name'] ?? 'Ukjent Manager';
        final String userId = userDocRef.id;

        final squadData = squadDoc.data();
        final points = _calculateSquadPoints(squadData, allPlayers);

        leaderboard.add(LeaderboardEntry(
          userId: userId,
          teamName: teamName,
          managerName: managerName,
          totalPoints: points,
        ));
      }

      // Sort descending
      leaderboard.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
    } catch (e) {
      debugPrint('Error fetching global leaderboard: $e');
    }

    return leaderboard;
  }

  // Calculate ownership percentages for all players
  static Future<Map<String, double>> getPlayerOwnershipPercentages() async {
    Map<String, int> selectionCounts = {};
    int totalSquads = 0;

    try {
      final squadsQuery = await _firestore.collectionGroup('fantasy').get();
      final squadDocs = squadsQuery.docs.where((doc) => doc.id == 'squad').toList();
      totalSquads = squadDocs.length;

      if (totalSquads == 0) return {};

      for (var doc in squadDocs) {
        final squadData = doc.data();
        for (var playerId in squadData.values) {
          if (playerId != null && playerId is String) {
            selectionCounts[playerId] = (selectionCounts[playerId] ?? 0) + 1;
          }
        }
      }
    } catch (e) {
      debugPrint('Error calculating ownership: $e');
    }

    Map<String, double> percentages = {};
    if (totalSquads > 0) {
      selectionCounts.forEach((playerId, selectionCount) {
        percentages[playerId] = (selectionCount / totalSquads) * 100.0;
      });
    }

    return percentages;
  }
}
