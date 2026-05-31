import 'package:flutter/material.dart';
import 'models.dart';
import 'mock_data.dart';

class FantasySquadView extends StatelessWidget {
  final Map<String, String?> selectedPlayers;
  final Function(String role) onRoleTap;

  const FantasySquadView({
    super.key,
    required this.selectedPlayers,
    required this.onRoleTap,
  });

  Widget _buildPlayerSlot(String role, String? playerId, double width) {
    FantasyPlayer? player;
    if (playerId != null) {
      player = mockFantasyPlayers.firstWhere((p) => p.id == playerId);
    }

    return GestureDetector(
      onTap: () => onRoleTap(role),
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
            child: Icon(
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
              player != null ? player.name.split(' ').last : role,
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
            final p = mockFantasyPlayers.firstWhere((p) => p.id == playerId);
            totalValue += p.price;
            totalPoints += p.totalPoints;
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
                  _buildStatItem('Budget', '\$${(100.0 - totalValue).toStringAsFixed(1)}m'),
                  _buildStatItem('Value', '\$${totalValue.toStringAsFixed(1)}m'),
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
                        child: _buildPlayerSlot(FantasyRole.block, selectedPlayers[FantasyRole.block], width),
                      ),
                    ),
                    
                    // Middle (Angrep, Legg)
                    Positioned(
                      top: 140,
                      left: width * 0.15,
                      child: _buildPlayerSlot(FantasyRole.attack, selectedPlayers[FantasyRole.attack], width),
                    ),
                    Positioned(
                      top: 140,
                      right: width * 0.15,
                      child: _buildPlayerSlot(FantasyRole.set, selectedPlayers[FantasyRole.set], width),
                    ),
                    
                    // Back (Mottak, Forsvar)
                    Positioned(
                      bottom: 120,
                      left: width * 0.15,
                      child: _buildPlayerSlot(FantasyRole.receive, selectedPlayers[FantasyRole.receive], width),
                    ),
                    Positioned(
                      bottom: 120,
                      right: width * 0.15,
                      child: _buildPlayerSlot(FantasyRole.defense, selectedPlayers[FantasyRole.defense], width),
                    ),
                    
                    // Serve (Deep back)
                    Positioned(
                      bottom: 20,
                      left: 0,
                      right: 0,
                      child: Center(
                        child: _buildPlayerSlot(FantasyRole.serve, selectedPlayers[FantasyRole.serve], width),
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
}
