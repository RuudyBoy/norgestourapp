import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:norges_tour_app/theme/app_colors.dart';

/// SpikeDunk · Norges Tour — Typography scale
///
/// Three families:
///   • [AppText.disp]   Saira Condensed — broadcast headlines, scores, wordmark
///   • [AppText.ui]     Schibsted Grotesk — body copy, labels, buttons
///   • [AppText.mono]   IBM Plex Mono — data labels, seed #, timer
///
/// Naming: [family][Weight][size?]
/// e.g.  AppText.dispBlack(36)   AppText.uiSemiBold   AppText.monoMd
class AppText {
  AppText._();

  // ── Saira Condensed (Disp) ────────────────────────────────────

  /// Broadcast score / hero headline — 42 pt italic black
  static TextStyle dispScore([double size = 42]) => GoogleFonts.saira(
    fontWeight: FontWeight.w900, fontStyle: FontStyle.italic,
    fontSize: size, color: AppColors.ink, letterSpacing: -0.5, height: 0.88,
  );

  /// Sidetittel / stor overskrift — 30 pt kursiv black
  static TextStyle dispH1([double size = 30]) => GoogleFonts.saira(
    fontWeight: FontWeight.w900, fontStyle: FontStyle.italic,
    fontSize: size, color: AppColors.ink, letterSpacing: 0.2, height: 0.95,
  );

  /// Kortoverskrift / turneringsnavn — 22 pt kursiv bold
  static TextStyle dispH2([double size = 22]) => GoogleFonts.saira(
    fontWeight: FontWeight.w800, fontStyle: FontStyle.italic,
    fontSize: size, color: AppColors.ink, letterSpacing: 0.15, height: 1.0,
  );

  /// Seksjonskicker over overskrifter — 15 pt kursiv extrabold, STORE BOKSTAVER
  static TextStyle dispKicker([double size = 15]) => GoogleFonts.saira(
    fontWeight: FontWeight.w800, fontStyle: FontStyle.italic,
    fontSize: size, color: AppColors.ink, letterSpacing: 0.3,
  );

  // ── Schibsted Grotesk (UI) ────────────────────────────────────

  /// Primary body — 14 pt medium
  static TextStyle uiBody = GoogleFonts.schibstedGrotesk(
    fontWeight: FontWeight.w500, fontSize: 14, color: AppColors.ink, height: 1.45,
  );

  /// Compact sub-label / caption — 12 pt regular
  static TextStyle uiCaption = GoogleFonts.schibstedGrotesk(
    fontWeight: FontWeight.w400, fontSize: 12, color: AppColors.ink2, height: 1.3,
  );

  /// Radtittel — 14 pt semibold
  static TextStyle uiTitle = GoogleFonts.schibstedGrotesk(
    fontWeight: FontWeight.w600, fontSize: 14, color: AppColors.ink, height: 1.2,
  );

  /// Knappetekst / CTA — 15 pt extrabold
  static TextStyle uiCta = GoogleFonts.schibstedGrotesk(
    fontWeight: FontWeight.w800, fontSize: 15, color: Colors.white, letterSpacing: 0.1,
  );

  /// Tab bar label — 10.5 pt bold
  static TextStyle uiTab = GoogleFonts.schibstedGrotesk(
    fontWeight: FontWeight.w700, fontSize: 10.5, color: AppColors.ink2,
  );

  // ── IBM Plex Mono (data / label) ──────────────────────────────

  /// Tiny ALL-CAPS data label (kicker, court, seed) — 9.5 pt
  static TextStyle monoSm = GoogleFonts.ibmPlexMono(
    fontWeight: FontWeight.w500, fontSize: 9.5, letterSpacing: 1.3, color: AppColors.ink3,
  );

  /// Mid-size data (score set, time) — 12 pt
  static TextStyle monoMd = GoogleFonts.ibmPlexMono(
    fontWeight: FontWeight.w500, fontSize: 12, letterSpacing: 0.8, color: AppColors.ink2,
  );

  /// On-dark variant
  static TextStyle monoSmLight = GoogleFonts.ibmPlexMono(
    fontWeight: FontWeight.w500, fontSize: 9.5, letterSpacing: 1.3,
    color: Colors.white.withValues(alpha: 0.75),
  );
}
