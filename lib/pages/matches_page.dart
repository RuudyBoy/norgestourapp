import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import '../widgets/nt_ui.dart';
import 'match_stats_page.dart';

typedef _Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

enum _Filter { alle, live, kommende, ferdig }

class MatchesPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final bool isEmbedded;

  const MatchesPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isEmbedded = false,
  });

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  static const _finishedPreview = 5;

  String? _categoryId;
  _Filter _filter = _Filter.alle;
  bool _searchOpen = false;
  String _query = '';
  final _searchCtrl = TextEditingController();

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);

    final content = StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('categories')
          .where('tournament_id', isEqualTo: widget.tournamentId)
          .where('published', isEqualTo: true)
          .snapshots(),
      builder: (context, catSnap) {
        if (!catSnap.hasData) return const Center(child: CircularProgressIndicator());
        final cats = catSnap.data!.docs;
        if (cats.isEmpty) return _empty(p, 'Kampoppsettet er ikke publisert ennå.');
        final catId = cats.any((c) => c.id == _categoryId) ? _categoryId! : cats.first.id;

        return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: FirebaseFirestore.instance
              .collection('matches')
              .where('tournament_id', isEqualTo: widget.tournamentId)
              .where('category_id', isEqualTo: catId)
              .snapshots(),
          builder: (context, matchSnap) {
            final all = matchSnap.data?.docs ?? const <_Doc>[];
            final ctx = NtMatchCtx({for (final m in all) m.id: m.data()});

            // Søk på lagnavn (inkl. plassholdernavn som "Vinner pulje B")
            final q = _query.trim().toLowerCase();
            bool matchesQuery(_Doc m) {
              if (q.isEmpty) return true;
              final d = m.data();
              return ctx.slot(d, 'team_a').name.toLowerCase().contains(q) ||
                  ctx.slot(d, 'team_b').name.toLowerCase().contains(q);
            }

            final visible = all.where(matchesQuery).toList();
            final live = visible.where((m) => m.data()['status'] == 'live').toList()
              ..sort(_byTimeThenCourt);
            final upcoming = visible.where((m) => ntIsUpcoming(m.data())).toList()
              ..sort(_byTimeThenCourt);
            final finished = visible.where((m) => m.data()['status'] == 'finished').toList()
              ..sort((a, b) => _byTimeThenCourt(b, a)); // nyeste først
            final liveCountAll = all.where((m) => m.data()['status'] == 'live').length;

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _controls(p, cats, catId),
                if (_searchOpen) _searchField(p),
                _filters(liveCountAll),
                Expanded(
                  child: !matchSnap.hasData
                      ? const Center(child: CircularProgressIndicator())
                      : _body(p, ctx, live, upcoming, finished, all.isEmpty),
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
        title: Text('Kamper – ${widget.tournamentName}'),
        backgroundColor: AppColors.ink,
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  static int _byTimeThenCourt(_Doc a, _Doc b) {
    final t = ntMatchTime(a.data()).compareTo(ntMatchTime(b.data()));
    if (t != 0) return t;
    final ca = int.tryParse(ntCourtNumber(a.data()['court'])) ?? 99;
    final cb = int.tryParse(ntCourtNumber(b.data()['court'])) ?? 99;
    return ca.compareTo(cb);
  }

  // ── Toppkontroller ─────────────────────────────────────────────────────────
  Widget _controls(NtPalette p, List<_Doc> cats, String catId) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 20, AppTheme.pageHPad, 0),
      child: Row(children: [
        Expanded(
          child: NtSegmented(
            labels: [for (final c in cats) (c.data()['name'] as String?) ?? 'Klasse'],
            selected: cats.indexWhere((c) => c.id == catId),
            onTap: (i) => setState(() => _categoryId = cats[i].id),
          ),
        ),
        const SizedBox(width: 12),
        GestureDetector(
          onTap: () => setState(() {
            _searchOpen = !_searchOpen;
            if (!_searchOpen) {
              _query = '';
              _searchCtrl.clear();
            }
          }),
          child: Container(
            width: 54,
            height: 54,
            decoration: BoxDecoration(
              color: _searchOpen ? AppColors.ink : p.card,
              borderRadius: BorderRadius.circular(AppTheme.radiusRow),
            ),
            child: Icon(_searchOpen ? Icons.close_rounded : Icons.search_rounded,
                color: _searchOpen ? Colors.white : p.ink, size: 24),
          ),
        ),
      ]),
    );
  }

  Widget _searchField(NtPalette p) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 12, AppTheme.pageHPad, 0),
      child: TextField(
        controller: _searchCtrl,
        autofocus: true,
        onChanged: (v) => setState(() => _query = v),
        style: AppText.uiBody.copyWith(color: p.ink, fontSize: 16),
        decoration: InputDecoration(
          hintText: 'Søk etter lag',
          hintStyle: AppText.uiBody.copyWith(color: p.ink3, fontSize: 16),
          filled: true,
          fillColor: p.card,
          prefixIcon: Icon(Icons.search_rounded, color: p.ink3),
          contentPadding: const EdgeInsets.symmetric(vertical: 14),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppTheme.radiusInput),
            borderSide: BorderSide.none,
          ),
        ),
      ),
    );
  }

  Widget _filters(int liveCount) {
    String label(_Filter f) => switch (f) {
          _Filter.alle => 'Alle',
          _Filter.live => liveCount > 0 ? 'Live · $liveCount' : 'Live',
          _Filter.kommende => 'Kommende',
          _Filter.ferdig => 'Ferdig',
        };
    return SizedBox(
      height: 46 + 28,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 14, AppTheme.pageHPad, 14),
        itemCount: _Filter.values.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (_, i) {
          final f = _Filter.values[i];
          return NtFilterChip(
            label: label(f),
            selected: _filter == f,
            onTap: () => setState(() => _filter = f),
          );
        },
      ),
    );
  }

  // ── Innhold ────────────────────────────────────────────────────────────────
  Widget _body(NtPalette p, NtMatchCtx ctx, List<_Doc> live, List<_Doc> upcoming,
      List<_Doc> finished, bool noMatchesAtAll) {
    if (noMatchesAtAll) return _empty(p, 'Ingen kamper satt opp for denne klassen ennå.');

    final showLive = _filter == _Filter.alle || _filter == _Filter.live;
    final showUpcoming = _filter == _Filter.alle || _filter == _Filter.kommende;
    final showFinished = _filter == _Filter.alle || _filter == _Filter.ferdig;

    final children = <Widget>[];

    if (showLive && live.isNotEmpty) {
      children.add(_pad(const NtSectionHeader(title: 'Live nå')));
      children.add(const SizedBox(height: 16));
      if (_filter == _Filter.live) {
        for (final m in live) {
          children.add(_pad(_LiveCard(doc: m, ctx: ctx, width: double.infinity)));
          children.add(const SizedBox(height: 12));
        }
      } else {
        children.add(SizedBox(
          height: 176,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad),
            itemCount: live.length,
            separatorBuilder: (_, _) => const SizedBox(width: 12),
            itemBuilder: (context, i) => _LiveCard(
              doc: live[i],
              ctx: ctx,
              width: MediaQuery.of(context).size.width - AppTheme.pageHPad * 2 - (live.length > 1 ? 56 : 0),
            ),
          ),
        ));
      }
      children.add(const SizedBox(height: 30));
    }

    if (showUpcoming && upcoming.isNotEmpty) {
      children.add(_pad(const NtSectionHeader(title: 'Kommende')));
      children.add(const SizedBox(height: 14));
      String? lastTime;
      for (final m in upcoming) {
        final t = ntMatchTime(m.data());
        if (t != lastTime) {
          lastTime = t;
          children.add(_pad(_TimeDivider(time: t.isEmpty ? 'Tid ikke satt' : t)));
          children.add(const SizedBox(height: 12));
        }
        children.add(_pad(_UpcomingCard(doc: m, ctx: ctx)));
        children.add(const SizedBox(height: 12));
      }
      children.add(const SizedBox(height: 18));
    }

    if (showFinished && finished.isNotEmpty) {
      final list = _filter == _Filter.alle ? finished.take(_finishedPreview).toList() : finished;
      children.add(_pad(NtSectionHeader(
        title: 'Ferdig',
        trailing: Text('${finished.length} KAMPER',
            style: AppText.monoSm.copyWith(color: p.ink2, fontSize: 10.5)),
      )));
      children.add(const SizedBox(height: 14));
      children.add(_pad(NtCard(
        child: Column(children: [
          for (var i = 0; i < list.length; i++) ...[
            _FinishedRow(doc: list[i], ctx: ctx),
            if (i < list.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 18),
                child: Divider(height: 1, thickness: 1, color: p.line),
              ),
          ],
        ]),
      )));
      if (_filter == _Filter.alle && finished.length > _finishedPreview) {
        children.add(const SizedBox(height: 14));
        children.add(_pad(OutlinedButton(
          onPressed: () => setState(() => _filter = _Filter.ferdig),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(60),
            side: BorderSide(color: p.ink3.withValues(alpha: 0.5)),
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppTheme.radiusRow)),
          ),
          child: Text('Vis alle ferdige kamper',
              style: AppText.uiCta.copyWith(color: p.ink, fontSize: 16, fontWeight: FontWeight.w600)),
        )));
      }
    }

    if (children.isEmpty) {
      final msg = switch (_filter) {
        _Filter.live => 'Ingen kamper er live akkurat nå.',
        _Filter.kommende => 'Ingen kommende kamper.',
        _Filter.ferdig => 'Ingen ferdige kamper ennå.',
        _Filter.alle => 'Ingen kamper funnet.',
      };
      return _empty(p, _query.isNotEmpty ? 'Ingen treff på «$_query».' : msg);
    }

    return ListView(
      padding: const EdgeInsets.only(top: 10, bottom: 40),
      children: children,
    );
  }

  Widget _pad(Widget w) =>
      Padding(padding: const EdgeInsets.symmetric(horizontal: AppTheme.pageHPad), child: w);

  Widget _empty(NtPalette p, String text) => Center(
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
    MaterialPageRoute(builder: (_) => MatchStatsPage(matchId: id, teamAName: a, teamBName: b)),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// Live-kort (mørkt, stor score)
// ─────────────────────────────────────────────────────────────────────────────
class _LiveCard extends StatelessWidget {
  final _Doc doc;
  final NtMatchCtx ctx;
  final double width;
  const _LiveCard({required this.doc, required this.ctx, required this.width});

  @override
  Widget build(BuildContext context) {
    final d = doc.data();
    final a = ctx.slot(d, 'team_a');
    final b = ctx.slot(d, 'team_b');
    final (pa, pb) = ntLivePoints(d);
    final (sa, sb) = ntSets(d);
    final set = (d['current_set'] as num?)?.toInt() ?? (sa + sb + 1);
    final court = ntCourtNumber(d['court']);
    final meta = [
      if (court.isNotEmpty) 'BANE $court',
      ctx.stageLabel(d),
    ].where((s) => s.isNotEmpty).join(' · ');

    Widget teamRow(NtSlot s, int pts, int sets) => Row(children: [
          Expanded(
            child: Text(s.name.toUpperCase(),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.dispH1(22).copyWith(color: Colors.white)),
          ),
          if (sa + sb > 0) ...[
            Text('$sets', style: AppText.dispScore(22).copyWith(color: Colors.white38)),
            const SizedBox(width: 14),
          ],
          SizedBox(
            width: 52,
            child: Text('$pts',
                textAlign: TextAlign.right, style: AppText.dispScore(40).copyWith(color: Colors.white)),
          ),
        ]);

    return GestureDetector(
      onTap: () => _openStats(context, doc.id, a.name, b.name),
      child: Container(
        width: width,
        height: 176,
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 18),
        decoration: BoxDecoration(
          gradient: AppColors.heroNavy,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard + 4),
          boxShadow: AppTheme.shadowLg,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              NtLivePill(text: 'LIVE · SETT $set', dot: true),
              const SizedBox(width: 10),
              Expanded(
                child: Text(meta,
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.monoSmLight.copyWith(fontSize: 10.5)),
              ),
            ]),
            teamRow(a, pa, sa),
            teamRow(b, pb, sb),
          ],
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Kommende
// ─────────────────────────────────────────────────────────────────────────────
class _TimeDivider extends StatelessWidget {
  final String time;
  const _TimeDivider({required this.time});

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return Row(children: [
      Text(time, style: AppText.monoMd.copyWith(color: p.ink, fontWeight: FontWeight.w700, fontSize: 14)),
      const SizedBox(width: 14),
      Expanded(child: Divider(height: 1, thickness: 1, color: p.line)),
    ]);
  }
}

