import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'profile_avatar_widget.dart';

class SeasonHeroSliver extends StatelessWidget {
  final String pageTitle;
  final String title;
  final String description;
  final String heroImage;
  final String? actionImage;
  final Widget? actionWidget;

  const SeasonHeroSliver({
    super.key,
    required this.pageTitle,
    this.title = 'NT',
    required this.description,
    this.heroImage = 'assets/images/hero_bg.jpg', // Standard bakgrunn
    this.actionImage, // Endret til null som standard
    this.actionWidget = const ProfileAvatarWidget(),
  });

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      expandedHeight: 340, // Litt ekstra høyde for å få plass til tittel + badge
      pinned: true,
      backgroundColor: AppColors.sand1,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: true,
      title: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Logo fjernet inntil ny er på plass
          const SizedBox(height: 12),
          Text(
            'NT | ${pageTitle.toUpperCase()}',
            style: AppText.monoSm.copyWith(
              color: AppColors.ink, // Endret til mørk farge i tilfelle bildet er lyst i toppen
              fontSize: 10,
              letterSpacing: 1.0,
            ),
          ),
        ],
      ),
      actions: actionWidget != null ? [actionWidget!] : null,
      flexibleSpace: FlexibleSpaceBar(
        background: Stack(
          fit: StackFit.expand,
          children: [
            // ── Background Action Image ─────────────────────────────
            Image.asset(
              heroImage,
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
            ),
            
            // ── Gradient Overlay ──────────────────────────────────────
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    AppColors.sand1.withOpacity(0.4), // Lysere i toppen så logo synes, men bildet ikke forsvinner i svart
                    Colors.transparent,
                    Colors.transparent,
                    AppColors.sand1, // Fader pent inn i bakgrunnen nederst
                  ],
                  stops: const [0.0, 0.25, 0.65, 1.0],
                ),
              ),
            ),
            
            // ── Text Content ──────────────────────────────────────────
            Positioned(
              left: AppTheme.pageHPad,
              bottom: 40, // Gjør plass til overlap-kortet
              right: AppTheme.pageHPad,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Badge "SESONGEN 2026"
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: AppColors.coral.withOpacity(0.9), // Gjorde den litt tydeligere
                      borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                    ),
                    child: Text(
                      'SESONGEN 2026',
                      style: AppText.monoSm.copyWith(
                        color: Colors.white,
                        letterSpacing: 1.2,
                        fontSize: 8.5,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),

                  // Store Tittelen (NT, TOURS, STATS etc)
                  Text(
                    title,
                    style: AppText.dispH1(42).copyWith(
                      color: AppColors.ink,
                      height: 0.95,
                    ),
                  ),
                  const SizedBox(height: 4),

                  // Description
                  Text(
                    description,
                    style: AppText.dispH2(20).copyWith(
                      color: AppColors.ink.withOpacity(0.8),
                      height: 1.1,
                    ),
                  ),
                ],
              ),
            ),
            
            // ── Foreground Player Cutout ──────────────────────────────
            if (actionImage != null)
              Positioned(
                right: -10, // Litt utenfor kanten for dynamikk
                bottom: 0, // Kuttet står flatt på bunnen
                height: 320, // Størrelsen på spilleren
                child: Image.asset(
                  actionImage!,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                ),
              ),
          ],
        ),
      ),
    );
  }
}
