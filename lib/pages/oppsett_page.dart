import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';
import '../theme/app_theme.dart';
import 'match_stats_page.dart';

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
  String? _selectedCategoryId;
  String? _selectedStage;

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
              .where('published', isEqualTo: true)
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

        // 2. Stages and Content
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
                      child: Text("Ingen kamper/oppsett for denne klassen."));
                }

                // Extract unique stages
                final stages = <String>{};
                for (final m in matches) {
                  final label = _getStageLabel(m.data() as Map<String, dynamic>);
                  if (label != 'Andre kamper') {
                    stages.add(label);
                  }
                }
                
                final stageList = stages.toList()..sort((a, b) {
                  final isGroupA = a.startsWith('Pulje');
                  final isGroupB = b.startsWith('Pulje');
                  if (isGroupA && !isGroupB) return -1;
                  if (!isGroupA && isGroupB) return 1;
                  return a.compareTo(b);
                });

                if (stageList.isEmpty) {
                   return const Center(
                      child: Text("Ingen grupper eller sluttspill funnet."));
                }

                if (_selectedStage == null || !stageList.contains(_selectedStage)) {
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    if (mounted) {
                      setState(() => _selectedStage = stageList.first);
                    }
                  });
                  return const SizedBox();
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    _buildStageChips(stageList, isDark),
                    Expanded(
                      child: _buildStageContent(matches, isDark),
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
        title: Text("Oppsett - ${widget.tournamentName}"),
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
                    _selectedStage = null; // Reset stage
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

  Widget _buildStageChips(List<String> stages, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(
          horizontal: AppTheme.pageHPad, vertical: 8),
      child: Wrap(
        spacing: 6,
        runSpacing: 8,
        children: stages.map((s) {
          final isSelected = _selectedStage == s;
          return InkWell(
            onTap: () => setState(() => _selectedStage = s),
            borderRadius: BorderRadius.circular(8),
            child: Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isSelected
                    ? (isDark ? AppColors.nightSurface2 : AppColors.ink3)
                    : (isDark ? AppColors.nightSurface1 : AppColors.sand1),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? (isDark ? AppColors.nightInk2 : AppColors.ink)
                      : Colors.transparent,
                ),
              ),
              child: Text(
                s,
                style: TextStyle(
                  color: isSelected
                      ? (isDark ? Colors.white : Colors.white)
                      : (isDark ? Colors.white70 : Colors.black87),
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildStageContent(List<DocumentSnapshot> allMatches, bool isDark) {
    final stageStr = _selectedStage ?? '';
    
    if (stageStr.startsWith('Pulje')) {
      final groupName = stageStr.replaceAll('Pulje ', '');
      return _GroupContent(
        tournamentId: widget.tournamentId,
        categoryId: _selectedCategoryId!,
        groupName: groupName,
        groupMatches: allMatches.where((m) {
          final d = m.data() as Map<String, dynamic>;
          return d['stage'] == 'group' && d['group'] == groupName;
        }).toList(),
        isDark: isDark,
      );
    } else if (stageStr.startsWith('Sluttspill')) {
      final bracket = stageStr.replaceAll('Sluttspill ', '');
      final bracketMatches = allMatches.where((m) {
        final d = m.data() as Map<String, dynamic>;
        return d['stage'] == 'playoff' && d['bracket']?.toString().toUpperCase() == bracket;
      }).toList();
      return _PlayoffContent(
        matches: bracketMatches,
        allMatches: allMatches, // For looking up source match numbers
        isDark: isDark,
      );
    }
    
    return const SizedBox();
  }
}

class _GroupContent extends StatelessWidget {
  final String tournamentId;
  final String categoryId;
  final String groupName;
  final List<DocumentSnapshot> groupMatches;
  final bool isDark;

  const _GroupContent({
    required this.tournamentId,
    required this.categoryId,
    required this.groupName,
    required this.groupMatches,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<QuerySnapshot>(
      stream: FirebaseFirestore.instance
          .collection('teams')
          .where('tournament_id', isEqualTo: tournamentId)
          .where('category_id', isEqualTo: categoryId)
          .where('group', isEqualTo: groupName)
          .snapshots(),
      builder: (context, teamSnap) {
        if (!teamSnap.hasData) {
          return const Center(child: CircularProgressIndicator());
        }
        final groupTeams = teamSnap.data!.docs.toList()
          ..sort((a, b) {
            final ap = (a.data() as Map<String, dynamic>)['group_placement'] as int? ?? 99;
            final bp = (b.data() as Map<String, dynamic>)['group_placement'] as int? ?? 99;
            if (ap != 99 || bp != 99) return ap.compareTo(bp);
            final as_ = (a.data() as Map<String, dynamic>)['seed'] as int? ?? 99;
            final bs = (b.data() as Map<String, dynamic>)['seed'] as int? ?? 99;
            return as_.compareTo(bs);
          });

        groupMatches.sort((a, b) {
          final ta = (a.data() as Map<String, dynamic>)['match_type'] as String? ?? '';
          final tb = (b.data() as Map<String, dynamic>)['match_type'] as String? ?? '';
          return ta.compareTo(tb);
        });

        return ListView(
          padding: const EdgeInsets.all(AppTheme.pageHPad),
          children: [
            Container(
              decoration: BoxDecoration(
                color: isDark ? AppColors.nightSurface1 : Colors.white,
                borderRadius: BorderRadius.circular(AppTheme.radiusCard),
                boxShadow: AppTheme.shadowSm,
              ),
              clipBehavior: Clip.antiAlias,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
                    decoration: BoxDecoration(
                      gradient: isDark ? AppColors.cardInk : AppColors.heroNavy,
                    ),
                    child: Text(
                      "Tabell - Pulje $groupName",
                      style: AppText.uiTitle.copyWith(color: Colors.white),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Column(
                      children: [
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                          child: Row(
                            children: [
                              const SizedBox(width: 36),
                              Expanded(
                                flex: 5,
                                child: Text("LAG",
                                    style: AppText.monoSm.copyWith(
                                        color: isDark ? AppColors.nightInk3 : AppColors.ink3)),
                              ),
                              SizedBox(
                                width: 60,
                                child: Text("PLASS",
                                    style: AppText.monoSm.copyWith(
                                        color: isDark ? AppColors.nightInk3 : AppColors.ink3),
                                    textAlign: TextAlign.center),
                              ),
                            ],
                          ),
                        ),
                        const Divider(height: 1),
                        ...groupTeams.asMap().entries.map((entry) {
                          final idx = entry.key;
                          final d = entry.value.data() as Map<String, dynamic>;
                          final placement = d['group_placement'] as int?;
                          final Color dotColor;
                          if (placement == 1) {
                            dotColor = AppColors.coral;
                          } else if (placement == 2) {
                            dotColor = AppColors.blueBright;
                          } else {
                            dotColor = isDark ? AppColors.nightSurface2 : AppColors.sand2;
                          }

                          return Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                            child: Row(
                              children: [
                                Container(
                                  width: 24,
                                  height: 24,
                                  alignment: Alignment.center,
                                  decoration: BoxDecoration(
                                    color: dotColor,
                                    shape: BoxShape.circle,
                                  ),
                                  child: Text(
                                    "${idx + 1}",
                                    style: AppText.uiBody.copyWith(
                                        color: Colors.white, fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  flex: 5,
                                  child: Text(
                                    d['team_name'] as String? ?? 'Lag',
                                    style: AppText.uiBody.copyWith(
                                        color: isDark ? AppColors.nightInk : AppColors.ink,
                                        fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                SizedBox(
                                  width: 60,
                                  child: Text(
                                    placement?.toString() ?? "-",
                                    style: AppText.monoMd.copyWith(
                                        color: isDark ? AppColors.nightInk : AppColors.ink),
                                    textAlign: TextAlign.center,
                                  ),
                                ),
                              ],
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            Text(
              "KAMPOPPSETT",
              style: AppText.dispKicker().copyWith(color: AppColors.coral),
            ),
            const SizedBox(height: 12),
            if (groupMatches.isEmpty)
              Text("Ingen kamper satt opp for denne puljen enda.",
                  style: TextStyle(color: isDark ? Colors.white54 : Colors.black54))
            else
              ...groupMatches.map((m) {
                final d = m.data() as Map<String, dynamic>;
                final time = (d['match_time'] ?? d['start_time']) as String?;
                final court = d['court'] as String?;
                final typeText = d['match_type'] as String? ?? 'Gruppespill';
                final matchInfo = [
                  typeText,
                  if (time != null && time.isNotEmpty) time,
                  if (court != null && court.isNotEmpty) court,
                ].join(' • ');

                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.nightSurface2 : AppColors.sand1,
                    borderRadius: BorderRadius.circular(AppTheme.radiusBadge),
                    border: Border.all(
                        color: isDark ? AppColors.nightSurface2 : AppColors.sand2),
                  ),
                  child: Row(
                    children: [
                      Container(
                        width: 100,
                        padding: const EdgeInsets.only(right: 12),
                        child: Text(matchInfo,
                            style: AppText.monoSm.copyWith(
                                color: isDark ? AppColors.nightInk3 : AppColors.ink3,
                                fontSize: 10)),
                      ),
                      Expanded(
                        child: Text(
                          "${d['team_a_name'] ?? 'TBD'} – ${d['team_b_name'] ?? 'TBD'}",
                          style: AppText.uiBody.copyWith(
                              color: isDark ? AppColors.nightInk : AppColors.ink,
                              fontWeight: FontWeight.w500),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                );
              }),
          ],
        );
      },
    );
  }
}

class _PlayoffContent extends StatelessWidget {
  final List<DocumentSnapshot> matches;
  final List<DocumentSnapshot> allMatches;
  final bool isDark;

  const _PlayoffContent({
    required this.matches,
    required this.allMatches,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    if (matches.isEmpty) {
      return Center(
        child: Text(
          'Sluttspill ikke satt opp.',
          style: AppText.uiCaption.copyWith(
              color: isDark ? AppColors.nightInk3 : AppColors.ink3),
        ),
      );
    }

    final byRound = <String, List<DocumentSnapshot>>{};
    for (final m in matches) {
      final round = (m.data() as Map)['round'] as String? ?? '';
      byRound.putIfAbsent(round, () => []).add(m);
    }

    const roundOrder = ['omspill', 'r16', 'r8', 'qf', 'sf', 'final'];
    final sortedRounds = byRound.keys.toList()
      ..sort((a, b) {
        final ia = roundOrder.indexOf(a);
        final ib = roundOrder.indexOf(b);
        return (ia == -1 ? 99 : ia).compareTo(ib == -1 ? 99 : ib);
      });

    final roundLabels = <String, String>{
      'omspill': 'Playoff',
      'r16': '1/16-finaler',
      'r8': '1/8-finaler',
      'qf': 'Kvartfinaler',
      'sf': 'Semifinaler',
      'final': 'FINALE',
    };

    return ListView(
      padding: const EdgeInsets.all(AppTheme.pageHPad),
      children: [
        for (final round in sortedRounds) ...[
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 10),
            child: Text(
              roundLabels[round] ?? round.toUpperCase(),
              style: AppText.dispKicker().copyWith(color: AppColors.coral),
            ),
          ),
          for (final m in byRound[round]!)
            _MatchCard(matchDoc: m, allMatches: allMatches, isDark: isDark),
        ],
      ],
    );
  }
}

class _MatchCard extends StatelessWidget {
  final DocumentSnapshot matchDoc;
  final List<DocumentSnapshot> allMatches;
  final bool isDark;

  const _MatchCard({
    required this.matchDoc,
    required this.allMatches,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final d = matchDoc.data() as Map<String, dynamic>;
    final status = d['status'] as String? ?? 'pending';
    final isLive = status == 'live';
    final isFinished = status == 'finished';
    final isPending = status == 'pending';
    final homeScore = d['home_score'] as int? ?? 0;
    final awayScore = d['away_score'] as int? ?? 0;
    final matchNumber = d['match_number'] as int?;
    final timeLabel = (d['match_time'] ?? d['start_time'])?.toString() ?? '';

    String getTeamName(String prefix) {
      String name = d['${prefix}_name'] as String? ?? 'TBD';
      if (name.toLowerCase() == 'vinner' || name.toLowerCase() == 'taper') {
        final fromMatchId = d['${prefix}_from_match_id'] as String?;
        if (fromMatchId != null) {
          final sourceMatch = allMatches.cast<DocumentSnapshot?>().firstWhere(
            (m) => m?.id == fromMatchId, 
            orElse: () => null
          );
          if (sourceMatch != null) {
            final sourceData = sourceMatch.data() as Map<String, dynamic>;
            final matchNum = sourceData['match_number'];
            if (matchNum != null) {
              return '$name kamp $matchNum';
            }
          }
        }
      }
      return name;
    }

    final teamAName = getTeamName('team_a');
    final teamBName = getTeamName('team_b');

    final textColor = isDark ? AppColors.nightInk : AppColors.ink;
    final dimColor = isDark ? AppColors.nightInk3 : AppColors.ink3;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: isDark ? AppColors.nightSurface1 : Colors.white,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        boxShadow: AppTheme.shadowSm,
        border: Border.all(
          color: isLive ? AppColors.coral : Colors.transparent,
          width: 1.5,
        ),
      ),
      child: InkWell(
        onTap: isFinished
            ? () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => MatchStatsPage(
                      matchId: matchDoc.id,
                      teamAName: teamAName,
                      teamBName: teamBName,
                    ),
                  ),
                )
            : null,
        borderRadius: BorderRadius.circular(AppTheme.radiusCard),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          child: Row(
            children: [
              if (matchNumber != null || timeLabel.isNotEmpty || d['court'] != null)
                Container(
                  width: 52,
                  margin: const EdgeInsets.only(right: 12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (matchNumber != null)
                        Text(
                          "#$matchNumber",
                          style: AppText.monoSm.copyWith(color: dimColor),
                        ),
                      if (timeLabel.isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            timeLabel,
                            style: AppText.monoSm.copyWith(color: dimColor, fontSize: 10),
                          ),
                        ),
                      if (d['court'] != null && d['court'].toString().isNotEmpty)
                        Padding(
                          padding: const EdgeInsets.only(top: 2),
                          child: Text(
                            d['court'].toString(),
                            style: AppText.monoSm.copyWith(color: dimColor, fontSize: 10),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                  ),
                ),
              Expanded(
                child: Text(
                  teamAName,
                  style: AppText.uiBody.copyWith(
                    color: isPending ? dimColor : textColor,
                    fontWeight:
                        (isFinished && homeScore > awayScore) ? FontWeight.bold : null,
                    fontStyle: isPending ? FontStyle.italic : null,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                child: isLive
                    ? Container(
                        padding:
                            const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                            color: AppColors.coral,
                            borderRadius: BorderRadius.circular(4)),
                        child: Text("LIVE",
                            style: AppText.monoSm
                                .copyWith(color: Colors.white, fontSize: 10)),
                      )
                    : Text(
                        isFinished ? "$homeScore – $awayScore" : "–",
                        style: AppText.dispScore(18).copyWith(color: textColor),
                      ),
              ),
              Expanded(
                child: Text(
                  teamBName,
                  style: AppText.uiBody.copyWith(
                    color: isPending ? dimColor : textColor,
                    fontWeight:
                        (isFinished && awayScore > homeScore) ? FontWeight.bold : null,
                    fontStyle: isPending ? FontStyle.italic : null,
                  ),
                  textAlign: TextAlign.right,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
