import 'package:flutter/material.dart';
import 'models.dart';
import 'league_logic.dart';
import 'fantasy_point_matrix.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import 'player_stats_sheet.dart';
// Deep navy palette for the sports-card theme
const Color _bg       = Color(0xFF0B1220);
const Color _surface  = Color(0xFF111C30);
const Color _surface2 = Color(0xFF18253E);
const Color _border   = Color(0xFF1E2E48);

class FantasySquadView extends StatefulWidget {
  final Map<String, String?> selectedPlayers;
  final List<FantasyPlayer> players;
  final Map<String, double> ownershipPercentages;
  final Function(String role) onRoleTap;
  final String? linkedPlayerId;
  final String teamName;
  final String? captainId;
  final int pendingChanges;
  final Function(String) onCaptainChanged;
  final VoidCallback onConfirmSquad;

  const FantasySquadView({
    super.key,
    required this.selectedPlayers,
    required this.players,
    required this.ownershipPercentages,
    required this.onRoleTap,
    this.linkedPlayerId,
    required this.teamName,
    this.captainId,
    required this.pendingChanges,
    required this.onCaptainChanged,
    required this.onConfirmSquad,
  });

  @override
  State<FantasySquadView> createState() => _FantasySquadViewState();
}

class _FantasySquadViewState extends State<FantasySquadView> {
  bool _isLoading = true;
  LeaderboardEntry? _bestManager;
  int _highestPoints = 0;
  int _averagePoints = 0;

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
      _highestPoints = leaderboard.first.totalPoints;
      
