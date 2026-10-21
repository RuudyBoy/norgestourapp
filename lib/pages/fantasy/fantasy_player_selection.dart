import 'package:flutter/material.dart';
import 'package:norges_tour_app/pages/fantasy/models.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';
import 'package:norges_tour_app/theme/app_theme.dart';
import 'package:norges_tour_app/pages/fantasy/player_stats_sheet.dart';

// ── Role accent colours ────────────────────────────────────────────────────────

Color _roleColor(String role) {
  return AppColors.coral;
}

// ── Main screen ───────────────────────────────────────────────────────────────

class FantasyPlayerSelection extends StatelessWidget {
  final String role;
  final Map<String, String?> currentSelectedPlayers;
  final List<FantasyPlayer> players;
  final Map<String, double> ownershipPercentages;
  final Function(String playerId) onSelect;
  final String? linkedPlayerId;

  const FantasyPlayerSelection({
    super.key,
    required this.role,
    required this.currentSelectedPlayers,
    required this.players,
    required this.ownershipPercentages,
    required this.onSelect,
    this.linkedPlayerId,
  });

  double get _otherRolesTotal {
    double total = 0;
    for (final entry in currentSelectedPlayers.entries) {
      if (entry.key != role && entry.value != null) {
        final match = players.where((p) => p.id == entry.value);
        if (match.isNotEmpty) total += match.first.price;
      }
    }
    return total;
  }

  String _primaryStat(FantasyPlayer p) {
    switch (role) {
      case FantasyRole.block:   return '${p.blocks} Blokk';
      case FantasyRole.defense: return '${p.digs} Digs';
      case FantasyRole.attack:  return '${p.attacks} Angrep';
      case FantasyRole.set:     return '${p.sets} Legg';
      case FantasyRole.receive: return '${p.receives} Mottak';
      case FantasyRole.serve:   return '${p.aces} Aces';
      default:                  return '${p.totalPoints} Pts';
    }
  }

