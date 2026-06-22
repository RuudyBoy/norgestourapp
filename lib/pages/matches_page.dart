import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'match_stats_page.dart';

class MatchesPage extends StatefulWidget {
  final String tournamentId;
  final String tournamentName;
  final bool isEmbedded;

  const MatchesPage({
    super.key,
    required this.tournamentId,
    required this.tournamentName,
    this.isEmbedded = false,
  });

  @override
  State<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends State<MatchesPage> {
  String? _selectedCategoryId;
  String _selectedStatus = 'alle'; // 'alle', 'live', 'scheduled', 'finished'

  String _getStageLabel(Map<String, dynamic> d) {
    final stage = d['stage'] as String?;
    if (stage == 'group') {
      final group = d['group'] as String?;
      return group != null ? 'Pulje $group' : 'Puljespill';
    } else if (stage == 'playoff') {
      final bracket = d['bracket'] as String?;
      return bracket != null ? 'Sluttspill ${bracket.toUpperCase()}' : 'Sluttspill';
    }
    return 'Andre kamper';
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // 1. Categories Row
        StreamBuilder<QuerySnapshot>(
          stream: FirebaseFirestore.instance
              .collection('categories')
              .where('tournament_id', isEqualTo: widget.tournamentId)
              .snapshots(),
          builder: (context, catSnap) {
            if (!catSnap.hasData) {
              return const SizedBox(
                  height: 60, child: Center(child: CircularProgressIndicator()));
            }
            final cats = catSnap.data!.docs;
            if (cats.isEmpty) {
              return const SizedBox(
                  height: 60, child: Center(child: Text("Ingen klasser funnet.")));
            }

            // Auto-select first category if null
            if (_selectedCategoryId == null && cats.isNotEmpty) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) {
                  setState(() => _selectedCategoryId = cats.first.id);
                }
              });
              return const SizedBox(height: 60);
            }

