import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:norges_tour_app/logic/stats_logic.dart';
import 'package:norges_tour_app/pages/stats/stats_details_page.dart';
import 'package:norges_tour_app/pages/stats/players_list_page.dart';
import 'package:norges_tour_app/widgets/season_hero_widget.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/widgets/stats_category_card.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';
import 'package:norges_tour_app/theme/app_theme.dart';

class StatsRootPage extends StatefulWidget {
  const StatsRootPage({super.key});

  @override
  State<StatsRootPage> createState() => _StatsRootPageState();
}

class _StatsRootPageState extends State<StatsRootPage> {
  late Future<List<PlayerMatchStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _calculateAllTimeStats();
  }

  Future<List<PlayerMatchStats>> _calculateAllTimeStats() async {
    final matchesSnapshot = await FirebaseFirestore.instance.collection('matches').get();
    Map<String, PlayerMatchStats> totalStatsMap = {};

    final playersSnapshot = await FirebaseFirestore.instance.collection('players').get();
    Map<String, String> playerImages = {};
    for (var doc in playersSnapshot.docs) {
      final data = doc.data();
      final firstName = (data['first_name'] ?? '').toString();
      final lastName = (data['last_name'] ?? '').toString();
      final fullName = '$firstName $lastName'.trim();
      if (fullName.isNotEmpty) {
        playerImages[fullName] = data['image_url'] ?? data['image'] ?? data['photoUrl'] ?? data['photo_url'] ?? data['picture'] ?? '';
      }
    }

    for (var matchDoc in matchesSnapshot.docs) {
      final eventsSnapshot = await matchDoc.reference.collection('events').get();
      if (eventsSnapshot.docs.isEmpty) continue;
      final eventsList = eventsSnapshot.docs.map((d) => d.data()).toList();
      final typedList = eventsList.cast<Map<String, dynamic>>();
      final matchStats = calculateMatchStats(typedList);

      matchStats.players.forEach((originalPlayerName, s) {
        String finalPlayerName = originalPlayerName;
        String foundImage = playerImages[originalPlayerName] ?? '';

        if (foundImage.isEmpty) {
          final mParts = originalPlayerName.toLowerCase().split(' ');
          if (mParts.isNotEmpty) {
            for (var pName in playerImages.keys) {
              final pParts = pName.toLowerCase().split(' ');
              if (pParts.isNotEmpty && pParts.first == mParts.first && pParts.last == mParts.last) {
                foundImage = playerImages[pName]!;
                finalPlayerName = pName;
                break;
              }
            }
          }
        }

        if (!totalStatsMap.containsKey(finalPlayerName)) {
          totalStatsMap[finalPlayerName] = PlayerMatchStats(
            playerName: finalPlayerName,
            teamName: s.teamName,
            imageUrl: foundImage.isNotEmpty ? foundImage : s.imageUrl,
          );
        }
        final total = totalStatsMap[finalPlayerName]!;
        total.kills += s.kills;
        total.attackErrors += s.attackErrors;
        total.blocks += s.blocks;
        total.aces += s.aces;
        total.serviceErrors += s.serviceErrors;
        total.receptionErrors += s.receptionErrors;
        total.sideoutPoints += s.sideoutPoints;
        total.setAssists += s.setAssists;
        total.setAttempts += s.setAttempts;
        s.killDetails.forEach((k, v) => total.killDetails[k] = (total.killDetails[k] ?? 0) + v);
        s.aceDetails.forEach((k, v) => total.aceDetails[k] = (total.aceDetails[k] ?? 0) + v);
        s.attackErrorDetails.forEach((k, v) => total.attackErrorDetails[k] = (total.attackErrorDetails[k] ?? 0) + v);
      });
    }
    return totalStatsMap.values.toList();
  }

  Future<void> _refreshStats() async {
    setState(() { _statsFuture = _calculateAllTimeStats(); });
    await _statsFuture;
  }

  void _navigateToDetails(BuildContext context, List<PlayerMatchStats> players, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (context) => StatsDetailsPage(allPlayers: players, initialSort: category)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent,
      body: RefreshIndicator(
        onRefresh: _refreshStats,
        color: AppColors.coral,
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            const SeasonHeroSliver(
              pageTitle: 'Statistikk',
              title: 'STATS',
              description: 'Dypdykk i tallene fra sesongen.',
              actionImage: 'assets/images/4.png',
            ),
            SliverToBoxAdapter(
              child: FutureBuilder<List<PlayerMatchStats>>(
                future: _statsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: CircularProgressIndicator(color: AppColors.coral)),
                    );
                  }

                  if (!snapshot.hasData || snapshot.data!.isEmpty) {
                    return Padding(
                      padding: const EdgeInsets.all(40),
                      child: Center(child: Text('Ingen statistikk registrert enda.', style: AppText.uiCaption.copyWith(color: Colors.white70))),
                    );
                  }

                  List<PlayerMatchStats> allPlayers = snapshot.data!;

                  final pointsList = List<PlayerMatchStats>.from(allPlayers)..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
                  final sideoutList = List<PlayerMatchStats>.from(allPlayers)..sort((a, b) => b.sideoutPoints.compareTo(a.sideoutPoints));
                  final blocksList = List<PlayerMatchStats>.from(allPlayers)..sort((a, b) => b.blocks.compareTo(a.blocks));
                  final settersList = List<PlayerMatchStats>.from(allPlayers)
                    ..sort((a, b) {
                      double aPct = a.setAttempts == 0 ? 0 : (a.setAssists / a.setAttempts);
                      double bPct = b.setAttempts == 0 ? 0 : (b.setAssists / b.setAttempts);
                      return bPct.compareTo(aPct);
                    });
                  final serverList = List<PlayerMatchStats>.from(allPlayers)..sort((a, b) => b.aces.compareTo(a.aces));
                  final mottakList = List<PlayerMatchStats>.from(allPlayers)
                    ..sort((a, b) {
                      double aPct = (a.sideoutPoints + a.receptionErrors) == 0 ? 0 : (a.sideoutPoints / (a.sideoutPoints + a.receptionErrors));
                      double bPct = (b.sideoutPoints + b.receptionErrors) == 0 ? 0 : (b.sideoutPoints / (b.sideoutPoints + b.receptionErrors));
                      return bPct.compareTo(aPct);
                    });
                  final forsvarList = List<PlayerMatchStats>.from(allPlayers)
                    ..sort((a, b) => b.overgangsPoeng.compareTo(a.overgangsPoeng));
                  return Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 16, AppTheme.pageHPad, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          // Knapp til alle spillere
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayersListPage())),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                                boxShadow: AppTheme.shadowLg,
                                gradient: AppColors.cardInk,
                              ),
                              padding: const EdgeInsets.symmetric(vertical: 18, horizontal: AppTheme.cardPad),
                              child: Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(10),
                                    decoration: BoxDecoration(
                                      color: AppColors.coral.withValues(alpha: 0.2),
                                      shape: BoxShape.circle,
                                    ),
                                    child: const Icon(Icons.groups_rounded, color: AppColors.coral, size: 26),
                                  ),
                                  const SizedBox(width: 14),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text('ALLE SPILLERE', style: AppText.dispKicker(14).copyWith(color: Colors.white)),
                                        const SizedBox(height: 3),
                                        Text('Se alle registrerte spillere og profiler',
                                            style: AppText.uiCaption.copyWith(color: Colors.white.withValues(alpha: 0.6))),
                                      ],
                                    ),
                                  ),
                                  const Icon(Icons.arrow_forward_ios, color: Colors.white54, size: 16),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: AppTheme.sectionGap),

                          StatsCategoryCard(
                            title: 'Toppscorer',
                            icon: Icons.emoji_events,
                            accentColor: AppColors.coral,
                            players: pointsList,
                            valueFormatter: (p) => '${p.totalPoints} p',
                            onTap: () => _navigateToDetails(context, allPlayers, 'Toppscorer'),
                          ),
                          const SizedBox(height: AppTheme.rowGap),
                          StatsCategoryCard(
                            title: 'Sideout-maskin',
                            icon: Icons.compare_arrows,
                            accentColor: AppColors.blue,
                            players: sideoutList,
                            valueFormatter: (p) => '${p.sideoutPoints} p',
                            onTap: () => _navigateToDetails(context, allPlayers, 'Sideout'),
                          ),
                          const SizedBox(height: AppTheme.rowGap),
                          StatsCategoryCard(
                            title: 'Blokk-monster',
                            icon: Icons.front_hand,
                            accentColor: AppColors.coral,
                            players: blocksList,
                            valueFormatter: (p) => '${p.blocks} blk',
                            onTap: () => _navigateToDetails(context, allPlayers, 'Blokk'),
                          ),
                          const SizedBox(height: AppTheme.rowGap),
                          StatsCategoryCard(
                            title: 'Legge-maestro',
                            icon: Icons.sports_volleyball,
                            accentColor: AppColors.green,
                            players: settersList,
                            valueFormatter: (p) => p.settingEfficiency,
                            onTap: () => _navigateToDetails(context, allPlayers, 'Legging'),
                          ),
                          const SizedBox(height: AppTheme.rowGap),
                          StatsCategoryCard(
                            title: 'Serve-Konge',
                            icon: Icons.flash_on,
                            accentColor: AppColors.blue,
                            players: serverList,
                            valueFormatter: (p) => '${p.aces} ess',
                            onTap: () => _navigateToDetails(context, allPlayers, 'Serve'),
                          ),
                          const SizedBox(height: AppTheme.rowGap),
                          StatsCategoryCard(
                            title: 'Mottak-mester',
                            icon: Icons.shield,
                            accentColor: AppColors.coralDeep,
                            players: mottakList,
                            valueFormatter: (p) => p.receptionEfficiency,
                            onTap: () => _navigateToDetails(context, allPlayers, 'Mottak'),
                          ),
                          const SizedBox(height: AppTheme.rowGap),
                          StatsCategoryCard(
                            title: 'Forsvars-klippe',
                            icon: Icons.security,
                            accentColor: AppColors.green,
                            players: forsvarList,
                            valueFormatter: (p) => '${p.overgangsPoeng} f.poeng',
                            onTap: () => _navigateToDetails(context, allPlayers, 'Forsvar'),
                          ),
                        ],
                      ),
                    );
                  },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
