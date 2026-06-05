import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stats_logic.dart';
import 'stats_details_page.dart';
import 'players_list_page.dart';
import '../widgets/profile_avatar_widget.dart';
import '../widgets/season_hero_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

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

      matchStats.forEach((playerName, s) {
        if (!totalStatsMap.containsKey(playerName)) {
          totalStatsMap[playerName] = PlayerMatchStats(
            playerName: playerName,
            teamName: s.teamName,
            imageUrl: playerImages[playerName] ?? s.imageUrl,
          );
        }
        final total = totalStatsMap[playerName]!;
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
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset('assets/images/ntlogo.png', fit: BoxFit.contain),
        ),
        actions: const [ProfileAvatarWidget()],
      ),
      body: FutureBuilder<List<PlayerMatchStats>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator(color: AppColors.coral));
          }

          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshStats,
              color: AppColors.coral,
              child: ListView(
                physics: const AlwaysScrollableScrollPhysics(),
                children: const [
                  SizedBox(height: 200),
                  Center(child: Text('Ingen statistikk registrert enda.')),
                ],
              ),
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

          return Column(
            children: [
              const SeasonHeroWidget(
                title: 'STATS',
                description: 'Hvem leder, og hvem har flest serveess?',
                playerImage: 'assets/images/8.png',
              ),
              Expanded(
                child: RefreshIndicator(
                  onRefresh: _refreshStats,
                  color: AppColors.coral,
                  child: SingleChildScrollView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, AppTheme.sectionGap, AppTheme.pageHPad, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                  // All players button
                  GestureDetector(
                    onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayersListPage())),
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: AppColors.heroNavy,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        boxShadow: AppTheme.shadowLg,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: AppTheme.cardPad),
                      child: Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(10),
                            decoration: BoxDecoration(
                              color: AppColors.coral.withOpacity(0.2),
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
                                    style: AppText.uiCaption.copyWith(color: Colors.white.withOpacity(0.6))),
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
                ],
              ),
            ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class StatsCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<PlayerMatchStats> players;
  final String Function(PlayerMatchStats) valueFormatter;
  final VoidCallback onTap;

  const StatsCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.players,
    required this.valueFormatter,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();

    final winner = players[0];
    final runnersUp = players.length > 1 ? players.sublist(1, players.length > 5 ? 5 : players.length) : [];

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: AppColors.sand0,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: AppTheme.cardPad),
              decoration: BoxDecoration(
                color: accentColor.withOpacity(0.10),
                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
              ),
              child: Row(
                children: [
                  Icon(icon, color: accentColor, size: 20),
                  const SizedBox(width: 10),
                  Text(title, style: AppText.dispKicker(14).copyWith(color: AppColors.ink)),
                  const Spacer(),
                  Icon(Icons.arrow_forward_ios, color: AppColors.ink3, size: 14),
                ],
              ),
            ),

            // Winner
            Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 38,
                    backgroundColor: accentColor.withOpacity(0.15),
                    backgroundImage: winner.imageUrl.isNotEmpty ? NetworkImage(winner.imageUrl) : null,
                    child: winner.imageUrl.isEmpty
                        ? Text(
                            winner.playerName.isEmpty ? '?' : winner.playerName.substring(0, 1).toUpperCase(),
                            style: AppText.dispScore(28).copyWith(color: accentColor),
                          )
                        : null,
                  ),
                  const SizedBox(height: 10),
                  Text(winner.playerName, style: AppText.uiTitle.copyWith(fontSize: 17)),
                  if (winner.teamName.isNotEmpty) ...[
                    const SizedBox(height: 2),
                    Text(winner.teamName, style: AppText.uiCaption),
                  ],
                  const SizedBox(height: 8),
                  Text(valueFormatter(winner), style: AppText.dispScore(28).copyWith(color: accentColor)),
                ],
              ),
            ),

            // Runners up
            if (runnersUp.isNotEmpty)
              Container(
                decoration: BoxDecoration(
                  color: AppColors.sand1,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(AppTheme.radiusCard)),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  children: runnersUp.asMap().entries.map((entry) {
                    final index = entry.key + 2;
                    final player = entry.value;
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPad, vertical: 7),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 22,
                            child: Text('$index.', style: AppText.monoMd.copyWith(color: AppColors.ink3)),
                          ),
                          if (player.imageUrl.isNotEmpty)
                            Padding(
                              padding: const EdgeInsets.only(right: 8.0),
                              child: CircleAvatar(
                                radius: 12,
                                backgroundImage: NetworkImage(player.imageUrl),
                                backgroundColor: AppColors.sand2,
                              ),
                            )
                          else
                            const SizedBox(width: 8),
                          Expanded(child: Text(player.playerName, style: AppText.uiTitle.copyWith(fontSize: 13))),
                          Text(valueFormatter(player), style: AppText.monoMd.copyWith(fontWeight: FontWeight.w700, color: AppColors.ink)),
                        ],
                      ),
                    );
                  }).toList(),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
