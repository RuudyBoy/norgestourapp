import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stats_logic.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class MatchStatsPage extends StatelessWidget {
  final String matchId;
  final String teamAName;
  final String teamBName;

  const MatchStatsPage({
    super.key,
    required this.matchId,
    required this.teamAName,
    required this.teamBName,
  });

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 3,
      child: Scaffold(
        backgroundColor: AppColors.ink,
        appBar: AppBar(
          backgroundColor: AppColors.ink,
          iconTheme: const IconThemeData(color: Colors.white),
          title: Text('KAMPFAKTA', style: AppText.dispH2(18).copyWith(color: Colors.white)),
          leading: IconButton(
            icon: const Icon(Icons.arrow_back_ios, size: 18),
            onPressed: () => Navigator.pop(context),
          ),
          bottom: TabBar(
            labelColor: AppColors.coral,
            unselectedLabelColor: Colors.white54,
            indicatorColor: AppColors.coral,
            labelStyle: AppText.uiTab,
            tabs: const [
              Tab(text: 'HENDELSER'),
              Tab(text: 'LAG'),
              Tab(text: 'SPILLERE'),
            ],
          ),
        ),
        body: StreamBuilder<DocumentSnapshot>(
          stream: FirebaseFirestore.instance.collection('matches').doc(matchId).snapshots(),
          builder: (context, matchSnapshot) {
            if (!matchSnapshot.hasData) {
              return const Center(child: CircularProgressIndicator(color: AppColors.coral));
            }
            
            final matchData = matchSnapshot.data!.data() as Map<String, dynamic>? ?? {};
            final int matchHomeScore = matchData['home_score'] ?? 0;
            final int matchAwayScore = matchData['away_score'] ?? 0;
            final int currentSet = matchData['current_set'] ?? 1;
            final int homeSets = matchData['home_sets'] ?? 0;
            final int awaySets = matchData['away_sets'] ?? 0;
            final List pastSets = matchData['past_sets'] ?? [];

            return StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches')
                  .doc(matchId)
                  .collection('events')
                  .orderBy('timestamp', descending: false)
                  .snapshots(),
              builder: (context, snapshot) {
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.coral));
                }

                final docs = snapshot.data!.docs;
                // Tillater å vise scoreboard selv om events er tom
                final eventsList = docs.map((d) => d.data() as Map<String, dynamic>).toList();
            
            int homeScore = 0;
            int awayScore = 0;
            int currentSetNumber = 1;
            
            // To show in the events tab (newest at top), we will store score with each event
            List<Map<String, dynamic>> enrichedEvents = [];
            for (var event in eventsList) {
              int eventSet = event['set_number'] ?? currentSetNumber;
              if (eventSet != currentSetNumber) {
                enrichedEvents.add({
                  'is_divider': true,
                  'title': 'Sett $eventSet',
                });
                homeScore = 0;
                awayScore = 0;
                currentSetNumber = eventSet;
              }

              String pointTo = event['point_to'] ?? 'none';
              if (pointTo == 'home') {
                homeScore++;
              } else if (pointTo == 'away') {
                awayScore++;
              }
              
              enrichedEvents.add({
                ...event,
                'current_home': homeScore,
                'current_away': awayScore,
              });
            }

            if (matchData['status'] == 'finished') {
              enrichedEvents.add({
                'is_divider': true,
                'title': 'Kampen er ferdig',
              });
            }
            
            // Reverse for the timeline tab (newest first)
            final reversedEvents = enrichedEvents.reversed.toList();

            final statsResult = calculateMatchStats(eventsList);
            final players = statsResult.players.values.toList();
            players.sort((a, b) {
              if (a.teamName == teamAName && b.teamName != teamAName) return -1;
              if (a.teamName != teamAName && b.teamName == teamAName) return 1;
              return b.totalPoints.compareTo(a.totalPoints);
            });

            final teamStatsMap = statsResult.teams;
            final teamAStats = teamStatsMap[teamAName] ?? TeamMatchStats(teamAName);
            final teamBStats = teamStatsMap[teamBName] ?? TeamMatchStats(teamBName);

            return Column(
              children: [
                _buildScoreboardHero(matchHomeScore, matchAwayScore, currentSet, homeSets, awaySets, pastSets),
                Expanded(
                  child: TabBarView(
                    children: [
                      // TAB 1: HENDELSER
                      _buildEventsTab(reversedEvents),

                      // TAB 2: LAG
                      _buildTeamStatsTab(teamAStats, teamBStats),
                      
                      // TAB 3: SPILLERE
                      _buildPlayerStatsTab(players),
                    ],
                  ),
                ),
              ],
            );
          },
        );
      },
    ),
      ),
    );
  }

  // --- SCOREBOARD HERO ---
  Widget _buildScoreboardHero(int matchHomeScore, int matchAwayScore, int currentSet, int homeSets, int awaySets, List pastSets) {
    return Container(
      decoration: const BoxDecoration(gradient: AppColors.heroNavy),
      padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 20, AppTheme.pageHPad, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.coral,
                  borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                    const SizedBox(width: 5),
                    Text('LIVE', style: AppText.monoSmLight),
                  ],
                ),
              ),
              const Spacer(),
              Text('SETT $currentSet', style: AppText.monoSmLight),
            ],
          ),
          const SizedBox(height: 16),
          _buildScoreRow(teamAName, homeSets, matchHomeScore, isLeading: true),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withValues(alpha: 0.10), height: 1),
          const SizedBox(height: 8),
          _buildScoreRow(teamBName, awaySets, matchAwayScore, isLeading: false),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String teamName, int sets, int score, {required bool isLeading}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: isLeading ? AppColors.blue : AppColors.coral, // Bruker lagfarger (blå/rød)
            borderRadius: BorderRadius.circular(3),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(teamName.toUpperCase(), style: AppText.dispH2(18).copyWith(color: Colors.white)),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text('$sets', style: AppText.dispScore(20).copyWith(color: Colors.white70)),
        ),
        const SizedBox(width: 16),
        Text('$score', style: AppText.dispScore(36).copyWith(color: Colors.white)),
      ],
    );
  }

  // --- TAB 1: LAG ---
  Widget _buildTeamStatsTab(TeamMatchStats teamA, TeamMatchStats teamB) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pageHPad),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(child: Text(teamAName, style: AppText.uiTitle.copyWith(color: AppColors.coral), overflow: TextOverflow.ellipsis)),
              Expanded(child: Text(teamBName, style: AppText.uiTitle.copyWith(color: AppColors.coral), textAlign: TextAlign.right, overflow: TextOverflow.ellipsis)),
            ],
          ),
          const SizedBox(height: 24),
          _buildStatComparison('Angrep (Kills)', teamA.attackPoints, teamB.attackPoints),
          _buildStatComparison('Blokk', teamA.blockPoints, teamB.blockPoints),
          _buildStatComparison('Serve-ess', teamA.servePoints, teamB.servePoints),
          _buildStatComparison('Motstanderfeil', teamA.opponentErrors, teamB.opponentErrors),
          _buildStatComparison('Sideout', teamA.sideoutPoints, teamB.sideoutPoints),
          _buildStatComparison('Overgangspoeng', teamA.overgangsPoeng, teamB.overgangsPoeng),
        ],
      ),
    );
  }

  Widget _buildStatComparison(String label, int valA, int valB) {
    int total = valA + valB;
    double flexA = total == 0 ? 0.5 : valA / total;
    double flexB = total == 0 ? 0.5 : valB / total;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('$valA', style: AppText.uiTitle.copyWith(color: Colors.white)),
              Text(label, style: AppText.uiCaption.copyWith(color: Colors.white70)),
              Text('$valB', style: AppText.uiTitle.copyWith(color: Colors.white)),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                flex: (flexA * 100).toInt() == 0 ? 1 : (flexA * 100).toInt(),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: valA > 0 ? AppColors.blue : Colors.white12,
                    borderRadius: const BorderRadius.only(topLeft: Radius.circular(4), bottomLeft: Radius.circular(4)),
                  ),
                ),
              ),
              const SizedBox(width: 2),
              Expanded(
                flex: (flexB * 100).toInt() == 0 ? 1 : (flexB * 100).toInt(),
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: valB > 0 ? AppColors.coral : Colors.white12,
                    borderRadius: const BorderRadius.only(topRight: Radius.circular(4), bottomRight: Radius.circular(4)),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // --- TAB 2: SPILLERE ---
  Widget _buildPlayerStatsTab(List<PlayerMatchStats> players) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.pageHPad),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final p = players[index];
        final isTeamA = p.teamName == teamAName;
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.rowGap),
          decoration: BoxDecoration(
            gradient: AppColors.cardInk,
            borderRadius: BorderRadius.circular(AppTheme.radiusRow),
            border: Border(
              left: BorderSide(color: isTeamA ? AppColors.blue : AppColors.coral, width: 3),
            ),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (p.imageUrl.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundImage: NetworkImage(p.imageUrl),
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                        ),
                      )
                    else
                      Padding(
                        padding: const EdgeInsets.only(right: 10.0),
                        child: CircleAvatar(
                          radius: 18,
                          backgroundColor: Colors.white.withValues(alpha: 0.1),
                          child: Text(
                            p.playerName.isEmpty ? '?' : p.playerName.substring(0, 1).toUpperCase(),
                            style: AppText.dispKicker(14).copyWith(color: Colors.white70),
                          ),
                        ),
                      ),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          RichText(
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            text: TextSpan(
                              children: [
                                TextSpan(
                                  text: p.playerName.split(' ').first + (p.playerName.split(' ').length > 1 ? ' ' : ''),
                                  style: AppText.uiTitle.copyWith(color: AppColors.coral),
                                ),
                                if (p.playerName.split(' ').length > 1)
                                  TextSpan(
                                    text: p.playerName.split(' ').skip(1).join(' '),
                                    style: AppText.uiTitle.copyWith(color: Colors.white),
                                  ),
                              ],
                            ),
                          ),
                          Text(p.teamName, style: AppText.uiCaption.copyWith(color: AppColors.nightInk2), overflow: TextOverflow.ellipsis),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Divider(color: Colors.white.withValues(alpha: 0.1), height: 1),
                const SizedBox(height: 12),
                
                // Full names stat list
                _buildFullStatRow('Totale Poeng', p.totalPoints.toString()),
                _buildFullStatRow('Angrep (Kills / Feil)', '${p.kills} / ${p.attackErrors}'),
                _buildFullStatRow('Sideout', '${p.sideoutPoints}'),
                _buildFullStatRow('Overgangspoeng', '${p.overgangsPoeng}'),
                _buildFullStatRow('Blokk', '${p.blocks}'),
                _buildFullStatRow('Serve-ess', '${p.aces}'),
                _buildFullStatRow('Servefeil', '${p.serviceErrors}', isNegative: p.serviceErrors > 0),
                _buildFullStatRow('Gode mottak (%)', p.receptionEfficiency),
                _buildFullStatRow('Legg-effektivitet', p.settingEfficiency),
                _buildFullStatRow('Tekniske Feil', '${p.technicalErrors}', isNegative: p.technicalErrors > 0),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildFullStatRow(String label, String value, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: AppText.uiCaption.copyWith(color: AppColors.nightInk2)),
          Text(value, style: AppText.uiTitle.copyWith(color: isNegative ? AppColors.coral : Colors.white)),
        ],
      ),
    );
  }

  // --- TAB 3: HENDELSER ---
  Widget _buildEventsTab(List<Map<String, dynamic>> events) {
    return ListView.builder(
      padding: const EdgeInsets.all(AppTheme.pageHPad),
      itemCount: events.length,
      itemBuilder: (context, index) {
        final event = events[index];
        final pName = event['player_name'] ?? 'Ukjent';
        final action = event['action'] ?? '';
        final subType = event['sub_type'];
        final isA = event['team'] == teamAName;
        
        if (event['is_divider'] == true) {
          return Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            alignment: Alignment.center,
            child: Text(event['title'], style: AppText.dispH2(18).copyWith(color: AppColors.coral)),
          );
        }

        // Skip background actions that clutters the list
        if (action == 'Set Assist' || action == 'Set Attempt' || action == 'Blocked' || action == 'Serve In Play') {
          return const SizedBox.shrink();
        }
        if (action == 'Reception Error' && event['is_ace'] == true) {
          return const SizedBox.shrink();
        }

        final homeScore = event['current_home'] ?? 0;
        final awayScore = event['current_away'] ?? 0;

        String title = '$pName $action';
        if (action == 'Kill') {
          title = '$pName angrep';
        } else if (action == 'Block') {
          if (event['victim_name'] != null) {
            title = '$pName blokket ${event['victim_name']}';
          } else {
            title = '$pName blokk';
          }
        } else if (action == 'Ace') {
          if (event['victim_name'] != null) {
            title = '$pName esset ${event['victim_name']}';
          } else {
            title = '$pName serve-ess';
          }
        } else if (action == 'Attack Error') {
          title = '$pName angrepsfeil';
        } else if (action == 'Service Error') {
          title = '$pName servefeil';
        } else if (action == 'Technical Error') {
          title = '$pName teknisk feil';
        } else if (action == 'Opponent Error') {
          title = '${event['team']} motstanderfeil';
        } else if (action == 'Reception Error') {
          title = '$pName mottaksfeil';
        } else if (action == 'Timeout') {
          title = pName;
        }
        
        if (subType != null && subType.toString().isNotEmpty) {
          title += ' ($subType)';
        }

        return Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            gradient: AppColors.cardInk,
            borderRadius: BorderRadius.circular(AppTheme.radiusRow),
            border: Border(left: BorderSide(color: isA ? AppColors.blue : AppColors.coral, width: 3)),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(title, style: AppText.uiBody.copyWith(color: Colors.white)),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text('$homeScore - $awayScore', style: AppText.monoMd.copyWith(fontWeight: FontWeight.bold, color: Colors.white)),
              ),
            ],
          ),
        );
      },
    );
  }
}
