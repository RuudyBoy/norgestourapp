import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'teams_page.dart';
import 'matches_page.dart';
import 'tournament_stats_page.dart';
import 'match_stats_page.dart';

class TournamentDetailsPage extends StatelessWidget {
  final String tournamentId;
  final Map<String, dynamic> data;

  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Ukjent Turnering';
    final date = data['start_date']?.toString() ?? 'Dato kommer';
    final imageUrl = data['image_url'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? AppColors.nightSurface1 : AppColors.sand1,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        decoration: const BoxDecoration(gradient: AppColors.heroNavy),
                      ),
                    )
                  else
                    Container(decoration: const BoxDecoration(gradient: AppColors.heroNavy)),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 24,
                    left: AppTheme.pageHPad,
                    right: AppTheme.pageHPad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                          ),
                          child: Text(
                            'TURNERING',
                            style: AppText.monoSm.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: AppText.dispH1Light(28),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 11,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: AppText.monoSmLight.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverToBoxAdapter(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: AppTheme.sectionGap),

                _MatchesSection(
                  tournamentId: tournamentId,
                  tournamentName: name,
                  onMatchTap: (matchId, teamA, teamB) {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MatchStatsPage(
                          matchId: matchId,
                          teamAName: teamA,
                          teamBName: teamB,
                        ),
                      ),
                    );
                  },
                  onSeeAll: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => MatchesPage(
                          tournamentId: tournamentId,
                          tournamentName: name,
                        ),
                      ),
                    );
                  },
                ),

                const SizedBox(height: AppTheme.sectionGap),

                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'UTFORSK',
                        style: AppText.dispKicker().copyWith(
                          color: isDark ? AppColors.nightInk3 : AppColors.ink3,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ActionCard(
                        icon: Icons.groups_rounded,
                        title: 'Lag',
                        subtitle: 'Se alle lag i turneringen',
                        description: 'Oversikt over alle lag og spillere som deltar i turneringen.',
                        buttonText: 'Se lag',
                        iconColor: AppColors.blue,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TeamsPage(
                              tournamentId: tournamentId,
                              tournamentName: name,
                            ),
                          ),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppTheme.rowGap),
                      _ActionCard(
                        icon: Icons.bar_chart_rounded,
                        title: 'Statistikk',
                        subtitle: 'Spillerstatistikk og toppscorer',
                        description: 'Dypdykk i spillerstatistikk, kamphistorikk og turneringsdata.',
                        buttonText: 'Se stats',
                        iconColor: AppColors.coral,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TournamentStatsPage(
                              tournamentId: tournamentId,
                              tournamentName: name,
                            ),
                          ),
                        ),
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppTheme.rowGap),
                      _ActionCard(
                        icon: Icons.emoji_events_rounded,
                        title: 'Resultater',
                        subtitle: 'Sluttresultater og standings',
                        description: 'Følg med på sluttresultater, rangeringer og hvem som vinner turneringen.',
                        buttonText: 'Resultater',
                        iconColor: AppColors.green,
                        onTap: () {},
                        isDark: isDark,
                      ),
                      const SizedBox(height: AppTheme.rowGap),
                      _ActionCard(
                        icon: Icons.calendar_month_rounded,
                        title: 'Alle kamper',
                        subtitle: 'Fullt kampprogram',
                        description: 'Se alle kommende, pågående og fullførte kamper i turneringen.',
                        buttonText: 'Kamper',
                        iconColor: AppColors.blueBright,
                        onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => MatchesPage(
                              tournamentId: tournamentId,
                              tournamentName: name,
                            ),
                          ),
                        ),
                        isDark: isDark,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 48),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Matches section ───────────────────────────────────────────────────────────

class _MatchesSection extends StatelessWidget {
  final String tournamentId;
  final String tournamentName;
  final void Function(String matchId, String teamA, String teamB) onMatchTap;
  final VoidCallback onSeeAll;

  const _MatchesSection({
    required this.tournamentId,
    required this.tournamentName,
    required this.onMatchTap,
    required this.onSeeAll,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Text(
                'KAMPER',
                style: AppText.dispKicker().copyWith(
                  color: isDark ? AppColors.nightInk3 : AppColors.ink3,
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: onSeeAll,
                child: Text(
                  'Se alle',
                  style: AppText.uiCaption.copyWith(color: AppColors.coral),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .where('tournament_id', isEqualTo: tournamentId)
              .snapshots(),
          builder: (context, snapshot) {
            if (snapshot.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              );
            }

            if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurface0 : AppColors.sand0,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Center(
                    child: Text(
                      'Ingen kamper satt opp enda',
                      style: AppText.uiCaption,
                    ),
                  ),
                ),
              );
            }

            final matches = snapshot.data!.docs;

            return ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
              itemCount: matches.length,
              separatorBuilder: (context, index) => const SizedBox(height: AppTheme.rowGap),
              itemBuilder: (context, index) {
                final d = matches[index].data() as Map<String, dynamic>;
                final status = d['status'] ?? 'scheduled';
                final homeScore = d['home_score'] ?? 0;
                final awayScore = d['away_score'] ?? 0;
                final court = d['court'] ?? '';
                final teamA = d['team_a_name'] ?? 'Lag A';
                final teamB = d['team_b_name'] ?? 'Lag B';
                final startTime = d['start_time']?.toString() ?? '';
                final matchId = matches[index].id;

                return _MatchCard(
                  teamA: teamA,
                  teamB: teamB,
                  homeScore: homeScore,
                  awayScore: awayScore,
                  court: court,
                  startTime: startTime,
                  status: status,
                  onTap: status == 'scheduled'
                      ? null
                      : () => onMatchTap(matchId, teamA, teamB),
                );
              },
            );
          },
        ),
      ],
    );
  }
}

