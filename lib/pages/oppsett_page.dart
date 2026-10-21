import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'match_stats_page.dart';
import '../widgets/nt_ui.dart';

typedef _Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

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

// ─────────────────────────────────────────────────────────────────────────────
// Side
// ─────────────────────────────────────────────────────────────────────────────
class OppsettPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final bool isEmbedded;

  const OppsettPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isEmbedded = false,
  });

  @override
  State<OppsettPage> createState() => _OppsettPageState();
}

class _OppsettPageState extends State<OppsettPage> {
  String? _categoryId;
  bool _showPlayoff = false;
  String? _group;
  String? _bracket;
  String? _round;

  @override
  Widget build(BuildContext context) {
    final p = _P(Theme.of(context).brightness == Brightness.dark);

    final content = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .where('tournament_id', isEqualTo: widget.tournamentId)
          .where('published', isEqualTo: true)
          .snapshots(),
      builder: (context, catSnap) {
        if (!catSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final cats = catSnap.data!.docs;
        if (cats.isEmpty) {
          return _Empty(p, 'Ingen klasser publisert ennå.');
        }
        final catId = cats.any((c) => c.id == _categoryId)
            ? _categoryId!
            : cats.first.id;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .where('tournament_id', isEqualTo: widget.tournamentId)
              .where('category_id', isEqualTo: catId)
              .snapshots(),
          builder: (context, matchSnap) {
            final matches = matchSnap.data?.docs ?? const <_Doc>[];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildControls(p, cats, catId),
                Expanded(
                  child: !matchSnap.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : _showPlayoff
                          ? _buildPlayoff(p, matches)
                          : _buildGroups(p, matches, catId),
                ),
              ],
            );
          },
        );
      },
    );

    if (widget.isEmbedded) return content;

    return Scaffold(
      appBar: AppBar(
        title: Text('Oppsett – ${widget.tournamentName}'),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  // ── Kontroller: Menn/Damer + Puljer/Sluttspill ───────────────────────────
  Widget _buildControls(_P p, List<_Doc> cats, String catId) {
    final catSeg = NtSegmented(
      labels: [for (final c in cats) (c.data()['name'] as String?) ?? 'Klasse'],
      selected: cats.indexWhere((c) => c.id == catId),
      darkSelected: true,
      onTap: (i) => setState(() {
        _categoryId = cats[i].id;
        _group = null;
        _bracket = null;
        _round = null;
      }),
    );
    final stageSeg = NtSegmented(
      labels: const ['Puljer', 'Sluttspill'],
      selected: _showPlayoff ? 1 : 0,
      darkSelected: false,
      onTap: (i) => setState(() => _showPlayoff = i == 1),
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 20, AppTheme.pageHPad, 0),
      child: cats.length <= 2
          ? Row(children: [
              Expanded(child: catSeg),
              const SizedBox(width: 12),
              Expanded(child: stageSeg),
            ])
          : Column(children: [catSeg, const SizedBox(height: 10), stageSeg]),
    );
  }

  // ── Puljer ───────────────────────────────────────────────────────────────
  Widget _buildGroups(_P p, List<_Doc> all, String catId) {
    final groupMatches =
        all.where((m) => m.data()['stage'] == 'group').toList();
    final groups = {
      for (final m in groupMatches)
        if (m.data()['group'] != null) m.data()['group'].toString()
    }.toList()
      ..sort();

    if (groups.isEmpty) {
      return _Empty(p, 'Puljene er ikke satt opp ennå.');
    }
    final group = groups.contains(_group) ? _group! : groups.first;

    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('tournament_id', isEqualTo: widget.tournamentId)
          .where('category_id', isEqualTo: catId)
          .snapshots(),
      builder: (context, teamSnap) {
        final teams = (teamSnap.data?.docs ?? const <_Doc>[])
            .where((t) => t.data()['group']?.toString() == group)
            .toList();
        return ListView(
          padding: const EdgeInsets.only(bottom: 32),
          children: [
            const SizedBox(height: 14),
            _GroupChips(
              p: p,
              groups: groups,
              selected: group,
              onTap: (g) => setState(() => _group = g),
            ),
            _GroupView(
              p: p,
              group: group,
              teams: teams,
              matches: groupMatches
                  .where((m) => m.data()['group']?.toString() == group)
                  .toList(),
              allMatches: all,
            ),
          ],
        );
      },
    );
  }

  // ── Sluttspill ───────────────────────────────────────────────────────────
  Widget _buildPlayoff(_P p, List<_Doc> all) {
    final playoff = all.where((m) => m.data()['stage'] == 'playoff').toList();
    final brackets = {
      for (final m in playoff) (m.data()['bracket'] ?? 'A').toString().toUpperCase()
    }.toList()
      ..sort();
    if (brackets.isEmpty) {
      return _Empty(p, 'Sluttspillet er ikke satt opp ennå.');
    }
    final bracket = brackets.contains(_bracket) ? _bracket! : brackets.first;
    final inBracket = playoff
        .where((m) =>
            (m.data()['bracket'] ?? 'A').toString().toUpperCase() == bracket)
        .toList();

    final rounds = {
      for (final m in inBracket) (m.data()['round'] as String?) ?? ''
    }.where((r) => r.isNotEmpty).toList()
      ..sort((a, b) => _roundIndex(a).compareTo(_roundIndex(b)));
    if (rounds.isEmpty) {
      return _Empty(p, 'Sluttspillet er ikke satt opp ennå.');
    }

    // Standard: første runde som ikke er ferdig spilt
    String defaultRound() {
      for (final r in rounds) {
        final ms = inBracket.where((m) => m.data()['round'] == r);
        if (ms.any((m) => m.data()['status'] != 'finished')) return r;
      }
      return rounds.last;
    }

    final round = rounds.contains(_round) ? _round! : defaultRound();
    final ctx = _Ctx(all);

    return ListView(
      padding: const EdgeInsets.only(bottom: 32),
      children: [
        const SizedBox(height: 14),
        _BracketChips(
          p: p,
          brackets: brackets,
          selected: bracket,
          onTap: (b) => setState(() {
            _bracket = b;
            _round = null;
          }),
        ),
        const SizedBox(height: 18),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
          child: _RoundTabs(
            p: p,
            rounds: rounds,
            selected: round,
            onTap: (r) => setState(() => _round = r),
          ),
        ),
        const SizedBox(height: 22),
        _RoundView(
          p: p,
          ctx: ctx,
          matches: inBracket.where((m) => m.data()['round'] == round).toList(),
          onOpenRound: (r) {
            if (rounds.contains(r)) setState(() => _round = r);
          },
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Puljevisning: tabell + kamper
// ─────────────────────────────────────────────────────────────────────────────
class _StandRow {
  final String id;
  final String name;
  final int seed;
  final int? placement;
  int played = 0, w = 0, l = 0, sw = 0, sl = 0;
  _StandRow(this.id, this.name, this.seed, this.placement);
}

class _GroupView extends StatelessWidget {
  final _P p;
  final String group;
  final List<_Doc> teams;
  final List<_Doc> matches;
  final List<_Doc> allMatches;

  const _GroupView({
    required this.p,
    required this.group,
    required this.teams,
    required this.matches,
    required this.allMatches,
  });

  List<_StandRow> _standings() {
    final rows = <String, _StandRow>{
      for (final t in teams)
        t.id: _StandRow(
          t.id,
          (t.data()['team_name'] as String?) ?? 'Lag',
          (t.data()['seed'] as num?)?.toInt() ?? 999,
          (t.data()['group_placement'] as num?)?.toInt(),
        ),
    };
    // Lag som finnes i kamper men ikke i teams-spørringen
    for (final m in matches) {
      final d = m.data();
      for (final pfx in ['team_a', 'team_b']) {
        final id = d['${pfx}_id'];
        if (ntIsPlaceholderId(id) || rows.containsKey(id)) continue;
        rows[id as String] =
            _StandRow(id, (d['${pfx}_name'] as String?) ?? 'Lag', 999, null);
      }
    }
    for (final m in matches) {
      final d = m.data();
      if (d['status'] != 'finished') continue;
      final a = rows[d['team_a_id']];
      final b = rows[d['team_b_id']];
      if (a == null || b == null) continue;
      final (hs, as_) = ntSets(d);
      a
        ..played += 1
        ..sw += hs
        ..sl += as_;
      b
        ..played += 1
        ..sw += as_
        ..sl += hs;
      if (hs > as_) {
        a.w++;
        b.l++;
      } else if (as_ > hs) {
        b.w++;
        a.l++;
      }
    }
    final list = rows.values.toList()
      ..sort((x, y) {
        final px = x.placement ?? 99, py = y.placement ?? 99;
        if (px != py) return px.compareTo(py);
        if (x.w != y.w) return y.w.compareTo(x.w);
        final dx = x.sw - x.sl, dy = y.sw - y.sl;
        if (dx != dy) return dy.compareTo(dx);
        if (x.sw != y.sw) return y.sw.compareTo(x.sw);
        return x.seed.compareTo(y.seed);
      });
    return list;
  }

  /// plass -> sluttspill (A/B/C), lest fra sluttspillkampenes plassholdere
  Map<int, String> _advancement() {
    final out = <int, String>{};
    for (final m in allMatches) {
      final d = m.data();
      if (d['stage'] != 'playoff') continue;
      for (final pfx in ['team_a', 'team_b']) {
        if (d['${pfx}_from_group']?.toString() != group) continue;
        final place = (d['${pfx}_from_place'] as num?)?.toInt();
        if (place == null) continue;
        out[place] = (d['bracket'] ?? 'A').toString().toUpperCase();
      }
    }
    return out;
  }

  @override
  Widget build(BuildContext context) {
    final rows = _standings();
    final adv = _advancement();
    final topBracket = adv.values.isEmpty
        ? null
        : (adv.values.toSet().toList()..sort()).first;
    final topPlaces = adv.entries
        .where((e) => e.value == topBracket)
        .map((e) => e.key)
        .toList()
      ..sort();
    final finished = matches.where((m) => m.data()['status'] == 'finished').length;

    // Legende: "Topp 2 går videre til sluttspill A · 3. plass til B …"
    final legendParts = <String>[];
    if (topBracket != null) {
      final contiguous = topPlaces.isNotEmpty &&
          topPlaces.first == 1 &&
          topPlaces.last == topPlaces.length;
      legendParts.add(contiguous && topPlaces.length > 1
          ? 'Topp ${topPlaces.length} går videre til sluttspill $topBracket'
          : '${topPlaces.map((p) => '$p.').join(', ')} plass går til sluttspill $topBracket');
      final others = adv.entries.where((e) => e.value != topBracket).toList()
        ..sort((a, b) => a.key.compareTo(b.key));
      for (final e in others) {
        legendParts.add('${e.key}. plass til ${e.value}');
      }
    }
    legendParts.addAll(['K = kamper', 'S-T = seier-tap']);

    final sortedMatches = [...matches]..sort((a, b) {
        final t = ntMatchTime(a.data()).compareTo(ntMatchTime(b.data()));
        if (t != 0) return t;
        return ((a.data()['match_number'] as num?) ?? 0)
            .compareTo((b.data()['match_number'] as num?) ?? 0);
      });
    final ctx = _Ctx(allMatches);

    final colStyle = AppText.monoSm.copyWith(color: p.ink3);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const SizedBox(height: 26),
          _SectionHeader(
            p: p,
            title: 'TABELL · PULJE $group',
            trailing: '$finished AV ${matches.length} KAMPER',
          ),
          const SizedBox(height: 14),
          NtCard(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(18, 16, 18, 10),
                  child: Row(children: [
                    SizedBox(width: 46, child: Text('#', style: colStyle)),
                    Expanded(child: Text('LAG', style: colStyle)),
                    SizedBox(width: 34, child: Text('K', style: colStyle, textAlign: TextAlign.center)),
                    SizedBox(width: 56, child: Text('S-T', style: colStyle, textAlign: TextAlign.center)),
                    SizedBox(width: 48, child: Text('SETT', style: colStyle, textAlign: TextAlign.right)),
                  ]),
                ),
                if (rows.isEmpty)
                  Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('Ingen lag i puljen ennå.',
                        style: AppText.uiCaption.copyWith(color: p.ink3)),
                  ),
                for (var i = 0; i < rows.length; i++) ...[
                  _StandingRow(
                    p: p,
                    rank: i + 1,
                    row: rows[i],
                    highlight: topPlaces.contains(i + 1),
                  ),
                  if (i < rows.length - 1)
                    (topPlaces.isNotEmpty && i + 1 == topPlaces.last)
                        ? _DashedLine(color: p.green)
                        : Divider(height: 1, thickness: 1, color: p.line),
                ],
              ],
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (topBracket != null)
                Padding(
                  padding: const EdgeInsets.only(top: 8, right: 10),
                  child: SizedBox(width: 18, child: _DashedLine(color: p.green, height: 2)),
                ),
              Expanded(
                child: Text(legendParts.join(' · '),
                    style: AppText.uiCaption.copyWith(color: p.ink2, fontSize: 13)),
              ),
            ],
          ),
          const SizedBox(height: 30),
          _SectionHeader(p: p, title: 'KAMPER I PULJE $group'),
          const SizedBox(height: 14),
          NtCard(
            child: sortedMatches.isEmpty
                ? Padding(
                    padding: const EdgeInsets.all(18),
                    child: Text('Ingen kamper satt opp ennå.',
                        style: AppText.uiCaption.copyWith(color: p.ink3)),
                  )
                : Column(children: [
                    for (var i = 0; i < sortedMatches.length; i++) ...[
                      _GroupMatchRow(p: p, doc: sortedMatches[i], ctx: ctx),
                      if (i < sortedMatches.length - 1)
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18),
                          child: Divider(height: 1, thickness: 1, color: p.line),
                        ),
                    ],
                  ]),
          ),
        ],
      ),
    );
  }
}

