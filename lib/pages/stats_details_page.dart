import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stats_logic.dart';
import 'player_detail_page.dart';

class StatsDetailsPage extends StatefulWidget {
  final List<PlayerMatchStats> allPlayers;
  final String initialSort; 

  const StatsDetailsPage({
    super.key,
    required this.allPlayers,
    required this.initialSort,
  });

  @override
  State<StatsDetailsPage> createState() => _StatsDetailsPageState();
}

class _StatsDetailsPageState extends State<StatsDetailsPage> {
  late List<PlayerMatchStats> sortedPlayers;
  late String currentSort;

  @override
  void initState() {
    super.initState();
    sortedPlayers = List.from(widget.allPlayers);
    currentSort = widget.initialSort;
    _sortPlayers(currentSort);
  }

  Future<void> _navigateToPlayerProfile(PlayerMatchStats p) async {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator(color: Color(0xFFFF3B30))),
    );

    try {
      final query = await FirebaseFirestore.instance.collection('players').get();
      
      if (!mounted) return;
      Navigator.pop(context); // Lukk loading

      final docs = query.docs.where((doc) {
        final data = doc.data();
        final firstName = data['first_name'] ?? '';
        final lastName = data['last_name'] ?? '';
        final fullName = "$firstName $lastName";
        return fullName.toLowerCase() == p.playerName.toLowerCase();
      }).toList();

      if (docs.isNotEmpty) {
        final doc = docs.first;
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PlayerDetailPage(
              playerId: doc.id,
              playerData: doc.data(),
            ),
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Fant ikke profil for ${p.playerName}')),
        );
      }
    } catch (e) {
      if (!mounted) return;
      Navigator.pop(context);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Feil ved henting av spiller')),
      );
    }
  }

  void _sortPlayers(String criteria) {
    setState(() {
      currentSort = criteria;
      if (criteria == "Toppscorer") {
        sortedPlayers.sort((a, b) => b.totalPoints.compareTo(a.totalPoints));
      } else if (criteria == "Sideout") {
        sortedPlayers.sort((a, b) => b.sideoutPoints.compareTo(a.sideoutPoints));
      } else if (criteria == "Blokk") {
        sortedPlayers.sort((a, b) => b.blocks.compareTo(a.blocks));
      } else if (criteria == "Legging") {
         sortedPlayers.sort((a, b) {
           double aPct = a.setAttempts == 0 ? 0 : (a.setAssists / a.setAttempts);
           double bPct = b.setAttempts == 0 ? 0 : (b.setAssists / b.setAttempts);
           return bPct.compareTo(aPct);
        });
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.transparent, // Inherit from main if used in stack, or black
      appBar: AppBar(
        title: const Text("FULL OVERSIKT", style: TextStyle(fontWeight: FontWeight.bold, letterSpacing: 1.2)),
        backgroundColor: Colors.transparent,
        elevation: 0,
        foregroundColor: Colors.white,
      ),
      body: Column(
        children: [
          // Knapperad for sortering
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _sortButton("Poeng", () => _sortPlayers("Toppscorer"), currentSort == "Toppscorer"),
                  _sortButton("Sideout", () => _sortPlayers("Sideout"), currentSort == "Sideout"),
                  _sortButton("Blokk", () => _sortPlayers("Blokk"), currentSort == "Blokk"),
                  _sortButton("Legg", () => _sortPlayers("Legging"), currentSort == "Legging"),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Expanded(
            child: _buildStatsList(sortedPlayers),
          ),
        ],
      ),
    );
  }

  Widget _sortButton(String text, VoidCallback onTap, bool isSelected) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(
          text,
          style: TextStyle(
            color: isSelected ? Colors.black : Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        onPressed: onTap,
        backgroundColor: isSelected ? const Color(0xFF1DD05D) : const Color(0xFF2C2C2E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        side: BorderSide(color: isSelected ? const Color(0xFF1DD05D) : Colors.white24),
      ),
    );
  }

  Widget _buildStatsList(List<PlayerMatchStats> players) {
    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      itemCount: players.length,
      itemBuilder: (context, index) {
        final p = players[index];
        return GestureDetector(
          onTap: () => _navigateToPlayerProfile(p),
          child: Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF1E1E1E),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Colors.white10),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 8,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: Row(
              children: [
                // Rank
                SizedBox(
                  width: 30,
                  child: Text(
                    "#${index + 1}",
                    style: const TextStyle(
                      color: Colors.white54,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                // Name & Team
                Expanded(
                  flex: 3,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        p.playerName,
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        p.teamName,
                        style: TextStyle(
                          color: Colors.grey[500],
                          fontSize: 12,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                // Key Stats
                Expanded(
                  flex: 4,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildMiniStat("TOT", p.totalPoints.toString(), isHighlight: currentSort == "Toppscorer"),
                      _buildMiniStat("SO", p.sideoutPoints.toString(), isHighlight: currentSort == "Sideout"),
                      _buildMiniStat("BLK", p.blocks.toString(), isHighlight: currentSort == "Blokk"),
                      _buildMiniStat("LEGG", p.settingEfficiency, isHighlight: currentSort == "Legging"),
                    ],
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildMiniStat(String label, String value, {bool isHighlight = false}) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            color: isHighlight ? const Color(0xFF1DD05D) : Colors.grey[500],
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            color: isHighlight ? Colors.white : Colors.grey[300],
            fontSize: 16,
            fontWeight: isHighlight ? FontWeight.w900 : FontWeight.bold,
          ),
        ),
      ],
    );
  }
}