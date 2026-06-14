import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'match_stats_page.dart';

class GroupsPage extends StatelessWidget {
  final String tournamentId;

  const GroupsPage({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('tournament_id', isEqualTo: tournamentId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasError) {
          return Center(child: Text('Error: ${snapshot.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final teams = snapshot.data!.docs;
        if (teams.isEmpty) {
          return Center(
            child: Text(
              "Ingen grupper generert enda.",
              style: AppText.uiCaption.copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3),
            ),
          );
        }

        // Grupper lagene
        Map<String, List<DocumentSnapshot>> groups = {};
        for (var t in teams) {
          final data = t.data() as Map<String, dynamic>;
          final g = data['group'] as String?;
          if (g != null) {
            groups.putIfAbsent(g, () => []).add(t);
          }
        }

        // Sorter gruppene alfabetisk
        final sortedGroups = groups.keys.toList()..sort();

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.pageHPad),
          itemCount: sortedGroups.length,
          itemBuilder: (context, index) {
            final groupName = sortedGroups[index];
            final groupTeams = groups[groupName]!;
            
            // Sorter lagene innad i gruppen etter plassering (hvis tilgjengelig), ellers seed
            groupTeams.sort((a, b) {
              final aData = a.data() as Map<String, dynamic>;
              final bData = b.data() as Map<String, dynamic>;
              final aPlacement = aData.containsKey('group_placement') ? aData['group_placement'] as int? : 99;
              final bPlacement = bData.containsKey('group_placement') ? bData['group_placement'] as int? : 99;
              return (aPlacement ?? 99).compareTo(bPlacement ?? 99);
            });

            return _GroupCard(
              groupName: groupName,
              teams: groupTeams,
              tournamentId: tournamentId,
              isDark: isDark,
            );
          },
        );
      },
    );
  }
}

class _TeamStats {
  final DocumentSnapshot doc;
  int matchesPlayed = 0;
  int wins = 0;
  int losses = 0;
  int points = 0;
  int pointDiff = 0;

  _TeamStats(this.doc);
}

class _GroupCard extends StatelessWidget {
  final String groupName;
  final List<DocumentSnapshot> teams;
  final String tournamentId;
  final bool isDark;

