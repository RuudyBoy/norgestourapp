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
    return Scaffold(
      appBar: AppBar(
        title: Text('KAMPFAKTA', style: AppText.dispH2(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .collection('events')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator(color: AppColors.coral));
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.sports_volleyball, size: 48, color: AppColors.ink3),
                  const SizedBox(height: 12),
                  Text('Ingen data enda.', style: AppText.uiBody),
                ],
              ),
            );
          }

          final eventsList = docs.map((d) => d.data() as Map<String, dynamic>).toList();
          final statsMap = calculateMatchStats(eventsList);
          final players = statsMap.values.toList();
          players.sort((a, b) {
            if (a.teamName == teamAName && b.teamName != teamAName) return -1;
            if (a.teamName != teamAName && b.teamName == teamAName) return 1;
            return b.totalPoints.compareTo(a.totalPoints);
          });

          return SingleChildScrollView(
            child: Column(
              children: [
                _buildScoreboardHero(),
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, AppTheme.sectionGap, AppTheme.pageHPad, 32),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(width: 14, height: 3, decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(2))),
                          const SizedBox(width: 8),
                          Text('LAGSTATISTIKK', style: AppText.dispKicker()),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('SO = Sideout  ·  MOT = Mottaksfeil', style: AppText.monoSm),
                      const SizedBox(height: 16),
                      _buildStatsTable(players),
                    ],
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildScoreboardHero() {
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
                    Text('LIVE · SETT 2', style: AppText.monoSmLight),
                  ],
                ),
              ),
              const Spacer(),
              Text('NORGES TOUR', style: AppText.monoSmLight),
            ],
          ),
          const SizedBox(height: 16),
          _buildScoreRow(teamAName, null, isLeading: true),
          const SizedBox(height: 8),
          Divider(color: Colors.white.withOpacity(0.10), height: 1),
          const SizedBox(height: 8),
          _buildScoreRow(teamBName, null, isLeading: false),
        ],
      ),
    );
  }

  Widget _buildScoreRow(String teamName, int? score, {required bool isLeading}) {
    return Row(
      children: [
        Container(
          width: 4,
          height: 32,
          decoration: BoxDecoration(
            color: isLeading ? AppColors.blue : AppColors.ink.withOpacity(0.5),
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
        if (score != null)
          Text('$score', style: AppText.dispScore(36).copyWith(color: Colors.white)),
      ],
    );
  }

  Widget _buildStatsTable(List<PlayerMatchStats> players) {
    return Column(
      children: players.map((p) {
        final isTeamA = p.teamName == teamAName;
        return Container(
          margin: const EdgeInsets.only(bottom: AppTheme.rowGap),
          decoration: BoxDecoration(
            color: AppColors.sand0,
            borderRadius: BorderRadius.circular(AppTheme.radiusRow),
            border: Border(
              left: BorderSide(
                color: isTeamA ? AppColors.blue : AppColors.coral,
                width: 3,
              ),
            ),
            boxShadow: AppTheme.shadowSm,
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                if (p.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(p.imageUrl),
                      backgroundColor: AppColors.sand2,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.sand2,
                      child: Text(
                        p.playerName.isEmpty ? '?' : p.playerName.substring(0, 1).toUpperCase(),
                        style: AppText.dispKicker(14).copyWith(color: AppColors.ink2),
                      ),
                    ),
                  ),
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.playerName, style: AppText.uiTitle, overflow: TextOverflow.ellipsis),
                      Text(p.teamName, style: AppText.uiCaption, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  flex: 3,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildMiniStat('TOT', p.totalPoints.toString(), color: AppColors.coral),
                      _buildMiniStat('ANG', '${p.kills}/${p.attackErrors}', color: AppColors.ink),
                      _buildMiniStat('SO', '${p.sideoutPoints}', color: AppColors.ink),
                      _buildMiniStat('LEGG', p.settingEfficiency, color: AppColors.ink),
                      _buildMiniStat('MOT', '${p.receptionErrors}',
                          color: p.receptionErrors > 0 ? AppColors.coral : AppColors.ink3),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildMiniStat(String label, String value, {required Color color}) {
    return Column(
      children: [
        Text(label, style: AppText.monoSm),
        const SizedBox(height: 3),
        Text(value, style: AppText.dispKicker(13).copyWith(color: color)),
      ],
    );
  }
}
