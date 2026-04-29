import 'package:flutter/material.dart';

class FantasyPage extends StatefulWidget {
  const FantasyPage({super.key});

  @override
  State<FantasyPage> createState() => _FantasyPageState();
}

class _FantasyPageState extends State<FantasyPage> {
  // The 5 roles for the fantasy team
  final List<String> roles = [
    'Defence',
    'Attack',
    'Serve',
    'Set',
    'Receive'
  ];

  // Map to keep track of the selected player for each role
  Map<String, String?> selectedPlayers = {
    'Defence': null,
    'Attack': null,
    'Serve': null,
    'Set': null,
    'Receive': null,
  };

  // Mock list of players to choose from
  final List<String> mockPlayers = [
    'Anders Mol',
    'Christian Sørum',
    'Hendrik Mol',
    'Mathias Berntsen',
    'Nils Ringøen',
    'Even Stray Aas',
    'Markus Hansen',
    'Jo Gladsøy',
    'Tarjei Skarlund',
    'Martin Spinnangr'
  ];

  void _showPlayerSelectionSheet(String role) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.symmetric(vertical: 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Select player for $role',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                  color: Color(0xFF0A1931),
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  itemCount: mockPlayers.length,
                  itemBuilder: (context, index) {
                    final player = mockPlayers[index];
                    // Check if player is already selected in any other role
                    final isSelected = selectedPlayers.values.contains(player);
                    
                    return ListTile(
                      leading: CircleAvatar(
                        backgroundColor: const Color(0xFF0A1931).withOpacity(0.1),
                        child: const Icon(Icons.person, color: Color(0xFF0A1931)),
                      ),
                      title: Text(player),
                      subtitle: isSelected ? const Text('Already selected', style: TextStyle(color: Colors.red)) : null,
                      onTap: () {
                        if (isSelected) {
                          // Prevent selecting the same player twice for now
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(content: Text('$player is already on your team!')),
                          );
                          return;
                        }
                        
                        setState(() {
                          selectedPlayers[role] = player;
                        });
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text('My Fantasy Team'),
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            width: double.infinity,
            decoration: const BoxDecoration(
              color: Color(0xFF0A1931),
              borderRadius: BorderRadius.only(
                bottomLeft: Radius.circular(30),
                bottomRight: Radius.circular(30),
              ),
            ),
            child: Column(
              children: [
                const Icon(
                  Icons.sports_volleyball,
                  size: 48,
                  color: Colors.white,
                ),
                const SizedBox(height: 12),
                const Text(
                  'Build Your Squad',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select 5 players, one for each category.',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.white.withOpacity(0.8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              itemCount: roles.length,
              itemBuilder: (context, index) {
                final role = roles[index];
                final selectedPlayer = selectedPlayers[role];
                final isFilled = selectedPlayer != null;

                return Card(
                  elevation: 2,
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () => _showPlayerSelectionSheet(role),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Container(
                            width: 60,
                            height: 60,
                            decoration: BoxDecoration(
                              color: isFilled 
                                  ? const Color(0xFF185ADB).withOpacity(0.1) 
                                  : Colors.grey[200],
                              shape: BoxShape.circle,
                            ),
                            child: Icon(
                              isFilled ? Icons.person : Icons.person_add,
                              color: isFilled ? const Color(0xFF185ADB) : Colors.grey[500],
                              size: 30,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  role.toUpperCase(),
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.grey[600],
                                    letterSpacing: 1.2,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  isFilled ? selectedPlayer : 'Tap to select player',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: isFilled ? FontWeight.bold : FontWeight.normal,
                                    color: isFilled ? const Color(0xFF0A1931) : Colors.grey[500],
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (isFilled)
                            IconButton(
                              icon: const Icon(Icons.close, color: Colors.grey),
                              onPressed: () {
                                setState(() {
                                  selectedPlayers[role] = null;
                                });
                              },
                            )
                          else
                            const Icon(
                              Icons.arrow_forward_ios,
                              size: 16,
                              color: Colors.grey,
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}