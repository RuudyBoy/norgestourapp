import 'dart:async';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'fantasy_page.dart';
import 'tours_page.dart';
import 'tournament_stats_page.dart';
import 'match_stats_page.dart';
import 'tour_detail_page.dart';
import 'fantasy/mock_data.dart';
import '../widgets/profile_avatar_widget.dart';
import '../widgets/season_hero_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class HomePage extends StatefulWidget {
  final Function(int)? onTabSelected;

  const HomePage({super.key, this.onTabSelected});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _uid;
  String? _teamName;
  int? _fantasyPoints;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        if (mounted) setState(() { _uid = null; _teamName = null; _fantasyPoints = null; });
        return;
      }
      if (user.uid == _uid) return;
      _uid = user.uid;
      _loadFantasyData(user.uid);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel();
    super.dispose();
  }

  Future<void> _loadFantasyData(String uid) async {
    try {
      final userDoc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
      if (!userDoc.exists || !mounted) return;
      final userData = userDoc.data()!;
      final teamName = userData['teamName'] as String?;
      if (teamName == null || teamName.isEmpty || teamName == 'Ukjent Lag') return;

      final squadDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .collection('fantasy')
          .doc('squad')
          .get();

      int points = 0;
      if (squadDoc.exists) {
        final squadData = squadDoc.data()!;
        final players = await fetchFantasyPlayers();
        for (final playerId in squadData.values) {
          if (playerId is String) {
            final match = players.where((p) => p.id == playerId);
            if (match.isNotEmpty) points += match.first.totalPoints;
          }
        }
      }

      if (mounted) setState(() { _teamName = teamName; _fantasyPoints = points; });
    } catch (_) {}
  }

  // ── Shared kicker header ───────────────────────────────────────

  Widget _buildSectionKicker(String label) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
      child: Row(
        children: [
          Container(
            width: 14, height: 3,
            decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(2)),
          ),
          const SizedBox(width: 8),
          Text(label.toUpperCase(), style: AppText.dispKicker()),
        ],
      ),
    );
  }

  Widget _buildKickerInline(String label) {
    return Row(
      children: [
        Container(
          width: 14, height: 3,
          decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(2)),
        ),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: AppText.dispKicker()),
      ],
    );
  }

  // ── Season timeline ────────────────────────────────────────────

  Widget _buildSeasonTimeline() {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final tournaments = snapshot.data!.docs;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionKicker('Sesongen 2026'),
            const SizedBox(height: 12),
            SizedBox(
              height: 40,
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
                itemCount: tournaments.length,
                itemBuilder: (context, index) {
                  final data = tournaments[index].data() as Map<String, dynamic>;
                  final name = data['name'] ?? 'Tour ${index + 1}';
                  final status = (data['status'] ?? '') as String;
                  final isLive = status == 'live';
                  final isDone = status == 'completed' || status == 'finished';

                  final bgColor = isLive
                      ? AppColors.coral
                      : isDone
                          ? AppColors.greenLight
                          : AppColors.sand2;
                  final textColor = isLive
                      ? Colors.white
                      : isDone
                          ? AppColors.green
                          : AppColors.ink2;

                  return GestureDetector(
                    onTap: () => widget.onTabSelected?.call(2),
                    child: Container(
                      margin: const EdgeInsets.only(right: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: bgColor,
                        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isLive) ...[
                            Container(
                              width: 5, height: 5,
                              margin: const EdgeInsets.only(right: 5),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                            ),
                          ] else if (isDone) ...[
                            const Icon(Icons.check, size: 10, color: AppColors.green),
                            const SizedBox(width: 4),
                          ],
                          Text(
                            name,
                            style: AppText.monoSm.copyWith(color: textColor, fontSize: 10),
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

  // ── Live matches OR next tour ─────────────────────────────────

  Widget _buildLiveOrNextSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'live')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return _buildLiveMatchesList(context, snapshot.data!.docs);
        }
        return _buildNextTourSection(context);
      },
    );
  }

  Widget _buildLiveMatchesList(BuildContext context, List<QueryDocumentSnapshot> matches) {
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
                    image: const DecorationImage(
                      image: AssetImage('assets/images/card_bg.png'),
                      fit: BoxFit.cover,
                    ),
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    boxShadow: AppTheme.shadowLg,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
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
                                style: AppText.dispH2(18).copyWith(color: Colors.white.withValues(alpha: 0.7)),
                                overflow: TextOverflow.ellipsis),
                          ),
                          Text('$scoreB',
                              style: AppText.dispScore(32).copyWith(color: Colors.white.withValues(alpha: 0.7))),
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
  }

  Widget _buildNextTourSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData) return const SizedBox.shrink();

        final docs = snapshot.data!.docs;
        final upcoming = docs.where((doc) {
          final data = doc.data() as Map<String, dynamic>;
          final status = (data['status'] ?? '') as String;
          return status != 'completed' && status != 'finished';
        }).toList();

        if (upcoming.isEmpty) return const SizedBox.shrink();

        upcoming.sort((a, b) {
          final aDate = ((a.data() as Map<String, dynamic>)['start_date'] ?? '').toString();
          final bDate = ((b.data() as Map<String, dynamic>)['start_date'] ?? '').toString();
          return aDate.compareTo(bDate);
        });

        final doc = upcoming.first;
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Neste Tour';
        final date = data['start_date']?.toString() ?? 'Dato kommer';
        final location = (data['location'] ?? '') as String;
        final imageUrl = (data['image_url'] ?? '') as String;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionKicker('Neste Tour'),
            const SizedBox(height: 12),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
              child: GestureDetector(
                onTap: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TournamentDetailsPage(tournamentId: doc.id, data: data),
                  ),
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                    boxShadow: AppTheme.shadowLg,
                    image: imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(imageUrl),
                            fit: BoxFit.cover,
                            colorFilter: ColorFilter.mode(
                              AppColors.ink.withValues(alpha: 0.55),
                              BlendMode.darken,
                            ),
                          )
                        : const DecorationImage(
                            image: AssetImage('assets/images/card_bg.png'),
                            fit: BoxFit.cover,
                          ),
                  ),
                  padding: const EdgeInsets.all(AppTheme.cardPad + 4),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.blue.withValues(alpha: 0.3),
                                borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                                border: Border.all(color: AppColors.blueBright.withValues(alpha: 0.5)),
                              ),
                              child: Text('KOMMENDE', style: AppText.monoSmLight),
                            ),
                            const SizedBox(height: 10),
                            Text(name, style: AppText.dispH1(22).copyWith(color: Colors.white)),
                            const SizedBox(height: 4),
                            if (location.isNotEmpty)
                              Row(
                                children: [
                                  const Icon(Icons.location_on, size: 11, color: Colors.white70),
                                  const SizedBox(width: 3),
                                  Text(location.toUpperCase(),
                                      style: AppText.monoSm.copyWith(color: Colors.white70)),
                                ],
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            ),
                            child: Text(date, style: AppText.monoSm.copyWith(color: Colors.white)),
                          ),
                          const SizedBox(height: 10),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                            decoration: BoxDecoration(
                              color: AppColors.coral,
                              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                              boxShadow: AppTheme.shadowCoral,
                            ),
                            child: Text('Se mer', style: AppText.uiCta.copyWith(fontSize: 13)),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  // ── Fantasy summary ────────────────────────────────────────────

  Widget _buildFantasySummary(BuildContext context) {
    if (_teamName == null) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
      child: GestureDetector(
        onTap: () {
          if (widget.onTabSelected != null) {
            widget.onTabSelected!(1);
          } else {
            Navigator.push(context, MaterialPageRoute(builder: (_) => const FantasyPage()));
          }
        },
        child: Container(
          decoration: BoxDecoration(
            image: const DecorationImage(
              image: AssetImage('assets/images/card_bg.png'),
              fit: BoxFit.cover,
            ),
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            boxShadow: AppTheme.shadowCoral,
          ),
          padding: const EdgeInsets.all(AppTheme.cardPad + 2),
          child: Row(
            children: [
              Container(
                width: 52,
                height: 52,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                ),
                child: const Icon(Icons.sports_volleyball, color: Colors.white, size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('DITT FANTASY-LAG', style: AppText.monoSmLight.copyWith(fontSize: 10)),
                    const SizedBox(height: 3),
                    Text(_teamName!, style: AppText.dispH2(20).copyWith(color: Colors.white)),
                    const SizedBox(height: 2),
                    Text(
                      '${_fantasyPoints ?? 0} poeng totalt',
                      style: AppText.uiCaption.copyWith(color: Colors.white.withValues(alpha: 0.8)),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                ),
                child: Text(
                  'Se laget',
                  style: AppText.uiCta.copyWith(color: AppColors.coral, fontSize: 13),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Explore cards ──────────────────────────────────────────────

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
              if (widget.onTabSelected != null) {
                widget.onTabSelected!(1);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const FantasyPage()));
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
                MaterialPageRoute(
                  builder: (_) => const TournamentStatsPage(
                    tournamentId: 'nt-season',
                    tournamentName: 'Årets NT sesong',
                  ),
                ),
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
            icon: Icons.emoji_events_rounded,
            iconColor: AppColors.green,
            onTap: () {
              if (widget.onTabSelected != null) {
                widget.onTabSelected!(2);
              } else {
                Navigator.push(context, MaterialPageRoute(builder: (_) => const ToursPage()));
              }
            },
          ),
        ],
      ),
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
        image: const DecorationImage(
          image: AssetImage('assets/images/card_bg.png'),
          fit: BoxFit.cover,
        ),
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
                      Text(title, style: AppText.dispH2(18).copyWith(color: Colors.white)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.monoSm.copyWith(color: Colors.white70)),
                      const SizedBox(height: 6),
                      Text(description, style: AppText.uiCaption.copyWith(color: Colors.white70), maxLines: 2, overflow: TextOverflow.ellipsis),
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SeasonHeroSliver(
            pageTitle: 'Hjem',
            description: 'Gjør deg klar for sesongen 2026!',
            actionImage: 'assets/images/player_action.png',
          ),
          SliverToBoxAdapter(
            child: Transform.translate(
              offset: const Offset(0, -20), // Skaper dybde/overlapping
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSeasonTimeline(),
                  const SizedBox(height: AppTheme.sectionGap),
                  _buildLiveOrNextSection(context),
                  const SizedBox(height: AppTheme.sectionGap),
                  _buildFantasySummary(context),
                  if (_teamName != null) const SizedBox(height: AppTheme.sectionGap),
                  _buildCards(context),
                  const SizedBox(height: 30 + 20), // Legg til 20 for å kompensere for offset
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