class _UpcomingCard extends StatelessWidget {
  final _Doc doc;
  final NtMatchCtx ctx;
  const _UpcomingCard({required this.doc, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    final d = doc.data();
    final a = ctx.slot(d, 'team_a');
    final b = ctx.slot(d, 'team_b');
    final court = ntCourtNumber(d['court']);
    final waiting = a.placeholder || b.placeholder;

    TextStyle name(NtSlot s) => AppText.uiBody.copyWith(
          fontSize: 17,
          height: 1.35,
          color: s.placeholder ? p.ink2 : p.ink,
          fontStyle: s.placeholder ? FontStyle.italic : null,
          fontWeight: FontWeight.w500,
        );

    return NtCard(
      padding: const EdgeInsets.fromLTRB(16, 16, 18, 16),
      child: Row(children: [
        Container(
          width: 58,
          height: 58,
          decoration: BoxDecoration(
            color: p.soft,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
            Text('BANE', style: AppText.monoSm.copyWith(color: p.ink2, fontSize: 9)),
            Text(court.isEmpty ? '–' : court, style: AppText.dispH1(24).copyWith(color: p.ink)),
          ]),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(ctx.stageLabel(d),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppText.monoSm.copyWith(color: p.ink2)),
            const SizedBox(height: 4),
            Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: name(a)),
            Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: name(b)),
          ]),
        ),
        const SizedBox(width: 10),
        Text(waiting ? 'Venter…' : 'Planlagt',
            style: AppText.uiCaption.copyWith(color: p.ink2, fontSize: 14)),
      ]),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Ferdig