  @override
  Widget build(BuildContext context) {
    final budget = 50.0 - _otherRolesTotal;
    final roleColor = _roleColor(role);

    // Sort: available players first, disabled last
    final sorted = [...players];
    sorted.sort((a, b) {
      final aDisabled = (currentSelectedPlayers.values.contains(a.id) &&
              currentSelectedPlayers.entries
                  .firstWhere((e) => e.value == a.id)
                  .key != role) ||
          (budget - a.price) < 0;
      final bDisabled = (currentSelectedPlayers.values.contains(b.id) &&
              currentSelectedPlayers.entries
                  .firstWhere((e) => e.value == b.id)
                  .key != role) ||
          (budget - b.price) < 0;
      if (aDisabled == bDisabled) return b.price.compareTo(a.price);
      return aDisabled ? 1 : -1;
    });

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: CustomScrollView(
        slivers: [
          // ── Overskrift ──────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: Colors.transparent,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            title: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'VELG SPILLER',
                  style: AppText.monoSm.copyWith(
                    color: roleColor,
                    letterSpacing: 1.5,
                    fontSize: 9,
                  ),
                ),
                Text(
                  role.toUpperCase(),
                  style: AppText.dispH2(18).copyWith(color: Colors.white),
                ),
              ],
            ),
            actions: [
              // Budget chip
              Container(
                margin: const EdgeInsets.only(right: 16, top: 10, bottom: 10),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: budget < 5
                      ? AppColors.coral.withValues(alpha: 0.15)
                      : Colors.white.withValues(alpha: 0.07),
                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                  border: Border.all(
                    color: budget < 5
                        ? AppColors.coral.withValues(alpha: 0.4)
                        : Colors.white.withValues(alpha: 0.12),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 12,
                      color: budget < 5 ? AppColors.coral : Colors.white70,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '\$${budget.toStringAsFixed(1)}m',
                      style: AppText.monoMd.copyWith(
                        color: budget < 5 ? AppColors.coral : Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ],
            // Fargelinje for rollen nederst
            bottom: PreferredSize(
              preferredSize: const Size.fromHeight(2),
              child: Container(
                height: 2,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [roleColor.withValues(alpha: 0.8), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // ── Player count label ─────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Text(
                '${sorted.length} SPILLERE',
                style: AppText.monoSm.copyWith(
                  color: Colors.white.withValues(alpha: 0.35),
                  letterSpacing: 1.5,
                ),
              ),
            ),
          ),

          // ── Grid ──────────────────────────────────────────────────
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(12, 0, 12, 24),
            sliver: SliverGrid(
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                childAspectRatio: 0.68,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
              ),
              delegate: SliverChildBuilderDelegate(
                (context, index) {
                  final player = sorted[index];

                  bool isSelectedElsewhere = false;
                  bool isSelectedHere = false;
                  String? selectedRole;

                  if (currentSelectedPlayers.values.contains(player.id)) {
                    currentSelectedPlayers.forEach((key, value) {
                      if (value == player.id) {
                        selectedRole = key;
                        if (key == role) {
                          isSelectedHere = true;
                        } else {
                          isSelectedElsewhere = true;
                        }
                      }
                    });
                  }

                  final exceedsBudget = (budget - player.price) < 0;
                  final isDisabled = isSelectedElsewhere || exceedsBudget;
                  final ownership = ownershipPercentages[player.id] ?? 0.0;

                  return _PlayerCard(
                    player: player,
                    roleColor: roleColor,
                    isSelectedHere: isSelectedHere,
                    isSelectedElsewhere: isSelectedElsewhere,
                    isDisabled: isDisabled,
                    exceedsBudget: exceedsBudget,
                    isMe: player.id == linkedPlayerId,
                    primaryStat: _primaryStat(player),
                    ownership: ownership,
                    selectedRole: selectedRole,
                    onTap: isDisabled
                        ? () {
                            if (exceedsBudget) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content:
                                      Text('Ikke nok budsjett! (Maks 50m)'),
                                  backgroundColor: AppColors.coral,
                                ),
                              );
                            } else {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      '${player.name} spiller allerede som $selectedRole!'),
                                ),
                              );
                            }
                          }
                        : () {
                            onSelect(player.id);
                            Navigator.pop(context);
                          },
                  );
                },
                childCount: sorted.length,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Spillerkort ─────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final FantasyPlayer player;
  final Color roleColor;
  final bool isSelectedHere;
  final bool isSelectedElsewhere;
  final bool isDisabled;
  final bool exceedsBudget;
  final bool isMe;
  final String primaryStat; // kept for compatibility but we will use calculatePlayerPoints
  final double ownership;
  final String? selectedRole;
  final VoidCallback onTap;

  const _PlayerCard({
    required this.player,
    required this.roleColor,
    required this.isSelectedHere,
    required this.isSelectedElsewhere,
    required this.isDisabled,
    required this.exceedsBudget,
    required this.isMe,
    required this.primaryStat,
    required this.ownership,
    required this.selectedRole,
    required this.onTap,
  });

  Widget _emptySlotContent() {
    return Container(
      color: roleColor.withValues(alpha: 0.1),
      child: Center(
        child: Icon(Icons.sports_volleyball, color: Colors.white24, size: 40),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelectedHere
        ? roleColor
        : isSelectedElsewhere
            ? Colors.redAccent.withValues(alpha: 0.5)
            : Colors.white;

    final borderWidth = isSelectedHere ? 3.0 : 2.0;

    return GestureDetector(
      onTap: onTap,
      child: Stack(
        children: [
          Container(
            decoration: BoxDecoration(
              color: const Color(0xFFF0F0F0), // Off-white/light-grey card background
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: borderColor,
                width: borderWidth,
              ),
              boxShadow: isSelectedHere
                  ? [
                      BoxShadow(
                        color: roleColor.withValues(alpha: 0.35),
                        blurRadius: 16,
                        spreadRadius: 1,
                      )
                    ]
                  : [
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
                // Øverste del (bilde)
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
                        if (player.imageUrl.isNotEmpty)
                          ClipRRect(
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(4)),
                            child: Image.network(
                              player.imageUrl,
                              fit: BoxFit.cover,
                              alignment: Alignment.topCenter,
                              errorBuilder: (_, _, _) => _emptySlotContent(),
                            ),
                          )
                        else
                          _emptySlotContent(),

                        // Prismerke øverst til høyre
                        Positioned(
                          top: 4,
                          right: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.65),
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              '\$${player.price}m',
                              style: const TextStyle(
                                fontFamily: 'RobotoMono',
                                fontSize: 9,
                                fontWeight: FontWeight.w900,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),

                        // «MEG»-merke øverst til venstre
                        if (isMe)
                          Positioned(
                            top: 4,
                            left: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                              decoration: BoxDecoration(
                                color: AppColors.coral,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: const Text(
                                'MEG',
                                style: TextStyle(
                                  fontFamily: 'RobotoMono',
                                  fontSize: 8,
                                  fontWeight: FontWeight.w900,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                
                // Nederste del (info)
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
                        // Player Name (bold, most visible)
                        Text(
                          isMe ? 'MEG' : player.name,
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
                        // Nederste rad: poeng og info
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.sports_volleyball, size: 9, color: roleColor.withValues(alpha: 0.8)),
                                const SizedBox(width: 3),
                                Text(
                                  '${player.totalPoints}',
                                  style: const TextStyle(
                                    fontFamily: 'RobotoMono',
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: Colors.black87,
                                  ),
                                ),
                              ],
                            ),
                            // Info-knapp
                            GestureDetector(
                              onTap: () {
                                showPlayerStatsSheet(context, player, ownership);
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
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),

          // ── Selected checkmark overlay ─────────────────────────
          if (isSelectedHere)
            Positioned(
              top: 8,
              left: 8,
              child: Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: roleColor,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(color: roleColor.withValues(alpha: 0.5), blurRadius: 8)
                  ],
                ),
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 14),
              ),
            ),

          // ── Disabled overlay ───────────────────────────────────
          if (isDisabled)
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.58),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Center(
                  child: Icon(
                    exceedsBudget ? Icons.lock_outline_rounded : Icons.block_rounded,
                    color: Colors.white.withValues(alpha: 0.35),
                    size: 28,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

// ignore: unused_element
class _StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;

  const _StatusBadge(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 9, color: color),
          const SizedBox(width: 3),
          Text(
            label,
            style: AppText.monoSm.copyWith(color: color, fontSize: 8.5),
          ),
        ],
      ),
    );
  }
}
