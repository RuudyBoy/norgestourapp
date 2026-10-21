part of 'oppsett_page.dart';

// Små byggesteiner som bare brukes i Oppsett-fanen.
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