  const _GroupCard({
    required this.groupName,
    required this.teams,
    required this.tournamentId,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('tournament_id', isEqualTo: tournamentId)
          .where('stage', isEqualTo: 'group')
          .snapshots(),
      builder: (context, matchSnap) {
        if (matchSnap.hasError) {
           return Center(child: Text('Error: ${matchSnap.error}', style: const TextStyle(color: Colors.red)));
        }
        final matchDocs = matchSnap.hasData ? matchSnap.data!.docs : [];
        final groupMatches = matchDocs.where((doc) {
           final d = doc.data() as Map<String, dynamic>;
           final mt = d['match_type'] as String?;
           final tAId = d['team_a_id'] as String?;
           bool isThisGroup = teams.any((t) => t.id == tAId);
           return isThisGroup && mt != null && mt.startsWith('group');
        }).toList();

        // Calculate stats
        Map<String, _TeamStats> statsMap = {};
        for (var t in teams) {
          statsMap[t.id] = _TeamStats(t);
        }

        for (var m in groupMatches) {
          final d = m.data() as Map<String, dynamic>;
          if (d['status'] != 'finished' && d['status'] != 'live') continue;

          final tA = d['team_a_id'] as String?;
          final tB = d['team_b_id'] as String?;
          final homeScore = d['home_score'] as int? ?? 0;
          final awayScore = d['away_score'] as int? ?? 0;

          if (tA != null && statsMap.containsKey(tA)) {
             statsMap[tA]!.pointDiff += (homeScore - awayScore);
             if (d['status'] == 'finished') {
               statsMap[tA]!.matchesPlayed++;
               if (homeScore > awayScore) {
                 statsMap[tA]!.wins++;
                 statsMap[tA]!.points += 2; // 2 poeng for seier
               } else if (homeScore < awayScore) {
                 statsMap[tA]!.losses++;
               }
             }
          }

          if (tB != null && statsMap.containsKey(tB)) {
             statsMap[tB]!.pointDiff += (awayScore - homeScore);
             if (d['status'] == 'finished') {
               statsMap[tB]!.matchesPlayed++;
               if (awayScore > homeScore) {
                 statsMap[tB]!.wins++;
                 statsMap[tB]!.points += 2;
               } else if (awayScore < homeScore) {
                 statsMap[tB]!.losses++;
               }
             }
          }
        }

        final sortedStats = statsMap.values.toList();
        sortedStats.sort((a, b) {
           if (b.points != a.points) return b.points.compareTo(a.points);
           if (b.pointDiff != a.pointDiff) return b.pointDiff.compareTo(a.pointDiff);
           return 0;
        });

        return Container(
          margin: const EdgeInsets.only(bottom: 24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.nightSurface1 : Colors.white,
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            boxShadow: AppTheme.shadowSm,
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Header
              Container(
                padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                decoration: BoxDecoration(
                  gradient: isDark ? AppColors.cardInk : AppColors.heroNavy,
                ),
                child: Text(
                  "Pulje $groupName",
                  style: AppText.uiTitle.copyWith(color: Colors.white),
                ),
              ),
              
              // Lag-liste (Tabell)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8.0),
                child: Column(
                  children: [
                    // Tabell-header
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      child: Row(
                        children: [
                          const SizedBox(width: 36), // For sirkelen
                          Expanded(
                            flex: 5,
                            child: Text("LAG", style: AppText.monoSm.copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3)),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text("K", style: AppText.monoSm.copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3), textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text("V", style: AppText.monoSm.copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3), textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text("T", style: AppText.monoSm.copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3), textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text("+/-", style: AppText.monoSm.copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3), textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 1,
                            child: Text("P", style: AppText.monoSm.copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3, fontWeight: FontWeight.bold), textAlign: TextAlign.center),
                          ),
                        ],
                      ),
                    ),
                    const Divider(height: 1),
                    ...sortedStats.asMap().entries.map((entry) {
                      int idx = entry.key;
                      _TeamStats stats = entry.value;
                      final data = stats.doc.data() as Map<String, dynamic>;
                      final placement = (idx + 1).toString();
                      
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                        child: Row(
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: idx == 0 
                                   ? AppColors.coral 
                                   : (idx == 1 ? AppColors.blueBright : (isDark ? AppColors.nightSurface2 : AppColors.sand2)),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  placement,
                                  style: AppText.monoSm.copyWith(
                                    color: (idx < 2) ? Colors.white : (isDark ? AppColors.nightInk2 : AppColors.ink2), 
                                    fontSize: 12
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              flex: 5,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    data['team_name'] ?? 'Ukjent Lag',
                                    style: AppText.uiBody.copyWith(
                                      fontWeight: FontWeight.bold,
                                      color: isDark ? AppColors.nightInk : AppColors.ink,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                  Text(
                                    "${data['player1_name']} & ${data['player2_name']}",
                                    style: AppText.uiCaption.copyWith(
                                      color: isDark ? AppColors.nightInk3 : AppColors.ink3,
                                      fontSize: 10,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text("${stats.matchesPlayed}", style: AppText.uiBody.copyWith(color: isDark ? AppColors.nightInk2 : AppColors.ink2), textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text("${stats.wins}", style: AppText.uiBody.copyWith(color: isDark ? AppColors.nightInk2 : AppColors.ink2), textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text("${stats.losses}", style: AppText.uiBody.copyWith(color: isDark ? AppColors.nightInk2 : AppColors.ink2), textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text("${stats.pointDiff > 0 ? '+' : ''}${stats.pointDiff}", style: AppText.uiBody.copyWith(color: isDark ? AppColors.nightInk2 : AppColors.ink2), textAlign: TextAlign.center),
                            ),
                            Expanded(
                              flex: 1,
                              child: Text("${stats.points}", style: AppText.uiBody.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.nightInk : AppColors.ink), textAlign: TextAlign.center),
                            ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),

              Divider(height: 1, color: isDark ? AppColors.nightSurface2 : AppColors.sand2),
              
              // Kamper i denne gruppen
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "KAMPER",
                      style: AppText.monoSm.copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3),
                    ),
                    const SizedBox(height: 8),
                    Builder(builder: (context) {
                      if (!matchSnap.hasData && matchSnap.connectionState == ConnectionState.waiting) {
                        return const Center(child: CircularProgressIndicator());
                      }
                      
                      if (groupMatches.isEmpty) return const Text("Ingen kamper satt opp for denne puljen.");

                      groupMatches.sort((a, b) {
                        final mtA = (a.data() as Map)['match_type'] as String;
                        final mtB = (b.data() as Map)['match_type'] as String;
                        return mtA.compareTo(mtB);
                      });

                      return Column(
                        children: groupMatches.map((m) {
                          final d = m.data() as Map<String, dynamic>;
                          final isLive = d['status'] == 'live';
                          final isFinished = d['status'] == 'finished';
                          final homeScore = d['home_score'] ?? 0;
                          final awayScore = d['away_score'] ?? 0;
                          
                          String label = "Kamp";
                          if (d['match_type'] == 'group_semi_1') label = "Semifinale 1";
                          if (d['match_type'] == 'group_semi_2') label = "Semifinale 2";
                          if (d['match_type'] == 'group_final') label = "Gruppefinale";
                          if (d['match_type'] == 'group_bronze') label = "3. Plass";

                          return InkWell(
                            onTap: isFinished ? () => Navigator.push(
                              context,
                              MaterialPageRoute(builder: (_) => MatchStatsPage(matchId: m.id, teamAName: d['team_a_name'] ?? 'Lag A', teamBName: d['team_b_name'] ?? 'Lag B')),
                            ) : null,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(vertical: 8.0),
                              child: Row(
                                children: [
                                  Expanded(
                                    flex: 2,
                                    child: Text(
                                      label,
                                      style: AppText.monoSm.copyWith(color: AppColors.coral, fontSize: 10),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 4,
                                    child: Text(
                                      "${d['team_a_name'] ?? 'Lag A'} - ${d['team_b_name'] ?? 'Lag B'}",
                                      style: AppText.uiCaption.copyWith(color: isDark ? AppColors.nightInk : AppColors.ink),
                                    ),
                                  ),
                                  Expanded(
                                    flex: 1,
                                    child: isLive 
                                      ? Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                                          decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(4)),
                                          child: Text("LIVE", style: AppText.monoSm.copyWith(color: Colors.white, fontSize: 10), textAlign: TextAlign.center),
                                        )
                                      : Text(
                                          isFinished ? "$homeScore - $awayScore" : "-",
                                          style: AppText.uiBody.copyWith(fontWeight: FontWeight.bold, color: isDark ? AppColors.nightInk : AppColors.ink),
                                          textAlign: TextAlign.right,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      );
                    }),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
