import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'models.dart';
import 'league_logic.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_text_styles.dart';
import '../../theme/app_theme.dart';

class FantasyLeaguesView extends StatefulWidget {
  final List<FantasyPlayer> players;
  const FantasyLeaguesView({super.key, required this.players});

  @override
  State<FantasyLeaguesView> createState() => _FantasyLeaguesViewState();
}

class _FantasyLeaguesViewState extends State<FantasyLeaguesView> {
  bool _isGlobalTab = true;
  bool _isLoading = true;
  List<LeaderboardEntry> _globalLeaderboard = [];
  final String? _currentUserId = FirebaseAuth.instance.currentUser?.uid;

  @override
  void initState() {
    super.initState();
    _fetchLeaderboard();
  }

  Future<void> _fetchLeaderboard() async {
    setState(() => _isLoading = true);
    _globalLeaderboard = await LeagueLogic.getGlobalLeaderboard(widget.players);
    if (mounted) setState(() => _isLoading = false);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Tab selector
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: AppTheme.pageHPad),
          child: Row(
            children: [
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _isGlobalTab = true),
                child: _buildTab('Global', _isGlobalTab),
              )),
              const SizedBox(width: 10),
              Expanded(child: GestureDetector(
                onTap: () => setState(() => _isGlobalTab = false),
                child: _buildTab('Mine Ligaer', !_isGlobalTab),
              )),
            ],
          ),
        ),

        if (!_isGlobalTab)
          Padding(
            padding: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 0, AppTheme.pageHPad, 12),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kommer snart!')),
                    ),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Lag Liga', style: TextStyle(color: Colors.white)),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral, foregroundColor: Colors.white),
                    onPressed: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Kommer snart!')),
                    ),
                    icon: const Icon(Icons.group_add, size: 16),
                    label: const Text('Bli med', style: TextStyle(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),

        // Leaderboard
        Expanded(
          child: Container(
            margin: const EdgeInsets.fromLTRB(AppTheme.pageHPad, 0, AppTheme.pageHPad, 16),
            decoration: BoxDecoration(
              color: AppColors.sand0,
              borderRadius: BorderRadius.circular(AppTheme.radiusCard),
              boxShadow: AppTheme.shadowSm,
            ),
            child: Column(
              children: [
                // Header row
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: AppTheme.cardPad, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppColors.sand2,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AppTheme.radiusCard)),
                  ),
                  child: Row(
                    children: [
                      SizedBox(width: 36, child: Text('#', style: AppText.monoSm)),
                      Expanded(child: Text('Team', style: AppText.monoSm)),
                      Text('Poeng', style: AppText.monoSm),
                    ],
                  ),
                ),

                Expanded(
                  child: _isLoading
                      ? const Center(child: CircularProgressIndicator(color: AppColors.coral))
                      : (!_isGlobalTab)
                          ? Center(child: Text('Du er ikke med i noen private ligaer ennå.', style: AppText.uiCaption))
                          : ListView.separated(
                              itemCount: _globalLeaderboard.length,
                              separatorBuilder: (_, _) => const Divider(height: 1, color: AppColors.line),
                              itemBuilder: (context, index) {
                                final entry = _globalLeaderboard[index];
                                final isCurrentUser = entry.userId == _currentUserId;
                                final rank = index + 1;
                                final isTop3 = rank <= 3;

                                return Container(
                                  color: isCurrentUser ? AppColors.coral.withOpacity(0.06) : Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: AppTheme.cardPad,
                                    vertical: 12,
                                  ),
                                  child: Row(
                                    children: [
                                      SizedBox(
                                        width: 36,
                                        child: Text(
                                          '$rank',
                                          style: isTop3
                                              ? AppText.dispH2(16).copyWith(color: AppColors.coral)
                                              : AppText.monoMd,
                                        ),
                                      ),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(entry.teamName, style: AppText.uiTitle),
                                            Text(entry.managerName, style: AppText.uiCaption),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        '${entry.totalPoints}',
                                        style: AppText.dispH2(18).copyWith(
                                          color: isCurrentUser ? AppColors.coral : AppColors.ink,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildTab(String title, bool isSelected) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10),
      decoration: BoxDecoration(
        color: isSelected ? AppColors.coral : AppColors.sand2,
        borderRadius: BorderRadius.circular(AppTheme.radiusChip),
      ),
      child: Text(
        title,
        textAlign: TextAlign.center,
        style: AppText.uiCta.copyWith(
          color: isSelected ? Colors.white : AppColors.ink2,
          fontSize: 13,
          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
        ),
      ),
    );
  }
}
