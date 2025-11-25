import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'stats_logic.dart';

class MatchStatsPage extends StatelessWidget {
  final String matchId;
  final String teamAName;
  final String teamBName;

  const MatchStatsPage({
    super.key,
    required this.matchId,
    required this.teamAName,
    required this.teamBName,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Kampfakta"),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: FirebaseFirestore.instance
            .collection('matches')
            .doc(matchId)
            .collection('events')
            .snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) return const Center(child: CircularProgressIndicator());

          final docs = snapshot.data!.docs;
          
          if (docs.isEmpty) {
            return const Center(child: Text("Ingen data enda."));
          }

          final eventsList = docs.map((d) => d.data() as Map<String, dynamic>).toList();
          final statsMap = calculateMatchStats(eventsList);
          
          final players = statsMap.values.toList();
          players.sort((a, b) {
            if (a.teamName == teamAName && b.teamName != teamAName) return -1;
            if (a.teamName != teamAName && b.teamName == teamAName) return 1;
            return b.totalPoints.compareTo(a.totalPoints);
          });

          return SingleChildScrollView(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                Text("$teamAName vs $teamBName", 
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)
                ),
                const SizedBox(height: 20),
                
                // Legend / Forklaring (Viktig når vi bruker forkortelser)
                const Padding(
                  padding: EdgeInsets.only(bottom: 10),
                  child: Text(
                    "SO = Sideout Poeng  |  MOT = Mottaksfeil",
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ),

                _buildStatsTable(players),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatsTable(List<PlayerMatchStats> players) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [const BoxShadow(color: Colors.black12, blurRadius: 4, offset: Offset(0, 2))],
      ),
      child: Table(
        defaultVerticalAlignment: TableCellVerticalAlignment.middle,
        // Vi justerer breddene for å få plass til alt
        columnWidths: const {
          0: FlexColumnWidth(2.5), // Navn
          1: FlexColumnWidth(1),   // Poeng
          2: FlexColumnWidth(1.2), // Angrep
          3: FlexColumnWidth(1),   // SO (Sideout)
          4: FlexColumnWidth(1.2), // Legg
          5: FlexColumnWidth(0.8), // Mot (Feil)
        },
        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey[200]!, width: 1)),
        children: [
          // HEADER
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
            children: [
              _HeaderCell("SPILLER", align: TextAlign.left),
              _HeaderCell("TOT"),
              _HeaderCell("ANG\n(V/F)"),
              _HeaderCell("SO"), // Sideout points
              _HeaderCell("LEGG"),
              _HeaderCell("MOT"), // Mottaksfeil
            ],
          ),
          
          // DATA RADER
          ...players.map((p) => TableRow(
            children: [
              // Navn
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(p.playerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                    Text(p.teamName, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
                  ],
                ),
              ),
              // Totalt poeng
              _DataCell(p.totalPoints.toString(), isBold: true, color: Colors.blue[800]),
              
              // Angrep (Kills / Feil)
              _DataCell("${p.kills}/${p.attackErrors}"),
              
              // Sideout poeng
              _DataCell("${p.sideoutPoints}"),
              
              // Legg effektivitet (Prosent)
              _DataCell(p.settingEfficiency),
              
              // Mottaksfeil (Rødt hvis mer enn 0)
              _DataCell("${p.receptionErrors}", color: p.receptionErrors > 0 ? Colors.red : Colors.black),
            ],
          )),
        ],
      ),
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  final TextAlign align;
  const _HeaderCell(this.text, {this.align = TextAlign.center});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      child: Text(text, 
        textAlign: align, 
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: Colors.grey[700])
      ),
    );
  }
}

class _DataCell extends StatelessWidget {
  final String text;
  final bool isBold;
  final Color? color;
  const _DataCell(this.text, {this.isBold = false, this.color});
  @override
  Widget build(BuildContext context) {
    return Text(text, 
      textAlign: TextAlign.center, 
      style: TextStyle(fontWeight: isBold ? FontWeight.bold : FontWeight.normal, color: color, fontSize: 12)
    );
  }
}