      int total = 0;
      for (var entry in leaderboard) {
        total += entry.totalPoints;
      }
      _averagePoints = (total / leaderboard.length).round();
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
    // Rollelåst: hver spiller teller kun poeng for rollen den er plassert i
    for (var entry in widget.selectedPlayers.entries) {
      final playerId = entry.value;
      if (playerId != null) {
        final matches = widget.players.where((p) => p.id == playerId);
        if (matches.isNotEmpty) {
          final p = matches.first;
          totalValue += p.price;
          int pts = calculatePlayerPoints(p.stats, entry.key);
          if (p.id == widget.captainId) {
            pts = (pts * 1.5).round();
          }
          totalPoints += pts;
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
            const SizedBox(height: 10),
            
            // ── Info Button & Confirm Squad ──────────────────────────────────────────────
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  if (widget.pendingChanges > 0)
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: widget.pendingChanges > 2 ? AppColors.coral : const Color(0xFF36C87A),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        elevation: 0,
                      ),
                      onPressed: widget.onConfirmSquad,
                      icon: const Icon(Icons.check_circle_outline, size: 16),
                      label: Text(
                        'Bekreft lag (${widget.pendingChanges} bytter)', 
                        style: AppText.monoSm.copyWith(fontWeight: FontWeight.bold, color: Colors.white)
                      ),
                    )
                  else
                    const SizedBox.shrink(),

                  GestureDetector(
                    onTap: () => _showRulebook(context),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.blueBright.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: AppColors.blueBright.withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.menu_book_rounded, size: 14, color: AppColors.blueBright),
                          const SizedBox(width: 6),
                          Text('Hvordan spille?', style: AppText.monoSm.copyWith(color: AppColors.blueBright, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 10),

            // ── Combined Team & Points Section ─────────────────────────
            _buildTeamSection(totalPoints, totalValue),

            // ── Deadline banner ────────────────────────────────────────
            _buildDeadlineBanner(),

            const SizedBox(height: 28),

            // ── Highlights sections ────────────────────────────────────
            if (widget.players.isNotEmpty) ...[
              _buildSectionHeader('Beste Manager (Denne Runden)'),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: _buildManagerCard(_bestManager),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Beste Manager (Totalt)'),
              Padding(
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 0),
                child: _buildManagerCard(_bestManager),
              ),
              const SizedBox(height: 24),
              _buildSectionHeader('Beste Spiller i Hver Posisjon'),
              Padding(
                padding: const EdgeInsets.only(left: 14, bottom: 12),
                child: Text(
                  'Spillerne med flest poeng i sine kategorier',
                  style: AppText.uiCaption.copyWith(color: AppColors.nightInk2),
                ),
              ),
              if (bestAttack != null)
                _buildTopPlayersCarousel(
                  bestAttack, bestBlock!, bestServe!,
                  bestDefense!, bestReceive!, bestSet!,
                ),
              const SizedBox(height: 40),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildTeamSection(int yourScore, double totalValue) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withValues(alpha: 0.15), blurRadius: 15, offset: const Offset(0, 5)),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          // Dark Banner
          Container(
            height: 155,
            width: double.infinity,
            decoration: const BoxDecoration(
              color: _surface,
            ),
            padding: const EdgeInsets.only(top: 24),
            child: Column(
              children: [
                Text(
                  widget.teamName,
                  style: AppText.dispH2(26).copyWith(color: Colors.white),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        'BUDSJETT: ',
                        style: TextStyle(fontFamily: 'RobotoMono', color: Colors.white70, fontWeight: FontWeight.w600, fontSize: 11),
                      ),
                      Text(
                        '\$${(50.0 - totalValue).toStringAsFixed(1)}m',
                        style: const TextStyle(fontFamily: 'RobotoMono', color: AppColors.coral, fontWeight: FontWeight.bold, fontSize: 14),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Court and Points Stack
          Stack(
            clipBehavior: Clip.none,
            children: [
              // The Sand Court Background
              _buildCourtLayout(),
              
              // Points row with badge overlapping the boundary
              Positioned(
                top: -45, left: 0, right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    // Average
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          width: 80,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLoading ? '-' : _averagePoints.toString(),
                                style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Average',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Your Score Badge
                    Container(
                      width: 90,
                      height: 100,
                      decoration: BoxDecoration(
                        color: AppColors.coral,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 4),
                        boxShadow: [
                          BoxShadow(color: AppColors.coral.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text(
                            'TOTAL',
                            style: TextStyle(color: Colors.white70, fontSize: 10, fontWeight: FontWeight.bold, letterSpacing: 1),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            yourScore.toString(),
                            style: const TextStyle(fontFamily: 'RobotoMono', color: Colors.white, fontSize: 32, fontWeight: FontWeight.w900),
                          ),
                          const SizedBox(height: 2),
                          const Text(
                            'Your Score',
                            style: TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w600),
                          ),
                        ],
                      ),
                    ),
                    
                    const SizedBox(width: 8),
                    
                    // Highest
                    Expanded(
                      child: Align(
                        alignment: Alignment.bottomCenter,
                        child: Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          width: 80,
                          height: 75,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.grey.shade200, width: 2),
                            boxShadow: [
                              BoxShadow(color: Colors.black.withValues(alpha: 0.1), blurRadius: 8, offset: const Offset(0, 4)),
                            ],
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                _isLoading ? '-' : _highestPoints.toString(),
                                style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.ink),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                'Highest',
                                style: TextStyle(fontSize: 10, color: Colors.grey[600], fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
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

  Widget _buildCourtLayout() {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        // The Sand Court Background
        Positioned.fill(
          child: Container(
            decoration: const BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/bakgrunn.png'),
                fit: BoxFit.cover,
              ),
            ),
          ),
        ),
        
        // Court boundaries
        Positioned(
          top: 70, bottom: 20, left: 15, right: 15, // Pushed top down to avoid overlap with points row
          child: Container(
            decoration: BoxDecoration(
              border: Border.all(color: AppColors.blueBright, width: 4),
            ),
            child: Center(
              child: Container(
                height: 3,
                color: Colors.white.withValues(alpha: 0.8), // The Net
              ),
            ),
          ),
        ),
        
        // The Grid
        Padding(
          padding: const EdgeInsets.only(top: 80, bottom: 30, left: 24, right: 24),
          child: _buildPlayerGrid(),
        ),
      ],
    );
  }

  Widget _buildPlayerGrid() {
    final roles = FantasyRole.all;
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 3,
        mainAxisSpacing: 30, // Spacing between the two rows
        crossAxisSpacing: 12,
        childAspectRatio: 0.68,
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
    final roleColor = _roleAccent(role);

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
          color: const Color(0xFFF0F0F0), // Off-white/light-grey card background
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: Colors.white,
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.2),
              blurRadius: 6,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Top Section (Photo Area)
            Expanded(
              flex: 60,
              child: Container(
                margin: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  color: roleColor,
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                ),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (filled && player.imageUrl.isNotEmpty)
                      ClipRRect(
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                        child: Image.network(
                          player.imageUrl,
                          fit: BoxFit.cover,
                          alignment: Alignment.topCenter,
                          errorBuilder: (_, _, _) => _emptySlotContent(roleColor),
                        ),
                      )
                    else if (!filled)
                      _emptySlotContent(roleColor),
                    
                    // Top Right Role Badge (Position)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.85),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          roleAbbr,
                          style: const TextStyle(
                            fontFamily: 'RobotoMono',
                            fontSize: 9,
                            fontWeight: FontWeight.w900,
                            color: Colors.black87,
                          ),
                        ),
                      ),
                    ),

                    // Top Left Captain Badge
                    if (filled && player.id == widget.captainId)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 1.5),
                          ),
                          child: const Text('C', style: TextStyle(color: Colors.white, fontSize: 10, fontWeight: FontWeight.w900)),
                        ),
                      )
                    else if (filled)
                      // Top Left Swap Icon (if not captain)
                      Positioned(
                        top: 4,
                        left: 4,
                        child: Container(
                          padding: const EdgeInsets.all(3),
                          decoration: BoxDecoration(
                            color: Colors.black.withValues(alpha: 0.4),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.swap_horiz, color: Colors.white, size: 12),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            
            // Bottom Section (Info Area)
            Expanded(
              flex: 40,
              child: Container(
                padding: const EdgeInsets.fromLTRB(6, 4, 6, 6),
                decoration: const BoxDecoration(
                  color: Color(0xFFF0F0F0),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (filled) ...[
                      // Player Name (bold, most visible)
                      Text(
                        isLinked ? 'MEG' : player.name,
                        style: const TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w900,
                          color: Color(0xFF111111),
                          letterSpacing: 0.2,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 1),
                      // Team Name (less visible)
                      Text(
                        player.team,
                        style: const TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF666666),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const Spacer(),
                      // Bottom Row: points and "logo"
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.sports_volleyball, size: 9, color: roleColor.withValues(alpha: 0.8)),
                              const SizedBox(width: 3),
                              Text(
                                '${calculatePlayerPoints(player.stats, role)}',
                                style: const TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 11,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.black87,
                                ),
                              ),
                            ],
                          ),
                          // Info button
                          GestureDetector(
                            onTap: () {
                              showPlayerStatsSheet(context, player!, widget.ownershipPercentages[player.id] ?? 0.0);
                            },
                            child: Container(
                              width: 22,
                              height: 22,
                              decoration: BoxDecoration(
                                color: roleColor.withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                                border: Border.all(color: roleColor.withValues(alpha: 0.4), width: 1),
                              ),
                              child: Icon(Icons.info_outline, size: 16, color: roleColor),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      Expanded(
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            Text(
                              roleName,
                              style: TextStyle(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: Colors.black.withValues(alpha: 0.3),
                              ),
                            ),
                            Positioned(
                              right: 0,
                              bottom: 0,
                              child: GestureDetector(
                                onTap: () {
                                  widget.onRoleTap(role);
                                },
                                child: Container(
                                  width: 22,
                                  height: 22,
                                  decoration: BoxDecoration(
                                    color: Colors.black.withValues(alpha: 0.05),
                                    shape: BoxShape.circle,
                                    border: Border.all(color: Colors.black.withValues(alpha: 0.1), width: 1),
                                  ),
                                  child: Icon(Icons.info_outline, size: 16, color: Colors.black.withValues(alpha: 0.2)),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _emptySlotContent(Color roleColor) {
    return Center(
      child: Icon(
        Icons.person,
        size: 36,
        color: Colors.white.withValues(alpha: 0.3),
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

  Widget _buildManagerCard(LeaderboardEntry? manager) {
    if (_isLoading) {
      return Container(
        height: 80,
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
        child: const Center(child: CircularProgressIndicator(color: AppColors.coral, strokeWidth: 2)),
      );
    }
    if (manager == null) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(color: _surface, borderRadius: BorderRadius.circular(14)),
        child: const Text('Ingen data enda', style: TextStyle(color: AppColors.nightInk2)),
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
                Text(manager.teamName, style: AppText.dispH2(17).copyWith(color: AppColors.sand0)),
                Text(manager.managerName, style: AppText.uiCaption.copyWith(color: Colors.white.withValues(alpha: 0.75))),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '${manager.totalPoints}',
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
                Text(player.name, style: AppText.dispH2(17).copyWith(color: AppColors.sand0)),
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

  Widget _buildTopPlayersCarousel(
    FantasyPlayer bestAttack,
    FantasyPlayer bestBlock,
    FantasyPlayer bestServe,
    FantasyPlayer bestDefense,
    FantasyPlayer bestReceive,
    FantasyPlayer bestSet,
  ) {
    final playersWithRole = [
      (FantasyRole.attack,  bestAttack),
      (FantasyRole.block,   bestBlock),
      (FantasyRole.set,     bestSet),
      (FantasyRole.receive, bestReceive),
      (FantasyRole.defense, bestDefense),
      (FantasyRole.serve,   bestServe),
    ];

    return SizedBox(
      height: 200, // Fixed height for carousel cards
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 14),
        itemCount: playersWithRole.length,
        itemBuilder: (context, index) {
          final item = playersWithRole[index];
          return Padding(
            padding: const EdgeInsets.only(right: 12),
            child: _buildCarouselPlayerCard(item.$1, item.$2),
          );
        },
      ),
    );
  }

  Widget _buildCarouselPlayerCard(String role, FantasyPlayer player) {
    return Container(
      width: 140, // Match typical card width
      decoration: BoxDecoration(
        gradient: AppColors.cardInk,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 8, offset: const Offset(0, 4))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Top Part (Hero bg + Image)
          Expanded(
            flex: 55,
            child: Container(
              decoration: const BoxDecoration(
                image: DecorationImage(
                  image: AssetImage('assets/images/hero_card_bg.png'),
                  fit: BoxFit.cover,
                ),
              ),
              child: player.imageUrl.isNotEmpty
                  ? Image.network(
                      player.imageUrl,
                      fit: BoxFit.contain,
                      alignment: Alignment.bottomCenter,
                      errorBuilder: (_, __, ___) => const Icon(Icons.person, size: 50, color: Colors.white54),
                    )
                  : const Icon(Icons.person, size: 50, color: Colors.white54),
            ),
          ),
          // Bottom Part (Name + Points)
          Expanded(
            flex: 45,
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    _roleLabel(role).toUpperCase(),
                    style: AppText.monoSm.copyWith(color: AppColors.coral, fontSize: 10, fontWeight: FontWeight.bold),
                    maxLines: 1,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    player.name,
                    style: AppText.uiTitle.copyWith(color: Colors.white, fontSize: 13, height: 1.1),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const Spacer(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'POENG',
                        style: AppText.monoSm.copyWith(color: Colors.white54, fontSize: 9),
                      ),
                      Text(
                        '${calculatePlayerPoints(player.stats, role)}',
                        style: const TextStyle(fontFamily: 'RobotoMono', color: AppColors.coral, fontSize: 18, fontWeight: FontWeight.w900),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ],
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
                Text(player.name, style: AppText.uiTitle.copyWith(color: AppColors.sand2, fontSize: 13)),
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
                        Text(player.name, style: AppText.dispH2(18).copyWith(color: AppColors.sand2)),
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
                        '${calculatePlayerPoints(player.stats, role)}',
                        style: TextStyle(fontFamily: 'RobotoMono', fontSize: 26, fontWeight: FontWeight.w900, color: accent),
                      ),
                      Text('pts i rollen', style: TextStyle(fontFamily: 'RobotoMono', fontSize: 11, color: AppColors.nightInk2)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Text('Poengoversikt – ${_roleLabel(role)}', style: AppText.dispKicker().copyWith(color: AppColors.nightInk2)),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
                decoration: BoxDecoration(color: _bg, borderRadius: BorderRadius.circular(12)),
                child: player.stats == null
                    ? Padding(
                        padding: const EdgeInsets.symmetric(vertical: 8),
                        child: Text('Ingen registrerte kamper enda',
                            style: AppText.uiCaption.copyWith(color: AppColors.nightInk2)),
                      )
                    : Column(
                        children: [
                          for (final line in calculatePointBreakdown(player.stats, role))
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 4),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text(line.action.label,
                                        style: AppText.uiCaption.copyWith(
                                            color: AppColors.nightInk2, fontSize: 12)),
                                  ),
                                  Text('${line.count} × ${line.pointsPerAction}',
                                      style: TextStyle(
                                          fontFamily: 'RobotoMono',
                                          fontSize: 12,
                                          color: AppColors.nightInk2)),
                                  SizedBox(
                                    width: 52,
                                    child: Text(
                                      '${line.subtotal >= 0 ? '+' : ''}${line.subtotal}',
                                      textAlign: TextAlign.right,
                                      style: TextStyle(
                                        fontFamily: 'RobotoMono',
                                        fontSize: 13,
                                        fontWeight: FontWeight.w800,
                                        color: line.subtotal < 0
                                            ? AppColors.coral
                                            : const Color(0xFF36C87A),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.blueBright,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
                      onPressed: () {
                        widget.onCaptainChanged(player.id);
                        Navigator.pop(context);
                      },
                      icon: const Icon(Icons.star, size: 20),
                      label: const Text('Gjør til Kaptein', style: TextStyle(fontFamily: 'RobotoMono', fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
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
                      label: const Text('Bytt Spiller', style: TextStyle(fontFamily: 'RobotoMono', fontWeight: FontWeight.w700, fontSize: 12)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  void _showRulebook(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: _surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.5,
          maxChildSize: 0.95,
          expand: false,
          builder: (context, scrollController) {
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 16),
                  Center(
                    child: Container(
                      width: 36, height: 4,
                      decoration: BoxDecoration(color: _border, borderRadius: BorderRadius.circular(2)),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Row(
                    children: [
                      const Icon(Icons.menu_book_rounded, color: AppColors.coral, size: 28),
                      const SizedBox(width: 12),
                      Text('Fantasy Regelbok', style: AppText.dispH2(24).copyWith(color: AppColors.sand0)),
                    ],
                  ),
                  const SizedBox(height: 24),
                  Expanded(
                    child: ListView(
                      controller: scrollController,
                      children: [
                        _buildRuleSection(
                          icon: Icons.sports_volleyball,
                          title: 'Slik fungerer Poengene',
                          content: 'Ditt lag scorer poeng basert på spillernes faktiske prestasjoner i Norges Tour. Hver spiller scorer kun poeng for den rollen du har satt dem i (f.eks. en Blokkspiller får bare poeng for blokkeringer).',
                        ),
                        const SizedBox(height: 20),
                        _buildPointsTable(),
                        const SizedBox(height: 20),
                        _buildRuleSection(
                          icon: Icons.access_time_filled_rounded,
                          title: 'Frister (Deadlines)',
                          content: 'Laget ditt låses klokken 23:59 dagen før turneringen starter. Sørg for at du har valgt de spillerne som faktisk deltar i den kommende turneringen!',
                        ),
                        const SizedBox(height: 20),
                        _buildRuleSection(
                          icon: Icons.swap_horizontal_circle,
                          title: 'Spillerbytter',
                          content: 'Etter hver runde har du 2 gratis bytter. Bruk dem klokt for å få inn spillere som er i form eller som deltar i neste turnering. Du kan ikke bytte flere enn 2 spillere.',
                        ),
                        const SizedBox(height: 20),
                        _buildRuleSection(
                          icon: Icons.star_rounded,
                          title: 'Kaptein (1.5x poeng)',
                          content: 'Velg en spiller som din Kaptein! Kapteinen får automatisk 1.5x poeng. Gjør et smart valg for å maksimere poengsummen din.',
                        ),
                        const SizedBox(height: 20),
                        _buildRuleSection(
                          icon: Icons.emoji_events_rounded,
                          title: 'Turneringsbonus',
                          content: 'Spillere som kommer på pallen får solide bonuspoeng (Gull: +30, Sølv: +20, Bronse: +10). Det lønner seg å velge spillere som går langt i turneringen!',
                        ),
                        const SizedBox(height: 40),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildRuleSection({required IconData icon, required String title, required String content}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.coral, size: 24),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: AppText.uiTitle.copyWith(color: AppColors.sand2, fontSize: 16)),
                const SizedBox(height: 6),
                Text(content, style: AppText.uiCaption.copyWith(color: AppColors.nightInk2, height: 1.4)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPointsTable() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: _surface2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.calculate_rounded, color: AppColors.coral, size: 24),
              const SizedBox(width: 14),
              Text('Poengoversikt per Rolle', style: AppText.uiTitle.copyWith(color: AppColors.sand2, fontSize: 16)),
            ],
          ),
          const SizedBox(height: 16),
          _buildPointRow('Angrep', 'Vellykket angrep', '+21'),
          _buildPointRow('Angrep', 'Angrepsfeil', '-12', isNegative: true),
          const Divider(color: _border, height: 16),
          _buildPointRow('Blokk', 'Poenggivende blokk', '+75'),
          _buildPointRow('Blokk', 'Nettfeil / overtråkk', '-15', isNegative: true),
          const Divider(color: _border, height: 16),
          _buildPointRow('Legg', 'Vellykket legg', '+18'),
          _buildPointRow('Legg', 'Mislykket legg / Partnerfeil', '-3', isNegative: true),
          _buildPointRow('Legg', 'Ballbehandlingsfeil', '-15', isNegative: true),
          const Divider(color: _border, height: 16),
          _buildPointRow('Mottak', 'Vellykket / Godt mottak', '+11'),
          _buildPointRow('Mottak', 'Mottaksfeil', '-15', isNegative: true),
          const Divider(color: _border, height: 16),
          _buildPointRow('Forsvar', 'Forsvar-til-Poeng (Kontra)', '+48'),
          const Divider(color: _border, height: 16),
          _buildPointRow('Serve', 'Serveess', '+115'),
          _buildPointRow('Serve', 'Ordinær serv i spill', '+5'),
          _buildPointRow('Serve', 'Servefeil', '-30', isNegative: true),
        ],
      ),
    );
  }

  Widget _buildPointRow(String role, String action, String points, {bool isNegative = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 55,
            child: Text(role.toUpperCase(), style: AppText.monoSm.copyWith(color: AppColors.nightInk2, fontSize: 9, fontWeight: FontWeight.bold)),
          ),
          Expanded(
            child: Text(action, style: AppText.uiCaption.copyWith(color: AppColors.sand2, fontSize: 12)),
          ),
          Text(points, style: TextStyle(fontFamily: 'RobotoMono', fontSize: 13, fontWeight: FontWeight.w800, color: isNegative ? AppColors.coral : const Color(0xFF36C87A))),
        ],
      ),
    );
  }
}
