import 'package:flutter/material.dart';
import 'models.dart';
import 'league_logic.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

class FantasyHighlightsView extends StatefulWidget {
  final List<FantasyPlayer> players;
  const FantasyHighlightsView({super.key, required this.players});

  @override
  State<FantasyHighlightsView> createState() => _FantasyHighlightsViewState();
}

class _FantasyHighlightsViewState extends State<FantasyHighlightsView> {
  bool _isLoading = true;
  LeaderboardEntry? _bestManager;

  @override
  void initState() {
    super.initState();
    _fetchBestManager();
  }

  Future<void> _fetchBestManager() async {
    setState(() => _isLoading = true);
    final leaderboard = await LeagueLogic.getGlobalLeaderboard(widget.players);
    if (leaderboard.isNotEmpty) {
      _bestManager = leaderboard.first;
    }
    if (mounted) setState(() => _isLoading = false);
  }

  FantasyPlayer _getBestPlayer() {
    return widget.players.reduce((a, b) => a.totalPoints > b.totalPoints ? a : b);
  }

  FantasyPlayer _getBestForStat(int Function(FantasyPlayer) getStat) {
    return widget.players.reduce((a, b) => getStat(a) > getStat(b) ? a : b);
  }

  @override
  Widget build(BuildContext context) {
    if (widget.players.isEmpty) {
      return const Center(child: Text('Ingen spillerdata tilgjengelig.'));
    }

    final bestPlayer = _getBestPlayer();
    
    // Team of the week
    final bestBlock = _getBestForStat((p) => p.blocks);
    final bestAttack = _getBestForStat((p) => p.attacks);
    final bestSet = _getBestForStat((p) => p.sets);
    final bestReceive = _getBestForStat((p) => p.receives);
    final bestDefense = _getBestForStat((p) => p.digs);
    final bestServe = _getBestForStat((p) => p.aces);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(AppTheme.pageHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Best Manager
          Text('Ukens Fantasy Manager', style: AppText.dispH2(20)),
          const SizedBox(height: 12),
          _buildManagerCard(),
          const SizedBox(height: 24),

          // Best Player
          Text('Ukens Beste Spiller', style: AppText.dispH2(20)),
          const SizedBox(height: 12),
          _buildBestPlayerCard(bestPlayer),
          const SizedBox(height: 24),

          // Team of the week
          Text('Ukens Lag', style: AppText.dispH2(20)),
          const SizedBox(height: 8),
          Text('Spillerne med flest poeng i hver kategori', style: AppText.uiCaption),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.all(AppTheme.cardPad),
            decoration: BoxDecoration(
              color: AppColors.sand0,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: [
                _buildTeamRow(FantasyRole.attack, bestAttack, '${bestAttack.attacks} angrep'),
                const Divider(height: 20, color: AppColors.line),
                _buildTeamRow(FantasyRole.block, bestBlock, '${bestBlock.blocks} blokker'),
                const Divider(height: 20, color: AppColors.line),
                _buildTeamRow(FantasyRole.serve, bestServe, '${bestServe.aces} ess'),
                const Divider(height: 20, color: AppColors.line),
                _buildTeamRow(FantasyRole.defense, bestDefense, '${bestDefense.digs} forsvar'),
                const Divider(height: 20, color: AppColors.line),
                _buildTeamRow(FantasyRole.receive, bestReceive, '${bestReceive.receives} mottak'),
                const Divider(height: 20, color: AppColors.line),
                _buildTeamRow(FantasyRole.set, bestSet, '${bestSet.sets} legg'),
              ],
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildManagerCard() {
    if (_isLoading) {
      return const Center(child: Padding(padding: EdgeInsets.all(20), child: CircularProgressIndicator(color: AppColors.coral)));
    }
    
    if (_bestManager == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: AppColors.sand0, borderRadius: BorderRadius.circular(AppTheme.radiusCard)),
        child: const Center(child: Text('Ingen data enda')),
      );
    }

    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPad),
      decoration: BoxDecoration(
        gradient: const LinearGradient(colors: [AppColors.coral, Color(0xFFD64A35)]),
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowLg,
      ),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: const BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.emoji_events, color: AppColors.coral, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_bestManager!.teamName, style: AppText.dispH2(18).copyWith(color: Colors.white)),
                Text(_bestManager!.managerName, style: AppText.uiCaption.copyWith(color: Colors.white.withOpacity(0.8))),
              ],
            ),
          ),
          Text('${_bestManager!.totalPoints} pts', style: AppText.dispScore(24).copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildBestPlayerCard(FantasyPlayer player) {
    return Container(
      padding: const EdgeInsets.all(AppTheme.cardPad),
      decoration: BoxDecoration(
        color: AppColors.sand0,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowSm,
        border: Border.all(color: AppColors.coral.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: AppColors.sand2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.coral, width: 2),
            ),
            child: player.imageUrl.isNotEmpty
                ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                : const Icon(Icons.person, color: AppColors.ink3, size: 30),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: AppText.dispH2(18)),
                Text(player.team, style: AppText.uiCaption),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('${player.totalPoints}', style: AppText.dispScore(24).copyWith(color: AppColors.coral)),
              Text('Poeng', style: AppText.monoSmLight.copyWith(fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTeamRow(String role, FantasyPlayer player, String statText) {
    return Row(
      children: [
        SizedBox(
          width: 70,
          child: Text(role.toUpperCase(), style: AppText.monoSmLight.copyWith(fontSize: 10, color: AppColors.coral)),
        ),
        Container(
          width: 40,
          height: 40,
          margin: const EdgeInsets.only(right: 12),
          decoration: const BoxDecoration(
            color: AppColors.sand2,
            shape: BoxShape.circle,
          ),
          child: player.imageUrl.isNotEmpty
              ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
              : const Icon(Icons.person, color: AppColors.ink3, size: 20),
        ),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(player.name, style: AppText.uiTitle),
              Text(player.team, style: AppText.uiCaption.copyWith(fontSize: 12)),
            ],
          ),
        ),
        Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(statText, style: AppText.uiBody.copyWith(fontWeight: FontWeight.w600)),
            Text('${player.totalPoints} pts totalt', style: AppText.uiCaption.copyWith(fontSize: 11)),
          ],
        ),
      ],
    );
  }
}
