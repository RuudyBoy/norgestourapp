import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';
import 'package:norges_tour_app/theme/app_theme.dart';
import 'package:norges_tour_app/pages/stats/match_stats_page.dart';
import 'package:norges_tour_app/widgets/nt_ui.dart';

// Oppsett-fanen på turneringssiden: puljer og sluttspill for én klasse.
// Siden og tilstanden ligger her; visningene er delt i egne filer.
part 'oppsett_helpers.dart';
part 'group_view.dart';
part 'bracket_view.dart';
part 'oppsett_widgets.dart';

typedef _Doc = QueryDocumentSnapshot<Map<String, dynamic>>;

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
