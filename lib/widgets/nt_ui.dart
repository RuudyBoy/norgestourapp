import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

// ─────────────────────────────────────────────────────────────────────────────
// Felles UI-byggesteiner og kamp-hjelpere for Norges Tour-appen.
// Brukes av hjemmesiden, turneringssiden og Kamper-fanen.
// ─────────────────────────────────────────────────────────────────────────────

/// Palett for lys / mørk modus.
class NtPalette {
  final bool dark;
  const NtPalette(this.dark);

  factory NtPalette.of(BuildContext context) =>
      NtPalette(Theme.of(context).brightness == Brightness.dark);

  Color get card => dark ? AppColors.nightSurface0 : AppColors.sand0;
  Color get soft => dark ? AppColors.nightSurface2 : AppColors.sand1;
  Color get segBg => dark ? AppColors.nightSurface2 : AppColors.sand2;
  Color get ink => dark ? AppColors.nightInk : AppColors.ink;
  Color get ink2 => dark ? AppColors.nightInk2 : AppColors.ink2;
  Color get ink3 => dark ? AppColors.nightInk3 : AppColors.ink3;
  Color get line => dark ? Colors.white12 : AppColors.line;
  Color get green => dark ? AppColors.greenBright : AppColors.green;
  Color get selectedDark => dark ? AppColors.coral : AppColors.ink;
}

// ── Seksjonsoverskrift: "— LIVE NÅ" ─────────────────────────────────────────
class NtSectionHeader extends StatelessWidget {
  final String title;
  final Widget? trailing;
  const NtSectionHeader({super.key, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return Row(children: [
      Container(width: 18, height: 3, color: AppColors.coral),
      const SizedBox(width: 12),
      Expanded(
        child: Text(title.toUpperCase(),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.dispKicker(18).copyWith(color: p.ink)),
      ),
      if (trailing != null) trailing!,
    ]);
  }
}

// ── LIVE-merke ───────────────────────────────────────────────────────────────
class NtLivePill extends StatelessWidget {
  final String text;
  final bool dot;
  const NtLivePill({super.key, this.text = 'LIVE', this.dot = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: AppColors.coral,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        if (dot) ...[
          Container(
            width: 5,
            height: 5,
            decoration: const BoxDecoration(color: AppColors.ink, shape: BoxShape.circle),
          ),
          const SizedBox(width: 7),
        ],
        Text(text,
            style: AppText.monoSm.copyWith(
                color: AppColors.ink, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
      ]),
    );
  }
}

// ── Segmentvelger: [Menn | Damer] ────────────────────────────────────────────
class NtSegmented extends StatelessWidget {
  final List<String> labels;
  final int selected;
  final bool darkSelected;
  final ValueChanged<int> onTap;

  const NtSegmented({
    super.key,
    required this.labels,
    required this.selected,
    required this.onTap,
    this.darkSelected = true,
  });

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return Container(
      height: 54,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.segBg,
        borderRadius: BorderRadius.circular(AppTheme.radiusRow),
      ),
      child: Row(children: [
        for (var i = 0; i < labels.length; i++)
          Expanded(
            child: GestureDetector(
              behavior: HitTestBehavior.opaque,
              onTap: () => onTap(i),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: i == selected
                      ? (darkSelected ? p.selectedDark : p.card)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: i == selected && !darkSelected ? AppTheme.shadowSm : null,
                ),
                child: Text(
                  labels[i],
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.uiCta.copyWith(
                    fontSize: 16,
                    fontWeight: i == selected ? FontWeight.w800 : FontWeight.w500,
                    color: i == selected && darkSelected ? Colors.white : p.ink,
                  ),
                ),
              ),
            ),
          ),
      ]),
    );
  }
}

// ── Pille-filter: (Alle) (Live · 3) ─────────────────────────────────────────
class NtFilterChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  const NtFilterChip({super.key, required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        height: 46,
        padding: const EdgeInsets.symmetric(horizontal: 18),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: selected ? AppColors.coral : p.card,
          borderRadius: BorderRadius.circular(AppTheme.radiusChip),
        ),
        child: Text(label,
            style: AppText.uiCta.copyWith(
                fontSize: 16, fontWeight: FontWeight.w700, color: selected ? AppColors.ink : p.ink)),
      ),
    );
  }
}

