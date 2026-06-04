import 'package:flutter/material.dart';
import 'models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

class FantasySquadView extends StatelessWidget {
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

  Widget _buildPlayerSlot(BuildContext context, String role, String? playerId, double width) {
    FantasyPlayer? player;
    if (playerId != null) {
      final matches = players.where((p) => p.id == playerId);
      player = matches.isNotEmpty ? matches.first : null;
    }

    final isLinked = player != null && player.id == linkedPlayerId;

    return GestureDetector(
      onTap: () {
        if (player != null) {
          _showPlayerOptions(context, role, player);
        } else {
          onRoleTap(role);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: width * 0.14,
            height: width * 0.14,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player != null ? AppColors.blue : AppColors.sand2,
              border: Border.all(
                color: player != null ? AppColors.coral : AppColors.ink3,
                width: player != null ? 2.5 : 1.5,
              ),
              boxShadow: player != null ? AppTheme.shadowSm : [],
            ),
            child: player != null && player.imageUrl.isNotEmpty
                ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                : Icon(
                    player != null ? Icons.person : Icons.person_add,
                    color: player != null ? Colors.white : AppColors.ink3,
                    size: width * 0.07,
                  ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
            decoration: BoxDecoration(
              color: isLinked ? AppColors.coral : AppColors.ink.withOpacity(0.85),
              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
            ),
            child: Text(
              player != null ? (isLinked ? 'MEG' : player.name.split(' ').last) : role,
              style: AppText.monoSmLight.copyWith(fontSize: 9),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (player != null)
            Container(
              margin: const EdgeInsets.only(top: 2),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.coral.withOpacity(0.15),
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Text('${player.price}m', style: AppText.monoSm.copyWith(color: AppColors.coral, fontSize: 9)),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        double totalValue = 0;
        int totalPoints = 0;
        for (var playerId in selectedPlayers.values) {
          if (playerId != null) {
            final matches = players.where((p) => p.id == playerId);
            if (matches.isNotEmpty) {
              final p = matches.first;
              totalValue += p.price;
              totalPoints += p.totalPoints;
            }
          }
        }

        return Column(
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

            // Pitch area
            Expanded(
              child: Container(
                margin: const EdgeInsets.all(AppTheme.pageHPad),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                  color: const Color(0xFFD4B896),
                  border: Border.all(color: Colors.white.withOpacity(0.3), width: 1.5),
                  boxShadow: AppTheme.shadowSm,
                ),
                child: Stack(
                  children: [
                    // Court lines
                    Positioned.fill(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        child: Column(
                          children: [
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                            Container(height: 2, color: Colors.white.withOpacity(0.7)),
                            Expanded(
                              child: Container(
                                margin: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  border: Border.all(color: Colors.white.withOpacity(0.6), width: 1.5),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Players
                    Positioned(
                      top: 32,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildPlayerSlot(context, FantasyRole.block, selectedPlayers[FantasyRole.block], width)),
                    ),
                    Positioned(
                      top: width * 0.32,
                      left: width * 0.12,
                      child: _buildPlayerSlot(context, FantasyRole.attack, selectedPlayers[FantasyRole.attack], width),
                    ),
                    Positioned(
                      top: width * 0.32,
                      right: width * 0.12,
                      child: _buildPlayerSlot(context, FantasyRole.set, selectedPlayers[FantasyRole.set], width),
                    ),
                    Positioned(
                      bottom: width * 0.28,
                      left: width * 0.12,
                      child: _buildPlayerSlot(context, FantasyRole.receive, selectedPlayers[FantasyRole.receive], width),
                    ),
                    Positioned(
                      bottom: width * 0.28,
                      right: width * 0.12,
                      child: _buildPlayerSlot(context, FantasyRole.defense, selectedPlayers[FantasyRole.defense], width),
                    ),
                    Positioned(
                      bottom: 24,
                      left: 0,
                      right: 0,
                      child: Center(child: _buildPlayerSlot(context, FantasyRole.serve, selectedPlayers[FantasyRole.serve], width)),
                    ),
                  ],
                ),
              ),
            ),
          ],
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
                    onRoleTap(role);
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