class _StandingRow extends StatelessWidget {
  final _P p;
  final int rank;
  final _StandRow row;
  final bool highlight;
  const _StandingRow({
    required this.p,
    required this.rank,
    required this.row,
    required this.highlight,
  });

  @override
  Widget build(BuildContext context) {
    final mono = AppText.monoMd.copyWith(color: p.ink, fontSize: 13);
    return Container(
      color: highlight ? p.greenTint : null,
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 20),
      child: Row(children: [
        SizedBox(
          width: 46,
          child: Text('$rank',
              style: AppText.dispH1(22).copyWith(color: highlight ? p.green : p.ink)),
        ),
        Expanded(
          child: Text(row.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.uiTitle.copyWith(
                  color: p.ink, fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        SizedBox(width: 34, child: Text('${row.played}', style: mono, textAlign: TextAlign.center)),
        SizedBox(
          width: 56,
          child: Text('${row.w}–${row.l}',
              style: mono.copyWith(fontWeight: FontWeight.w700), textAlign: TextAlign.center),
        ),
        SizedBox(width: 48, child: Text('${row.sw}–${row.sl}', style: mono, textAlign: TextAlign.right)),
      ]),
    );
  }
}

class _GroupMatchRow extends StatelessWidget {
  final _P p;
  final _Doc doc;
  final _Ctx ctx;
  const _GroupMatchRow({required this.p, required this.doc, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final status = d['status'] as String? ?? 'pending';
    final finished = status == 'finished';
    final live = status == 'live';
    final a = ctx.slot(d, 'team_a');
    final b = ctx.slot(d, 'team_b');
    final (hs, as_) = ntSets(d);
    final aWon = finished && hs > as_;
    final bWon = finished && as_ > hs;
    final sets = ntSetScores(d);

    TextStyle nameStyle(_Slot s, bool won) => AppText.uiBody.copyWith(
          fontSize: 16,
          color: won ? p.green : (s.placeholder ? p.ink3 : p.ink),
          fontWeight: won ? FontWeight.w700 : FontWeight.w500,
          fontStyle: s.placeholder ? FontStyle.italic : null,
          height: 1.3,
        );

    Widget trailing;
    if (finished) {
      trailing = Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text('$hs – $as_', style: AppText.dispScore(22).copyWith(color: p.green)),
          if (sets.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(sets, style: AppText.monoSm.copyWith(color: p.ink2, letterSpacing: 0.4)),
          ],
        ],
      );
    } else if (live) {
      trailing = const _LivePill();
    } else {
      trailing = Text('Planlagt', style: AppText.uiCaption.copyWith(color: p.ink2, fontSize: 14));
    }

    final time = ntMatchTime(d);
    return InkWell(
      onTap: (finished || live) ? () => _openStats(context, doc.id, a.name, b.name) : null,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          SizedBox(
            width: 66,
            child: Text(time.isEmpty ? '--:--' : time,
                style: AppText.monoMd.copyWith(color: p.ink2, fontSize: 13)),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle(a, aWon)),
                Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: nameStyle(b, bWon)),
              ],
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ]),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Sluttspill: én runde med bracket-linjer til neste runde
// ─────────────────────────────────────────────────────────────────────────────
class _RoundView extends StatelessWidget {
  final _P p;
  final _Ctx ctx;
  final List<_Doc> matches;
  final ValueChanged<String> onOpenRound;

