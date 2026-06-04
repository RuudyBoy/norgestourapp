import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class SeasonHeroWidget extends StatelessWidget {
  final String title;
  final String description;

  const SeasonHeroWidget({
    super.key,
    required this.title,
    required this.description,
  });

  @override
  Widget build(BuildContext context) {
    // Gjør banneret litt mindre i høyden (ca 20% av skjermhøyden)
    final height = MediaQuery.of(context).size.height * 0.20;

    return Container(
      width: double.infinity,
      height: height,
      decoration: const BoxDecoration(
        image: DecorationImage(
          image: AssetImage('assets/images/ntbanner.png'),
          fit: BoxFit.cover,
          alignment: Alignment.center,
        ),
      ),
      child: Stack(
        children: [
          // Gradient slik at teksten alltid er lesbar uansett bilde
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.0),
                    Colors.black.withValues(alpha: 0.6),
                  ],
                  stops: const [0.4, 1.0],
                ),
              ),
            ),
          ),
          // Tekst nederst i banneret
          Positioned(
            left: 20,
            right: 20,
            bottom: 30,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  title,
                  style: AppText.dispH1(36).copyWith(
                    color: Colors.white,
                    height: 1.1,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  description,
                  style: AppText.uiBody.copyWith(
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
