import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'match_stats_page.dart';

class PlayoffsPage extends StatelessWidget {
  final String tournamentId;

  const PlayoffsPage({super.key, required this.tournamentId});

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('tournament_id', isEqualTo: tournamentId)
          .where('stage', isEqualTo: 'playoff')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final playoffMatches = snapshot.data!.docs;
        if (playoffMatches.isEmpty) {
          return Center(
            child: Text(
              "Sluttspill er ikke satt opp enda.",
              style: AppText.uiCaption.copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3),
            ),
          );
        }

        // Grupper kampene etter type (round)
        Map<String, List<DocumentSnapshot>> rounds = {};
        for (var m in playoffMatches) {
          final data = m.data() as Map<String, dynamic>;
          final type = data['match_type'] as String? ?? 'Ukjent';
          rounds.putIfAbsent(type, () => []).add(m);
        }

        // Enkel logikk for å sortere runder for visning (nederst i treet til toppen)
        List<String> roundOrder = ['playoff_a_po', 'playoff_1_16', 'playoff_1_8', 'playoff_quarter', 'playoff_semi', 'playoff_bronze', 'playoff_final'];
        
        final sortedRounds = rounds.keys.toList()..sort((a, b) {
          int indexA = roundOrder.indexOf(a);
          int indexB = roundOrder.indexOf(b);
          if (indexA == -1) indexA = 99;
          if (indexB == -1) indexB = 99;
          return indexA.compareTo(indexB);
        });

        return ListView.builder(
          padding: const EdgeInsets.all(AppTheme.pageHPad),
          itemCount: sortedRounds.length,
          itemBuilder: (context, index) {
            final roundKey = sortedRounds[index];
            final matches = rounds[roundKey]!;
            
            String roundTitle = "Sluttspill";
            if (roundKey == 'playoff_a_po') roundTitle = "A-Playoff (Play-in)";
            if (roundKey == 'playoff_1_16') roundTitle = "1/16 Finaler";
            if (roundKey == 'playoff_1_8') roundTitle = "1/8 Finaler";
            if (roundKey == 'playoff_quarter') roundTitle = "Kvartfinaler";
            if (roundKey == 'playoff_semi') roundTitle = "Semifinaler";
            if (roundKey == 'playoff_bronze') roundTitle = "Bronsefinale";
            if (roundKey == 'playoff_final') roundTitle = "Finale";

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 12.0),
                  child: Text(
                    roundTitle,
                    style: AppText.dispKicker().copyWith(color: AppColors.coral),
                  ),
                ),
                ...matches.map((m) {
                  final d = m.data() as Map<String, dynamic>;
                  final isLive = d['status'] == 'live';
                  final isFinished = d['status'] == 'finished';
                  final homeScore = d['home_score'] ?? 0;
                  final awayScore = d['away_score'] ?? 0;

                  return Container(
                    margin: const EdgeInsets.only(bottom: 12),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.nightSurface1 : Colors.white,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      boxShadow: AppTheme.shadowSm,
                      border: Border.all(color: isLive ? AppColors.coral : Colors.transparent, width: 1),
                    ),
                    child: ListTile(
                      onTap: isFinished ? () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => MatchStatsPage(matchId: m.id, teamAName: d['team_a_name'] ?? 'Lag A', teamBName: d['team_b_name'] ?? 'Lag B')),
                      ) : null,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                      title: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              d['team_a_name'] ?? 'Lag A',
                              style: AppText.uiBody.copyWith(
                                color: isDark ? AppColors.nightInk : AppColors.ink,
                                fontWeight: (isFinished && homeScore > awayScore) ? FontWeight.bold : FontWeight.normal,
                              ),
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16.0),
                            child: isLive 
                                ? Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(4)),
                                    child: Text("LIVE", style: AppText.monoSm.copyWith(color: Colors.white, fontSize: 10)),
                                  )
                                : Text(
                                    isFinished ? "$homeScore - $awayScore" : "-",
                                    style: AppText.dispScore(18).copyWith(color: isDark ? AppColors.nightInk : AppColors.ink),
                                  ),
                          ),
                          Expanded(
                            child: Text(
                              d['team_b_name'] ?? 'Lag B',
                              style: AppText.uiBody.copyWith(
                                color: isDark ? AppColors.nightInk : AppColors.ink,
                                fontWeight: (isFinished && awayScore > homeScore) ? FontWeight.bold : FontWeight.normal,
                              ),
                              textAlign: TextAlign.right,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 12),
              ],
            );
          },
        );
      },
    );
  }
}
