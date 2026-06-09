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
  final String teamName;

  const FantasySquadView({
    super.key,
    required this.selectedPlayers,
    required this.players,
    required this.onRoleTap,
    this.linkedPlayerId,
    required this.teamName,
  });

  @override
  State<FantasySquadView> createState() => _FantasySquadViewState();
}

class _FantasySquadViewState extends State<FantasySquadView> {
  bool _isLoading = true;
  LeaderboardEntry? _bestManager;
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
      case FantasyRole.serve:   return 'SERV';
      default:                  return role.toUpperCase();
    }
  }

  static Color _roleAccent(String role) {
    return AppColors.coral;
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
      color: Colors.transparent,
      child: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Top stats bar ──────────────────────────────────────────
            _buildTopStatsBar(totalValue, totalPoints),

            const SizedBox(height: 24),

            // ── Team Name Header ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Center(
                child: Text(
                  widget.teamName,
                  style: AppText.dispH2(26).copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
              ),
            ),

            const SizedBox(height: 16),

            // ── Player card grid ───────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: _buildPlayerGrid(),
            ),

            // ── Deadline banner ────────────────────────────────────────
            _buildDeadlineBanner(),

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

  Widget _buildTopStatsBar(double totalValue, int totalPoints) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 0),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.account_balance_wallet_rounded,
            iconColor: const Color(0xFF36C87A),
            value: '\$${(50.0 - totalValue).toStringAsFixed(1)}m',
            label: 'BUDSJETT',
          ),
          const SizedBox(width: 12),
          _buildStatCard(
            icon: Icons.star_rounded,
            iconColor: const Color(0xFFFFB72B),
            value: totalPoints.toString(),
            label: 'POENG',
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: _surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _border),
          boxShadow: [
            BoxShadow(color: Colors.black.withValues(alpha: 0.4), blurRadius: 12, offset: const Offset(0, 4)),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: iconColor, size: 16),
                const SizedBox(width: 6),
                Text(label, style: TextStyle(fontSize: 10, color: AppColors.nightInk2, fontFamily: 'RobotoMono', fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: const TextStyle(
                fontFamily: 'RobotoMono',
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: Colors.white,
                letterSpacing: -0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDeadlineBanner() {
    return Center(
      child: Container(
        margin: const EdgeInsets.fromLTRB(14, 16, 14, 0),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
        decoration: BoxDecoration(
          color: AppColors.coral.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: AppColors.coral.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.timer_outlined, color: AppColors.coral, size: 14),
            const SizedBox(width: 8),
            Text(
              'Frist: I morgen kl 18:00',
              style: AppText.monoSm.copyWith(color: AppColors.coral, fontSize: 11),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerGrid() {
    final roles = FantasyRole.all;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
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
    final filled   = player != null;
    final roleName = _roleLabel(role);
    final roleAbbr = roleName.length >= 3 ? roleName.substring(0, 3) : roleName;

    return GestureDetector(
      onTap: () {
        if (player != null) {
          _showPlayerOptions(context, role, player);
        } else {
          widget.onRoleTap(role);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          color: const Color(0xFF1E1E1E), // Dark card background
          borderRadius: BorderRadius.circular(6),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.15),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // 1. Image section
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (filled && player.imageUrl.isNotEmpty)
                    Image.network(
                      player.imageUrl,
                      fit: BoxFit.cover,
                      alignment: Alignment.topCenter,
                      errorBuilder: (_, _, _) => _emptySlotContent(),
                    )
                  else if (!filled)
                    _emptySlotContent(),
                  
                  // Top-right swap icon if filled
                  if (filled)
                    Positioned(
                      top: 6, right: 6,
                      child: Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: Colors.black.withValues(alpha: 0.5),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.swap_horiz, color: Colors.white70, size: 14),
                      ),
                    ),
                ],
              ),
            ),
            
            // 2. Info Strip
            Container(
              height: 26,
              color: Colors.black.withValues(alpha: 0.4),
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: [
                  Text(
                    roleAbbr,
                    style: const TextStyle(
                      fontFamily: 'RobotoMono',
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: Colors.white70,
                    ),
                  ),
                  const Spacer(),
                  if (filled) ...[
                    const Icon(Icons.sports_volleyball, size: 12, color: Colors.white70),
                    const Spacer(),
                    Text(
                      '${player.totalPoints} PTS',
                      style: const TextStyle(
                        fontFamily: 'RobotoMono',
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ] else ...[
                    const Icon(Icons.sports_volleyball, size: 12, color: Colors.white30),
                    const Spacer(),
                  ],
                ],
              ),
            ),
            
            // 3. Name and Subtext section
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (filled) ...[
                    Text(
                      isLinked ? 'MEG' : player.name.split(' ').last,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.1,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            player.team,
                            style: TextStyle(
                              fontSize: 11,
                              color: Colors.white.withValues(alpha: 0.6),
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        const Icon(Icons.info, size: 14, color: Colors.lightBlue),
                      ],
                    ),
                  ] else ...[
                    Center(
                      child: Text(
                        roleName,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySlotContent() {
    return Container(
      color: const Color(0xFF2A2A2A),
      child: Center(
        child: Icon(
          Icons.person,
          size: 70,
          color: Colors.white.withValues(alpha: 0.1),
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
