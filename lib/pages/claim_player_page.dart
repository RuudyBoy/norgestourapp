import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';

class ClaimPlayerPage extends StatefulWidget {
  const ClaimPlayerPage({super.key});

  @override
  State<ClaimPlayerPage> createState() => _ClaimPlayerPageState();
}

class _ClaimPlayerPageState extends State<ClaimPlayerPage> {
  String _searchQuery = '';

  Future<void> _submitClaim(BuildContext context, String playerId, String playerName) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance.collection('player_claims').add({
        'uid': user.uid,
        'userName': user.email,
        'playerId': playerId,
        'playerName': playerName,
        'status': 'pending',
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Forespørsel sendt! Venter på godkjenning.', style: AppText.uiBody.copyWith(color: Colors.white)),
            backgroundColor: AppColors.green,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Feil ved sending: $e', style: AppText.uiCaption.copyWith(color: Colors.white)),
            backgroundColor: AppColors.coral,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Er du en spiller?', style: AppText.dispH2(18)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, size: 18),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Column(
        children: [
          // Info banner
          Container(
            margin: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 12, AppTheme.pageHPad, 0),
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.blue.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(AppTheme.radiusRow),
              border: Border.all(color: AppColors.blue.withValues(alpha: 0.3)),
            ),
            child: Row(
              children: [
                const Icon(Icons.info_outline, color: AppColors.blue, size: 18),
                const SizedBox(width: 10),
                Expanded(
                  child: Text('Søk etter ditt navn og knytt kontoen din til spillerprofilen.', style: AppText.uiCaption),
                ),
              ],
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 12, AppTheme.pageHPad, 0),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Søk etter navnet ditt...',
                prefixIcon: const Icon(Icons.search, color: AppColors.ink3),
              ),
              style: AppText.uiBody,
              onChanged: (value) => setState(() => _searchQuery = value.toLowerCase()),
            ),
          ),

          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance.collection('players').snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.coral));
                }
                if (!snapshot.hasData || snapshot.data!.docs.isEmpty) {
                  return Center(child: Text('Fant ingen spillere.', style: AppText.uiBody));
                }

                final players = snapshot.data!.docs.where((doc) {
                  final data = doc.data() as Map<String, dynamic>;
                  final name = (data['name'] ?? '').toString().toLowerCase();
                  final firstName = (data['first_name'] ?? '').toString().toLowerCase();
                  final lastName = (data['last_name'] ?? '').toString().toLowerCase();
                  return name.contains(_searchQuery) ||
                      '$firstName $lastName'.contains(_searchQuery);
                }).toList();

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 16, AppTheme.pageHPad, 32),
                  itemCount: players.length,
                  itemBuilder: (context, index) {
                    final doc = players[index];
                    final data = doc.data() as Map<String, dynamic>;
                    final firstName = data['first_name'] ?? '';
                    final lastName = data['last_name'] ?? '';
                    final name = data['name'] ?? '$firstName $lastName'.trim();
                    final imageUrl = data['image_url'] ?? data['image'] ?? '';
                    final team = data['team'] ?? '';
                    final status = data['claimed'] == true;

                    return Container(
                      margin: const EdgeInsets.only(bottom: AppTheme.rowGap),
                      padding: const EdgeInsets.all(AppTheme.cardPad),
                      decoration: BoxDecoration(
                        color: AppColors.sand0,
                        borderRadius: BorderRadius.circular(AppTheme.radiusRow),
                        boxShadow: AppTheme.shadowSm,
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 22,
                            backgroundColor: AppColors.sand2,
                            backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                            child: imageUrl.isEmpty
                                ? Text(name.isEmpty ? '?' : name.substring(0, 1).toUpperCase(),
                                    style: AppText.dispKicker(16).copyWith(color: AppColors.ink2))
                                : null,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(name, style: AppText.uiTitle),
                                if (team.isNotEmpty) Text(team, style: AppText.uiCaption),
                              ],
                            ),
                          ),
                          if (status)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.green.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(AppTheme.radiusChip),
                              ),
                              child: Text('Krevd', style: AppText.monoSm.copyWith(color: AppColors.green)),
                            )
                          else
                            ElevatedButton(
                              onPressed: () => _submitClaim(context, doc.id, name),
                              style: ElevatedButton.styleFrom(
                                minimumSize: const Size(80, 36),
                                padding: const EdgeInsets.symmetric(horizontal: 14),
                              ),
                              child: Text('Det er meg', style: AppText.uiCta.copyWith(fontSize: 12)),
                            ),
                        ],
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
