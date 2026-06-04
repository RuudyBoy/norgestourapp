import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'fantasy_page.dart';
import 'tours_page.dart';
import 'tournament_stats_page.dart';
import 'match_stats_page.dart';
import '../widgets/profile_avatar_widget.dart';
import '../widgets/season_hero_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class HomePage extends StatelessWidget {
  final Function(int)? onTabSelected;

  const HomePage({super.key, this.onTabSelected});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Image.asset('assets/images/ntlogo.png', height: 60, fit: BoxFit.contain),
        actions: const [ProfileAvatarWidget()],
      ),
      body: SafeArea(
        child: Column(
          children: [
            const SeasonHeroWidget(
              title: 'NT',
              description: 'Gjør deg klar for sesongen 2026!',
            ),
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
              const SizedBox(height: 8),
              _buildLiveMatches(context),
              const SizedBox(height: AppTheme.sectionGap),
              _buildCards(context),
              const SizedBox(height: 30),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionKicker(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
      child: Row(
        children: [
          Container(width: 14, height: 3, decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 8),
          Text(label.toUpperCase(), style: AppText.dispKicker()),
        ],
      ),
    );
  }

  Widget _buildLiveMatches(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'live')
          .snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
          return const SizedBox.shrink();
        }

        final matches = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionKicker('Live nå'),
            const SizedBox(height: 12),
            SizedBox(
              height: 150,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
                itemCount: matches.length,
                itemBuilder: (context, index) {
                  final data = matches[index].data() as Map<String, dynamic>;
                  final matchId = matches[index].id;
                  final teamA = data['team_a_name'] ?? 'Lag A';
                  final teamB = data['team_b_name'] ?? 'Lag B';
                  final scoreA = data['home_score'] ?? 0;
                  final scoreB = data['away_score'] ?? 0;
                  final set = data['current_set'] ?? 1;

                  return GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => MatchStatsPage(
                            matchId: matchId,
                            teamAName: teamA,
                            teamBName: teamB,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      width: 270,
                      margin: const EdgeInsets.only(right: AppTheme.rowGap),
                      padding: const EdgeInsets.all(AppTheme.cardPad),
                      decoration: BoxDecoration(
                        gradient: AppColors.heroNavy,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        boxShadow: AppTheme.shadowLg,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                decoration: BoxDecoration(
                                  color: AppColors.coral,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                    const SizedBox(width: 5),
                                    Text('LIVE · SETT $set', style: AppText.monoSmLight),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const Spacer(),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(teamA.toUpperCase(),
                                    style: AppText.dispH2(18).copyWith(color: Colors.white),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('$scoreA', style: AppText.dispScore(32).copyWith(color: Colors.white)),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(teamB.toUpperCase(),
                                    style: AppText.dispH2(18).copyWith(color: Colors.white.withOpacity(0.7)),
                                    overflow: TextOverflow.ellipsis),
                              ),
                              Text('$scoreB',
                                  style: AppText.dispScore(32).copyWith(color: Colors.white.withOpacity(0.7))),
                            ],
                          ),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildKickerInline('Utforsk'),
          const SizedBox(height: 12),
          _buildActionCard(
            context: context,
            title: 'Fantasy',
            subtitle: 'Bygg drømmelaget ditt',
            description: 'Velg spillere, styr budsjettet og konkurrèr mot andre basert på ekte prestasjoner.',
            buttonText: 'Spill nå',
            icon: Icons.sports_volleyball,
            iconColor: AppColors.coral,
            onTap: () {
              if (onTabSelected != null) {
                onTabSelected!(1);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const FantasyPage()));
              }
            },
          ),
          const SizedBox(height: AppTheme.rowGap),
          _buildActionCard(
            context: context,
            title: 'Statistikk',
            subtitle: 'Sesongstats & rangeringer',
            description: 'Dypdykk i spillerstatistikk, kamphistorikk og sesongdata.',
            buttonText: 'Se stats',
            icon: Icons.bar_chart,
            iconColor: AppColors.blue,
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const TournamentStatsPage(
                  tournamentId: 'nt-season',
                  tournamentName: 'Årets NT sesong',
                )),
              );
            },
          ),
          const SizedBox(height: AppTheme.rowGap),
          _buildActionCard(
            context: context,
            title: 'Tours',
            subtitle: 'Kamper & resultater',
            description: 'Følg kommende tours, liveresultater og sluttresultater for hele sesongen.',
            buttonText: 'Se tours',
            icon: Icons.flag,
            iconColor: AppColors.green,
            onTap: () {
              if (onTabSelected != null) {
                onTabSelected!(2);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (context) => const ToursPage()));
              }
            },
          ),
        ],
      ),
    );
  }

  Widget _buildKickerInline(String label) {
    return Row(
      children: [
        Container(width: 14, height: 3, decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: AppText.dispKicker()),
      ],
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required String buttonText,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColors.sand0,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          splashColor: AppColors.coral.withOpacity(0.08),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPad),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.dispH2(18)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.monoSm),
                      const SizedBox(height: 6),
                      Text(description, style: AppText.uiCaption, maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                    boxShadow: AppTheme.shadowCoral,
                  ),
                  child: Text(buttonText, style: AppText.uiCta.copyWith(fontSize: 13)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
