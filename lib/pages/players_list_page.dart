import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'player_detail_page.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class PlayersListPage extends StatefulWidget {
  const PlayersListPage({super.key});

  @override
  State<PlayersListPage> createState() => _PlayersListPageState();
}

class _PlayersListPageState extends State<PlayersListPage> {
  String _searchQuery = '';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('SPILLERE', style: AppText.dispH2(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.of(context).pop(),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/ntlogo.png', width: 40, fit: BoxFit.contain),
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 12, AppTheme.pageHPad, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Søk etter spiller...',
                prefixIcon: const Icon(Icons.search, color: AppColors.ink3),
              ),
              style: AppText.uiBody,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),
          const SizedBox(height: 12),
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('players').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.coral));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Noe gikk galt.', style: AppText.uiBody));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Ingen spillere funnet.', style: AppText.uiBody));
                }

                final players = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final firstName = (data['first_name'] ?? '').toString().toLowerCase();
                  final lastName = (data['last_name'] ?? '').toString().toLowerCase();
                  return '$firstName $lastName'.contains(_searchQuery);
                }).toList();

                players.sort((a, b) {
                  final aName = (a.data() as Map<String, dynamic>)['first_name'] ?? '';
                  final bName = (b.data() as Map<String, dynamic>)['first_name'] ?? '';
                  return aName.toString().compareTo(bName.toString());
                });

                return GridView.builder(
                  padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 0, AppTheme.pageHPad, 32),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.75,
                    crossAxisSpacing: AppTheme.rowGap,
                    mainAxisSpacing: AppTheme.rowGap,
                  ),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final doc = players[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final firstName = data['first_name'] ?? '';
                    final lastName = data['last_name'] ?? '';
                    final imageUrl = data['image_url'] ?? data['image'] ?? data['photoUrl'] ?? data['photo_url'] ?? data['picture'] ?? '';
                    final jersey = data['jersey_number']?.toString() ?? '';
                    final position = data['position'] ?? 'Spiller';

                    return GestureDetector(
                      onTap: () => Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => PlayerDetailPage(playerId: doc.id, playerData: data)),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          color: AppColors.sand0,
                          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                          boxShadow: AppTheme.shadowSm,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
                                child: imageUrl.isNotEmpty
                                    ? Image.network(
                                        imageUrl,
                                        fit: BoxFit.cover,
                                        errorBuilder: (context, error, stackTrace) => Container(
                                          color: AppColors.sand2,
                                          child: const Icon(Icons.person, size: 50, color: AppColors.ink3),
                                        ),
                                      )
                                    : Container(
                                        color: AppColors.sand2,
                                        child: const Icon(Icons.person, size: 50, color: AppColors.ink3),
                                      ),
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.all(10.0),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(firstName, style: AppText.uiCaption, maxLines: 1, overflow: TextOverflow.ellipsis),
                                    Text(lastName, style: AppText.uiTitle.copyWith(fontSize: 15), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 5),
                                    Row(
                                      children: [
                                        if (jersey.isNotEmpty)
                                          Container(
                                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                            margin: const EdgeInsets.only(right: 5),
                                            decoration: BoxDecoration(
                                              color: AppColors.coral,
                                              borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                                            ),
                                            child: Text(jersey, style: AppText.monoSm.copyWith(color: Colors.white, fontSize: 9)),
                                          ),
                                        Expanded(
                                          child: Text(position, style: AppText.monoSm, maxLines: 1, overflow: TextOverflow.ellipsis),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
