import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class SeasonHeroWidget extends StatelessWidget {
  final String title;
  final String description;
  final String playerImage;

  const SeasonHeroWidget({
    super.key,
    required this.title,
    required this.description,
    this.playerImage = 'assets/images/1.png',
  });

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final screenW = mq.size.width;
    final screenH = mq.size.height;
    // Tall enough to peek behind the transparent AppBar (status + toolbar)
    final height = screenH * 0.28;
    return SizedBox(
      width: double.infinity,
      height: height,
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // ── Background image ─────────────────────────────────────
          Positioned.fill(
            child: Image.asset(
              'assets/images/bakgrunn.png',
              fit: BoxFit.cover,
            ),
          ),

          // ── Dark overlay for text readability ────────────────────
          Positioned.fill(
            child: Container(
              color: Colors.black.withValues(alpha: 0.35),
            ),
          ),

          // ── Player cutout — right side ───────────────────────────
          // Fix: give explicit width AND height so the image can render
          Positioned(
            right: 0,
            bottom: 0,
            width: screenW * 0.46,
            height: height * 1.18,
            child: Image.asset(
              playerImage,
              fit: BoxFit.contain,
              alignment: Alignment.bottomRight,
            ),
          ),

          // ── Left-to-right fade so text is always readable ────────
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            width: screenW * 0.65,
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    Colors.black.withValues(alpha: 0.15),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),

          // ── Coral left accent bar ────────────────────────────────
          Positioned(
            left: 0,
            top: 0,
            bottom: 0,
            child: Container(width: 3, color: AppColors.coral),
          ),

          // ── Text content ─────────────────────────────────────────
          Positioned(
            left: AppTheme.pageHPad + 3,
            right: screenW * 0.42,
            bottom: 20,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Season kicker badge
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.coral.withValues(alpha: 0.25),
                    borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                    border: Border.all(
                      color: AppColors.coral.withValues(alpha: 0.5),
                    ),
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
                const SizedBox(height: 6),

                // Title
                Text(
                  title,
                  style: AppText.dispH1(38).copyWith(
                    color: Colors.white,
                    height: 0.95,
                  ),
                ),
                const SizedBox(height: 5),

                // Description
                Text(
                  description,
                  style: AppText.uiCaption.copyWith(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 11,
                    height: 1.35,
                  ),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),

          // ── Subtle bottom divider ────────────────────────────────
          Positioned(
            left: 0,
            right: 0,
            bottom: 0,
            child: Container(
              height: 1,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.coral.withValues(alpha: 0.6),
                    AppColors.blueBright.withValues(alpha: 0.3),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
