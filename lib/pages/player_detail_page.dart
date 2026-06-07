import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class PlayerDetailPage extends StatelessWidget {
  final String playerId;
  final Map<String, dynamic> playerData;

  const PlayerDetailPage({
    super.key,
    required this.playerId,
    required this.playerData,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = playerData['first_name'] ?? '';
    final lastName = playerData['last_name'] ?? '';
    final fullName = '$firstName $lastName';
    final position = playerData['position'] ?? 'Ukjent posisjon';
    final team = playerData['team'] ?? 'Ukjent lag';
    final imageUrl = playerData['image_url'] ?? playerData['image'] ?? playerData['photoUrl'] ?? playerData['photo_url'] ?? playerData['picture'] ?? '';
    final jerseyNumber = playerData['jersey_number']?.toString() ?? '';
    final birthDate = playerData['birth_date'] ?? '';
    final nationality = playerData['nationality'] ?? '';
    final height = playerData['height']?.toString() ?? '';
    final weight = playerData['weight']?.toString() ?? '';
    final matchesPlayed = playerData['matches_played']?.toString() ?? '0';
    final goals = playerData['goals']?.toString() ?? '0';
    final blocks = playerData['blocks']?.toString() ?? '0';
    final wins = playerData['wins']?.toString() ?? '0';
    final assists = playerData['assists']?.toString() ?? '0';
    final top3 = playerData['top_3']?.toString() ?? '0';
    final firstPlaces = playerData['first_places']?.toString() ?? '0';

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        systemOverlayStyle: const SystemUiOverlayStyle(statusBarBrightness: Brightness.dark),
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
            child: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 16),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.3), shape: BoxShape.circle),
              child: const Icon(Icons.share, color: Colors.white, size: 16),
            ),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- HERO HEADER ---
            SizedBox(
              height: 460,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  // Background gradient
                  Container(decoration: const BoxDecoration(gradient: AppColors.heroNavy)),

                  // Watermark text
                  Positioned(
                    top: 100,
                    left: -20,
                    right: -20,
                    child: Text(
                      (team.isNotEmpty ? team : lastName).toUpperCase(),
                      style: AppText.dispScore(110).copyWith(
                        color: Colors.white.withOpacity(0.04),
                        letterSpacing: -4,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                      textAlign: TextAlign.center,
                    ),
                  ),

                  // Player image
                  if (imageUrl.isNotEmpty)
                    Positioned(
                      bottom: 60,
                      left: 0,
                      right: 0,
                      child: Image.network(
                        imageUrl,
                        height: 360,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),

                  // Player info (top left)
                  Positioned(
                    top: 100,
                    left: AppTheme.pageHPad,
                    right: AppTheme.pageHPad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (jerseyNumber.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.coral,
                                  borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                                ),
                                child: Text(jerseyNumber, style: AppText.monoSmLight),
                              ),
                            const SizedBox(width: 8),
                            Text(team.toUpperCase(), style: AppText.monoSmLight),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(fullName, style: AppText.dispH1(30).copyWith(color: Colors.white)),
                        const SizedBox(height: 4),
                        Text(position.toUpperCase(), style: AppText.monoSmLight),
                      ],
                    ),
                  ),

                  // Floating stat card
                  Positioned(
                    bottom: 0,
                    left: AppTheme.pageHPad,
                    right: AppTheme.pageHPad,
                    child: Container(
                      padding: const EdgeInsets.symmetric(vertical: 18, horizontal: AppTheme.cardPad),
                      decoration: BoxDecoration(
                        color: AppColors.sand0,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        boxShadow: AppTheme.shadowLg,
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTopStat('Kamper', matchesPlayed),
                          Container(width: 1, height: 36, color: AppColors.line),
                          _buildTopStat('Poeng', goals),
                          Container(width: 1, height: 36, color: AppColors.line),
                          _buildTopStat('Blokker', blocks),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: AppTheme.sectionGap),

            // --- DETAILS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionKicker('Statistikk'),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 18, horizontal: AppTheme.cardPad),
                    decoration: BoxDecoration(
                      color: AppColors.sand0,
                      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                      boxShadow: AppTheme.shadowSm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailedStat(wins, 'Seiere', AppColors.ink),
                        _buildDetailedStat(assists, 'Assists', AppColors.ink),
                        _buildDetailedStat(top3, 'Topp 3', AppColors.ink),
                        _buildDetailedStat(firstPlaces, '1. Plass', Colors.amber.shade700),
                      ],
                    ),
                  ),

                  if (height.isNotEmpty || weight.isNotEmpty || birthDate.isNotEmpty || nationality.isNotEmpty) ...[
                    const SizedBox(height: AppTheme.sectionGap),
                    _buildSectionKicker('Profil'),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: AppColors.sand0,
                        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                        boxShadow: AppTheme.shadowSm,
                      ),
                      child: Column(
                        children: [
                          if (height.isNotEmpty) _buildListTile('Høyde', '$height cm'),
                          if (weight.isNotEmpty) ...[const Divider(height: 1), _buildListTile('Vekt', '$weight kg')],
                          if (birthDate.isNotEmpty) ...[const Divider(height: 1), _buildListTile('Født', birthDate)],
                          if (nationality.isNotEmpty) ...[const Divider(height: 1), _buildListTile('Nasjonalitet', nationality)],
                        ],
                      ),
                    ),
                  ],

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSectionKicker(String label) {
    return Row(
      children: [
        Container(width: 14, height: 3, decoration: BoxDecoration(color: AppColors.coral, borderRadius: BorderRadius.circular(2))),
        const SizedBox(width: 8),
        Text(label.toUpperCase(), style: AppText.dispKicker()),
      ],
    );
  }

  Widget _buildTopStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(label, style: AppText.monoSm),
        const SizedBox(height: 6),
        Text(value, style: AppText.dispScore(26)),
      ],
    );
  }

  Widget _buildDetailedStat(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(value, style: AppText.dispH2(22).copyWith(color: valueColor)),
        const SizedBox(height: 4),
        Text(label, style: AppText.monoSm, textAlign: TextAlign.center),
      ],
    );
  }

  Widget _buildListTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPad, vertical: 14),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title, style: AppText.uiCaption),
          Text(value, style: AppText.uiTitle),
        ],
      ),
    );
  }
}
