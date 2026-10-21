import 'package:flutter/material.dart';
import 'package:norges_tour_app/pages/fantasy/models.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';

void showPlayerStatsSheet(BuildContext context, FantasyPlayer player, double ownership) {
  showModalBottomSheet(
    context: context,
    backgroundColor: const Color(0xFF111C30),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (context) {
      return SafeArea(
        child: SingleChildScrollView(
          child: Padding(
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
                decoration: BoxDecoration(color: const Color(0xFF1E2E48), borderRadius: BorderRadius.circular(2)),
              ),
            ),
            Row(
              children: [
                Container(
                  width: 62, height: 62,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white24, width: 2),
                    color: const Color(0xFF18253E),
                  ),
                  child: player.imageUrl.isNotEmpty
                      ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                      : const Icon(Icons.person, color: Colors.white54, size: 32),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(player.name, style: AppText.dispH2(18).copyWith(color: AppColors.sand2)),
                      const SizedBox(height: 3),
                      Text(player.team, style: AppText.uiCaption.copyWith(color: AppColors.nightInk2)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      '${player.totalPoints}',
                      style: const TextStyle(fontFamily: 'RobotoMono', fontSize: 26, fontWeight: FontWeight.w900, color: AppColors.coral),
                    ),
                    Text('totale poeng', style: TextStyle(fontFamily: 'RobotoMono', fontSize: 11, color: AppColors.nightInk2)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 20),
            
            // Ownership
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Valgt av:', style: AppText.uiCaption.copyWith(color: Colors.white70)),
                Text('${ownership.toStringAsFixed(1)}%', style: AppText.monoMd.copyWith(color: Colors.white, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            
            Text('Statistikk (Totalt antall)', style: AppText.dispKicker().copyWith(color: AppColors.nightInk2)),
            const SizedBox(height: 12),
            Container(
              padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 14),
              decoration: BoxDecoration(color: const Color(0xFF0B1220), borderRadius: BorderRadius.circular(12)),
              child: Column(
                children: [
                  _buildStatRow('Blokk', player.blocks),
                  _buildStatRow('Forsvar (Digs)', player.digs),
                  _buildStatRow('Angrep', player.attacks),
                  _buildStatRow('Legg (Sets)', player.sets),
                  _buildStatRow('Mottak', player.receives),
                  _buildStatRow('Ess', player.aces),
                ],
              ),
            ),
            const SizedBox(height: 20),
          ],
        ),
      ),
      ),
    );
    },
  );
}

Widget _buildStatRow(String label, int value) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: AppText.uiCaption.copyWith(color: AppColors.nightInk2, fontSize: 12)),
        Text(
          value.toString(),
          style: const TextStyle(
            fontFamily: 'RobotoMono',
            fontSize: 13,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
      ],
    ),
  );
}