// ── Kort ─────────────────────────────────────────────────────────────────────
class NtCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  const NtCard({super.key, required this.child, this.padding});

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return Container(
      padding: padding,
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowSm,
      ),
      child: child,
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kamp-hjelpere (samme datamodell som admin)
// ─────────────────────────────────────────────────────────────────────────────
const ntRoundOrder = ['omspill', 'r16', 'r8', 'qf', 'sf', 'bronze', 'final'];

const ntRoundShort = {
  'omspill': 'PO',
  'r16': '1/16',
  'r8': '1/8',
  'qf': 'KF',
  'sf': 'SF',
  'bronze': 'BRONSE',
  'final': 'FINALE',
};

bool ntIsPlaceholderId(dynamic id) =>
    id == null || id == 'placeholder' || (id is String && id.isEmpty);

bool ntIsUpcoming(Map<String, dynamic> d) {
  final s = d['status'];
  return s != 'live' && s != 'finished';
}

String ntMatchTime(Map<String, dynamic> d) =>
    (d['match_time'] ?? d['start_time'])?.toString() ?? '';

/// Vunne sett (live og ferdig).
(int, int) ntSets(Map<String, dynamic> d) {
  final hs = (d['home_sets'] as num?)?.toInt() ?? 0;
  final as_ = (d['away_sets'] as num?)?.toInt() ?? 0;
  if (hs + as_ > 0) return (hs, as_);
  if (d['status'] == 'finished') {
    return ((d['home_score'] as num?)?.toInt() ?? 0, (d['away_score'] as num?)?.toInt() ?? 0);
  }
  return (0, 0);
}

/// Poeng i settet som pågår (live).
(int, int) ntLivePoints(Map<String, dynamic> d) => (
      (d['home_score'] as num?)?.toInt() ?? 0,
      (d['away_score'] as num?)?.toInt() ?? 0,
    );

/// "21-17 · 21-15"
String ntSetScores(Map<String, dynamic> d) {
  final past = d['past_sets'];
  if (past is! List || past.isEmpty) return '';
  return past.whereType<Map>().map((s) => '${s['home'] ?? 0}-${s['away'] ?? 0}').join(' · ');
}

/// "Bane 3" / "3" -> "3". Tom streng hvis ukjent.
String ntCourtNumber(dynamic court) {
  final c = court?.toString().trim() ?? '';
  if (c.isEmpty || c.toUpperCase() == 'TBD') return '';
  final m = RegExp(r'\d+').firstMatch(c);
  return m?.group(0) ?? c;
}

String ntPlaceName(int place, String group) {
  switch (place) {
    case 1:
      return 'Vinner pulje $group';
    case 2:
      return 'Toer pulje $group';
    case 3:
      return '3. plass pulje $group';
    case 4:
      return '4. plass pulje $group';
    default:
      return '$place. plass pulje $group';
  }
}

class NtSlot {
  final String name;
  final bool placeholder;
  const NtSlot(this.name, this.placeholder);
}

/// Oppslag på tvers av kampene i en turnering/klasse.
class NtMatchCtx {
  final Map<String, Map<String, dynamic>> byId;
  NtMatchCtx(Map<String, Map<String, dynamic>> matches) : byId = matches;

  /// "KF 1", "SF 2", "FINALE"
  String playoffLabel(Map<String, dynamic> d) {
    final round = d['round'] as String? ?? '';
    final same = byId.values
        .where((x) =>
            x['stage'] == 'playoff' && x['bracket'] == d['bracket'] && x['round'] == round)
        .toList()
      ..sort((a, b) =>
          ((a['match_number'] as num?) ?? 0).compareTo((b['match_number'] as num?) ?? 0));
    final base = ntRoundShort[round] ?? round.toUpperCase();
    if (same.length <= 1) return base;
    final idx = same.indexWhere((x) => x['match_number'] == d['match_number']);
    return '$base ${idx + 1}';
  }

