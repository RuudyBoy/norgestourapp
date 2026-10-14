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
import 'fantasy/league_logic.dart';
import '../widgets/nt_ui.dart';
import '../widgets/season_hero_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

typedef _Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

class HomePage extends StatefulWidget {
  final Function(int)? onTabSelected;

  const HomePage({super.key, this.onTabSelected});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String? _uid;
  bool _hasFantasy = false;
  String? _teamName;
  int? _fantasyPoints; // null = laster
  int? _fantasyRank;
  StreamSubscription<User?>? _authSub;

  @override
  void initState() {
    super.initState();
    _authSub = FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user == null) {
        if (mounted) setState(() { _uid = null; _hasFantasy = false; _teamName = null; _fantasyPoints = null; _fantasyRank = null; });
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

  /// Henter fantasy-laget til innlogget bruker.
  /// Lagnavnet vises med en gang; poeng og plassering fylles inn når
  /// spillerdata og tabell er hentet (samme utregning som Fantasy-siden).
  Future<void> _loadFantasyData(String uid) async {
    final db = FirebaseFirestore.instance;
    try {
      final userDoc = await db.collection('users').doc(uid).get();
      final squadDoc = await db.collection('users').doc(uid).collection('fantasy').doc('squad').get();
      if (!mounted || uid != _uid) return;

      final rawName = (userDoc.data()?['teamName'] as String?)?.trim();
      final hasName = rawName != null && rawName.isNotEmpty && rawName != 'Ukjent Lag';
      if (!hasName && !squadDoc.exists) return; // ingen fantasy-lag ennå

      setState(() {
        _hasFantasy = true;
        _teamName = hasName ? rawName : 'Mitt lag';
        _fantasyPoints = null;
        _fantasyRank = null;
      });

      final players = await fetchFantasyPlayers();
      final board = await LeagueLogic.getGlobalLeaderboard(players);
      if (!mounted || uid != _uid) return;

      final idx = board.indexWhere((e) => e.userId == uid);
      setState(() {
        _fantasyPoints = idx >= 0 ? board[idx].totalPoints : 0;
        _fantasyRank = idx >= 0 ? idx + 1 : null;
      });
    } catch (e) {
      debugPrint('Kunne ikke hente fantasy-lag: $e');
      if (mounted && _hasFantasy && _fantasyPoints == null) {
        setState(() => _fantasyPoints = 0);
      }
    }
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
                  // 1. Live-kamper rett under bildet
                  _buildLiveMatchesSection(context),
                  // 2. Pågående tour
                  _buildLiveTournamentSection(context),
                  // 3. Neste tour + Utforsk (nytt design)
                  _buildNewContent(context),
                  const SizedBox(height: 30 + 20), // kompenserer for offset
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNewContent(BuildContext context) {
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
      builder: (context, snap) {
        final next = _nextTournament(snap.data?.docs ?? const <_Doc>[]);
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (next != null) ...[
              _pad(const NtSectionHeader(title: 'Neste tour')),
              const SizedBox(height: 14),
              _pad(_NextTourCard(tour: next)),
              const SizedBox(height: AppTheme.sectionGap),
            ],
            _buildFantasySection(context, next),
            const SizedBox(height: AppTheme.sectionGap),
            _pad(const NtSectionHeader(title: 'Utforsk')),
            const SizedBox(height: 14),
            _pad(_exploreRow(context)),
          ],
        );
      },
    );
  }

  // ── Seksjonsoverskrift (original) ─────────────────────────────

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

  // ── Pågående tour (original, uten fantasy-topscorer) ──────────

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

        return Padding(
          padding: const EdgeInsets.only(bottom: AppTheme.sectionGap),
          child: Column(
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
            ],
          ),
        );
      },
    );
  }

  // ── Live-kamper (original) ────────────────────────────────────

  Widget _buildLiveMatchesSection(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('status', isEqualTo: 'live')
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.hasData && snapshot.data!.docs.isNotEmpty) {
          return _buildLiveMatchesList(context, snapshot.data!.docs);
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildLiveMatchesList(BuildContext context, List<QueryDocumentSnapshot> matches) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
      builder: (context, tourSnapshot) {
        final Map<String, String> tourNames = {};
        if (tourSnapshot.hasData) {
          for (var doc in tourSnapshot.data!.docs) {
            final tData = doc.data() as Map<String, dynamic>;
            tourNames[doc.id] = tData['name'] ?? doc.id;
          }
        }

        final Map<String, List<QueryDocumentSnapshot>> groupedMatches = {};
        for (var match in matches) {
          final data = match.data() as Map<String, dynamic>;
          final tourId = data['tournament_id'] as String? ?? 'ukjent';
          final tourName = data['tournament_name'] ?? tourNames[tourId] ?? (tourId == 'ukjent' ? 'Live nå' : tourId);

          if (!groupedMatches.containsKey(tourName)) {
            groupedMatches[tourName] = [];
          }
          groupedMatches[tourName]!.add(match);
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: groupedMatches.entries.map((entry) {
            final tourName = entry.key;
            final tourMatches = entry.value;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildSectionKicker(tourName),
                const SizedBox(height: 12),
                SizedBox(
                  height: 150,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
                    itemCount: tourMatches.length,
                    itemBuilder: (context, index) {
                      final matchDoc = tourMatches[index];
                      final data = matchDoc.data() as Map<String, dynamic>;
                      final matchId = matchDoc.id;
                      final teamA = data['team_a_name'] ?? 'Lag A';
                      final teamB = data['team_b_name'] ?? 'Lag B';
                      final scoreA = data['home_score'] ?? 0;
                      final scoreB = data['away_score'] ?? 0;

                      final currentSet = data['current_set'] ?? 1;
                      final homeSets = data['home_sets'] ?? 0;
                      final awaySets = data['away_sets'] ?? 0;

                      String setText = '$currentSet. SETT';

                      final startTime = data['start_time']?.toString() ?? '';
                      final court = data['court']?.toString() ?? 'TBD';

                      String rightInfo = startTime.isNotEmpty ? '$startTime • $court' : court;

                      final stage = data['stage'] as String?;
                      String stageLabel = '';
                      if (stage == 'group') {
                        final group = data['group'] as String?;
                        stageLabel = group != null ? 'Pulje $group' : 'Puljespill';
                      } else if (stage == 'playoff') {
                        final bracket = data['bracket'] as String?;
                        stageLabel = bracket ?? 'Sluttspill';
                      }

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
                                        Text('LIVE · $setText', style: AppText.monoSmLight),
                                      ],
                                    ),
                                  ),
                                  Text(rightInfo.toUpperCase(), style: AppText.monoSm.copyWith(color: Colors.white70)),
                                ],
                              ),
                              const Spacer(),
                              if (stageLabel.isNotEmpty)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6.0),
                                  child: Text(stageLabel.toUpperCase(), style: AppText.monoSm.copyWith(color: AppColors.coral)),
                                ),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Expanded(
                                    child: Text(teamA.toUpperCase(),
                                        style: AppText.dispH2(18).copyWith(color: Colors.white),
                                        overflow: TextOverflow.ellipsis),
                                  ),
                                  Row(
                                    children: [
                                      if (currentSet > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 12),
                                          child: Text('$homeSets', style: AppText.dispScore(24).copyWith(color: Colors.white54)),
                                        ),
                                      Text('$scoreA', style: AppText.dispScore(32).copyWith(color: Colors.white)),
                                    ],
                                  ),
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
                                  Row(
                                    children: [
                                      if (currentSet > 1)
                                        Padding(
                                          padding: const EdgeInsets.only(right: 12),
                                          child: Text('$awaySets', style: AppText.dispScore(24).copyWith(color: Colors.white38)),
                                        ),
                                      Text('$scoreB',
                                          style: AppText.dispScore(32).copyWith(color: Colors.white.withValues(alpha: 0.7))),
                                    ],
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 24),
              ],
            );
          }).toList(),
        );
      },
    );
  }

  /// Første turnering som ikke er live/ferdig og ikke har startdato i fortiden.
  _Doc? _nextTournament(List<_Doc> tours) {
    final today = DateTime.now();
    final start = DateTime(today.year, today.month, today.day);
    final candidates = tours.where((t) {
      final d = t.data();
      final status = (d['status'] ?? '').toString();
      if (status == 'live' || status == 'finished' || status == 'completed') return false;
      final date = ntParseDate(d['start_date']);
      return date == null || !date.isBefore(start);
    }).toList()
      ..sort((a, b) {
        final da = ntParseDate(a.data()['start_date']) ?? DateTime(9999);
        final db = ntParseDate(b.data()['start_date']) ?? DateTime(9999);
        return da.compareTo(db);
      });
    return candidates.isEmpty ? null : candidates.first;
  }

  Widget _pad(Widget w) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad), child: w);

  void _openFantasy() {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(1);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const FantasyPage()));
    }
  }

  void _openTours() {
    if (widget.onTabSelected != null) {
      widget.onTabSelected!(2);
    } else {
      Navigator.push(context, MaterialPageRoute(builder: (_) => const ToursPage()));
    }
  }

  void _openSeasonStats() => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const TournamentStatsPage(
            tournamentId: 'nt-season',
            tournamentName: 'Årets NT sesong',
          ),
        ),
      );

  // ── Fantasy denne helgen ───────────────────────────────────────

  Widget _buildFantasySection(BuildContext context, _Doc? next) {
    // Frist = start på neste turnering (når den finnes)
    String? deadline;
    final start = next == null ? null : ntParseDate(next.data()['start_date'], next.data()['start_time']);
    if (start != null) {
      const days = ['MAN', 'TIR', 'ONS', 'TOR', 'FRE', 'LØR', 'SØN'];
      final hh = start.hour.toString().padLeft(2, '0');
      final mm = start.minute.toString().padLeft(2, '0');
      deadline = 'FRIST · ${days[start.weekday - 1]} $hh:$mm';
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const NtSectionHeader(title: 'Fantasy denne helgen'),
          const SizedBox(height: 14),
          if (_hasFantasy) ...[
            _FantasyTeamCard(
              teamName: _teamName ?? 'Mitt lag',
              points: _fantasyPoints,
              rank: _fantasyRank,
              deadline: deadline,
              onTap: _openFantasy,
            ),
            const SizedBox(height: 12),
          ],
          _FantasyPromoCard(
            hasTeam: _hasFantasy,
            onTap: _openFantasy,
          ),
          const SizedBox(height: 12),
          Row(children: [
            Expanded(
              child: _InfoTile(
                title: 'Statistikk',
                subtitle: 'Stats og rangeringer',
                onTap: _openSeasonStats,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _InfoTile(
                title: 'Tours',
                subtitle: 'Kamper og resultater',
                onTap: _openTours,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  Widget _exploreRow(BuildContext context) {
    return Row(children: [
      Expanded(
        child: _ExploreTile(
          label: 'Fantasy',
          icon: Icons.sports_volleyball_rounded,
          iconBg: AppColors.coral,
          iconColor: AppColors.ink,
          onTap: _openFantasy,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _ExploreTile(
          label: 'Statistikk',
          icon: Icons.bar_chart_rounded,
          iconBg: AppColors.ink,
          iconColor: Colors.white,
          onTap: _openSeasonStats,
        ),
      ),
      const SizedBox(width: 10),
      Expanded(
        child: _ExploreTile(
          label: 'Tours',
          icon: Icons.emoji_events_outlined,
          iconBg: AppColors.ink,
          iconColor: Colors.white,
          onTap: _openTours,
        ),
      ),
    ]);
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Neste tour
// ─────────────────────────────────────────────────────────────────────────────
class _NextTourCard extends StatefulWidget {
  final _Doc tour;
  const _NextTourCard({required this.tour});

  @override
  State<_NextTourCard> createState() => _NextTourCardState();
}

class _NextTourCardState extends State<_NextTourCard> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    // Oppdater nedtellingen hvert halve minutt
    _timer = Timer.periodic(const Duration(seconds: 30), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _openTour({int tab = 0}) => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => TournamentDetailsPage(
            tournamentId: widget.tour.id,
            data: widget.tour.data(),
            initialTab: tab,
          ),
        ),
      );

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    final d = widget.tour.data();
    final name = (d['name'] ?? 'Neste tour').toString();
    final location = (d['location'] ?? '').toString();
    final imageUrl = (d['image_url'] ?? '').toString();
    final dateText = ntDateRange(d);
    final regOpen = ntRegistrationOpen(d);
    final startsAt = ntParseDate(d['start_date'], d['start_time']);

    var left = startsAt?.difference(DateTime.now()) ?? Duration.zero;
    if (left.isNegative) left = Duration.zero;
    String two(int n) => n.toString().padLeft(2, '0');

    return NtCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          GestureDetector(
            onTap: () => _openTour(),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radiusRow),
              child: SizedBox(
                height: 150,
                child: imageUrl.isNotEmpty
                    ? Image.network(imageUrl,
                        fit: BoxFit.cover,
                        errorBuilder: (_, _, _) => _imageFallback(p))
                    : _imageFallback(p),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Expanded(
              child: Text(name, style: AppText.dispH1(24).copyWith(color: p.ink)),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
              decoration: BoxDecoration(
                color: regOpen ? AppColors.greenLight : p.soft,
                borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
              ),
              child: Text(regOpen ? 'Påmelding åpen' : 'Påmelding snart',
                  style: AppText.uiCaption.copyWith(
                      color: regOpen ? p.green : p.ink2, fontWeight: FontWeight.w700)),
            ),
          ]),
          const SizedBox(height: 4),
          Text([location, dateText].where((s) => s.isNotEmpty).join(' · '),
              style: AppText.uiCaption.copyWith(color: p.ink2, fontSize: 13)),
          const SizedBox(height: 14),
          StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
            stream: FirebaseFirestore.instance
                .collection('teams')
                .where('tournament_id', isEqualTo: widget.tour.id)
                .snapshots(),
            builder: (context, teamSnap) {
              final teams = teamSnap.data?.docs.length;
              return Row(children: [
                Expanded(child: _CountTile(value: startsAt == null ? '–' : two(left.inDays), label: 'DAGER')),
                const SizedBox(width: 6),
                Expanded(child: _CountTile(value: startsAt == null ? '–' : two(left.inHours % 24), label: 'TIMER')),
                const SizedBox(width: 6),
                Expanded(child: _CountTile(value: startsAt == null ? '–' : two(left.inMinutes % 60), label: 'MIN')),
                const SizedBox(width: 6),
                Expanded(child: _CountTile(value: teams == null ? '–' : '$teams', label: 'LAG')),
              ]);
            },
          ),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(
              child: _PrimaryButton(
                label: 'Meld på',
                onTap: () => _onMeldPa(d, regOpen),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _SecondaryButton(
                label: 'Se påmeldte',
                onTap: _onSePameldte,
              ),
            ),
          ]),
        ],
      ),
    );
  }

  // ── Påmelding ────────────────────────────────────────────────────────────
  // Knappene er kun design inntil påmeldingssystemet er ferdig.
  // Aktiver ved å sette kRegistrationEnabled = true i lib/widgets/nt_ui.dart.

  void _onMeldPa(Map<String, dynamic> d, bool regOpen) {
    if (kRegistrationEnabled && regOpen) {
      TournamentDetailsPage(tournamentId: widget.tour.id, data: d)
          .showRegistrationCategoryPicker(context);
      return;
    }
    _comingSoon('Påmelding åpner snart');
  }

  void _onSePameldte() {
    if (kRegistrationEnabled) {
      _openTour(tab: 3); // Lag-fanen
      return;
    }
    _comingSoon('Påmeldingslisten kommer snart');
  }

  void _comingSoon(String text) {
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(text)));
  }

  Widget _imageFallback(NtPalette p) => Container(
        color: p.segBg,
        alignment: Alignment.center,
        child: Icon(Icons.sports_volleyball_rounded, color: p.ink3, size: 40),
      );
}

