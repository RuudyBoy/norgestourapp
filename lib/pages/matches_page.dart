import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'match_stats_page.dart';

class MatchesPage extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;
  final bool isEmbedded;

  const MatchesPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isEmbedded = false,
  });

  @override
  Widget build(BuildContext context) {
    final content = DefaultTabController(
      length: 3,
      child: Column(
        children: [
          const TabBar(
            labelColor: AppColors.coral,
            unselectedLabelColor: Colors.grey,
            indicatorColor: AppColors.coral,
            tabs: [
              Tab(text: "Kommende"),
              Tab(text: "Live"),
              Tab(text: "Ferdig"),
            ],
          ),
          Expanded(
            child: TabBarView(
              children: [
                _MatchesList(tournamentId: tournamentId, statusFilter: 'scheduled'),
                _MatchesList(tournamentId: tournamentId, statusFilter: 'live'),
                _MatchesList(tournamentId: tournamentId, statusFilter: 'finished'),
              ],
            ),
          ),
        ],
      ),
    );

    if (isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Kamper - $tournamentName"),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }
}

class _MatchesList extends StatelessWidget {
  final String tournamentId;
  final String statusFilter;

  const _MatchesList({required this.tournamentId, required this.statusFilter});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('tournament_id', isEqualTo: tournamentId)
          .where('status', isEqualTo: statusFilter)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }

        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const Center(
            child: Text("Ingen kamper i denne kategorien enda."),
          );
        }

        final matches = snapshot.data!.docs;

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: matches.length,
          itemBuilder: (context, index) {
            final data = matches[index].data() as Map<String, dynamic>;
            final homeScore = data['home_score'] ?? 0;
            final awayScore = data['away_score'] ?? 0;
            final homeSets = data['home_sets'] ?? 0;
            final awaySets = data['away_sets'] ?? 0;
            final currentSet = data['current_set'] ?? 1;
            final court = data['court'] ?? 'Bane ?';
            final teamAName = data['team_a_name'] ?? 'Lag A';
            final teamBName = data['team_b_name'] ?? 'Lag B';
            final startTime = data['start_time']?.toString() ?? '';
            final matchType = data['group']?.toString() ?? '';
            
            // Build the top right info string
            String rightInfo = '';
            if (startTime.isNotEmpty && matchType.isNotEmpty) {
              rightInfo = '$startTime • $matchType';
            } else if (startTime.isNotEmpty) {
              rightInfo = '$startTime • $court';
            } else if (matchType.isNotEmpty) {
              rightInfo = matchType;
            } else {
              rightInfo = court;
            }

            return GestureDetector(
              onTap: () {
                if (statusFilter == 'scheduled') {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Kampen har ikke startet enda."))
                  );
                } else {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => MatchStatsPage(
                        matchId: matches[index].id,
                        teamAName: teamAName,
                        teamBName: teamBName,
                      ),
                    ),
                  );
                }
              },
              child: Container(
                margin: const EdgeInsets.only(bottom: AppTheme.rowGap),
                padding: const EdgeInsets.all(AppTheme.cardPad),
                decoration: BoxDecoration(
                  gradient: AppColors.cardInk,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: statusFilter == 'live' ? AppColors.coral : (statusFilter == 'finished' ? Colors.white.withValues(alpha: 0.15) : AppColors.blue.withValues(alpha: 0.3)),
                            borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (statusFilter == 'live') ...[
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                const SizedBox(width: 5),
                              ],
                              Text(
                                statusFilter == 'scheduled' ? 'KOMMENDE' : (statusFilter == 'finished' ? 'FERDIG' : 'LIVE · SETT $currentSet'), 
                                style: AppText.monoSmLight
                              ),
                            ],
                          ),
                        ),
                        Text(rightInfo.toUpperCase(), style: AppText.monoSm.copyWith(color: Colors.white70)),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(teamAName.toUpperCase(),
                              style: AppText.dispH2(18).copyWith(color: Colors.white),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (statusFilter == 'finished')
                          Text('$homeSets', style: AppText.dispScore(32).copyWith(color: Colors.white))
                        else if (statusFilter == 'live')
                          Text('$homeScore', style: AppText.dispScore(32).copyWith(color: Colors.white))
                        else
                          Text('-', style: AppText.dispScore(32).copyWith(color: Colors.white54)),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(teamBName.toUpperCase(),
                              style: AppText.dispH2(18).copyWith(color: Colors.white.withValues(alpha: 0.7)),
                              overflow: TextOverflow.ellipsis),
                        ),
                        if (statusFilter == 'finished')
                          Text('$awaySets', style: AppText.dispScore(32).copyWith(color: Colors.white.withValues(alpha: 0.7)))
                        else if (statusFilter == 'live')
                          Text('$awayScore', style: AppText.dispScore(32).copyWith(color: Colors.white.withValues(alpha: 0.7)))
                        else
                          Text('-', style: AppText.dispScore(32).copyWith(color: Colors.white54)),
                      ],
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}