// ─────────────────────────────────────────────────────────────────────────────
class _FinishedRow extends StatelessWidget {
  final _Doc doc;
  final NtMatchCtx ctx;
  const _FinishedRow({required this.doc, required this.ctx});

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    final d = doc.data();
    final a = ctx.slot(d, 'team_a');
    final b = ctx.slot(d, 'team_b');
    final (sa, sb) = ntSets(d);
    final sets = ntSetScores(d);
    final time = ntMatchTime(d);

    TextStyle name(bool won) => AppText.uiBody.copyWith(
          fontSize: 17,
          height: 1.35,
          color: won ? p.green : p.ink,
          fontWeight: won ? FontWeight.w700 : FontWeight.w500,
        );

    return InkWell(
      onTap: () => _openStats(context, doc.id, a.name, b.name),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 16),
        child: Row(children: [
          SizedBox(
            width: 66,
            child: Text(time.isEmpty ? '--:--' : time,
                style: AppText.monoMd.copyWith(color: p.ink2, fontSize: 13)),
          ),
          Expanded(
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Text(a.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: name(sa > sb)),
              Text(b.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: name(sb > sa)),
            ]),
          ),
          const SizedBox(width: 8),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('$sa – $sb', style: AppText.dispScore(22).copyWith(color: p.green)),
            if (sets.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(sets, style: AppText.monoSm.copyWith(color: p.ink2, letterSpacing: 0.4)),
            ],
          ]),
        ]),
      ),
    );
  }
}
