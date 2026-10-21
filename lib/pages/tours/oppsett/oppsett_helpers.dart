part of 'oppsett_page.dart';

// Hjelpere for Oppsett-fanen: rundenavn, fargepalett og oppslag av lag i kamper.

// ─────────────────────────────────────────────────────────────────────────────
// Runder i sluttspill — rekkefølge og etiketter (samme nøkler som admin)
// Runder som ikke finnes i turneringen vises aldri.
// ─────────────────────────────────────────────────────────────────────────────
const _roundTab = {
  'omspill': 'Playoff',
  'r16': '1/16',
  'r8': '1/8',
  'qf': 'Kvartfinale',
  'sf': 'Semifinale',
  'bronze': 'Bronse',
  'final': 'Finale',
};

// Etikett på "neste kamp"-kortet: "SEMI 1"
const _roundNext = {
  'omspill': 'PLAYOFF',
  'r16': '1/16',
  'r8': '1/8',
  'qf': 'KF',
  'sf': 'SEMI',
  'bronze': 'BRONSE',
  'final': 'FINALE',
};

int _roundIndex(String r) {
  final i = ntRoundOrder.indexOf(r);
  return i == -1 ? 99 : i;
}

// ─────────────────────────────────────────────────────────────────────────────
// Palett (lys / mørk)
// ─────────────────────────────────────────────────────────────────────────────
class _P {
  final bool dark;
  const _P(this.dark);

  Color get card => dark ? AppColors.nightSurface0 : AppColors.sand0;
  Color get strip => dark
      ? AppColors.nightSurface2
      : Color.lerp(AppColors.sand1, AppColors.sand2, 0.65)!;
  Color get ink => dark ? AppColors.nightInk : AppColors.ink;
  Color get ink2 => dark ? AppColors.nightInk2 : AppColors.ink2;
  Color get ink3 => dark ? AppColors.nightInk3 : AppColors.ink3;
  Color get line => dark ? Colors.white12 : AppColors.line;
  Color get green => dark ? AppColors.greenBright : AppColors.green;
  Color get greenTint => AppColors.greenLight;
  Color get selectedDark => dark ? AppColors.coral : AppColors.ink;
}

// ─────────────────────────────────────────────────────────────────────────────
// Hjelpere for kampdata
// ─────────────────────────────────────────────────────────────────────────────
String _placeName(int place, String group) {
  switch (place) {
    case 1:
      return 'Vinner pulje $group';
    case 2:
      return 'Toer pulje $group';
    case 3:
      return 'Treer pulje $group';
    case 4:
      return 'Firer pulje $group';
    default:
      return '$place. plass pulje $group';
  }
}

String _courtLabel(dynamic court) {
  final c = court?.toString().trim() ?? '';
  if (c.isEmpty || c.toUpperCase() == 'TBD') return '';
  if (int.tryParse(c) != null) return 'BANE $c';
  return c.toUpperCase();
}

/// Slår opp navn på et lag-slot. Returnerer (navn, erPlassholder, seedLabel).
class _Slot {
  final String name;
  final bool placeholder;
  final String? seed;
  const _Slot(this.name, this.placeholder, this.seed);
}

class _Ctx {
  final Map<String, _Doc> byId;
  _Ctx(List<_Doc> all) : byId = {for (final m in all) m.id: m};

  /// "KF 1", "SF 2", "FINALE" for en sluttspillkamp
  String playoffLabel(Map<String, dynamic> d, {bool next = false}) {
    final round = d['round'] as String? ?? '';
    final bracket = d['bracket'];
    final same = byId.values.where((m) {
      final x = m.data();
      return x['stage'] == 'playoff' &&
          x['bracket'] == bracket &&
          x['round'] == round;
    }).toList()
      ..sort((a, b) => ((a.data()['match_number'] as num?) ?? 0)
          .compareTo((b.data()['match_number'] as num?) ?? 0));
    final base = (next ? _roundNext : ntRoundShort)[round] ?? round.toUpperCase();
    if (same.length <= 1) return base;
    final idx = same.indexWhere((m) => m.data()['match_number'] == d['match_number']);
    return '$base ${idx + 1}';
  }

  _Slot slot(Map<String, dynamic> d, String p) {
    final seed = (d['${p}_from_group'] != null && d['${p}_from_place'] != null)
        ? '${d['${p}_from_group']}${d['${p}_from_place']}'
        : null;
    final id = d['${p}_id'];
    final name = (d['${p}_name'] as String?)?.trim() ?? '';

    if (!ntIsPlaceholderId(id) && name.isNotEmpty) {
      return _Slot(name, false, seed);
    }
    final fromGroup = d['${p}_from_group'];
    final fromPlace = (d['${p}_from_place'] as num?)?.toInt();
    if (fromGroup != null && fromPlace != null) {
      return _Slot(_placeName(fromPlace, fromGroup.toString()), true, seed);
    }
    final fromMatch = d['${p}_from_match_id'] as String?;
    if (fromMatch != null && byId[fromMatch] != null) {
      final src = byId[fromMatch]!.data();
      final isWinner = (d['${p}_from_slot'] ?? 'winner') == 'winner';
      final String srcLabel;
      if (src['stage'] == 'playoff') {
        srcLabel = playoffLabel(src);
      } else if (src['match_number'] != null) {
        srcLabel = 'kamp ${src['match_number']}';
      } else {
        srcLabel = (src['match_type'] as String?)?.toLowerCase() ?? 'kamp';
      }
      return _Slot('${isWinner ? 'Vinner' : 'Taper'} $srcLabel', true, seed);
    }
    if (name.isNotEmpty && name.toUpperCase() != 'TBD') {
      return _Slot(name, true, seed);
    }
    return _Slot('TBD', true, seed);
  }
}


void _openStats(BuildContext context, String id, String a, String b) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MatchStatsPage(matchId: id, teamAName: a, teamBName: b),
    ),
  );
}
