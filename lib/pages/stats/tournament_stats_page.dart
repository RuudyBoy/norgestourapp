import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:norges_tour_app/logic/stats_logic.dart';
import 'package:norges_tour_app/pages/stats/stats_details_page.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/widgets/stats_category_card.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';
import 'package:norges_tour_app/theme/app_theme.dart';

class TournamentStatsPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final bool isEmbedded;

  const TournamentStatsPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isEmbedded = false,
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

  // Henter alle kampene i turneringen og slår sammen statistikken per spiller.
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
    final content = FutureBuilder<List<PlayerMatchStats>>(
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
          final mottakList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) {
               double aPct = (a.sideoutPoints + a.receptionErrors) == 0 ? 0 : (a.sideoutPoints / (a.sideoutPoints + a.receptionErrors));
               double bPct = (b.sideoutPoints + b.receptionErrors) == 0 ? 0 : (b.sideoutPoints / (b.sideoutPoints + b.receptionErrors));
               return bPct.compareTo(aPct);
            });
          final forsvarList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.overgangsPoeng.compareTo(a.overgangsPoeng));
          final serverList = List<PlayerMatchStats>.from(allPlayers)
            ..sort((a, b) => b.aces.compareTo(a.aces));

          return RefreshIndicator(
            onRefresh: _refreshStats,
            child: SingleChildScrollView(
              // Alltid scrollbar, slik at «dra for å oppdatere» virker også med lite innhold.
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  StatsCategoryCard(
                    titleColor: Colors.white,
                    title: 'Toppscorer',
                    icon: Icons.emoji_events,
                    accentColor: AppColors.coral,
                    players: pointsList,
                    valueFormatter: (p) => '${p.totalPoints} p',
                    onTap: () => _navigateToDetails(context, allPlayers, 'Toppscorer'),
                  ),
                  const SizedBox(height: AppTheme.rowGap),
                  
                  StatsCategoryCard(
                    titleColor: Colors.white,
                    title: 'Sideout-maskin',
                    icon: Icons.compare_arrows,
                    accentColor: AppColors.blue,
                    players: sideoutList,
                    valueFormatter: (p) => '${p.sideoutPoints} p',
                    onTap: () => _navigateToDetails(context, allPlayers, 'Sideout'),
                  ),
                  const SizedBox(height: AppTheme.rowGap),

                  StatsCategoryCard(
                    titleColor: Colors.white,
                    title: 'Blokk-monster',
                    icon: Icons.front_hand,
                    accentColor: AppColors.coralDeep,
                    players: blocksList,
                    valueFormatter: (p) => '${p.blocks} blk',
                    onTap: () => _navigateToDetails(context, allPlayers, 'Blokk'),
                  ),
                  const SizedBox(height: AppTheme.rowGap),

                  StatsCategoryCard(
                    titleColor: Colors.white,
                    title: 'Legge-maestro',
                    icon: Icons.sports_volleyball,
                    accentColor: AppColors.green,
                    players: settersList,
                    valueFormatter: (p) => p.settingEfficiency,
                    onTap: () => _navigateToDetails(context, allPlayers, 'Legging'),
                  ),
                  const SizedBox(height: AppTheme.rowGap),

                  StatsCategoryCard(
                    titleColor: Colors.white,
                    title: 'Serve-Konge',
                    icon: Icons.flash_on,
                    accentColor: AppColors.blueBright,
                    players: serverList,
                    valueFormatter: (p) => '${p.aces} ess',
                    onTap: () => _navigateToDetails(context, allPlayers, 'Serve'),
                  ),
                  const SizedBox(height: AppTheme.rowGap),

                  StatsCategoryCard(
                    titleColor: Colors.white,
                    title: 'Mottak-mester',
                    icon: Icons.shield,
                    accentColor: AppColors.blue,
                    players: mottakList,
                    valueFormatter: (p) => p.receptionEfficiency,
                    onTap: () => _navigateToDetails(context, allPlayers, 'Mottak'),
                  ),
                  const SizedBox(height: AppTheme.rowGap),

                  StatsCategoryCard(
                    titleColor: Colors.white,
                    title: 'Forsvars-klippe',
                    icon: Icons.security,
                    accentColor: AppColors.coral,
                    players: forsvarList,
                    valueFormatter: (p) => '${p.overgangsPoeng} f.poeng',
                    onTap: () => _navigateToDetails(context, allPlayers, 'Forsvar'),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          );
        },
      );

    if (widget.isEmbedded) return content;

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
      body: content,
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
