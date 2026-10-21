import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:norges_tour_app/pages/tours/tour_detail_page.dart';
import 'package:norges_tour_app/widgets/season_hero_widget.dart';
import 'package:norges_tour_app/theme/app_colors.dart';
import 'package:norges_tour_app/theme/app_text_styles.dart';
import 'package:norges_tour_app/theme/app_theme.dart';

class ToursPage extends StatelessWidget {
  const ToursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const SeasonHeroSliver(
            pageTitle: 'Tours',
            title: 'TOURS',
            description: 'Finn din neste turnering og meld deg på!',
            actionImage: 'assets/images/7.png',
          ),
          SliverToBoxAdapter(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Padding(padding: EdgeInsets.all(40), child: Center(child: CircularProgressIndicator(color: AppColors.coral)));
                }
                if (snapshot.hasError) {
                  return Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('Noe gikk galt.', style: AppText.uiBody)));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Padding(padding: const EdgeInsets.all(40), child: Center(child: Text('Ingen turneringer funnet.', style: AppText.uiBody)));
                }

                final tournaments = snapshot.data!.docs;

                return ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pageHPad, 24,
                    AppTheme.pageHPad, 32,
                  ),
                  itemCount: tournaments.length,
                  itemBuilder: (context, index) {
                    final doc = tournaments[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final name = data['name'] ?? 'Ukjent Navn';
                    final date = data['start_date']?.toString() ?? 'Dato kommer';
                    final imageUrl = data['image_url'] ?? '';
                    final location = data['location'] ?? '';
                    final status = data['status'] ?? '';
                    final deadline = data['registration_deadline'] as String?;
                    final regStatus = data['registration_status'] as String? ?? '';

                    return _buildTourCard(context, doc.id, data, name, date, imageUrl, location, status, deadline, regStatus);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }


  bool _deadlinePassed(String? deadline) {
    if (deadline == null) return false;
    try {
      final parts = deadline.split('.');
      if (parts.length == 3) {
        final d = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]), 23, 59);
        return DateTime.now().isAfter(d);
      }
    } catch (_) {}
    return false;
  }

  Widget _buildTourCard(
    BuildContext context,
    String id,
    Map<String, dynamic> data,
    String name,
    String date,
    String imageUrl,
    String location,
    String status,
    String? registrationDeadline,
    String registrationStatus,
  ) {
    final isLive = status == 'live';
    final regOpen = registrationStatus == 'open' && !_deadlinePassed(registrationDeadline);
    final regClosed = registrationStatus == 'closed' || (registrationStatus == 'open' && _deadlinePassed(registrationDeadline));

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sectionGap),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Material(
          color: AppColors.ink,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentDetailsPage(tournamentId: id, data: data),
                ),
              );
            },
            splashColor: AppColors.coral.withValues(alpha: 0.08),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (imageUrl.isNotEmpty)
                  Stack(
                    children: [
                      Image.network(
                        imageUrl,
                        height: 160,
                        width: double.infinity,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 160,
                            decoration: BoxDecoration(gradient: AppColors.heroNavy),
                          );
                        },
                      ),
                      Positioned.fill(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              begin: Alignment.topCenter,
                              end: Alignment.bottomCenter,
                              colors: [Colors.transparent, AppColors.ink.withValues(alpha: 0.6)],
                              stops: const [0.5, 1.0],
                            ),
                          ),
                        ),
                      ),
                      if (isLive)
                        Positioned(
                          top: 12,
                          left: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.coral,
                              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Container(width: 6, height: 6, decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle)),
                                const SizedBox(width: 5),
                                Text('LIVE', style: AppText.monoSmLight),
                              ],
                            ),
                          ),
                        ),
                    ],
                  )
                else
                  Container(
                    height: 100,
                    decoration: const BoxDecoration(
                      image: DecorationImage(
                        image: AssetImage('assets/images/card_bg.png'),
                        fit: BoxFit.cover,
                      ),
                    ),
                    child: Center(
                      child: Text(name.toUpperCase(),
                          style: AppText.dispH2(24).copyWith(color: Colors.white)),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.cardPad),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Container(
                            width: 4,
                            height: 40,
                            decoration: BoxDecoration(
                              color: isLive ? AppColors.coral : AppColors.blue,
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: AppText.dispH2(20).copyWith(color: AppColors.coral)),
                                const SizedBox(height: 3),
                                if (location.isNotEmpty)
                                  Text(location.toUpperCase(), style: AppText.monoSm.copyWith(color: Colors.white70)),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                                decoration: BoxDecoration(
                                  color: Colors.white.withValues(alpha: 0.1),
                                  borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                                ),
                                child: Text(date, style: AppText.monoSm.copyWith(color: Colors.white)),
                              ),
                              const SizedBox(height: 8),
                              const Icon(Icons.arrow_forward_ios, size: 14, color: Colors.white54),
                            ],
                          ),
                        ],
                      ),
                      // ── Påmeldingsfrist ──────────────────────────────────
                      if (registrationDeadline != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          decoration: BoxDecoration(
                            color: regOpen
                                ? AppColors.coral.withValues(alpha: 0.15)
                                : Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            border: Border.all(
                              color: regOpen
                                  ? AppColors.coral.withValues(alpha: 0.5)
                                  : Colors.white.withValues(alpha: 0.12),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                regOpen ? Icons.how_to_reg : Icons.lock_outline,
                                size: 12,
                                color: regOpen ? AppColors.coral : Colors.white38,
                              ),
                              const SizedBox(width: 6),
                              Text(
                                regOpen
                                    ? 'Påmelding åpen  –  frist $registrationDeadline'
                                    : regClosed
                                        ? 'Påmelding stengt  –  frist var $registrationDeadline'
                                        : 'Frist: $registrationDeadline',
                                style: AppText.monoSm.copyWith(
                                  fontSize: 10,
                                  color: regOpen ? AppColors.coral : Colors.white38,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
