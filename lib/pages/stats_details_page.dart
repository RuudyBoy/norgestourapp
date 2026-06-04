import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stats_logic.dart';
import 'player_detail_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class StatsDetailsPage extends StatefulWidget {
  final List<PlayerMatchStats> allPlayers;
  final String initialSort;

  const StatsDetailsPage({
    super.key,
    required this.allPlayers,
    required this.initialSort,
  });

  @override
  State<StatsDetailsPage> createState() => _StatsDetailsPageState();
}

class _StatsDetailsPageState extends State<StatsDetailsPage> {
  late List<PlayerMatchStats> sortedPlayers;
  late String currentSort;

  @override
  void initState() {
    super.initState();
    sortedPlayers = List.from(widget.allPlayers);
    currentSort = widget.initialSort;
    _sortPlayers(currentSort);
  }

  Future<void> _navigateToPlayerProfile(PlayerMatchStats p) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: AppColors.coral)),
    );

    try {
      final query = await FirebaseFirestore.instance.collection('players').get();
      if (!mounted) return;
      Navigator.pop(context);

      final docs = query.docs.where((doc) {
        final data = doc.data();
        final firstName = data['first_name'] ?? '';
        final lastName = data['last_name'] ?? '';
        return '$firstName $lastName'.toLowerCase() == p.playerName.toLowerCase();
      }).toList();

      if (docs.isNotEmpty) {
        final doc = docs.first;
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PlayerDetailPage(playerId: doc.id, playerData: doc.data())),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fant ikke profil for ${p.playerName}', style: AppText.uiCaption)),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feil ved henting av spiller')),
      );
    }
  }

  void _sortPlayers(String criteria) {
    setState(() {
      currentSort = criteria;
      if (criteria == 'Toppscorer') {
        sortedPlayers.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      } else if (criteria == 'Sideout') {
        sortedPlayers.sort((a, b) => b.sideoutPoints.compareTo(a.sideoutPoints));
      } else if (criteria == 'Blokk') {
        sortedPlayers.sort((a, b) => b.blocks.compareTo(a.blocks));
      } else if (criteria == 'Legging') {
        sortedPlayers.sort((a, b) {
          double aPct = a.setAttempts == 0 ? 0 : (a.setAssists / a.setAttempts);
          double bPct = b.setAttempts == 0 ? 0 : (b.setAssists / b.setAttempts);
          return bPct.compareTo(aPct);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('FULL OVERSIKT', style: AppText.dispH2(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 12, AppTheme.pageHPad, 0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _sortChip('Poeng', () => _sortPlayers('Toppscorer'), currentSort == 'Toppscorer'),
                  _sortChip('Sideout', () => _sortPlayers('Sideout'), currentSort == 'Sideout'),
                  _sortChip('Blokk', () => _sortPlayers('Blokk'), currentSort == 'Blokk'),
                  _sortChip('Legg', () => _sortPlayers('Legging'), currentSort == 'Legging'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(child: _buildStatsList(sortedPlayers)),
        ],
      ),
    );
  }

  Widget _sortChip(String text, VoidCallback onTap, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.coral : AppColors.sand2,
            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
          ),
          child: Text(
            text,
            style: AppText.monoSm.copyWith(
              color: isSelected ? Colors.white : AppColors.ink2,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildStatsList(List<PlayerMatchStats> players) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 0, AppTheme.pageHPad, 32),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final p = players[index];
        final isTop3 = index < 3;
        return GestureDetector(
          onTap: () => _navigateToPlayerProfile(p),
          child: Container(
            margin: const EdgeInsets.only(bottom: AppTheme.rowGap),
            padding: const EdgeInsets.all(AppTheme.cardPad),
            decoration: BoxDecoration(
              color: AppColors.sand0,
              borderRadius: BorderRadius.circular(AppTheme.radiusRow),
              border: isTop3
                  ? Border(left: BorderSide(color: AppColors.coral, width: 3))
                  : null,
              boxShadow: AppTheme.shadowSm,
            ),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  child: Text(
                    '#${index + 1}',
                    style: isTop3
                        ? AppText.dispH2(16).copyWith(color: AppColors.coral)
                        : AppText.monoMd.copyWith(color: AppColors.ink3),
                  ),
                ),
                if (p.imageUrl.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundImage: NetworkImage(p.imageUrl),
                      backgroundColor: AppColors.sand2,
                    ),
                  )
                else
                  Padding(
                    padding: const EdgeInsets.only(right: 10.0),
                    child: CircleAvatar(
                      radius: 18,
                      backgroundColor: AppColors.sand2,
                      child: Text(
                        p.playerName.isEmpty ? '?' : p.playerName.substring(0, 1).toUpperCase(),
                        style: AppText.dispKicker(14).copyWith(color: AppColors.ink2),
                      ),
                    ),
                  ),
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(p.playerName, style: AppText.uiTitle, overflow: TextOverflow.ellipsis),
                      Text(p.teamName, style: AppText.uiCaption, overflow: TextOverflow.ellipsis),
                    ],
                  ),
                ),
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat('TOT', p.totalPoints.toString(), isHighlight: currentSort == 'Toppscorer'),
                      _buildMiniStat('SO', p.sideoutPoints.toString(), isHighlight: currentSort == 'Sideout'),
                      _buildMiniStat('BLK', p.blocks.toString(), isHighlight: currentSort == 'Blokk'),
                      _buildMiniStat('LEGG', p.settingEfficiency, isHighlight: currentSort == 'Legging'),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(label, style: AppText.monoSm.copyWith(color: isHighlight ? AppColors.coral : AppColors.ink3)),
        const SizedBox(height: 3),
        Text(
          value,
          style: isHighlight
              ? AppText.dispKicker(14).copyWith(color: AppColors.coral)
              : AppText.uiTitle.copyWith(fontSize: 13),
        ),
      ],
    );
  }
}
