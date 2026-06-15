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
      builder: (context, teamSnap) {
        if (teamSnap.hasError) {
          return Center(child: Text('Error: ${teamSnap.error}', style: const TextStyle(color: Colors.red)));
        }
        if (!teamSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }

        final allTeams = teamSnap.data!.docs;

        // Collect unique group names from teams
        final groupNames = allTeams
            .map((t) => (t.data() as Map<String, dynamic>)['group'] as String?)
            .whereType<String>()
            .toSet()
            .toList()
          ..sort();

        if (groupNames.isEmpty) {
          return Center(
            child: Text(
              "Ingen grupper generert enda.",
              style: AppText.uiCaption.copyWith(
                  color: isDark ? AppColors.nightInk3 : AppColors.ink3),
            ),
          );
        }

        // Fetch all group matches for this tournament once
        return StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .where('tournament_id', isEqualTo: tournamentId)
              .where('stage', isEqualTo: 'group')
              .snapshots(),
          builder: (context, matchSnap) {
            final allMatches =
                matchSnap.hasData ? matchSnap.data!.docs : <DocumentSnapshot>[];

            return ListView.builder(
              padding: const EdgeInsets.all(AppTheme.pageHPad),
              itemCount: groupNames.length,
              itemBuilder: (context, index) {
                final groupName = groupNames[index];

                final groupTeams = allTeams
                    .where((t) =>
                        (t.data() as Map<String, dynamic>)['group'] == groupName)
                    .toList()
                  ..sort((a, b) {
                    final ap =
                        (a.data() as Map<String, dynamic>)['group_placement']
                            as int? ??
                            99;
                    final bp =
                        (b.data() as Map<String, dynamic>)['group_placement']
                            as int? ??
                            99;
                    if (ap != 99 || bp != 99) return ap.compareTo(bp);
                    final as_ = (a.data() as Map<String, dynamic>)['seed']
                            as int? ??
                        99;
                    final bs = (b.data() as Map<String, dynamic>)['seed']
                            as int? ??
                        99;
                    return as_.compareTo(bs);
                  });

                final groupMatches = allMatches
                    .where((m) =>
                        (m.data() as Map<String, dynamic>)['group'] == groupName)
                    .toList()
                  ..sort((a, b) {
                    final ta = (a.data() as Map<String, dynamic>)['match_type']
                            as String? ??
                        '';
                    final tb = (b.data() as Map<String, dynamic>)['match_type']
                            as String? ??
                        '';
                    return ta.compareTo(tb);
                  });

                return _GroupCard(
                  groupName: groupName,
                  groupTeams: groupTeams,
                  groupMatches: groupMatches,
                  isDark: isDark,
                );
              },
            );
          },
        );
      },
    );
  }
}

class _GroupCard extends StatelessWidget {
  final String groupName;
  final List<DocumentSnapshot> groupTeams;
  final List<DocumentSnapshot> groupMatches;
  final bool isDark;

