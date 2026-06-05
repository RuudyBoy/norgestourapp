import 'package:flutter/material.dart';
import 'models.dart';
import 'league_logic.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

class FantasySquadView extends StatefulWidget {
  final Map<String, String?> selectedPlayers;
  final List<FantasyPlayer> players;
  final Function(String role) onRoleTap;
  final String? linkedPlayerId;

  const FantasySquadView({
    super.key,
    required this.selectedPlayers,
    required this.players,
    required this.onRoleTap,
    this.linkedPlayerId,
  });

  @override
  State<FantasySquadView> createState() => _FantasySquadViewState();
}

class _FantasySquadViewState extends State<FantasySquadView> {
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

  FantasyPlayer _getBestForStat(int Function(FantasyPlayer) getStat) {
    return widget.players.reduce((a, b) => getStat(a) > getStat(b) ? a : b);
  }

  static String _roleLabel(String role) {
    switch (role) {
      case FantasyRole.block:   return 'BLOKK';
      case FantasyRole.attack:  return 'ANGREP';
      case FantasyRole.set:     return 'LEGG';
      case FantasyRole.receive: return 'MOTTAK';
      case FantasyRole.defense: return 'FORSVAR';
      case FantasyRole.serve:   return 'SERVE';
      default:                  return role.toUpperCase();
    }
  }

  static Color _roleColor(String role) => AppColors.coral;

