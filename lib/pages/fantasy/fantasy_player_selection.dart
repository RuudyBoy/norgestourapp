import 'package:flutter/material.dart';
import 'models.dart';

class FantasyPlayerSelection extends StatelessWidget {
  final String role;
  final Map<String, String?> currentSelectedPlayers;
  final List<FantasyPlayer> players;
  final Map<String, double> ownershipPercentages;
  final Function(String playerId) onSelect;
  final String? linkedPlayerId;

  const FantasyPlayerSelection({
    super.key,
    required this.role,
    required this.currentSelectedPlayers,
    required this.players,
    required this.ownershipPercentages,
    required this.onSelect,
    this.linkedPlayerId,
  });

  @override
  Widget build(BuildContext context) {
    // Calculate current total value excluding the player currently in this role
    double currentTotalValue = 0;
    for (var entry in currentSelectedPlayers.entries) {
      if (entry.key != role && entry.value != null) {
        final match = players.where((p) => p.id == entry.value);
        if (match.isNotEmpty) {
          currentTotalValue += match.first.price;
        }
      }
    }

    // Determine which stat is most relevant for the selected role to highlight
    String primaryStat(FantasyPlayer p) {
      switch (role) {
        case FantasyRole.block:
          return '${p.blocks} Blocks';
        case FantasyRole.defense:
          return '${p.digs} Digs';
        case FantasyRole.attack:
          return '${p.attacks} Attacks';
        case FantasyRole.set:
          return '${p.sets} Sets';
        case FantasyRole.receive:
          return '${p.receives} Receives';
        case FantasyRole.serve:
          return '${p.aces} Aces';
        default:
          return '${p.totalPoints} Pts';
      }
    }

    return Scaffold(
      backgroundColor: const Color(0xFF0A1931),
      appBar: AppBar(
        title: Text('Select $role'),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: players.length,
        itemBuilder: (context, index) {
          final player = players[index];
          // Check if player is already selected in any other role
          bool isSelected = currentSelectedPlayers.values.contains(player.id);
          String? selectedRole;
          if (isSelected) {
            currentSelectedPlayers.forEach((key, value) {
              if (value == player.id) {
                selectedRole = key;
              }
            });
          }

          // Check if selecting this player would exceed the 50m budget
          bool exceedsBudget = (currentTotalValue + player.price) > 50.0;
          bool isDisabled = (isSelected && selectedRole != role) || exceedsBudget;

          double ownership = ownershipPercentages[player.id] ?? 0.0;

          return Card(
            color: isDisabled ? const Color(0xFF1E3A8A).withValues(alpha: 0.5) : const Color(0xFF1E3A8A),
            margin: const EdgeInsets.only(bottom: 12),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
              side: BorderSide(
                color: isSelected ? Colors.redAccent.withValues(alpha: 0.5) : Colors.transparent,
                width: 1,
              ),
            ),
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              leading: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white12,
                  border: Border.all(color: const Color(0xFF00FFCC), width: 1),
                ),
                child: player.imageUrl.isNotEmpty
                    ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                    : const Icon(Icons.person, color: Colors.white),
              ),
              title: Text(
                player.id == linkedPlayerId ? 'MEG (${player.name})' : player.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  Text(
                    player.team,
                    style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 12),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Valgt av: ${ownership.toStringAsFixed(1)}%',
                    style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 11),
                  ),
                  if (isSelected)
                    Padding(
                      padding: const EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Selected for $selectedRole',
                        style: const TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                  if (exceedsBudget && !isSelected)
                    const Padding(
                      padding: EdgeInsets.only(top: 4.0),
                      child: Text(
                        'Overgår budsjett!',
                        style: TextStyle(color: Colors.redAccent, fontSize: 12),
                      ),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '\$${player.price}m',
                    style: const TextStyle(
                      color: Color(0xFF00FFCC),
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    primaryStat(player),
                    style: const TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
              onTap: isDisabled ? () {
                if (exceedsBudget) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Du har ikke nok budsjett til å velge denne spilleren! (Maks 50m)')),
                  );
                } else if (isSelected && selectedRole != role) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text('${player.name} spiller allerede som $selectedRole!')),
                  );
                }
              } : () {
                onSelect(player.id);
                Navigator.pop(context);
              },
            ),
          );
        },
      ),
    );
  }
}
