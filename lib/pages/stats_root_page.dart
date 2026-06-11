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

      matchStats.players.forEach((playerName, s) {
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
              actionImage: 'assets/images/player_action.png',
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
                    return const Padding(
                      padding: EdgeInsets.all(40),
                      child: Center(child: Text('Ingen statistikk registrert enda.')),
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

                  return Padding(
                    padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 16, AppTheme.pageHPad, 32),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                          // All players button
                          GestureDetector(
                            onTap: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const PlayersListPage())),
                            child: Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                                boxShadow: AppTheme.shadowLg,
                                image: const DecorationImage(
                                  image: AssetImage('assets/images/card_bg.png'),
                                  fit: BoxFit.cover,
                                ),
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

    final valString = valueFormatter(winner);
    String bigNum = valString;
    String labelText = '';
    if (valString.contains(' ')) {
      final parts = valString.split(' ');
      bigNum = parts[0];
      labelText = parts.sublist(1).join(' ').toUpperCase();
    } else {
      if (valString.endsWith('%')) {
        bigNum = valString.substring(0, valString.length - 1);
        labelText = '%';
      }
    }

    final nameParts = winner.playerName.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header / Title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Text(title.toUpperCase(), style: AppText.dispKicker(16).copyWith(color: AppColors.ink)),
            ],
          ),
        ),

        // PREMIER LEAGUE STYLE CARD
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 280, // tall card
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.shadowLg,
              image: const DecorationImage(
                image: AssetImage('assets/images/card_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                
                // Player Image Cutout on right
                if (winner.imageUrl.isNotEmpty)
                  Positioned(
                    right: 0, bottom: 50, top: 20, width: 200,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.transparent],
                          stops: [0.75, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.network(
                        winner.imageUrl, 
                        fit: BoxFit.cover,
                        alignment: Alignment.topCenter,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 150, color: Colors.white.withOpacity(0.05)),
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: 10, bottom: 50, top: 20, width: 180,
                    child: Icon(Icons.person, size: 150, color: Colors.white.withOpacity(0.05)),
                  ),
                
                // Text Overlay (Left Side)
                Positioned(
                  left: 20, top: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(firstName.toUpperCase(), 
                        style: AppText.dispScore(22).copyWith(color: accentColor, height: 1.1)
                      ),
                      if (lastName.isNotEmpty)
                        Text(lastName.toUpperCase(), 
                          style: AppText.dispScore(22).copyWith(color: Colors.white, height: 1.1)
                        ),
                      const SizedBox(height: 6),
                      Text(winner.teamName.isNotEmpty ? winner.teamName.toUpperCase() : 'SPILLER', 
                        style: AppText.monoMd.copyWith(color: Colors.white70, fontSize: 11)
                      ),
                    ],
                  ),
                ),
                
                // Big Number (Right Side, Top)
                Positioned(
                  right: 20, top: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(bigNum, 
                        style: AppText.dispScore(42).copyWith(color: Colors.white, height: 1.0)
                      ),
                      Text(labelText, 
                        style: AppText.dispKicker(14).copyWith(color: Colors.white, height: 1.2)
                      ),
                    ],
                  ),
                ),
                
                // Bottom small stats
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSmallStat('KILLS', winner.kills.toString()),
                        _buildSmallStat('BLOKK', winner.blocks.toString()),
                        _buildSmallStat('ESS', winner.aces.toString()),
                        _buildSmallStat('FEIL', (winner.attackErrors + winner.serviceErrors).toString()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Runners Up List Below Card
        if (runnersUp.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.cardInk,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: [
                ...runnersUp.asMap().entries.map((entry) {
                  final index = entry.key + 2;
                  final player = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPad, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text('$index.', style: AppText.monoMd.copyWith(color: Colors.white70, fontWeight: FontWeight.bold)),
                        ),
                        if (player.imageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(player.imageUrl),
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                            ),
                          )
                        else
                          const SizedBox(width: 8),
                        Expanded(child: Text(player.playerName, style: AppText.uiTitle.copyWith(fontSize: 14, color: Colors.white))),
                        Text(valueFormatter(player), style: AppText.monoMd.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  );
                }),
                // Link to full list
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                InkWell(
                  onTap: onTap,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Vis alle', style: AppText.uiTitle.copyWith(color: Colors.white)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: AppText.uiCaption.copyWith(color: Colors.white70, fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: AppText.uiTitle.copyWith(color: Colors.white, fontSize: 15)),
      ],
    );
  }
}
