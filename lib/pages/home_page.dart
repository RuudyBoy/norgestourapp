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
import 'fantasy/models.dart';
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

  // ── Live Tournament ──────────────────────────────────────────────

  Widget _buildLiveTournamentSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').where('status', isEqualTo: 'live').snapshots(),
      builder: (context, snapshot) {
        if (!snapshot.hasData || snapshot.data!.docs.isEmpty) return const SizedBox.shrink();

        final doc = snapshot.data!.docs.first;
        final data = doc.data() as Map<String, dynamic>;
        final name = data['name'] ?? 'Live Tour';
        final location = (data['location'] ?? '') as String;
        final imageUrl = (data['image_url'] ?? '') as String;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildSectionKicker('Pågående Tour'),
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
                    gradient: AppColors.cardInk,
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
                        : null,
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
                            const SizedBox(height: 10),
                            Text(name, style: AppText.dispH1(22).copyWith(color: AppColors.sand2)),
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
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                        ),
                        child: Text('Se mer', style: AppText.uiCta.copyWith(fontSize: 13, color: Colors.white)),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 24),
            _buildSectionKicker('Topscorer'),
            const SizedBox(height: 12),
            FutureBuilder<List<FantasyPlayer>>(
              future: fetchFantasyPlayers(),
              builder: (context, playerSnapshot) {
                if (!playerSnapshot.hasData || playerSnapshot.data!.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
                    child: Text('Ingen data', style: TextStyle(color: Colors.white70)),
                  );
                }
                final topScorer = playerSnapshot.data!.first;
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
                  child: Container(
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [AppColors.coralDeep, AppColors.coral],
                      ),
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 30,
                          backgroundColor: Colors.white24,
                          backgroundImage: topScorer.imageUrl.isNotEmpty ? NetworkImage(topScorer.imageUrl) : null,
                          child: topScorer.imageUrl.isEmpty ? Text(topScorer.name[0], style: AppText.dispH2(20).copyWith(color: Colors.white)) : null,
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(topScorer.name, style: AppText.dispH2(18).copyWith(color: Colors.white)),
                              Text(topScorer.team, style: AppText.monoSm.copyWith(color: Colors.white70)),
                            ],
                          ),
                        ),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text('${topScorer.totalPoints}', style: AppText.dispH1(28).copyWith(color: Colors.white)),
                            Text('POENG', style: AppText.monoSm.copyWith(color: Colors.white)),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
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

              final startTime = data['start_time']?.toString() ?? '';
              final matchType = data['group']?.toString() ?? '';
              final court = data['court']?.toString() ?? 'TBD';

              String rightInfo = '';
              if (startTime.isNotEmpty && matchType.isNotEmpty) {
                rightInfo = '$startTime • $matchType';
              } else if (startTime.isNotEmpty) rightInfo = '$startTime • $court';
              else if (matchType.isNotEmpty) rightInfo = matchType;
              else rightInfo = court;

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
                    gradient: AppColors.cardInk,
                    borderRadius: BorderRadius.circular(AppTheme.radiusCard),
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
                          Text(rightInfo.toUpperCase(), style: AppText.monoSm.copyWith(color: Colors.white70)),
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
                    gradient: AppColors.cardInk,
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
                        : null,
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
                                border: Border.all(color: AppColors.blue.withValues(alpha: 0.5)),
                              ),
                              child: Text('KOMMENDE', style: AppText.monoSmLight),
                            ),
                            const SizedBox(height: 10),
                            Text(name, style: AppText.dispH1(22).copyWith(color: AppColors.sand2)),
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
                              gradient: AppColors.cardInk,
                              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            ),
                            child: Text('Se mer', style: AppText.uiCta.copyWith(fontSize: 13, color: Colors.white)),
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
            title: _teamName != null ? _teamName! : 'Fantasy',
            subtitle: _teamName != null ? 'Ditt drømmelag' : 'Bygg drømmelaget ditt',
            description: _teamName != null
                ? '${_fantasyPoints ?? 0} poeng totalt. Sjekk hvordan du ligger an mot resten av Norge!'
                : 'Velg spillere, styr budsjettet og konkurrèr mot andre basert på ekte prestasjoner.',
            buttonText: _teamName != null ? 'Se laget' : 'Spill nå',
            cardGradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [AppColors.coral, AppColors.coralDeep],
            ),
            textColor: AppColors.ink,
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
            cardGradient: AppColors.cardInk,
            textColor: Colors.white,
            icon: Icons.bar_chart,
            iconColor: AppColors.ink,
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
            cardGradient: AppColors.cardInk,
            textColor: Colors.white,
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
    required Gradient cardGradient,
    required Color textColor,
    required IconData icon,
    required Color iconColor,
    required VoidCallback onTap,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: cardGradient,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowSm,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          splashColor: Colors.white.withValues(alpha: 0.2),
          child: Padding(
            padding: const EdgeInsets.all(AppTheme.cardPad),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: textColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                  ),
                  child: Icon(icon, color: textColor, size: 28),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: AppText.dispH2(18).copyWith(color: textColor == Colors.white ? AppColors.coral : textColor)),
                      const SizedBox(height: 2),
                      Text(subtitle, style: AppText.monoSm.copyWith(color: textColor.withValues(alpha: 0.7))),
                      const SizedBox(height: 6),
                      Text(description, style: AppText.uiCaption.copyWith(color: textColor.withValues(alpha: 0.7)), maxLines: 2, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(AppTheme.radiusChip),
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
                  _buildLiveTournamentSection(context),
                  const SizedBox(height: AppTheme.sectionGap),
                  _buildLiveOrNextSection(context),
                  const SizedBox(height: AppTheme.sectionGap),
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
