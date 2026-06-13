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
          .where('group', isNull: false)
          .snapshots(),
      builder: (context, snapshot) {
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
              children: teams.map((t) {
                final data = t.data() as Map<String, dynamic>;
                final placement = data['group_placement']?.toString();
                
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  child: Row(
                    children: [
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: placement != null 
                             ? (placement == '1' ? AppColors.coral : (placement == '2' ? AppColors.blueBright : AppColors.ink3))
                             : (isDark ? AppColors.nightSurface2 : AppColors.sand2),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text(
                            placement ?? '-',
                            style: AppText.monoSm.copyWith(color: Colors.white, fontSize: 12),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              data['team_name'] ?? 'Ukjent Lag',
                              style: AppText.uiBody.copyWith(
                                fontWeight: placement != null ? FontWeight.bold : FontWeight.normal,
                                color: isDark ? AppColors.nightInk : AppColors.ink,
                              ),
                            ),
                            Text(
                              "${data['player1_name']} & ${data['player2_name']}",
                              style: AppText.uiCaption.copyWith(
                                color: isDark ? AppColors.nightInk3 : AppColors.ink3,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
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
                StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('matches')
                      .where('tournament_id', isEqualTo: tournamentId)
                      .where('stage', isEqualTo: 'group') // Krever at Admin/Simulator setter 'stage': 'group'
                      // Fiks for legacy: hvis ikke stage finnes, kan man filtrere manuelt, 
                      // men for ny struktur antar vi 'stage' finnes.
                      .snapshots(),
                  builder: (context, matchSnap) {
                    if (!matchSnap.hasData) return const SizedBox.shrink();
                    
                    final groupMatches = matchSnap.data!.docs.where((doc) {
                       final d = doc.data() as Map<String, dynamic>;
                       final mt = d['match_type'] as String?;
                       // Her sjekker vi enklest ved å se om lagene i kampen er i denne gruppen
                       final tAId = d['team_a_id'] as String?;
                       bool isThisGroup = teams.any((t) => t.id == tAId);
                       return isThisGroup && mt != null && mt.startsWith('group');
                    }).toList();

                    if (groupMatches.isEmpty) return const Text("Ingen kamper satt opp for denne puljen.");

                    // Sorter kampene logisk (semi 1 og 2 først, så bronse og finale)
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
                                    style: AppText.monoSm.copyWith(color: AppColors.coral),
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
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
