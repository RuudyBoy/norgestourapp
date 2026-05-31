import 'package:flutter/material.dart';
import 'stats_logic.dart';

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

  @override
  void initState() {
    super.initState();
    sortedPlayers = List.from(widget.allPlayers);
    _sortPlayers(widget.initialSort);
  }

  void _showPlayerDrilldown(PlayerMatchStats p) {
  showDialog(
    context: context,
    builder: (context) => AlertDialog(
      title: Text("${p.playerName} - Detaljer"),
      content: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            if (p.killDetails.isNotEmpty) ...[
              const Text("ANGREPSFORDELING", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
              ...p.killDetails.entries.map((e) => Text("${e.key}: ${e.value}")),
              const SizedBox(height: 15),
            ],
            if (p.aceDetails.isNotEmpty) ...[
              const Text("SERVEFORDELING", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
              ...p.aceDetails.entries.map((e) => Text("${e.key}: ${e.value}")),
              const SizedBox(height: 15),
            ],
            if (p.attackErrorDetails.isNotEmpty) ...[
              const Text("FEILFORDELING", style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
              ...p.attackErrorDetails.entries.map((e) => Text("${e.key}: ${e.value}")),
            ],
          ],
        ),
      ),
      actions: [TextButton(onPressed: () => Navigator.pop(context), child: const Text("Lukk"))],
    ),
  );
}

  void _sortPlayers(String criteria) {
    setState(() {
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
      appBar: AppBar(
        title: const Text("Full oversikt"),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            // Knapperad for sortering
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _sortButton("Poeng", () => _sortPlayers("Toppscorer")),
                  _sortButton("Sideout", () => _sortPlayers("Sideout")), // Oppdatert
                  _sortButton("Blokk", () => _sortPlayers("Blokk")), // Oppdatert
                  _sortButton("Legg", () => _sortPlayers("Legging")),
                ],
              ),
            ),
            const SizedBox(height: 15),
            _buildStatsTable(sortedPlayers),
          ],
        ),
      ),
    );
  }

  Widget _sortButton(String text, VoidCallback onTap) {
    return Padding(
      padding: const EdgeInsets.only(right: 8.0),
      child: ActionChip(
        label: Text(text),
        onPressed: onTap,
        backgroundColor: Colors.white,
        elevation: 2,
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
        columnWidths: const {
          0: FlexColumnWidth(2.5), // Navn
          1: FlexColumnWidth(1),   // Tot
          2: FlexColumnWidth(1),   // SO (Sideout)
          3: FlexColumnWidth(1),   // Blokk
          4: FlexColumnWidth(1.2), // Legg
          5: FlexColumnWidth(1),   // Angrep (K/F)
        },
        border: TableBorder(horizontalInside: BorderSide(color: Colors.grey[200]!, width: 1)),
        children: [
          const TableRow(
            decoration: BoxDecoration(color: Color(0xFFF5F5F5)),
            children: [
              _HeaderCell("SPILLER", align: TextAlign.left),
              _HeaderCell("TOT"), 
              _HeaderCell("SO"),   // Sideout
              _HeaderCell("BLK"),  // Blokk
              _HeaderCell("LEGG"), 
              _HeaderCell("ANG"),
            ],
          ),
          ...players.map((p) => TableRow(
           children: [
    GestureDetector(
      onTap: () => _showPlayerDrilldown(p), // <--- Kaller detalj-visningen!
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(p.playerName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.blue)),
            Text(p.teamName, style: TextStyle(fontSize: 9, color: Colors.grey[600])),
          ],
        ),
      ),
    ),
              _DataCell(p.totalPoints.toString(), isBold: true, color: Colors.blue[800]),
              _DataCell("${p.sideoutPoints}", color: Colors.blue[600]), // Sideout
              _DataCell("${p.blocks}", color: Colors.red[700], isBold: true), // Blokk
              _DataCell(p.settingEfficiency),
              _DataCell("${p.kills}/${p.attackErrors}", color: Colors.grey[700]), // Vinn/Feil
            ],
          )),
        ],
      ),
    );
  }
}

// Hjelpeklasser
class _HeaderCell extends StatelessWidget {
  final String text; final TextAlign align;
  const _HeaderCell(this.text, {this.align = TextAlign.center});
  @override Widget build(BuildContext context) => Padding(padding: const EdgeInsets.symmetric(vertical: 8), child: Text(text, textAlign: align, style: const TextStyle(fontSize: 10, fontWeight: FontWeight.bold)));
}
class _DataCell extends StatelessWidget {
  final String text; final bool isBold; final Color? color;
  const _DataCell(this.text, {this.isBold = false, this.color});
  @override Widget build(BuildContext context) => Text(text, textAlign: TextAlign.center, style: TextStyle(fontWeight: isBold?FontWeight.bold:FontWeight.normal, color: color, fontSize: 12));
}