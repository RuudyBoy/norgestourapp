import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class SplashPage extends StatefulWidget {
  final VoidCallback onGetStarted;

  const SplashPage({super.key, required this.onGetStarted});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;
  late Animation<double> _fade;
  late Animation<Offset> _slide;
  late Animation<double> _playerFade;
  late Animation<Offset> _playerSlide;

  @override
  void initState() {
    super.initState();

    SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ));

    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1100),
    );

    _playerFade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.6, curve: Curves.easeOut),
    );
    _playerSlide = Tween<Offset>(
      begin: const Offset(0.12, 0),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.0, 0.7, curve: Curves.easeOutCubic),
    ));

    _fade = CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 0.85, curve: Curves.easeOut),
    );
    _slide = Tween<Offset>(
      begin: const Offset(0, 0.25),
      end: Offset.zero,
    ).animate(CurvedAnimation(
      parent: _ctrl,
      curve: const Interval(0.35, 0.9, curve: Curves.easeOutCubic),
    ));

    Future.delayed(const Duration(milliseconds: 150), () {
      if (mounted) _ctrl.forward();
    });
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          children: [
            // ── Background image ─────────────────────────────────────
            Positioned.fill(
              child: Image.asset(
                'assets/images/hero_card_bg.png',
                fit: BoxFit.cover,
              ),
            ),

          // ── Dark overlay removed per user request ────────────────

          // ── Player cutout image ──────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SlideTransition(
              position: _playerSlide,
              child: FadeTransition(
                opacity: _playerFade,
                child: SizedBox(
                  height: size.height * 1.0,
                  child: Image.asset(
                    'assets/images/2.png',
                    fit: BoxFit.contain,
                    alignment: Alignment.bottomCenter,
                  ),
                ),
              ),
            ),
          ),

          // ── Bottom fade to blend player into content ─────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              height: size.height * 0.42,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.transparent,
                    Color(0xFF0B1220).withValues(alpha: 0.6),
                    Color(0xFF0B1220).withValues(alpha: 0.85),
                    Color(0xFF0B1220),
                  ],
                  stops: const [0.0, 0.28, 0.52, 1.0],
                ),
              ),
            ),
          ),

          // ── NT Logo top ──────────────────────────────────────────
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppTheme.pageHPad,
                vertical: 18,
              ),
              child: const SizedBox(height: 48),
            ),
          ),

          // ── Bottom content ───────────────────────────────────────
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: SafeArea(
              top: false,
              child: FadeTransition(
                opacity: _fade,
                child: SlideTransition(
                  position: _slide,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppTheme.pageHPad,
                      0,
                      AppTheme.pageHPad,
                      36,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Badge
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius:
                                BorderRadius.circular(AppTheme.radiusBadge),
                          ),
                          child: Text(
                            'NORGES TOUR 2026',
                            style: AppText.monoSm.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 10),

                        // Headline
                        Text(
                          'VELG DINE\nSPILLERE.\nBYGG LAGET\nDITT.',
                          style: AppText.dispH1(32).copyWith(
                            color: Colors.white,
                            height: 1.02,
                          ),
                        ),
                        const SizedBox(height: 28),

                        // CTA button
                        SizedBox(
                          width: double.infinity,
                          height: 54,
                          child: ElevatedButton(
                            onPressed: widget.onGetStarted,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.coral,
                              elevation: 0,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(
                                    AppTheme.radiusButton),
                              ),
                            ),
                            child: Text(
                              'Kom i gang!',
                              style: AppText.uiCta.copyWith(
                                color: Colors.white,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
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
