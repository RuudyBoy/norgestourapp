import 'package:flutter/material.dart';
import 'models.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

// ── Role accent colours ────────────────────────────────────────────────────────

Color _roleColor(String role) {
  switch (role) {
    case FantasyRole.block:   return AppColors.coral;
    case FantasyRole.defense: return AppColors.blue;
    case FantasyRole.attack:  return const Color(0xFFFF8522);
    case FantasyRole.set:     return AppColors.green;
    case FantasyRole.receive: return const Color(0xFF00B8A9);
    case FantasyRole.serve:   return const Color(0xFF9B59B6);
    default:                  return AppColors.blueBright;
  }
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
      backgroundColor: const Color(0xFF0B1220),
      body: CustomScrollView(
        slivers: [
          // ── Header ────────────────────────────────────────────────
          SliverAppBar(
            pinned: true,
            backgroundColor: const Color(0xFF0B1220),
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
            // Role colour accent line at bottom
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
                crossAxisCount: 2,
                childAspectRatio: 0.62,
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

// ── Player card ────────────────────────────────────────────────────────────────

class _PlayerCard extends StatelessWidget {
  final FantasyPlayer player;
  final Color roleColor;
  final bool isSelectedHere;
  final bool isSelectedElsewhere;
  final bool isDisabled;
  final bool exceedsBudget;
  final bool isMe;
  final String primaryStat;
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

  @override
  Widget build(BuildContext context) {
    final borderColor = isSelectedHere
        ? roleColor
        : isSelectedElsewhere
            ? Colors.redAccent.withValues(alpha: 0.5)
            : Colors.white.withValues(alpha: 0.07);
    final borderWidth = isSelectedHere ? 2.0 : 1.0;

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        decoration: BoxDecoration(
          color: const Color(0xFF111C30),
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          border: Border.all(color: borderColor, width: borderWidth),
          boxShadow: isSelectedHere
              ? [
                  BoxShadow(
                    color: roleColor.withValues(alpha: 0.35),
                    blurRadius: 16,
                    spreadRadius: 1,
                  )
                ]
              : [],
        ),
        child: Stack(
          children: [
            Column(
              children: [
                // ── Player photo area ──────────────────────────────
                Expanded(
                  flex: 58,
                  child: _PhotoArea(player: player, roleColor: roleColor),
                ),

                // ── Info strip ────────────────────────────────────
                Expanded(
                  flex: 42,
                  child: _InfoStrip(
                    player: player,
                    roleColor: roleColor,
                    primaryStat: primaryStat,
                    ownership: ownership,
                    isSelectedHere: isSelectedHere,
                    isSelectedElsewhere: isSelectedElsewhere,
                    selectedRole: selectedRole,
                  ),
                ),
              ],
            ),

            // ── Price badge top-right ──────────────────────────────
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.65),
                  borderRadius:
                      BorderRadius.circular(AppTheme.radiusBadge),
                  border:
                      Border.all(color: roleColor.withValues(alpha: 0.5)),
                ),
                child: Text(
                  '\$${player.price}m',
                  style: AppText.monoMd.copyWith(
                    color: roleColor,
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),

            // ── "MEG" badge top-left ───────────────────────────────
            if (isMe)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.coral,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'MEG',
                    style: AppText.monoSm
                        .copyWith(color: Colors.white, fontSize: 8),
                  ),
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
                      BoxShadow(
                          color: roleColor.withValues(alpha: 0.5),
                          blurRadius: 8)
                    ],
                  ),
                  child: const Icon(Icons.check_rounded,
                      color: Colors.white, size: 14),
                ),
              ),

            // ── Disabled overlay ───────────────────────────────────
            if (isDisabled)
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.58),
                    borderRadius:
                        BorderRadius.circular(AppTheme.radiusCard),
                  ),
                  child: Center(
                    child: Icon(
                      exceedsBudget
                          ? Icons.lock_outline_rounded
                          : Icons.block_rounded,
                      color: Colors.white.withValues(alpha: 0.35),
                      size: 28,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

// ── Photo area ─────────────────────────────────────────────────────────────────

class _PhotoArea extends StatelessWidget {
  final FantasyPlayer player;
  final Color roleColor;

  const _PhotoArea({required this.player, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius:
          const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              const Color(0xFF18253E),
              Color.lerp(const Color(0xFF111C30), roleColor, 0.22)!,
            ],
          ),
        ),
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Player image or initials placeholder
            if (player.imageUrl.isNotEmpty)
              Image.network(
                player.imageUrl,
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (ctx, err, stack) => _Initials(
                  name: player.name,
                  roleColor: roleColor,
                ),
              )
            else
              _Initials(name: player.name, roleColor: roleColor),

            // Bottom fade for smooth transition into info strip
            Positioned(
              bottom: 0,
              left: 0,
              right: 0,
              height: 36,
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      const Color(0xFF111C30).withValues(alpha: 0.95),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Initials placeholder ───────────────────────────────────────────────────────

class _Initials extends StatelessWidget {
  final String name;
  final Color roleColor;

  const _Initials({required this.name, required this.roleColor});

  @override
  Widget build(BuildContext context) {
    final parts = name.trim().split(' ');
    final initials = parts.length >= 2
        ? '${parts.first[0]}${parts.last[0]}'.toUpperCase()
        : name.isNotEmpty
            ? name[0].toUpperCase()
            : '?';

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: roleColor.withValues(alpha: 0.12),
              border:
                  Border.all(color: roleColor.withValues(alpha: 0.35), width: 2),
            ),
            child: Center(
              child: Text(
                initials,
                style: AppText.dispH2(22).copyWith(color: Colors.white),
              ),
            ),
          ),
          const SizedBox(height: 6),
          Icon(Icons.sports_volleyball,
              color: roleColor.withValues(alpha: 0.25), size: 14),
        ],
      ),
    );
  }
}

