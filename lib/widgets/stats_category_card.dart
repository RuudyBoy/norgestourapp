import 'package:flutter/material.dart';
import 'package:norges_tour_app/logic/stats_logic.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';
import 'package:norges_tour_app/theme/app_theme.dart';

/// Kort for én statistikkategori (f.eks. «Flest poeng»): vinneren stort,
/// og de neste fire under. Brukes på sesong- og turneringsstatistikken.
class StatsCategoryCard extends StatelessWidget {
  final String title;
  final IconData icon;
  final Color accentColor;
  final List<PlayerMatchStats> players;
  final String Function(PlayerMatchStats) valueFormatter;
  final VoidCallback onTap;

  /// Farge på tittelen (mørk på sesongstatistikk, hvit på turneringsstatistikk).
  final Color titleColor;

  const StatsCategoryCard({
    super.key,
    required this.title,
    required this.icon,
    required this.accentColor,
    required this.players,
    required this.valueFormatter,
    required this.onTap,
    this.titleColor = AppColors.ink,
  });

  @override
  Widget build(BuildContext context) {
    if (players.isEmpty) return const SizedBox.shrink();

    final winner = players[0];
    final runnersUp = players.length > 1 ? players.sublist(1, players.length > 5 ? 5 : players.length) : [];

    final valString = valueFormatter(winner);
    String bigNum = valString;
    String labelText = '';
    if (valString.contains(' ')) {
      final parts = valString.split(' ');
      bigNum = parts[0];
      labelText = parts.sublist(1).join(' ').toUpperCase();
    } else {
      if (valString.endsWith('%')) {
        bigNum = valString.substring(0, valString.length - 1);
        labelText = '%';
      }
    }

    final nameParts = winner.playerName.split(' ');
    final firstName = nameParts.first;
    final lastName = nameParts.length > 1 ? nameParts.sublist(1).join(' ') : '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Header / Title
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Row(
            children: [
              Icon(icon, color: accentColor, size: 22),
              const SizedBox(width: 8),
              Text(title.toUpperCase(), style: AppText.dispKicker(16).copyWith(color: titleColor)),
            ],
          ),
        ),

        // PREMIER LEAGUE STYLE CARD
        GestureDetector(
          onTap: onTap,
          child: Container(
            height: 280, // tall card
            clipBehavior: Clip.hardEdge,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              boxShadow: AppTheme.shadowLg,
              image: const DecorationImage(
                image: AssetImage('assets/images/card_bg.png'),
                fit: BoxFit.cover,
              ),
            ),
            child: Stack(
              children: [
                
                // Player Image Cutout on right
                if (winner.imageUrl.isNotEmpty)
                  Positioned(
                    right: 0, bottom: 50, top: 20, width: 200,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.transparent],
                          stops: [0.75, 1.0],
                        ).createShader(rect);
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.network(
                        winner.imageUrl, 
                        fit: BoxFit.contain,
                        alignment: Alignment.bottomRight,
                        errorBuilder: (context, error, stackTrace) => Icon(Icons.person, size: 150, color: Colors.white.withValues(alpha: 0.05)),
                      ),
                    ),
                  )
                else
                  Positioned(
                    right: 10, bottom: 50, top: 20, width: 180,
                    child: Icon(Icons.person, size: 150, color: Colors.white.withValues(alpha: 0.05)),
                  ),
                
                // Text Overlay (Left Side)
                Positioned(
                  left: 20, top: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(firstName.toUpperCase(), 
                        style: AppText.dispScore(22).copyWith(color: accentColor, height: 1.1)
                      ),
                      if (lastName.isNotEmpty)
                        Text(lastName.toUpperCase(), 
                          style: AppText.dispScore(22).copyWith(color: Colors.white, height: 1.1)
                        ),
                      const SizedBox(height: 6),
                      Text(winner.teamName.isNotEmpty ? winner.teamName.toUpperCase() : 'SPILLER', 
                        style: AppText.monoMd.copyWith(color: Colors.white70, fontSize: 11)
                      ),
                    ],
                  ),
                ),
                
                // Big Number (Right Side, Top)
                Positioned(
                  right: 20, top: 24,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(bigNum, 
                        style: AppText.dispScore(42).copyWith(color: Colors.white, height: 1.0)
                      ),
                      Text(labelText, 
                        style: AppText.dispKicker(14).copyWith(color: Colors.white, height: 1.2)
                      ),
                    ],
                  ),
                ),
                
                // Bottom small stats
                Positioned(
                  left: 0, right: 0, bottom: 0,
                  child: Container(
                    height: 56,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.4),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildSmallStat('KILLS', winner.kills.toString()),
                        _buildSmallStat('BLOKK', winner.blocks.toString()),
                        _buildSmallStat('ESS', winner.aces.toString()),
                        _buildSmallStat('FEIL', (winner.attackErrors + winner.serviceErrors).toString()),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
        
        // Runners Up List Below Card
        if (runnersUp.isNotEmpty) ...[
          const SizedBox(height: 12),
          Container(
            decoration: BoxDecoration(
              gradient: AppColors.cardInk,
              borderRadius: BorderRadius.circular(12),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: [
                ...runnersUp.asMap().entries.map((entry) {
                  final index = entry.key + 2;
                  final player = entry.value;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPad, vertical: 10),
                    child: Row(
                      children: [
                        SizedBox(
                          width: 24,
                          child: Text('$index.', style: AppText.monoMd.copyWith(color: Colors.white70, fontWeight: FontWeight.bold)),
                        ),
                        if (player.imageUrl.isNotEmpty)
                          Padding(
                            padding: const EdgeInsets.only(right: 12.0),
                            child: CircleAvatar(
                              radius: 14,
                              backgroundImage: NetworkImage(player.imageUrl),
                              backgroundColor: Colors.white.withValues(alpha: 0.1),
                            ),
                          )
                        else
                          const SizedBox(width: 8),
                        Expanded(child: Text(player.playerName, style: AppText.uiTitle.copyWith(fontSize: 14, color: Colors.white))),
                        Text(valueFormatter(player), style: AppText.monoMd.copyWith(fontWeight: FontWeight.w700, color: Colors.white)),
                      ],
                    ),
                  );
                }),
                // Link to full list
                Divider(height: 1, color: Colors.white.withValues(alpha: 0.1)),
                InkWell(
                  onTap: onTap,
                  borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Vis alle', style: AppText.uiTitle.copyWith(color: Colors.white)),
                        const SizedBox(width: 4),
                        const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildSmallStat(String label, String value) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(label, style: AppText.uiCaption.copyWith(color: Colors.white70, fontSize: 10, letterSpacing: 0.5)),
        const SizedBox(height: 2),
        Text(value, style: AppText.uiTitle.copyWith(color: Colors.white, fontSize: 15)),
      ],
    );
  }
}