  Widget _buildPlayerSlot(BuildContext context, String role, String? playerId, double width) {
    FantasyPlayer? player;
    if (playerId != null) {
      final matches = widget.players.where((p) => p.id == playerId);
      player = matches.isNotEmpty ? matches.first : null;
    }

    final isLinked = player != null && player.id == widget.linkedPlayerId;
    final cardW    = width * 0.22;
    final cardH    = width * 0.28;
    final color    = _roleColor(role);

    return GestureDetector(
      onTap: () {
        if (player != null) {
          _showPlayerOptions(context, role, player);
        } else {
          widget.onRoleTap(role);
        }
      },
      child: SizedBox(
        width: cardW,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                // Dark card
                Container(
                  width: cardW,
                  height: cardH,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(10),
                    gradient: player != null
                        ? LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            colors: [
                              const Color(0xFF1C1C2E),
                              Color.lerp(const Color(0xFF1C1C2E), color, 0.35)!,
                            ],
                          )
                        : const LinearGradient(
                            colors: [Color(0xFF1C1C2E), Color(0xFF252535)],
                          ),
                    border: Border.all(
                      color: player != null ? AppColors.coral.withValues(alpha: 0.7) : Colors.white.withValues(alpha: 0.15),
                      width: 1.2,
                    ),
                    boxShadow: player != null
                        ? [BoxShadow(color: AppColors.coral.withValues(alpha: 0.3), blurRadius: 10, spreadRadius: 1)]
                        : [],
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(9),
                    child: Stack(
                      children: [
                        // Player image or placeholder
                        if (player != null && player.imageUrl.isNotEmpty)
                          Positioned.fill(
                            child: Image.network(
                              player.imageUrl,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Center(
                                child: Icon(Icons.person, color: color, size: cardW * 0.40),
                              ),
                            ),
                          )
                        else
                          Center(
                            child: Icon(
                              player != null ? Icons.person : Icons.person_add_outlined,
                              color: player != null ? color : Colors.white.withValues(alpha: 0.4),
                              size: cardW * 0.38,
                            ),
                          ),
                        // Top-left role badge
                        Positioned(
                          top: 5,
                          left: 5,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                            decoration: BoxDecoration(
                              color: color,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              _roleLabel(role),
                              style: AppText.monoSmLight.copyWith(fontSize: 7, color: Colors.white, letterSpacing: 0.3),
                            ),
                          ),
                        ),
                        // Bottom gradient overlay
                        if (player != null)
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              height: cardH * 0.45,
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black.withValues(alpha: 0.85), Colors.transparent],
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Glowing score badge centered at bottom edge
                if (player != null)
                  Positioned(
                    bottom: -10,
                    left: 0,
                    right: 0,
                    child: Center(
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: isLinked ? AppColors.coral : color,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(color: color.withValues(alpha: 0.7), blurRadius: 8, spreadRadius: 0),
                          ],
                        ),
                        child: Text(
                          '${player.totalPoints}p',
                          style: AppText.monoSm.copyWith(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w900),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 14),
            // Name
            Text(
              player != null
                  ? (isLinked ? 'MEG' : player.name.split(' ').last)
                  : 'Legg til',
              style: AppText.monoSmLight.copyWith(
                fontSize: 9,
                color: player != null ? Colors.white : Colors.white.withValues(alpha: 0.5),
              ),
              overflow: TextOverflow.ellipsis,
              maxLines: 1,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pitchHeight = width * 1.25;

        double totalValue = 0;
        int totalPoints = 0;
        for (var playerId in widget.selectedPlayers.values) {
          if (playerId != null) {
            final matches = widget.players.where((p) => p.id == playerId);
            if (matches.isNotEmpty) {
              final p = matches.first;
              totalValue += p.price;
              totalPoints += p.totalPoints;
            }
          }
        }

        final bestBlock   = widget.players.isNotEmpty ? _getBestForStat((p) => p.blocks)   : null;
        final bestAttack  = widget.players.isNotEmpty ? _getBestForStat((p) => p.attacks)  : null;
        final bestSet     = widget.players.isNotEmpty ? _getBestForStat((p) => p.sets)     : null;
        final bestReceive = widget.players.isNotEmpty ? _getBestForStat((p) => p.receives) : null;
        final bestDefense = widget.players.isNotEmpty ? _getBestForStat((p) => p.digs)     : null;
        final bestServe   = widget.players.isNotEmpty ? _getBestForStat((p) => p.aces)     : null;
        final bestPlayer  = widget.players.isNotEmpty
            ? widget.players.reduce((a, b) => a.totalPoints > b.totalPoints ? a : b)
            : null;

        return SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Stats header
              Container(
                padding: const EdgeInsets.all(AppTheme.cardPad),
                margin: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 12, AppTheme.pageHPad, 0),
                decoration: BoxDecoration(
                  gradient: AppColors.heroNavy,
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  boxShadow: AppTheme.shadowLg,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildStatItem('Poeng', totalPoints.toString()),
                    Container(width: 1, height: 32, color: Colors.white.withOpacity(0.15)),
                    _buildStatItem('Budsjett', '\$${(50.0 - totalValue).toStringAsFixed(1)}m'),
                    Container(width: 1, height: 32, color: Colors.white.withOpacity(0.15)),
                    _buildStatItem('Verdi', '\$${totalValue.toStringAsFixed(1)}m'),
                  ],
                ),
              ),

              // Deadline banner
              Container(
                margin: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 10, AppTheme.pageHPad, 0),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 14),
                decoration: BoxDecoration(
                  color: AppColors.coral.withOpacity(0.12),
                  borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                  border: Border.all(color: AppColors.coral.withOpacity(0.4)),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.timer_outlined, color: AppColors.coral, size: 15),
                    const SizedBox(width: 8),
                    Text('Tidsfrist for neste runde: I morgen kl 18:00',
                        style: AppText.monoSm.copyWith(color: AppColors.coral)),
                  ],
                ),
              ),

              // Pitch area (fixed height)
              Container(
                height: pitchHeight,
                margin: const EdgeInsets.all(AppTheme.pageHPad),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF16243F), Color(0xFF0B1420), Color(0xFF16243F)],
                    stops: [0.0, 0.5, 1.0],
                  ),
                  border: Border.all(color: AppColors.coral.withOpacity(0.18), width: 1.2),
                  boxShadow: AppTheme.shadowLg,
                ),
                child: Stack(
                  children: [
                    // Subtle radial glow in center
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: RadialGradient(
                              center: Alignment.center,
                              radius: 0.75,
                              colors: [
                                AppColors.coral.withOpacity(0.07),
                                Colors.transparent,
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Faint horizontal divider line in middle
                    Positioned(
                      top: pitchHeight * 0.5 - 0.5,
                      left: 24,
                      right: 24,
                      child: Container(
                        height: 1,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.transparent,
                              AppColors.coral.withOpacity(0.25),
                              AppColors.coral.withOpacity(0.25),
                              Colors.transparent,
                            ],
                          ),
                        ),
                      ),
                    ),
                    // Row 1 – Block (center top)
                    Positioned(
                      top: 16,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildPlayerSlot(context, FantasyRole.block, widget.selectedPlayers[FantasyRole.block], width)),
                    ),
                    // Row 2 – Attack (left) & Set (right)
                    Positioned(
                      top: pitchHeight * 0.26,
                      left: width * 0.08,
                      child: _buildPlayerSlot(context, FantasyRole.attack, widget.selectedPlayers[FantasyRole.attack], width),
                    ),
                    Positioned(
                      top: pitchHeight * 0.26,
                      right: width * 0.08,
                      child: _buildPlayerSlot(context, FantasyRole.set, widget.selectedPlayers[FantasyRole.set], width),
                    ),
                    // Row 3 – Receive (left) & Defense (right)
                    Positioned(
                      top: pitchHeight * 0.52,
                      left: width * 0.08,
                      child: _buildPlayerSlot(context, FantasyRole.receive, widget.selectedPlayers[FantasyRole.receive], width),
                    ),
                    Positioned(
                      top: pitchHeight * 0.52,
                      right: width * 0.08,
                      child: _buildPlayerSlot(context, FantasyRole.defense, widget.selectedPlayers[FantasyRole.defense], width),
                    ),
                    // Row 4 – Serve (center bottom)
                    Positioned(
                      bottom: 16,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildPlayerSlot(context, FantasyRole.serve, widget.selectedPlayers[FantasyRole.serve], width)),
                    ),
                  ],
                ),
              ),

              // ── Highlights section ────────────────────────────────────
              if (widget.players.isNotEmpty) ...[
                Padding(
                  padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 8, AppTheme.pageHPad, 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Text('Ukens Fantasy Manager', style: AppText.dispH2(20)),
                      const SizedBox(height: 12),
                      _buildManagerCard(),
                      const SizedBox(height: 24),

                      Text('Ukens Beste Spiller', style: AppText.dispH2(20)),
                      const SizedBox(height: 12),
                      if (bestPlayer != null) _buildBestPlayerCard(bestPlayer),
                      const SizedBox(height: 24),

                      Text('Ukens Lag', style: AppText.dispH2(20)),
                      const SizedBox(height: 8),
                      Text('Spillerne med flest poeng i hver kategori', style: AppText.uiCaption),
                      const SizedBox(height: 12),
                      if (bestAttack != null)
                        Container(
                          padding: const EdgeInsets.all(AppTheme.cardPad),
                          decoration: BoxDecoration(
                            color: AppColors.sand0,
                            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                            boxShadow: AppTheme.shadowSm,
                          ),
                          child: Column(
                            children: [
                              _buildTeamRow(FantasyRole.attack,  bestAttack,  '${bestAttack.attacks} angrep'),
                              const Divider(height: 20, color: AppColors.line),
                              _buildTeamRow(FantasyRole.block,   bestBlock!,  '${bestBlock.blocks} blokker'),
                              const Divider(height: 20, color: AppColors.line),
                              _buildTeamRow(FantasyRole.serve,   bestServe!,  '${bestServe.aces} ess'),
                              const Divider(height: 20, color: AppColors.line),
                              _buildTeamRow(FantasyRole.defense, bestDefense!,'${bestDefense.digs} forsvar'),
                              const Divider(height: 20, color: AppColors.line),
                              _buildTeamRow(FantasyRole.receive, bestReceive!,'${bestReceive.receives} mottak'),
                              const Divider(height: 20, color: AppColors.line),
                              _buildTeamRow(FantasyRole.set,     bestSet!,    '${bestSet.sets} legg'),
                            ],
                          ),
                        ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ],
          ),
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(label, style: AppText.monoSmLight.copyWith(fontSize: 9.5)),
        const SizedBox(height: 4),
        Text(value, style: AppText.dispH2(18).copyWith(color: Colors.white)),
      ],
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
            decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
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
          decoration: const BoxDecoration(color: AppColors.sand2, shape: BoxShape.circle),
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

  void _showPlayerOptions(BuildContext context, String role, FantasyPlayer player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.sand0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 58,
                    height: 58,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: AppColors.coral, width: 2.5),
                      color: AppColors.sand2,
                    ),
                    child: player.imageUrl.isNotEmpty
                        ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                        : const Icon(Icons.person, color: AppColors.ink2, size: 32),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.name, style: AppText.dispH2(18)),
                        Text('${player.team} · $role', style: AppText.uiCaption),
                      ],
                    ),
                  ),
                  Text('${player.totalPoints} pts', style: AppText.dispScore(24).copyWith(color: AppColors.coral)),
                ],
              ),
              const SizedBox(height: 20),
              Text('Poengoversikt:', style: AppText.dispKicker()),
              const SizedBox(height: 12),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailStat('Angrep', player.attacks.toString()),
                  _buildDetailStat('Blokk', player.blocks.toString()),
                  _buildDetailStat('Ess', player.aces.toString()),
                  _buildDetailStat('Forsvar', player.digs.toString()),
                ],
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRoleTap(role);
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Bytt Spiller'),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppText.dispH2(20)),
        Text(label, style: AppText.uiCaption),
      ],
    );
  }
}
