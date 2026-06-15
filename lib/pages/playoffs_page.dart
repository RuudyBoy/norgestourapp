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

        final all = snapshot.data!.docs;

        if (all.isEmpty) {
          return Center(
            child: Text(
              "Sluttspill er ikke satt opp enda.",
              style: AppText.uiCaption.copyWith(
                  color: isDark ? AppColors.nightInk3 : AppColors.ink3),
            ),
          );
        }

        List<DocumentSnapshot> forBracket(String b) => (all
            .where((m) => (m.data() as Map)['bracket'] == b)
            .toList()
          ..sort((a, x) =>
              ((a.data() as Map)['match_number'] as int? ?? 0)
                  .compareTo((x.data() as Map)['match_number'] as int? ?? 0)));

        final aMatches = forBracket('A');
        final bMatches = forBracket('B');
        final cMatches = forBracket('C');

        return DefaultTabController(
          length: 3,
          child: Column(
            children: [
              TabBar(
                tabs: const [
                  Tab(text: "A-Sluttspill"),
                  Tab(text: "B-Sluttspill"),
                  Tab(text: "C-Sluttspill"),
                ],
                labelColor: AppColors.coral,
                unselectedLabelColor: isDark ? AppColors.nightInk3 : AppColors.ink3,
                indicatorColor: AppColors.coral,
              ),
              Expanded(
                child: TabBarView(
                  children: [
                    _BracketList(matches: aMatches, isDark: isDark, emptyLabel: 'A'),
                    _BracketList(matches: bMatches, isDark: isDark, emptyLabel: 'B'),
                    _BracketList(matches: cMatches, isDark: isDark, emptyLabel: 'C'),
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

class _BracketList extends StatelessWidget {
  final List<DocumentSnapshot> matches;
  final bool isDark;
  final String emptyLabel;

  const _BracketList({
    required this.matches,
    required this.isDark,
    required this.emptyLabel,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          '$emptyLabel-sluttspill ikke satt opp.',
          style: AppText.uiCaption.copyWith(
              color: isDark ? AppColors.nightInk3 : AppColors.ink3),
        ),
      );
    }

    // Group by round
    final byRound = <String, List<DocumentSnapshot>>{};
    for (final m in matches) {
      final round = (m.data() as Map)['round'] as String? ?? '';
      byRound.putIfAbsent(round, () => []).add(m);
    }

    const roundOrder = ['r16', 'qf', 'sf', 'final'];
    final sortedRounds = byRound.keys.toList()
      ..sort((a, b) {
        final ia = roundOrder.indexOf(a);
        final ib = roundOrder.indexOf(b);
        return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
      });

    final roundLabels = <String, String>{
      'r16': '16-delsfinaler',
      'qf': 'Kvartfinaler',
      'sf': 'Semifinaler',
      'final': 'FINALE',
    };

    return ListView(
      padding: const EdgeInsets.all(AppTheme.pageHPad),
      children: [
        for (final round in sortedRounds) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              roundLabels[round] ?? round.toUpperCase(),
              style: AppText.dispKicker().copyWith(color: AppColors.coral),
            ),
          ),
          for (final m in byRound[round]!) _MatchCard(matchDoc: m, isDark: isDark),
        ],
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final DocumentSnapshot matchDoc;
  final bool isDark;

  const _MatchCard({required this.matchDoc, required this.isDark});

  @override
  Widget build(BuildContext context) {
    final d = matchDoc.data() as Map<String, dynamic>;
    final status = d['status'] as String? ?? 'pending';
    final isLive = status == 'live';
    final isFinished = status == 'finished';
    final isPending = status == 'pending';
    final homeScore = d['home_score'] as int? ?? 0;
    final awayScore = d['away_score'] as int? ?? 0;
    final teamAName = d['team_a_name'] as String? ?? 'TBD';
    final teamBName = d['team_b_name'] as String? ?? 'TBD';

    final textColor = isDark ? AppColors.nightInk : AppColors.ink;
    final dimColor = isDark ? AppColors.nightInk3 : AppColors.ink3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface1 : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowSm,
        border: Border.all(
          color: isLive ? AppColors.coral : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: isFinished
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchStatsPage(
                      matchId: matchDoc.id,
                      teamAName: teamAName,
                      teamBName: teamBName,
                    ),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  teamAName,
                  style: AppText.uiBody.copyWith(
                    color: isPending ? dimColor : textColor,
                    fontWeight:
                        (isFinished && homeScore > awayScore) ? FontWeight.bold : null,
                    fontStyle: isPending ? FontStyle.italic : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: isLive
                    ? Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text("LIVE",
                            style: AppText.monoSm
                                .copyWith(color: Colors.white, fontSize: 10)),
                      )
                    : Text(
                        isFinished ? "$homeScore – $awayScore" : "–",
                        style: AppText.dispScore(18).copyWith(color: textColor),
                      ),
              ),
              Expanded(
                child: Text(
                  teamBName,
                  style: AppText.uiBody.copyWith(
                    color: isPending ? dimColor : textColor,
                    fontWeight:
                        (isFinished && awayScore > homeScore) ? FontWeight.bold : null,
                    fontStyle: isPending ? FontStyle.italic : null,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
