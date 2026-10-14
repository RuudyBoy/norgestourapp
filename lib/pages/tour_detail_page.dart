import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'teams_page.dart';
import 'matches_page.dart';
import 'tournament_stats_page.dart';
import 'oppsett_page.dart';
import 'tournament_registration_page.dart';
import '../widgets/nt_ui.dart';

class TournamentDetailsPage extends StatelessWidget {
  final String tournamentId;
  final Map<String, dynamic> data;

  /// 0 = Kamper, 1 = Oppsett, 2 = Stats, 3 = Lag
  final int initialTab;

  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
    required this.data,
    this.initialTab = 0,
  });

  bool _isRegistrationOpen() {
    final regStatus = data['registration_status'] as String? ?? '';
    final deadline = data['registration_deadline'] as String?;
    if (regStatus != 'open') return false;
    if (deadline == null) return true;
    // Parse DD.MM.YYYY
    try {
      final parts = deadline.split('.');
      if (parts.length == 3) {
        final d = DateTime(
          int.parse(parts[2]),
          int.parse(parts[1]),
          int.parse(parts[0]),
          23, 59,
        );
        return DateTime.now().isBefore(d);
      }
    } catch (_) {}
    return false;
  }

  void showRegistrationCategoryPicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: Theme.of(ctx).scaffoldBackgroundColor,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text("Velg klasse",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text("Hvilken klasse vil du melde på til?",
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            const SizedBox(height: 16),
            StreamBuilder<QuerySnapshot>(
              // Påmelding styres av registration_status/frist – ikke av
              // 'published' (som først settes når oppsettet publiseres).
              stream: FirebaseFirestore.instance
                  .collection('categories')
                  .where('tournament_id', isEqualTo: tournamentId)
                  .snapshots(),
              builder: (ctx, snap) {
                if (!snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final cats = snap.data!.docs;
                if (cats.isEmpty) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Text("Ingen klasser funnet for denne turneringen."),
                  );
                }
                return Column(
                  children: cats.map((cat) {
                    final catData = cat.data() as Map<String, dynamic>;
                    final catName = catData['name'] as String? ?? 'Ukjent';
                    final maxTeams = catData['max_teams'] as int? ?? 0;
                    return ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: AppColors.coral,
                        child: Icon(Icons.sports_volleyball,
                            color: Colors.white, size: 18),
                      ),
                      title: Text(catName,
                          style:
                              const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text("Maks $maxTeams lag"),
                      trailing:
                          const Icon(Icons.chevron_right, color: AppColors.coral),
                      onTap: () {
                        Navigator.pop(ctx);
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => TournamentRegistrationPage(
                              tournamentId: tournamentId,
                              tournamentData: data,
                              categoryId: cat.id,
                              categoryName: catName,
                            ),
                          ),
                        );
                      },
                    );
                  }).toList(),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final name = (data['name'] ?? 'Ukjent turnering').toString();
    final location = (data['location'] ?? '').toString();
    final dateText = ntDateRange(data);
    final p = NtPalette.of(context);
    final registrationOpen = _isRegistrationOpen();

    return DefaultTabController(
      length: 4,
      initialIndex: initialTab.clamp(0, 3),
      child: Scaffold(
        floatingActionButton: registrationOpen
            ? FloatingActionButton.extended(
                onPressed: () => showRegistrationCategoryPicker(context),
                backgroundColor: AppColors.coral,
                foregroundColor: AppColors.ink,
                icon: const Icon(Icons.how_to_reg),
                label: Text('Meld på', style: AppText.uiCta.copyWith(color: AppColors.ink)),
              )
            : null,
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
                pinned: true,
                automaticallyImplyLeading: false,
                toolbarHeight: 96,
                titleSpacing: AppTheme.pageHPad,
                backgroundColor: p.card,
                surfaceTintColor: Colors.transparent,
                elevation: 0,
                scrolledUnderElevation: 0,
                title: Row(children: [
                  GestureDetector(
                    onTap: () => Navigator.pop(context),
                    child: Container(
                      width: 58,
                      height: 58,
                      decoration: BoxDecoration(
                        color: p.segBg,
                        borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                      ),
                      child: Icon(Icons.chevron_left_rounded, color: p.ink, size: 30),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppText.dispH1(30).copyWith(color: p.ink)),
                        const SizedBox(height: 6),
                        _TourMetaLine(
                          tournamentId: tournamentId,
                          location: location,
                          dateText: dateText,
                        ),
                      ],
                    ),
                  ),
                ]),
              ),
              SliverPersistentHeader(
                pinned: true,
                delegate: _SliverAppBarDelegate(
                  TabBar(
                    isScrollable: true,
                    tabAlignment: TabAlignment.start,
                    padding: const EdgeInsets.symmetric(horizontal: 6),
                    labelColor: AppColors.coral,
                    unselectedLabelColor: p.ink2,
                    indicatorColor: AppColors.coral,
                    indicatorWeight: 3,
                    indicatorSize: TabBarIndicatorSize.label,
                    dividerColor: Colors.transparent,
                    labelStyle: AppText.uiCta.copyWith(fontSize: 19, fontWeight: FontWeight.w700),
                    unselectedLabelStyle:
                        AppText.uiCta.copyWith(fontSize: 19, fontWeight: FontWeight.w500),
                    tabs: const [
                      Tab(text: 'Kamper'),
                      Tab(text: 'Oppsett'),
                      Tab(text: 'Stats'),
                      Tab(text: 'Lag'),
                    ],
                  ),
                ),
              ),
            ];
          },
          body: TabBarView(
            children: [
              MatchesPage(tournamentId: tournamentId, tournamentName: name, isEmbedded: true),
              OppsettPage(tournamentId: tournamentId, tournamentName: name, isEmbedded: true),
              TournamentStatsPage(tournamentId: tournamentId, tournamentName: name, isEmbedded: true),
              TeamsPage(tournamentId: tournamentId, tournamentName: name, isEmbedded: true),
            ],
          ),
        ),
      ),
    );
  }
}

/// "ASKIM · 14.11.2026 · 8 PULJER" — antall puljer telles fra kampene.
class _TourMetaLine extends StatelessWidget {
  final String tournamentId;
  final String location;
  final String dateText;
  const _TourMetaLine({
    required this.tournamentId,
    required this.location,
    required this.dateText,
  });

  @override
  Widget build(BuildContext context) {
    final p = NtPalette.of(context);
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection('matches')
          .where('tournament_id', isEqualTo: tournamentId)
          .where('stage', isEqualTo: 'group')
          .snapshots(),
      builder: (context, snap) {
        final groups = <String>{
          for (final m in snap.data?.docs ?? const <QueryDocumentSnapshot<Map<String, dynamic>>>[])
            if (m.data()['group'] != null) '${m.data()['category_id']}_${m.data()['group']}',
        };
        final parts = [
          if (location.isNotEmpty) location.toUpperCase(),
          if (dateText.isNotEmpty) dateText,
          if (groups.isNotEmpty) '${groups.length} ${groups.length == 1 ? 'PULJE' : 'PULJER'}',
        ];
        return Text(parts.join(' · '),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppText.monoSm.copyWith(color: p.ink2, fontSize: 11, letterSpacing: 1.6));
      },
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height + 8;
  @override
  double get maxExtent => _tabBar.preferredSize.height + 8;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final p = NtPalette.of(context);
    return Container(
      decoration: BoxDecoration(
        color: p.card,
        border: Border(bottom: BorderSide(color: p.line)),
      ),
      alignment: Alignment.bottomLeft,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) => false;
}
