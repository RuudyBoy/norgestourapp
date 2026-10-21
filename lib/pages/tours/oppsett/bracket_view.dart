part of 'oppsett_page.dart';

// Sluttspillvisningen: én runde med kampkort og linjer til neste runde.
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