  const _RoundView({
    required this.p,
    required this.ctx,
    required this.matches,
    required this.onOpenRound,
  });

  @override
  Widget build(BuildContext context) {
    final sorted = [...matches]..sort((a, b) =>
        ((a.data()['match_number'] as num?) ?? 0)
            .compareTo((b.data()['match_number'] as num?) ?? 0));

    // Grupper kampene etter hvilken kamp vinneren går videre til
    final blocks = <String, List<_Doc>>{};
    for (final m in sorted) {
      final next = m.data()['next_match_id'] as String?;
      final key = (next != null && ctx.byId.containsKey(next)) ? next : '_solo_${m.id}';
      blocks.putIfAbsent(key, () => []).add(m);
    }

    final hasSeeds = sorted.any((m) =>
        m.data()['team_a_from_group'] != null || m.data()['team_b_from_group'] != null);

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (final e in blocks.entries) ...[
            _Block(
              p: p,
              ctx: ctx,
              matches: e.value,
              next: e.key.startsWith('_solo_') ? null : ctx.byId[e.key],
              onOpenRound: onOpenRound,
            ),
            const SizedBox(height: 26),
          ],
          _InfoBox(
            p: p,
            text: hasSeeds
                ? 'A1 = vinner pulje A, B2 = toer i pulje B. Trykk på en kamp for settresultater.'
                : 'Trykk på en kamp for settresultater.',
          ),
        ],
      ),
    );
  }
}

