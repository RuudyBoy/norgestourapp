import 'package:flutter/material.dart';
import 'models.dart';
import 'league_logic.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
// Deep navy palette for the sports-card theme
const Color _bg       = Color(0xFF0B1220);
const Color _surface  = Color(0xFF111C30);
const Color _surface2 = Color(0xFF18253E);
const Color _border   = Color(0xFF1E2E48);

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
  String? _selectedRole; // null = show all

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
      case FantasyRole.serve:   return 'SERV';
      default:                  return role.toUpperCase();
    }
  }

  static Color _roleAccent(String role) {
    return AppColors.coral;
  }

  List<String> get _visibleRoles {
    if (_selectedRole == null) return FantasyRole.all;
    return [_selectedRole!];
  }

  @override
  Widget build(BuildContext context) {
    double totalValue = 0;
    int totalPoints = 0;
    int filledSlots = 0;
    for (var playerId in widget.selectedPlayers.values) {
      if (playerId != null) {
        final matches = widget.players.where((p) => p.id == playerId);
        if (matches.isNotEmpty) {
          final p = matches.first;
          totalValue += p.price;
          totalPoints += p.totalPoints;
          filledSlots++;
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

    return Container(
      color: _bg,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top stats bar ──────────────────────────────────────────
            _buildTopStatsBar(filledSlots, totalValue, totalPoints),

            // ── Deadline banner ────────────────────────────────────────
            _buildDeadlineBanner(),

            // ── Role filter tabs ───────────────────────────────────────
            _buildRoleTabs(),

            const SizedBox(height: 16),

            // ── Player card grid ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _buildPlayerGrid(),
            ),

            const SizedBox(height: 28),

            // ── Highlights sections ────────────────────────────────────
            if (widget.players.isNotEmpty) ...[
              _buildSectionHeader('Ukens Fantasy Manager'),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: _buildManagerCard(),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Ukens Beste Spiller'),
              if (bestPlayer != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                  child: _buildBestPlayerCard(bestPlayer),
                ),
              const SizedBox(height: 24),
              _buildSectionHeader('Ukens Lag'),
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 6),
                child: Text(
                  'Spillerne med flest poeng i hver kategori',
                  style: AppText.uiCaption.copyWith(color: AppColors.nightInk2),
                ),
              ),
              if (bestAttack != null)
                Padding(
                  padding: const EdgeInsets.fromLTRB(14, 4, 14, 0),
                  child: _buildBestTeamCard(
                    bestAttack, bestBlock!, bestServe!,
                    bestDefense!, bestReceive!, bestSet!,
                  ),
                ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTopStatsBar(int filled, double totalValue, int totalPoints) {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      decoration: BoxDecoration(
        color: _surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
        ],
      ),
      child: Row(
        children: [
          _buildStatCell(
            icon: Icons.people_alt_rounded,
            iconColor: AppColors.coral,
            value: '$filled/${FantasyRole.all.length}',
            label: 'Spillere',
          ),
          _buildDivider(),
          _buildStatCell(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF36C87A),
            value: '\$${(50.0 - totalValue).toStringAsFixed(1)}m',
            label: 'Budsjett igjen',
          ),
          _buildDivider(),
          _buildStatCell(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFFB72B),
            value: totalPoints.toString(),
            label: 'Totalt poeng',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCell({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: iconColor, size: 14),
              const SizedBox(width: 5),
              Text(
                value,
                style: const TextStyle(
                  fontFamily: 'RobotoMono',
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                  letterSpacing: -0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Text(label, style: TextStyle(fontSize: 10, color: AppColors.nightInk2, fontFamily: 'RobotoMono')),
        ],
      ),
    );
  }

  Widget _buildDivider() {
    return Container(width: 1, height: 36, color: _border);
  }

  Widget _buildDeadlineBanner() {
    return Container(
      margin: const EdgeInsets.fromLTRB(14, 10, 14, 0),
      padding: const EdgeInsets.symmetric(vertical: 9, horizontal: 14),
      decoration: BoxDecoration(
        color: AppColors.coral.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.timer_outlined, color: AppColors.coral, size: 14),
          const SizedBox(width: 8),
          Text(
            'Tidsfrist for neste runde: I morgen kl 18:00',
            style: AppText.monoSm.copyWith(color: AppColors.coral, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildRoleTabs() {
    return SizedBox(
      height: 40,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
        children: [
          _buildRoleTab(null, 'ALLE'),
          ...FantasyRole.all.map((r) => _buildRoleTab(r, _roleLabel(r))),
        ],
      ),
    );
  }

  Widget _buildRoleTab(String? role, String label) {
    final isActive = _selectedRole == role;
    final accent = role != null ? _roleAccent(role) : Colors.white;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        margin: const EdgeInsets.only(right: 8),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: BoxDecoration(
          color: isActive ? accent.withValues(alpha: 0.18) : _surface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: isActive ? accent : _border,
            width: isActive ? 1.5 : 1,
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 10,
            fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
            color: isActive ? accent : AppColors.nightInk2,
            letterSpacing: 0.8,
          ),
        ),
      ),
    );
  }

  Widget _buildPlayerGrid() {
    final roles = _visibleRoles;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 12,
        crossAxisSpacing: 10,
        childAspectRatio: 0.85,
      ),
      itemCount: roles.length,
      itemBuilder: (context, i) => _buildPlayerCard(context, roles[i]),
    );
  }

  Widget _buildPlayerCard(BuildContext context, String role) {
    final playerId = widget.selectedPlayers[role];
    FantasyPlayer? player;
    if (playerId != null) {
      final matches = widget.players.where((p) => p.id == playerId);
      player = matches.isNotEmpty ? matches.first : null;
    }

    final isLinked = player != null && player.id == widget.linkedPlayerId;
    final accent   = _roleAccent(role);
    final filled   = player != null;

    return GestureDetector(
      onTap: () {
        if (player != null) {
          _showPlayerOptions(context, role, player);
        } else {
          widget.onRoleTap(role);
        }
      },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: filled
              ? LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    _surface2,
                    Color.lerp(_surface2, accent, 0.2)!,
                  ],
                )
              : const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [_surface, Color(0xFF0F1A2E)],
                ),
          border: Border.all(
            color: filled ? accent.withValues(alpha: 0.5) : _border,
            width: filled ? 1.5 : 1,
          ),
          boxShadow: filled
              ? [BoxShadow(color: accent.withValues(alpha: 0.2), blurRadius: 12, spreadRadius: 0)]
              : [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 6)],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(13),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // Player image
              if (filled && player.imageUrl.isNotEmpty)
                Image.network(
                  player.imageUrl,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, _, _) => _emptySlotContent(accent),
                )
              else if (!filled)
                _emptySlotContent(accent),

              // Bottom gradient + info overlay
              Positioned(
                bottom: 0, left: 0, right: 0,
                child: Container(
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [Color(0xE6050D1A), Color(0x80050D1A), Colors.transparent],
                      stops: [0.0, 0.55, 1.0],
                    ),
                  ),
                  padding: const EdgeInsets.fromLTRB(8, 24, 8, 8),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (filled) ...[
                        Text(
                          isLinked ? 'MEG' : player.name.split(' ').last,
                          style: const TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          player.team,
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 9,
                            color: AppColors.nightInk2,
                          ),
                          overflow: TextOverflow.ellipsis,
                          maxLines: 1,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 5),
                        // Points pill
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(10),
                            boxShadow: [BoxShadow(color: accent.withValues(alpha: 0.5), blurRadius: 6)],
                          ),
                          child: Text(
                            '${player.totalPoints} pts',
                            style: const TextStyle(
                              fontFamily: 'RobotoMono',
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ] else ...[
                        const Icon(Icons.add_circle_outline, color: Colors.white38, size: 22),
                        const SizedBox(height: 4),
                        Text(
                          'Legg til',
                          style: TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 10,
                            color: Colors.white.withValues(alpha: 0.5),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

              // Role badge top-left
              Positioned(
                top: 8, left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                  decoration: BoxDecoration(
                    color: accent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    _roleLabel(role),
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 7.5,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
              ),

              // Swap icon top-right when filled
              if (filled)
                Positioned(
                  top: 6, right: 6,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.5),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.swap_horiz, color: Colors.white54, size: 13),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _emptySlotContent(Color accent) {
    return Container(
      decoration: BoxDecoration(
        gradient: RadialGradient(
          center: Alignment.center,
          radius: 0.8,
          colors: [accent.withValues(alpha: 0.07), Colors.transparent],
        ),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 0, 14, 0),
      child: Row(
        children: [
          Container(width: 3, height: 18, decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Text(title, style: AppText.dispH2(18).copyWith(color: Colors.white)),
        ],
      ),
    );
  }

  Widget _buildManagerCard() {
    if (_isLoading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
        child: const Center(child: CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2)),
      );
    }
    if (_bestManager == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
        child: Text('Ingen data enda', style: TextStyle(color: AppColors.nightInk2)),
      );
    }
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/card_bg.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(14),
        boxShadow: [BoxShadow(color: AppColors.coral.withValues(alpha: 0.3), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Container(
            width: 52, height: 52,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              shape: BoxShape.circle,
              border: Border.all(color: Colors.white.withValues(alpha: 0.4), width: 1.5),
            ),
            child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_bestManager!.teamName, style: AppText.dispH2(17).copyWith(color: Colors.white)),
                Text(_bestManager!.managerName, style: AppText.uiCaption.copyWith(color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${_bestManager!.totalPoints}',
                style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 26, fontWeight: FontWeight.w900, color: Colors.white),
              ),
              Text('pts', style: TextStyle(fontFamily: 'RobotoMono', fontSize: 11, color: Colors.white.withValues(alpha: 0.7))),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestPlayerCard(FantasyPlayer player) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/card_bg.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.coral.withValues(alpha: 0.3)),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
      ),
      child: Row(
        children: [
          Container(
            width: 58, height: 58,
            decoration: BoxDecoration(
              color: _surface2,
              shape: BoxShape.circle,
              border: Border.all(color: AppColors.coral, width: 2),
            ),
            child: player.imageUrl.isNotEmpty
                ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                : const Icon(Icons.person, color: AppColors.nightInk2, size: 30),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: AppText.dispH2(17).copyWith(color: Colors.white)),
                const SizedBox(height: 2),
                Text(player.team, style: AppText.uiCaption.copyWith(color: AppColors.nightInk2)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${player.totalPoints}',
                style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 24, fontWeight: FontWeight.w900, color: AppColors.coral),
              ),
              Text('poeng', style: AppText.monoSmLight.copyWith(fontSize: 10, color: AppColors.nightInk2)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBestTeamCard(
    FantasyPlayer bestAttack,
    FantasyPlayer bestBlock,
    FantasyPlayer bestServe,
    FantasyPlayer bestDefense,
    FantasyPlayer bestReceive,
    FantasyPlayer bestSet,
  ) {
    final rows = [
      (FantasyRole.attack,  bestAttack,  '${bestAttack.attacks} angrep'),
      (FantasyRole.block,   bestBlock,   '${bestBlock.blocks} blokker'),
      (FantasyRole.serve,   bestServe,   '${bestServe.aces} ess'),
      (FantasyRole.defense, bestDefense, '${bestDefense.digs} forsvar'),
      (FantasyRole.receive, bestReceive, '${bestReceive.receives} mottak'),
      (FantasyRole.set,     bestSet,     '${bestSet.sets} legg'),
    ];
    return Container(
      decoration: BoxDecoration(
        image: const DecorationImage(
          image: AssetImage('assets/images/card_bg.png'),
          fit: BoxFit.cover,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10)],
      ),
      child: Column(
        children: rows.asMap().entries.map((e) {
          final isLast = e.key == rows.length - 1;
          final (role, player, stat) = e.value;
          return Column(
            children: [
              _buildTeamRow(role, player, stat),
              if (!isLast) Divider(height: 1, color: _border),
            ],
          );
        }).toList(),
      ),
    );
  }

  Widget _buildTeamRow(String role, FantasyPlayer player, String statText) {
    final accent = _roleAccent(role);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        children: [
          Container(
            width: 52, height: 18,
            decoration: BoxDecoration(color: accent.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(5)),
            alignment: Alignment.center,
            child: Text(
              _roleLabel(role),
              style: TextStyle(fontFamily: 'RobotoMono', fontSize: 8.5, fontWeight: FontWeight.w700, color: accent, letterSpacing: 0.5),
            ),
          ),
          const SizedBox(width: 10),
          Container(
            width: 38, height: 38,
            decoration: BoxDecoration(color: _surface2, shape: BoxShape.circle, border: Border.all(color: accent.withValues(alpha: 0.4))),
            child: player.imageUrl.isNotEmpty
                ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                : Icon(Icons.person, color: AppColors.nightInk3, size: 20),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(player.name, style: AppText.uiTitle.copyWith(color: Colors.white, fontSize: 13)),
                Text(player.team, style: AppText.uiCaption.copyWith(color: AppColors.nightInk2, fontSize: 11)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(statText, style: TextStyle(fontFamily: 'RobotoMono', fontSize: 12, fontWeight: FontWeight.w700, color: Colors.white)),
              Text('${player.totalPoints} pts totalt', style: AppText.uiCaption.copyWith(color: AppColors.nightInk3, fontSize: 10)),
            ],
          ),
        ],
      ),
    );
  }

  void _showPlayerOptions(BuildContext context, String role, FantasyPlayer player) {
    final accent = _roleAccent(role);
    showModalBottomSheet(
      context: context,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Handle bar
              Center(
                child: Container(
                  width: 36, height: 4,
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
                ),
              ),
              Row(
                children: [
                  Container(
                    width: 62, height: 62,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: accent, width: 2.5),
                      color: _surface2,
                    ),
                    child: player.imageUrl.isNotEmpty
                        ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                        : Icon(Icons.person, color: AppColors.nightInk2, size: 32),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(player.name, style: AppText.dispH2(18).copyWith(color: Colors.white)),
                        const SizedBox(height: 3),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(color: accent, borderRadius: BorderRadius.circular(6)),
                              child: Text(
                                _roleLabel(role),
                                style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 9, fontWeight: FontWeight.w700, color: Colors.white),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(player.team, style: AppText.uiCaption.copyWith(color: AppColors.nightInk2)),
                          ],
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '${player.totalPoints}',
                        style: TextStyle(fontFamily: 'RobotoMono', fontSize: 26, fontWeight: FontWeight.w900, color: accent),
                      ),
                      Text('pts', style: TextStyle(fontFamily: 'RobotoMono', fontSize: 11, color: AppColors.nightInk2)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Poengoversikt', style: AppText.dispKicker().copyWith(color: AppColors.nightInk2)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildDetailStat('Angrep',  player.attacks.toString(),  AppColors.coral),
                    _buildDetailStat('Blokk',   player.blocks.toString(),   const Color(0xFF4C8BFF)),
                    _buildDetailStat('Ess',     player.aces.toString(),     const Color(0xFF26D4CC)),
                    _buildDetailStat('Forsvar', player.digs.toString(),     const Color(0xFFAA6FFF)),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: accent,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                  ),
                  onPressed: () {
                    Navigator.pop(context);
                    widget.onRoleTap(role);
                  },
                  icon: const Icon(Icons.swap_horiz, size: 20),
                  label: const Text('Bytt Spiller', style: TextStyle(fontFamily: 'RobotoMono', fontWeight: FontWeight.w700, fontSize: 14)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStat(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          value,
          style: TextStyle(fontFamily: 'RobotoMono', fontSize: 22, fontWeight: FontWeight.w900, color: color),
        ),
        const SizedBox(height: 3),
        Text(label, style: AppText.uiCaption.copyWith(color: AppColors.nightInk2, fontSize: 11)),
      ],
    );
  }
}