  const _GroupCard({
    required this.groupName,
    required this.groupTeams,
    required this.groupMatches,
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

          // Teams list (standings)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8),
            child: Column(
              children: [
                // Header row
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                  child: Row(
                    children: [
                      const SizedBox(width: 36),
                      Expanded(
                        flex: 5,
                        child: Text("LAG",
                            style: AppText.monoSm.copyWith(
                                color: isDark ? AppColors.nightInk3 : AppColors.ink3)),
                      ),
                      SizedBox(
                        width: 60,
                        child: Text("PLASS",
                            style: AppText.monoSm.copyWith(
                                color: isDark ? AppColors.nightInk3 : AppColors.ink3),
                            textAlign: TextAlign.center),
                      ),
                    ],
                  ),
                ),
                const Divider(height: 1),
                ...groupTeams.asMap().entries.map((entry) {
                  final idx = entry.key;
                  final d = entry.value.data() as Map<String, dynamic>;
                  final placement = d['group_placement'] as int?;
                  final seed = d['seed'] as int?;

                  final Color dotColor;
                  if (placement == 1) {
                    dotColor = AppColors.coral;
                  } else if (placement == 2) {
                    dotColor = AppColors.blueBright;
                  } else if (placement != null) {
                    dotColor = isDark ? AppColors.nightSurface2 : AppColors.sand2;
                  } else {
                    dotColor = isDark ? AppColors.nightSurface2 : AppColors.sand2;
                  }

                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Row(
                      children: [
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                          child: Center(
                            child: Text(
                              placement?.toString() ?? (idx + 1).toString(),
                              style: AppText.monoSm.copyWith(
                                color: (placement != null && placement <= 2)
                                    ? Colors.white
                                    : (isDark ? AppColors.nightInk2 : AppColors.ink2),
                                fontSize: 12,
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
                                d['team_name'] ?? 'Ukjent Lag',
                                style: AppText.uiBody.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: isDark ? AppColors.nightInk : AppColors.ink,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                "Seed $seed • ${d['player1_name'] ?? ''} & ${d['player2_name'] ?? ''}",
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
                        SizedBox(
                          width: 60,
                          child: Text(
                            placement != null ? "${placement}. plass" : "-",
                            style: AppText.uiBody.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? AppColors.nightInk : AppColors.ink,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),

          Divider(height: 1, color: isDark ? AppColors.nightSurface2 : AppColors.sand2),

          // Matches
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "KAMPER",
                  style: AppText.monoSm
                      .copyWith(color: isDark ? AppColors.nightInk3 : AppColors.ink3),
                ),
                const SizedBox(height: 8),
                if (groupMatches.isEmpty)
                  Text("Ingen kamper satt opp.",
                      style: AppText.uiCaption.copyWith(
                          color: isDark ? AppColors.nightInk3 : AppColors.ink3))
                else
                  ...groupMatches.map((m) => _buildMatchRow(context, m, isDark)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMatchRow(
      BuildContext context, DocumentSnapshot matchDoc, bool isDark) {
    final d = matchDoc.data() as Map<String, dynamic>;
    final mType = d['match_type'] as String? ?? '';
    final isLive = d['status'] == 'live';
    final isFinished = d['status'] == 'finished';
    final homeScore = d['home_score'] as int? ?? 0;
    final awayScore = d['away_score'] as int? ?? 0;

    String label = 'Kamp';
    Color labelColor = AppColors.coral;
    if (mType == 'group_match_1') { label = 'Kamp 1'; }
    if (mType == 'group_match_2') { label = 'Kamp 2'; }
    if (mType == 'group_match_3') { label = 'Vinnerkamp'; labelColor = Colors.amber.shade700; }
    if (mType == 'group_match_4') { label = 'Taperkamp'; labelColor = Colors.grey.shade500; }

    return InkWell(
      onTap: isFinished
          ? () => Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => MatchStatsPage(
                    matchId: matchDoc.id,
                    teamAName: d['team_a_name'] ?? 'Lag A',
                    teamBName: d['team_b_name'] ?? 'Lag B',
                  ),
                ),
              )
          : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Row(
          children: [
            SizedBox(
              width: 90,
              child: Text(label,
                  style: AppText.monoSm.copyWith(color: labelColor, fontSize: 10)),
            ),
            Expanded(
              child: Text(
                "${d['team_a_name'] ?? 'TBD'} – ${d['team_b_name'] ?? 'TBD'}",
                style: AppText.uiCaption
                    .copyWith(color: isDark ? AppColors.nightInk : AppColors.ink),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (isLive)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                    color: AppColors.coral, borderRadius: BorderRadius.circular(4)),
                child: Text("LIVE",
                    style: AppText.monoSm.copyWith(color: Colors.white, fontSize: 10)),
              )
            else
              Text(
                isFinished ? "$homeScore – $awayScore" : "-",
                style: AppText.uiBody.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? AppColors.nightInk : AppColors.ink,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