class _Block extends StatelessWidget {
  final _P p;
  final _Ctx ctx;
  final List<_Doc> matches;
  final _Doc? next;
  final ValueChanged<String> onOpenRound;

  const _Block({
    required this.p,
    required this.ctx,
    required this.matches,
    required this.next,
    required this.onOpenRound,
  });

  static const double _gap = 14;

  @override
  Widget build(BuildContext context) {
    final cards = Column(
      children: [
        for (var i = 0; i < matches.length; i++) ...[
          if (i > 0) const SizedBox(height: _gap),
          _BracketMatchCard(p: p, ctx: ctx, doc: matches[i]),
        ],
      ],
    );

    if (next == null) return cards;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(child: cards),
          SizedBox(
            width: 34,
            child: CustomPaint(
              painter: _ConnectorPainter(
                count: matches.length,
                gap: _gap,
                color: p.ink3.withValues(alpha: 0.7),
              ),
            ),
          ),
          Center(
            child: _NextCard(
              p: p,
              ctx: ctx,
              doc: next!,
              onTap: () => onOpenRound((next!.data()['round'] as String?) ?? ''),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConnectorPainter extends CustomPainter {
  final int count;
  final double gap;
  final Color color;
  _ConnectorPainter({required this.count, required this.gap, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final h = (size.height - gap * (count - 1)) / count;
    final centers = [for (var i = 0; i < count; i++) h / 2 + i * (h + gap)];
    const x0 = 6.0;
    final xm = size.width * 0.5;
    for (final y in centers) {
      canvas.drawLine(Offset(x0, y), Offset(xm, y), paint);
    }
    if (centers.length > 1) {
      canvas.drawLine(Offset(xm, centers.first), Offset(xm, centers.last), paint);
    }
    final mid = (centers.first + centers.last) / 2;
    canvas.drawLine(Offset(xm, mid), Offset(size.width, mid), paint);
  }

  @override
  bool shouldRepaint(covariant _ConnectorPainter old) =>
      old.count != count || old.color != color;
}

class _BracketMatchCard extends StatelessWidget {
  final _P p;
  final _Ctx ctx;
  final _Doc doc;
  const _BracketMatchCard({required this.p, required this.ctx, required this.doc});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final status = d['status'] as String? ?? 'pending';
    final finished = status == 'finished';
    final live = status == 'live';
    final a = ctx.slot(d, 'team_a');
    final b = ctx.slot(d, 'team_b');
    final (hs, as_) = ntSets(d);

    final header = [
      ctx.playoffLabel(d),
      _courtLabel(d['court']),
      ntMatchTime(d),
    ].where((s) => s.isNotEmpty).join(' · ');

    Widget statusWidget;
    if (live) {
      statusWidget = const _LivePill();
    } else if (finished) {
      statusWidget = Text('FERDIG',
          style: AppText.monoSm.copyWith(color: p.green, fontWeight: FontWeight.w700));
    } else {
      statusWidget = Text('PLANLAGT', style: AppText.monoSm.copyWith(color: p.ink2));
    }

    return Material(
      color: p.card,
      borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: (finished || live) ? () => _openStats(context, doc.id, a.name, b.name) : null,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(AppTheme.radiusCard),
            border: Border.all(
              color: live ? AppColors.coral : Colors.transparent,
              width: 1.5,
            ),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(
                color: p.strip,
                height: 40,
                padding: const EdgeInsets.symmetric(horizontal: 14),
                child: Row(children: [
                  Expanded(
                    child: Text(header,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppText.monoSm.copyWith(
                            color: p.ink, fontWeight: FontWeight.w600, fontSize: 10.5)),
                  ),
                  statusWidget,
                ]),
              ),
              _TeamLine(
                p: p,
                slot: a,
                score: (finished || live) ? '$hs' : '–',
                won: finished && hs > as_,
                pending: !finished && !live,
              ),
              Divider(height: 1, thickness: 1, color: p.line),
              _TeamLine(
                p: p,
                slot: b,
                score: (finished || live) ? '$as_' : '–',
                won: finished && as_ > hs,
                pending: !finished && !live,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _TeamLine extends StatelessWidget {
  final _P p;
  final _Slot slot;
  final String score;
  final bool won;
  final bool pending;
  const _TeamLine({
    required this.p,
    required this.slot,
    required this.score,
    required this.won,
    required this.pending,
  });

  @override
  Widget build(BuildContext context) {
    final nameColor = won ? p.green : (slot.placeholder ? p.ink2 : p.ink);
    return Container(
      height: 58,
      color: won ? p.greenTint : null,
      padding: const EdgeInsets.symmetric(horizontal: 14),
      child: Row(children: [
        if (slot.seed != null)
          SizedBox(
            width: 26,
            child: Text(slot.seed!,
                style: AppText.monoSm.copyWith(color: p.ink2, letterSpacing: 0.4, fontSize: 10.5)),
          ),
        Expanded(
          child: Text(slot.name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppText.uiBody.copyWith(
                fontSize: 16,
                color: nameColor,
                fontWeight: won ? FontWeight.w700 : FontWeight.w500,
                fontStyle: slot.placeholder ? FontStyle.italic : null,
              )),
        ),
        Text(score,
            style: AppText.dispScore(pending ? 18 : 22)
                .copyWith(color: pending ? p.ink3 : (won ? p.green : p.ink))),
      ]),
    );
  }
}

class _NextCard extends StatelessWidget {
  final _P p;
  final _Ctx ctx;
  final _Doc doc;
  final VoidCallback onTap;
  const _NextCard({required this.p, required this.ctx, required this.doc, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final a = ctx.slot(d, 'team_a');
    final b = ctx.slot(d, 'team_b');
    final known = !a.placeholder || !b.placeholder;
    final bg = known ? AppColors.ink : p.card;
    final fg = known ? Colors.white : p.ink;
    final dim = known ? Colors.white70 : p.ink2;

    Widget name(_Slot s) => Text(
          s.placeholder ? 'TBD' : s.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppText.uiBody.copyWith(
            fontSize: 15,
            color: s.placeholder ? dim : fg,
            fontWeight: s.placeholder ? FontWeight.w400 : FontWeight.w700,
            fontStyle: s.placeholder ? FontStyle.italic : null,
            height: 1.35,
          ),
        );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 118,
        padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(AppTheme.radiusRow),
          boxShadow: known ? AppTheme.shadowSm : null,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(ctx.playoffLabel(d, next: true),
                style: (known ? AppText.monoSmLight : AppText.monoSm.copyWith(color: p.ink2))
                    .copyWith(fontSize: 10.5)),
            const SizedBox(height: 6),
            name(a),
            name(b),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Felles UI-byggesteiner
// ─────────────────────────────────────────────────────────────────────────────
class _GroupChips extends StatelessWidget {
  final _P p;
  final List<String> groups;
  final String selected;
  final ValueChanged<String> onTap;
  const _GroupChips({required this.p, required this.groups, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 60,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
        itemCount: groups.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final g = groups[i];
          final sel = g == selected;
          return GestureDetector(
            onTap: () => onTap(g),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 60,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? AppColors.coral : p.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusRow),
              ),
              child: Text(g, style: AppText.dispH1(26).copyWith(color: sel ? AppColors.ink : p.ink)),
            ),
          );
        },
      ),
    );
  }
}

class _BracketChips extends StatelessWidget {
  final _P p;
  final List<String> brackets;
  final String selected;
  final ValueChanged<String> onTap;
  const _BracketChips({required this.p, required this.brackets, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 54,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
        itemCount: brackets.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final b = brackets[i];
          final sel = b == selected;
          return GestureDetector(
            onTap: () => onTap(b),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              constraints: const BoxConstraints(minWidth: 54),
              padding: EdgeInsets.symmetric(horizontal: sel ? 22 : 0),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: sel ? AppColors.coral : p.card,
                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
              ),
              child: Text(
                sel ? 'Sluttspill $b' : b,
                style: AppText.uiCta.copyWith(
                    fontSize: 16, color: sel ? AppColors.ink : p.ink, fontWeight: FontWeight.w800),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _RoundTabs extends StatelessWidget {
  final _P p;
  final List<String> rounds;
  final String selected;
  final ValueChanged<String> onTap;
  const _RoundTabs({required this.p, required this.rounds, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    // Mange runder → korte etiketter og sidelengs scroll
    final compact = rounds.length > 3;
    String label(String r) {
      if (!compact) return _roundTab[r] ?? r;
      return const {
            'omspill': 'Playoff',
            'r16': '1/16',
            'r8': '1/8',
            'qf': 'Kvart',
            'sf': 'Semi',
            'bronze': 'Bronse',
            'final': 'Finale',
          }[r] ??
          r;
    }

    Widget tab(String r) {
      final sel = r == selected;
      return GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () => onTap(r),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          alignment: Alignment.center,
          padding: EdgeInsets.symmetric(horizontal: compact ? 16 : 8),
          decoration: BoxDecoration(
            color: sel ? p.selectedDark : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(label(r),
              style: AppText.uiCta.copyWith(
                fontSize: 16,
                fontWeight: sel ? FontWeight.w800 : FontWeight.w500,
                color: sel ? Colors.white : p.ink,
              )),
        ),
      );
    }

    return Container(
      height: 58,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusRow),
        boxShadow: AppTheme.shadowSm,
      ),
      child: rounds.length <= 4
          ? Row(children: [for (final r in rounds) Expanded(child: tab(r))])
          : ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: rounds.length,
              separatorBuilder: (_, _) => const SizedBox(width: 4),
              itemBuilder: (_, i) => tab(rounds[i]),
            ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final _P p;
  final String title;
  final String? trailing;
  const _SectionHeader({required this.p, required this.title, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(children: [
      Container(width: 18, height: 3, color: AppColors.coral),
      const SizedBox(width: 12),
      Expanded(
        child: Text(title, style: AppText.dispKicker(18).copyWith(color: p.ink)),
      ),
      if (trailing != null)
        Text(trailing!, style: AppText.monoSm.copyWith(color: p.ink2, fontSize: 10.5)),
    ]);
  }
}

class _DashedLine extends StatelessWidget {
  final Color color;
  final double height;
  const _DashedLine({required this.color, this.height = 2});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(builder: (context, c) {
      const dash = 7.0, space = 5.0;
      final n = (c.maxWidth / (dash + space)).floor();
      return SizedBox(
        height: height,
        child: Row(
          children: List.generate(
            n,
            (_) => Padding(
              padding: const EdgeInsets.only(right: space),
              child: Container(width: dash, height: height, color: color),
            ),
          ),
        ),
      );
    });
  }
}

class _LivePill extends StatelessWidget {
  const _LivePill();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.coral,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text('LIVE',
          style: AppText.monoSm.copyWith(
              color: AppColors.ink, fontWeight: FontWeight.w700, letterSpacing: 1.6)),
    );
  }
}

class _InfoBox extends StatelessWidget {
  final _P p;
  final String text;
  const _InfoBox({required this.p, required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
      decoration: BoxDecoration(
        color: p.card,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.only(top: 2),
            child: Icon(Icons.info_outline_rounded, size: 18, color: p.ink2),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: AppText.uiCaption.copyWith(color: p.ink2, fontSize: 14)),
          ),
        ],
      ),
    );
  }
}

class _Empty extends StatelessWidget {
  final _P p;
  final String text;
  const _Empty(this.p, this.text);

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Text(text,
              textAlign: TextAlign.center,
              style: AppText.uiCaption.copyWith(color: p.ink3, fontSize: 14)),
        ),
      );
}

void _openStats(BuildContext context, String id, String a, String b) {
  Navigator.push(
    context,
    MaterialPageRoute(
      builder: (_) => MatchStatsPage(matchId: id, teamAName: a, teamBName: b),
    ),
  );
}