// ── Info strip ─────────────────────────────────────────────────────────────────

class _InfoStrip extends StatelessWidget {
  final FantasyPlayer player;
  final Color roleColor;
  final String primaryStat;
  final double ownership;
  final bool isSelectedHere;
  final bool isSelectedElsewhere;
  final String? selectedRole;

  const _InfoStrip({
    required this.player,
    required this.roleColor,
    required this.primaryStat,
    required this.ownership,
    required this.isSelectedHere,
    required this.isSelectedElsewhere,
    required this.selectedRole,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 7, 10, 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Name
          Text(
            player.name,
            style: AppText.uiTitle.copyWith(
              color: Colors.white,
              fontSize: 12,
              height: 1.1,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 1),

          // Team
          Text(
            player.team,
            style: AppText.uiCaption.copyWith(
              color: AppColors.nightInk3,
              fontSize: 10,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),

          const Spacer(),

          // Stat row
          Row(
            children: [
              Expanded(
                child: Text(
                  primaryStat,
                  style: AppText.monoSm.copyWith(
                    color: roleColor,
                    fontSize: 9,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
              Text(
                '${ownership.toStringAsFixed(0)}%',
                style: AppText.monoSm.copyWith(
                  color: Colors.white.withValues(alpha: 0.4),
                  fontSize: 9,
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),

          // Status badge
          if (isSelectedHere)
            _StatusBadge(
              label: 'VALGT',
              color: roleColor,
              icon: Icons.check_rounded,
            )
          else if (isSelectedElsewhere && selectedRole != null)
            _StatusBadge(
              label: selectedRole!.toUpperCase(),
              color: Colors.redAccent,
              icon: Icons.swap_horiz_rounded,
            )
          else
            // Ownership bar
            ClipRRect(
              borderRadius: BorderRadius.circular(2),
              child: LinearProgressIndicator(
                value: (ownership / 100).clamp(0.0, 1.0),
                minHeight: 3,
                backgroundColor: Colors.white.withValues(alpha: 0.07),
                valueColor:
                    AlwaysStoppedAnimation<Color>(roleColor.withValues(alpha: 0.6)),
              ),
            ),
        ],
      ),
    );
  }
}

// ── Status badge ──────────────────────────────────────────────────────────────

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
