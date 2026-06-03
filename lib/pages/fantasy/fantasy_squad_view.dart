import 'package:flutter/material.dart';
import 'models.dart';

class FantasySquadView extends StatelessWidget {
  final Map<String, String?> selectedPlayers;
  final List<FantasyPlayer> players;
  final Function(String role) onRoleTap;
  final String? linkedPlayerId;

  const FantasySquadView({
    super.key,
    required this.selectedPlayers,
    required this.players,
    required this.onRoleTap,
    this.linkedPlayerId,
  });

  Widget _buildPlayerSlot(BuildContext context, String role, String? playerId, double width) {
    FantasyPlayer? player;
    if (playerId != null) {
      final matches = players.where((p) => p.id == playerId);
      player = matches.isNotEmpty ? matches.first : null;
    }

    return GestureDetector(
      onTap: () {
        if (player != null) {
          _showPlayerOptions(context, role, player);
        } else {
          onRoleTap(role);
        }
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: width * 0.15,
            height: width * 0.15,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: player != null ? const Color(0xFF1E3A8A) : Colors.black45,
              border: Border.all(
                color: player != null ? const Color(0xFF00FFCC) : Colors.white54,
                width: 2,
              ),
              boxShadow: player != null
                  ? [
                      BoxShadow(
                        color: const Color(0xFF00FFCC).withValues(alpha: 0.5),
                        blurRadius: 10,
                        spreadRadius: 1,
                      )
                    ]
                  : [],
            ),
            child: player != null && player.imageUrl.isNotEmpty
                ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                : Icon(
                    player != null ? Icons.person : Icons.person_add,
                    color: Colors.white,
                    size: width * 0.08,
                  ),
          ),
          const SizedBox(height: 4),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.black87,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              player != null ? (player.id == linkedPlayerId ? 'MEG' : player.name.split(' ').last) : role,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.bold,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (player != null)
            Container(
              margin: const EdgeInsets.only(top: 2.0),
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: const Color(0xFF00FFCC).withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '${player.price}m',
                style: const TextStyle(
                  color: Color(0xFF00FFCC),
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        // Calculate total team value
        double totalValue = 0;
        int totalPoints = 0;
        for (var playerId in selectedPlayers.values) {
          if (playerId != null) {
            final matches = players.where((p) => p.id == playerId);
            if (matches.isNotEmpty) {
              final p = matches.first;
              totalValue += p.price;
              totalPoints += p.totalPoints;
            }
          }
        }

        return Column(
          children: [
            // Stats Header
            Container(
              padding: const EdgeInsets.all(16),
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF1E3A8A), Color(0xFF0A1931)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.3),
                    blurRadius: 10,
                    offset: const Offset(0, 5),
                  ),
                ],
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildStatItem('Points', totalPoints.toString()),
                  _buildStatItem('Budget', '\$${(50.0 - totalValue).toStringAsFixed(1)}m'),
                  _buildStatItem('Value', '\$${totalValue.toStringAsFixed(1)}m'),
                ],
              ),
            ),
            
            // Deadline Info
            Container(
              padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
              margin: const EdgeInsets.only(bottom: 8),
              decoration: BoxDecoration(
                color: Colors.redAccent.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Colors.redAccent, width: 1),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.timer, color: Colors.white, size: 16),
                  SizedBox(width: 8),
                  Text(
                    'Tidsfrist for neste runde: I morgen kl 18:00',
                    style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
            ),
            
            // Pitch Area
            Expanded(
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  color: const Color(0xFFD2B48C), // Sand color
                  image: const DecorationImage(
                    image: AssetImage('assets/sand_texture.png'), // Will fallback nicely if not exists
                    fit: BoxFit.cover,
                    colorFilter: ColorFilter.mode(
                      Colors.black26,
                      BlendMode.darken,
                    ),
                  ),
                  border: Border.all(color: Colors.white24, width: 2),
                ),
                child: Stack(
                  children: [
                    // Court lines (Top half)
                    Positioned.fill(
                      child: Column(
                        children: [
                          Container(
                            height: 4,
                            color: Colors.white70, // Net
                          ),
                          Expanded(
                            child: Container(
                              margin: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                border: Border.all(color: Colors.white70, width: 2),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    
                    // Players Positioned
                    // Net (Blokk)
                    Positioned(
                      top: 40,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildPlayerSlot(context, FantasyRole.block, selectedPlayers[FantasyRole.block], width),
                      ),
                    ),
                    
                    // Middle (Angrep, Legg)
                    Positioned(
                      top: 140,
                      left: width * 0.15,
                      child: _buildPlayerSlot(context, FantasyRole.attack, selectedPlayers[FantasyRole.attack], width),
                    ),
                    Positioned(
                      top: 140,
                      right: width * 0.15,
                      child: _buildPlayerSlot(context, FantasyRole.set, selectedPlayers[FantasyRole.set], width),
                    ),
                    
                    // Back (Mottak, Forsvar)
                    Positioned(
                      bottom: 120,
                      left: width * 0.15,
                      child: _buildPlayerSlot(context, FantasyRole.receive, selectedPlayers[FantasyRole.receive], width),
                    ),
                    Positioned(
                      bottom: 120,
                      right: width * 0.15,
                      child: _buildPlayerSlot(context, FantasyRole.defense, selectedPlayers[FantasyRole.defense], width),
                    ),
                    
                    // Serve (Deep back)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildPlayerSlot(context, FantasyRole.serve, selectedPlayers[FantasyRole.serve], width),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            color: Colors.white70,
            fontSize: 12,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 18,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  void _showPlayerOptions(BuildContext context, String role, FantasyPlayer player) {
    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF1E3A8A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Padding(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: const Color(0xFF00FFCC), width: 2),
                    ),
                    child: player.imageUrl.isNotEmpty
                        ? ClipOval(child: Image.network(player.imageUrl, fit: BoxFit.cover))
                        : const Icon(Icons.person, color: Colors.white, size: 40),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          player.name,
                          style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '${player.team} - $role',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    '${player.totalPoints} pts',
                    style: const TextStyle(color: Color(0xFF00FFCC), fontSize: 24, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Text('Poengoversikt:', style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildDetailStat('Angrep', player.attacks.toString()),
                  _buildDetailStat('Blokk', player.blocks.toString()),
                  _buildDetailStat('Ess', player.aces.toString()),
                  _buildDetailStat('Forsvar', player.digs.toString()),
                ],
              ),
              const SizedBox(height: 32),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    Navigator.pop(context);
                    onRoleTap(role); // Åpne byttespiller skjermen
                  },
                  icon: const Icon(Icons.swap_horiz),
                  label: const Text('Bytt Spiller'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFFFF3B30),
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildDetailStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold)),
        Text(label, style: const TextStyle(color: Colors.white70, fontSize: 12)),
      ],
    );
  }
}