// ── Match card ────────────────────────────────────────────────────────────────

class _MatchCard extends StatelessWidget {
  final String teamA;
  final String teamB;
  final int homeScore;
  final int awayScore;
  final String court;
  final String startTime;
  final String status;
  final VoidCallback? onTap;

  const _MatchCard({
    required this.teamA,
    required this.teamB,
    required this.homeScore,
    required this.awayScore,
    required this.court,
    required this.startTime,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isLive = status == 'live';
    final isScheduled = status == 'scheduled';

    final String headerLabel;
    if (startTime.isNotEmpty) {
      headerLabel = startTime;
    } else if (court.isNotEmpty) {
      headerLabel = court.toUpperCase();
    } else {
      headerLabel = isScheduled ? 'KOMMENDE' : status.toUpperCase();
    }

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          gradient: AppColors.cardInk,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: AppTheme.shadowLg,
        ),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            if (isLive)
              Positioned(
                top: -30,
                right: -30,
                child: Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.coral.withValues(alpha: 0.15),
                  ),
                ),
              ),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 14, 16, 14),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (isLive) ...[
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.coral.withValues(alpha: 0.7),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'LIVE',
                          style: AppText.monoSm.copyWith(
                            color: AppColors.coral,
                            letterSpacing: 2,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Container(
                          width: 7,
                          height: 7,
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                            boxShadow: [
                              BoxShadow(
                                color: AppColors.coral.withValues(alpha: 0.7),
                                blurRadius: 6,
                              ),
                            ],
                          ),
                        ),
                      ] else
                        Text(
                          headerLabel,
                          style: AppText.monoSm.copyWith(
                            color: Colors.white.withValues(alpha: 0.45),
                            letterSpacing: 1.5,
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Column(
                          children: [
                            _TeamBadge(name: teamA),
                            const SizedBox(height: 8),
                            Text(
                              teamA,
                              style: AppText.uiTitle.copyWith(color: Colors.white),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),

                      Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 10),
                        child: isScheduled
                            ? Text(
                                'Vs',
                                style: AppText.dispH1(20).copyWith(
                                  color: Colors.white.withValues(alpha: 0.5),
                                  fontStyle: FontStyle.italic,
                                ),
                              )
                            : Text(
                                '$homeScore-$awayScore',
                                style: AppText.dispScore(38).copyWith(color: Colors.white),
                              ),
                      ),

                      Expanded(
                        child: Column(
                          children: [
                            _TeamBadge(name: teamB),
                            const SizedBox(height: 8),
                            Text(
                              teamB,
                              style: AppText.uiTitle.copyWith(color: Colors.white),
                              textAlign: TextAlign.center,
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  if (!isScheduled) ...[
                    const SizedBox(height: 14),
                    Divider(color: Colors.white.withValues(alpha: 0.08), height: 1),
                    const SizedBox(height: 10),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.bar_chart_rounded,
                          size: 13,
                          color: Colors.white.withValues(alpha: 0.35),
                        ),
                        const SizedBox(width: 5),
                        Text(
                          'Kampfakta',
                          style: AppText.monoSm.copyWith(
                            color: Colors.white.withValues(alpha: 0.35),
                            letterSpacing: 0.8,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 14,
                          color: isLive
                              ? AppColors.coral
                              : Colors.white.withValues(alpha: 0.35),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Team badge ────────────────────────────────────────────────────────────────

class _TeamBadge extends StatelessWidget {
  final String name;

  const _TeamBadge({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        shape: BoxShape.circle,
        border: Border.all(
          color: Colors.white.withValues(alpha: 0.18),
          width: 1.5,
        ),
      ),
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: AppText.dispH2(20).copyWith(color: Colors.white),
        ),
      ),
    );
  }
}

// ── Navigation row ────────────────────────────────────────────────────────────

class _ActionCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String description;
  final String buttonText;
  final Color iconColor;
  final VoidCallback onTap;
  final bool isDark;

  const _ActionCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.description,
    required this.buttonText,
    required this.iconColor,
    required this.onTap,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final surface = isDark ? AppColors.nightSurface0 : AppColors.sand0;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: surface,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          splashColor: AppColors.coral.withValues(alpha: 0.08),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPad),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                  ),
                  child: Icon(icon, color: iconColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.dispH2(18).copyWith(color: isDark ? AppColors.nightInk : AppColors.ink)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.monoSm),
                      const SizedBox(height: 6),
                      Text(
                        description,
                        style: AppText.uiCaption.copyWith(color: isDark ? AppColors.nightInk2 : AppColors.ink2),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
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
                  child: Text(buttonText, style: AppText.uiCta.copyWith(fontSize: 13, color: Colors.white)),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
