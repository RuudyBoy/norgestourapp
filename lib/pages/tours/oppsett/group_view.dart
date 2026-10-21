part of 'oppsett_page.dart';

// Puljevisningen: tabell og kamper i én pulje.
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