            return _buildCategoryChips(cats, isDark);
          },
        ),

        // 2. Status Row
        _buildStatusChips(isDark),

        // 3. Matches and Stages List
        if (_selectedCategoryId != null)
          Expanded(
            child: StreamBuilder<QuerySnapshot>(
              stream: FirebaseFirestore.instance
                  .collection('matches')
                  .where('tournament_id', isEqualTo: widget.tournamentId)
                  .where('category_id', isEqualTo: _selectedCategoryId)
                  .snapshots(),
              builder: (context, matchSnap) {
                if (!matchSnap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final matches = matchSnap.data!.docs;

                if (matches.isEmpty) {
                  return const Center(
                      child: Text("Ingen kamper satt opp for denne klassen."));
                }

                // Filter matches locally
                final filtered = matches.where((m) {
                  final d = m.data() as Map<String, dynamic>;
                  if (_selectedStatus != 'alle' && d['status'] != _selectedStatus) {
                    return false;
                  }
                  return true;
                }).toList();

                // Sort matches chronologically
                filtered.sort((a, b) {
                  final da = a.data() as Map<String, dynamic>;
                  final db = b.data() as Map<String, dynamic>;
                  final ta = da['scheduled_minutes'] as int? ?? 999999;
                  final tb = db['scheduled_minutes'] as int? ?? 999999;
                  if (ta != tb) return ta.compareTo(tb);
                  return (da['court'] as String? ?? '')
                      .compareTo(db['court'] as String? ?? '');
                });

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: filtered.isEmpty
                          ? const Center(
                              child: Text(
                                "Ingen kamper matcher valgt filter.",
                                style: TextStyle(color: Colors.grey),
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.all(AppTheme.pageHPad),
                              itemCount: filtered.length,
                              itemBuilder: (ctx, i) =>
                                  _buildMatchCard(filtered[i], isDark),
                            ),
                    ),
                  ],
                );
              },
            ),
          ),
      ],
    );

    if (widget.isEmbedded) {
      return content;
    }

    return Scaffold(
      appBar: AppBar(
        title: Text("Kamper - ${widget.tournamentName}"),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: content,
    );
  }

  Widget _buildCategoryChips(List<QueryDocumentSnapshot> cats, bool isDark) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pageHPad, vertical: 12),
      child: Row(
        children: cats.map((c) {
          final d = c.data() as Map<String, dynamic>;
          final name = d['name'] as String? ?? 'Ukjent';
          final isSelected = _selectedCategoryId == c.id;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(name),
              selected: isSelected,
              onSelected: (v) {
                if (v) {
                  setState(() {
                    _selectedCategoryId = c.id;
                  });
                }
              },
              selectedColor: AppColors.coral,
              labelStyle: TextStyle(
                color: isSelected
                    ? Colors.white
                    : (isDark ? Colors.white70 : Colors.black87),
                fontWeight: FontWeight.bold,
              ),
              backgroundColor: isDark ? AppColors.nightSurface1 : Colors.white,
              side: BorderSide(
                color: isSelected
                    ? AppColors.coral
                    : (isDark ? AppColors.nightSurface2 : AppColors.sand2),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStatusChips(bool isDark) {
    final statuses = [
      {'id': 'alle', 'label': 'Alle'},
      {'id': 'live', 'label': 'Live'},
      {'id': 'scheduled', 'label': 'Kommende'},
      {'id': 'finished', 'label': 'Ferdig'},
    ];

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pageHPad, vertical: 4),
      child: Row(
        children: statuses.map((s) {
          final isSelected = _selectedStatus == s['id'];
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(s['label']!),
              selected: isSelected,
              onSelected: (v) {
                if (v) setState(() => _selectedStatus = s['id']!);
              },
              selectedColor: isDark ? AppColors.nightSurface2 : AppColors.sand2,
              labelStyle: TextStyle(
                color: isSelected
                    ? (isDark ? AppColors.coral : AppColors.coral)
                    : (isDark ? Colors.white54 : Colors.black54),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
              backgroundColor: Colors.transparent,
              side: BorderSide.none,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20)),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildMatchCard(QueryDocumentSnapshot matchDoc, bool isDark) {
    final data = matchDoc.data() as Map<String, dynamic>;
    final status = data['status'] as String? ?? 'scheduled';

    final homeScore = data['home_score'] ?? 0;
    final awayScore = data['away_score'] ?? 0;
    final homeSets = data['home_sets'] ?? 0;
    final awaySets = data['away_sets'] ?? 0;
    final currentSet = data['current_set'] ?? 1;
    final court = data['court'] ?? 'Bane ?';
    final teamAName = data['team_a_name'] ?? 'Lag A';
    final teamBName = data['team_b_name'] ?? 'Lag B';
    final startTime = data['match_time']?.toString() ??
        data['start_time']?.toString() ??
        '';
    final stageLabel = _getStageLabel(data);

    String rightInfo = '';
    if (startTime.isNotEmpty) {
      rightInfo = '$startTime • $court • $stageLabel';
    } else {
      rightInfo = '$court • $stageLabel';
    }

    return GestureDetector(
      onTap: () {
        if (status == 'scheduled') {
          ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(content: Text("Kampen har ikke startet enda.")));
        } else {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => MatchStatsPage(
                matchId: matchDoc.id,
                teamAName: teamAName,
                teamBName: teamBName,
              ),
            ),
          );
        }
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: AppTheme.rowGap),
        padding: const EdgeInsets.all(AppTheme.cardPad),
        decoration: BoxDecoration(
          gradient: AppColors.cardInk,
          borderRadius: BorderRadius.circular(AppTheme.radiusCard),
          boxShadow: AppTheme.shadowSm,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: status == 'live'
                        ? AppColors.coral
                        : (status == 'finished'
                            ? (isDark
                                ? AppColors.nightSurface2
                                : AppColors.sand2)
                            : AppColors.blue.withValues(alpha: 0.1)),
                    borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (status == 'live') ...[
                        Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                                color: Colors.white, shape: BoxShape.circle)),
                        const SizedBox(width: 5),
                      ],
                      Text(
                          status == 'scheduled'
                              ? 'KOMMENDE'
                              : (status == 'finished'
                                  ? 'FERDIG'
                                  : 'LIVE · SETT $currentSet'),
                          style: AppText.monoSm.copyWith(
                              color: status == 'live'
                                  ? Colors.white
                                  : (status == 'scheduled'
                                      ? AppColors.blue
                                      : (isDark
                                          ? AppColors.nightInk2
                                          : AppColors.ink2)))),
                    ],
                  ),
                ),
                Expanded(
                  child: Text(
                    rightInfo.toUpperCase(),
                    style: AppText.monoSm.copyWith(color: Colors.white70),
                    textAlign: TextAlign.right,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(teamAName.toUpperCase(),
                      style: AppText.dispH2(18).copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                ),
                if (status == 'finished')
                  Text('$homeSets',
                      style: AppText.dispScore(32).copyWith(color: Colors.white))
                else if (status == 'live')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (currentSet > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text('($homeSets)',
                              style: AppText.dispScore(20).copyWith(color: Colors.white54)),
                        ),
                      Text('$homeScore',
                          style: AppText.dispScore(32).copyWith(color: Colors.white)),
                    ],
                  )
                else
                  Text('-',
                      style: AppText.dispScore(32).copyWith(color: Colors.white70)),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Text(teamBName.toUpperCase(),
                      style: AppText.dispH2(18).copyWith(color: Colors.white),
                      overflow: TextOverflow.ellipsis),
                ),
                if (status == 'finished')
                  Text('$awaySets',
                      style: AppText.dispScore(32).copyWith(color: Colors.white))
                else if (status == 'live')
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      if (currentSet > 1)
                        Padding(
                          padding: const EdgeInsets.only(right: 12.0),
                          child: Text('($awaySets)',
                              style: AppText.dispScore(20).copyWith(color: Colors.white54)),
                        ),
                      Text('$awayScore',
                          style: AppText.dispScore(32).copyWith(color: Colors.white)),
                    ],
                  )
                else
                  Text('-',
                      style: AppText.dispScore(32).copyWith(color: Colors.white70)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}