class _CountTile extends StatelessWidget {
  final String value;
  final String label;
  const _CountTile({required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: p.soft,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(children: [
        Text(value, style: AppText.dispH1(24).copyWith(color: p.ink)),
        const SizedBox(height: 4),
        Text(label, style: AppText.monoSm.copyWith(color: p.ink2, fontSize: 8.5)),
      ]),
    );
  }
}

class _PrimaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _PrimaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: AppColors.coral,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          boxShadow: AppTheme.shadowCoral,
        ),
        child: Text(label, style: AppText.uiCta.copyWith(color: AppColors.ink, fontSize: 16)),
      ),
    );
  }
}

class _SecondaryButton extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _SecondaryButton({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 52,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusButton),
          border: Border.all(color: p.ink3.withValues(alpha: 0.4)),
        ),
        child: Text(label, style: AppText.uiCta.copyWith(color: p.ink, fontSize: 16)),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Utforsk-fliser
// ─────────────────────────────────────────────────────────────────────────────
class _ExploreTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final Color iconBg;
  final Color iconColor;
  final VoidCallback onTap;
  const _ExploreTile({
    required this.label,
    required this.icon,
    required this.iconBg,
    required this.iconColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 104,
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusRow),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Container(
              width: 38,
              height: 38,
              decoration: BoxDecoration(color: iconBg, borderRadius: BorderRadius.circular(10)),
              child: Icon(icon, color: iconColor, size: 20),
            ),
            Text(label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.dispH2(17).copyWith(color: p.ink)),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Fantasy-kort
// ─────────────────────────────────────────────────────────────────────────────
const _coralGradient = LinearGradient(
  begin: Alignment.topLeft,
  end: Alignment.bottomRight,
  colors: [AppColors.coralDeep, AppColors.coral, AppColors.coralDeep],
  stops: [0.0, 0.55, 1.0],
);

class _FantasyTeamCard extends StatelessWidget {
  final String teamName;
  final int? points;
  final int? rank;
  final String? deadline;
  final VoidCallback onTap;
  const _FantasyTeamCard({
    required this.teamName,
    required this.points,
    required this.rank,
    required this.deadline,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final label = AppText.monoSm.copyWith(color: Colors.white.withValues(alpha: 0.85), fontSize: 10.5);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 22, 18, 18),
        decoration: BoxDecoration(
          gradient: _coralGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard + 4),
          boxShadow: AppTheme.shadowCoral,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Expanded(
                child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Text('DITT LAG · ${teamName.toUpperCase()}',
                      maxLines: 1, overflow: TextOverflow.ellipsis, style: label),
                  const SizedBox(height: 6),
                  Row(crossAxisAlignment: CrossAxisAlignment.baseline, textBaseline: TextBaseline.alphabetic, children: [
                    Text(points == null ? '…' : '$points',
                        style: AppText.dispScore(48).copyWith(color: Colors.white)),
                    const SizedBox(width: 8),
                    Text('POENG', style: label),
                  ]),
                ]),
              ),
              Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
                Text('PLASSERING', style: label),
                const SizedBox(height: 6),
                Text(rank == null ? '#–' : '#$rank',
                    style: AppText.dispH1(30).copyWith(color: Colors.white)),
              ]),
            ]),
            const SizedBox(height: 20),
            Row(children: [
              Expanded(child: Text(deadline ?? '', style: label.copyWith(fontSize: 12))),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                decoration: BoxDecoration(
                  color: AppColors.sand0,
                  borderRadius: BorderRadius.circular(AppTheme.radiusButton),
                ),
                child: Text('Gjør bytter', style: AppText.uiCta.copyWith(color: AppColors.ink, fontSize: 16)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _FantasyPromoCard extends StatelessWidget {
  final bool hasTeam;
  final VoidCallback onTap;
  const _FantasyPromoCard({required this.hasTeam, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(22, 20, 18, 20),
        decoration: BoxDecoration(
          gradient: _coralGradient,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard + 4),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Row(children: [
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text('Fantasy', style: AppText.dispH1(26).copyWith(color: Colors.white)),
              const SizedBox(height: 4),
              Text(hasTeam ? 'Se laget ditt og ligaene' : 'Bygg drømmelaget ditt',
                  style: AppText.uiBody.copyWith(color: Colors.white, fontSize: 15)),
            ]),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
            decoration: BoxDecoration(
              color: AppColors.sand0,
              borderRadius: BorderRadius.circular(AppTheme.radiusButton),
            ),
            child: Text(hasTeam ? 'Åpne' : 'Spill nå',
                style: AppText.uiCta.copyWith(color: AppColors.ink, fontSize: 16)),
          ),
        ]),
      ),
    );
  }
}

class _InfoTile extends StatelessWidget {
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  const _InfoTile({required this.title, required this.subtitle, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.fromLTRB(18, 18, 14, 18),
        decoration: BoxDecoration(
          color: p.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusRow),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(title, style: AppText.dispH2(20).copyWith(color: p.ink)),
          const SizedBox(height: 8),
          Text(subtitle,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.uiCaption.copyWith(color: p.ink2, fontSize: 14)),
        ]),
      ),
    );
  }
}
