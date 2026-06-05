import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'tour_detail_page.dart';
import '../widgets/profile_avatar_widget.dart';
import '../widgets/season_hero_widget.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class ToursPage extends StatelessWidget {
  const ToursPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        leadingWidth: 80,
        leading: Padding(
          padding: const EdgeInsets.only(left: 16.0),
          child: Image.asset('assets/images/ntlogo.png', fit: BoxFit.contain),
        ),
        actions: const [ProfileAvatarWidget()],
      ),
      body: Column(
        children: [
          const SeasonHeroWidget(
            title: 'TOURS',
            description: 'Finn din neste turnering og meld deg på!',
          ),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('tournaments').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.coral));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Noe gikk galt.', style: AppText.uiBody));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Ingen turneringer funnet.', style: AppText.uiBody));
                }

                final tournaments = snapshot.data!.docs;

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(
                    AppTheme.pageHPad, AppTheme.sectionGap,
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

                    return _buildTourCard(context, doc.id, data, name, date, imageUrl, location, status);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
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
  ) {
    final isLive = status == 'live';

    return Container(
      margin: const EdgeInsets.only(bottom: AppTheme.sectionGap),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowSm,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Material(
          color: AppColors.sand0,
          child: InkWell(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TournamentDetailsPage(tournamentId: id, data: data),
                ),
              );
            },
            splashColor: AppColors.coral.withOpacity(0.08),
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
                              colors: [Colors.transparent, AppColors.ink.withOpacity(0.6)],
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
                    decoration: BoxDecoration(gradient: AppColors.heroNavy),
                    child: Center(
                      child: Text(name.toUpperCase(),
                          style: AppText.dispH2(24).copyWith(color: Colors.white.withOpacity(0.3))),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.all(AppTheme.cardPad),
                  child: Row(
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
                            Text(name, style: AppText.dispH2(20)),
                            const SizedBox(height: 3),
                            if (location.isNotEmpty)
                              Text(location.toUpperCase(), style: AppText.monoSm),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                            decoration: BoxDecoration(
                              color: AppColors.sand2,
                              borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                            ),
                            child: Text(date, style: AppText.monoSm.copyWith(color: AppColors.ink2)),
                          ),
                          const SizedBox(height: 8),
                          const Icon(Icons.arrow_forward_ios, size: 14, color: AppColors.ink3),
                        ],
                      ),
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
