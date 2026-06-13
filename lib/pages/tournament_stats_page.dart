import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stats_logic.dart'; 
import 'stats_details_page.dart'; // Husk å lage/oppdatere denne filen (se under)
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class TournamentStatsPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;

  const TournamentStatsPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
  });

  @override
  State<TournamentStatsPage> createState() => _TournamentStatsPageState();
}

class _TournamentStatsPageState extends State<TournamentStatsPage> {
  late Future<List<PlayerMatchStats>> _statsFuture;

  @override
  void initState() {
    super.initState();
    _statsFuture = _calculateTournamentStats();
  }

  // Henter og slår sammen stats (Samme logikk som før)
  Future<List<PlayerMatchStats>> _calculateTournamentStats() async {
    Query query = FirebaseFirestore.instance.collection('matches');
    
    if (widget.tournamentId != 'all' && widget.tournamentId != 'nt-season') {
      query = query.where('tournament_id', isEqualTo: widget.tournamentId);
    }
    
    final matchesSnapshot = await query.get();

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

    Map<String, PlayerMatchStats> totalStatsMap = {};

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
      });
    }
    return totalStatsMap.values.toList();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    
    return Scaffold(
      backgroundColor: AppColors.ink,
      appBar: AppBar(
        title: Text(
          "Hall of Fame - ${widget.tournamentName}",
          style: AppText.dispH2(18).copyWith(color: Colors.white),
        ),
        backgroundColor: AppColors.ink,
        elevation: 0,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: FutureBuilder<List<PlayerMatchStats>>(
        future: _statsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return RefreshIndicator(
              onRefresh: _refreshStats,
              child: ListView(
                children: [
                  const SizedBox(height: 200),
                  Center(child: Text("Ingen stats registrert enda.", style: AppText.uiCaption.copyWith(color: Colors.white70))),
                ],
              ),
            );
          }

          final allPlayers = snapshot.data!;

          // ... (Din sorterings-kode her: pointsList, sideoutList osv.) ...
          // ... (Lim inn sorterings-blokken vi lagde sist her) ...
          
          final pointsList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
          final sideoutList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.sideoutPoints.compareTo(a.sideoutPoints));
          final blocksList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.blocks.compareTo(a.blocks));
          final settersList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) {
               double aPct = a.setAttempts == 0 ? 0 : (a.setAssists / a.setAttempts);
               double bPct = b.setAttempts == 0 ? 0 : (b.setAssists / b.setAttempts);
               return bPct.compareTo(aPct);
            });
          final serverList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.aces.compareTo(a.aces));


          // HER ER ENDRINGEN:
          return RefreshIndicator(
            onRefresh: _refreshStats, // Kaller funksjonen under
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(), // Viktig for at den skal kunne dras
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
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
                    accentColor: AppColors.coralDeep,
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
                    accentColor: AppColors.blueBright,
                    players: serverList,
                    valueFormatter: (p) => '${p.aces} ess',
                    onTap: () => _navigateToDetails(context, allPlayers, 'Serve'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Legg til denne funksjonen nederst i klassen din:
  Future<void> _refreshStats() async {
    setState(() {
      // Dette trigger en ny henting av data
      _statsFuture = _calculateTournamentStats();
    });
    // Vi venter på at den skal bli ferdig
    await _statsFuture;
  }

  void _navigateToDetails(BuildContext context, List<PlayerMatchStats> players, String category) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => StatsDetailsPage(allPlayers: players, initialSort: category),
      ),
    );
  }
}

// --- WIDGET FOR KORTENE ---
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
              Text(title.toUpperCase(), style: AppText.dispKicker(16).copyWith(color: Colors.white)),
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
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
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