  /// "PULJE A", "PULJE A · VINNERKAMP", "SLUTTSPILL A · KF 1"
  String stageLabel(Map<String, dynamic> d) {
    if (d['stage'] == 'group') {
      final g = d['group']?.toString();
      final base = g != null ? 'PULJE $g' : 'PULJESPILL';
      final sa = d['team_a_from_slot'], sb = d['team_b_from_slot'];
      if (sa != null && sa == sb) {
        return '$base · ${sa == 'winner' ? 'VINNERKAMP' : 'TAPERKAMP'}';
      }
      return base;
    }
    if (d['stage'] == 'playoff') {
      final b = (d['bracket'] ?? '').toString().toUpperCase();
      return 'SLUTTSPILL $b · ${playoffLabel(d)}'.replaceAll('  ', ' ');
    }
    return '';
  }

  NtSlot slot(Map<String, dynamic> d, String p) {
    final id = d['${p}_id'];
    final name = (d['${p}_name'] as String?)?.trim() ?? '';
    if (!ntIsPlaceholderId(id) && name.isNotEmpty) return NtSlot(name, false);

    final fromGroup = d['${p}_from_group'];
    final fromPlace = (d['${p}_from_place'] as num?)?.toInt();
    if (fromGroup != null && fromPlace != null) {
      return NtSlot(ntPlaceName(fromPlace, fromGroup.toString()), true);
    }
    final fromMatch = d['${p}_from_match_id'] as String?;
    final src = fromMatch != null ? byId[fromMatch] : null;
    if (src != null) {
      final isWinner = (d['${p}_from_slot'] ?? 'winner') == 'winner';
      final String srcLabel;
      if (src['stage'] == 'playoff') {
        srcLabel = playoffLabel(src);
      } else if (src['match_number'] != null) {
        srcLabel = 'kamp ${src['match_number']}';
      } else {
        srcLabel = ntMatchTime(src).isNotEmpty ? 'kampen ${ntMatchTime(src)}' : 'kamp';
      }
      return NtSlot('${isWinner ? 'Vinner' : 'Taper'} $srcLabel', true);
    }
    if (name.isNotEmpty && name.toUpperCase() != 'TBD') return NtSlot(name, true);
    return const NtSlot('TBD', true);
  }
}

/// "14.11.2026" -> DateTime (med valgfri "09:00").
DateTime? ntParseDate(dynamic date, [dynamic time]) {
  final s = date?.toString().trim() ?? '';
  final parts = s.split('.');
  if (parts.length != 3) return null;
  final d = int.tryParse(parts[0]), m = int.tryParse(parts[1]), y = int.tryParse(parts[2]);
  if (d == null || m == null || y == null) return null;
  var h = 0, min = 0;
  final t = time?.toString().split(':');
  if (t != null && t.length >= 2) {
    h = int.tryParse(t[0]) ?? 0;
    min = int.tryParse(t[1]) ?? 0;
  }
  return DateTime(y, m, d, h, min);
}

/// "14.11.2026" eller "14.–15.11.2026"
String ntDateRange(Map<String, dynamic> t) {
  final start = t['start_date']?.toString() ?? '';
  final end = t['end_date']?.toString() ?? '';
  if (start.isEmpty) return '';
  if (end.isEmpty || end == start) return start;
  final s = ntParseDate(start), e = ntParseDate(end);
  if (s != null && e != null && s.month == e.month && s.year == e.year) {
    return '${s.day}.–$end';
  }
  return '$start – $end';
}

/// Påmelding fra appen. Sett til true når påmeldingssystemet er klart —
/// da kobles «Meld på» og «Se påmeldte» på hjemmesiden til ekte funksjon.
const bool kRegistrationEnabled = false;

/// Samme regel som turneringssiden: påmelding åpen og frist ikke passert.
bool ntRegistrationOpen(Map<String, dynamic> t) {
  if (t['registration_status'] != 'open') return false;
  final deadline = t['registration_deadline'];
  if (deadline == null) return true;
  final d = ntParseDate(deadline);
  if (d == null) return false;
  return DateTime.now().isBefore(DateTime(d.year, d.month, d.day, 23, 59));
}
