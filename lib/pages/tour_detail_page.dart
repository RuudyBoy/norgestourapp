import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'teams_page.dart';
import 'matches_page.dart';
import 'tournament_stats_page.dart';
import 'match_stats_page.dart';
import 'groups_page.dart';
import 'playoffs_page.dart';

class TournamentDetailsPage extends StatelessWidget {
  final String tournamentId;
  final Map<String, dynamic> data;

  const TournamentDetailsPage({
    super.key,
    required this.tournamentId,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final name = data['name'] ?? 'Ukjent Turnering';
    final date = data['start_date']?.toString() ?? 'Dato kommer';
    final imageUrl = data['image_url'] ?? '';
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DefaultTabController(
      length: 5,
      child: Scaffold(
        body: NestedScrollView(
          headerSliverBuilder: (context, innerBoxIsScrolled) {
            return [
              SliverAppBar(
            expandedHeight: 300,
            pinned: true,
            backgroundColor: isDark ? AppColors.nightSurface1 : AppColors.sand1,
            elevation: 0,
            leading: Padding(
              padding: const EdgeInsets.only(left: 12),
              child: Center(
                child: GestureDetector(
                  onTap: () => Navigator.pop(context),
                  child: Container(
                    width: 36,
                    height: 36,
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.35),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              collapseMode: CollapseMode.parallax,
              background: Stack(
                fit: StackFit.expand,
                children: [
                  if (imageUrl.isNotEmpty)
                    Image.network(
                      imageUrl,
                      fit: BoxFit.cover,
                      errorBuilder: (ctx, err, stack) => Container(
                        decoration: const BoxDecoration(gradient: AppColors.heroNavy),
                      ),
                    )
                  else
                    Container(decoration: const BoxDecoration(gradient: AppColors.heroNavy)),

                  Container(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.black.withValues(alpha: 0.1),
                          Colors.black.withValues(alpha: 0.4),
                          Colors.black.withValues(alpha: 0.88),
                        ],
                        stops: const [0.0, 0.5, 1.0],
                      ),
                    ),
                  ),

                  Positioned(
                    bottom: 24,
                    left: AppTheme.pageHPad,
                    right: AppTheme.pageHPad,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                          ),
                          child: Text(
                            'TURNERING',
                            style: AppText.monoSm.copyWith(
                              color: Colors.white,
                              letterSpacing: 1.5,
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          name,
                          style: AppText.dispH1Light(28),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        Row(
                          children: [
                            Icon(
                              Icons.calendar_today_outlined,
                              color: Colors.white.withValues(alpha: 0.6),
                              size: 11,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              date,
                              style: AppText.monoSmLight.copyWith(fontSize: 11),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),

          SliverPersistentHeader(
            pinned: true,
            delegate: _SliverAppBarDelegate(
              TabBar(
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                labelColor: AppColors.coral,
                unselectedLabelColor: isDark ? AppColors.nightInk3 : AppColors.ink3,
                indicatorColor: AppColors.coral,
                indicatorWeight: 3,
                labelStyle: AppText.uiCta,
                unselectedLabelStyle: AppText.uiCta,
                tabs: const [
                  Tab(text: "Kamper"),
                  Tab(text: "Grupper"),
                  Tab(text: "Sluttspill"),
                  Tab(text: "Stats"),
                  Tab(text: "Lag"),
                ],
              ),
            ),
          ),
            ];
          },
          body: TabBarView(
            children: [
              MatchesPage(tournamentId: tournamentId, tournamentName: name, isEmbedded: true),
              GroupsPage(tournamentId: tournamentId),
              PlayoffsPage(tournamentId: tournamentId),
              TournamentStatsPage(tournamentId: tournamentId, tournamentName: name, isEmbedded: true),
              TeamsPage(tournamentId: tournamentId, tournamentName: name, isEmbedded: true),
            ],
          ),
        ),
      ),
    );
  }
}

class _SliverAppBarDelegate extends SliverPersistentHeaderDelegate {
  _SliverAppBarDelegate(this._tabBar);

  final TabBar _tabBar;

  @override
  double get minExtent => _tabBar.preferredSize.height;
  @override
  double get maxExtent => _tabBar.preferredSize.height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      color: isDark ? AppColors.nightSurface1 : AppColors.sand1,
      child: _tabBar,
    );
  }

  @override
  bool shouldRebuild(_SliverAppBarDelegate oldDelegate) {
    return false;
  }
}

