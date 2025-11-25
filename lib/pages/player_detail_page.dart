
import 'package:flutter/material.dart';

class PlayerDetailPage extends StatelessWidget {
  final String playerId;
  final Map<String, dynamic> playerData;

  const PlayerDetailPage({
    super.key,
    required this.playerId,
    required this.playerData,
  });

  @override
  Widget build(BuildContext context) {
    final firstName = playerData['first_name'] ?? '';
    final lastName = playerData['last_name'] ?? '';
    final fullName = "$firstName $lastName";
    final position = playerData['position'] ?? 'Ukjent posisjon';
    final team = playerData['team'] ?? 'Ukjent lag';
    final imageUrl = playerData['image_url'] ?? '';
    final jerseyNumber = playerData['jersey_number']?.toString() ?? '';
    final birthDate = playerData['birth_date'] ?? '';
    final nationality = playerData['nationality'] ?? '';
    final height = playerData['height']?.toString() ?? '';
    final weight = playerData['weight']?.toString() ?? '';

    return Scaffold(
      appBar: AppBar(
        title: Text(fullName),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Image Header
            Container(
              width: double.infinity,
              height: 250,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Colors.blue[700]!, Colors.blue[400]!],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  CircleAvatar(
                    radius: 70,
                    backgroundColor: Colors.white,
                    backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                    child: imageUrl.isEmpty ? const Icon(Icons.person, size: 70, color: Colors.grey) : null,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    position,
                    style: const TextStyle(
                      fontSize: 18,
                      color: Colors.white70,
                    ),
                  ),
                ],
              ),
            ),

            // Player Information
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info Section
                  const Text(
                    'Grunnleggende informasjon',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (team.isNotEmpty)
                    _buildInfoRow(Icons.shield, 'Lag', team),
                  
                  if (jerseyNumber.isNotEmpty)
                    _buildInfoRow(Icons.tag, 'Draktnummer', jerseyNumber),
                  
                  if (nationality.isNotEmpty)
                    _buildInfoRow(Icons.flag, 'Nasjonalitet', nationality),
                  
                  if (birthDate.isNotEmpty)
                    _buildInfoRow(Icons.cake, 'Fødselsdato', birthDate.toString()),

                  const SizedBox(height: 24),

                  // Physical Stats Section
                  const Text(
                    'Fysiske egenskaper',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),

                  if (height.isNotEmpty)
                    _buildInfoRow(Icons.height, 'Høyde', '$height cm'),
                  
                  if (weight.isNotEmpty)
                    _buildInfoRow(Icons.monitor_weight, 'Vekt', '$weight kg'),

                  const SizedBox(height: 24),

                  // Statistics Section (placeholder for future implementation)
                  const Text(
                    'Statistikk',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        children: [
                          _buildStatRow('Kamper spilt', playerData['matches_played']?.toString() ?? '0'),
                          const Divider(),
                          _buildStatRow('Mål', playerData['goals']?.toString() ?? '0'),
                          const Divider(),
                          _buildStatRow('Assist', playerData['assists']?.toString() ?? '0'),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12.0),
      child: Row(
        children: [
          Icon(icon, color: Colors.blue, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[600],
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 16,
            ),
          ),
          Text(
            value,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.blue,
            ),
          ),
        ],
      ),
    );
  }
}
