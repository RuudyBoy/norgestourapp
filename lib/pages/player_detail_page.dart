
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
        backgroundColor: const Color(0xFF0A1931),
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Player Image Header
            Container(
              width: double.infinity,
              height: 280,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    const Color(0xFF0A1931),
                    const Color(0xFF185ADB),
                  ],
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0.0, end: 1.0),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOut,
                    builder: (context, value, child) {
                      return Transform.scale(
                        scale: 0.7 + (0.3 * value),
                        child: Opacity(
                          opacity: value,
                          child: Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.3),
                                  blurRadius: 20,
                                  offset: const Offset(0, 8),
                                ),
                              ],
                            ),
                            child: CircleAvatar(
                              radius: 75,
                              backgroundColor: Colors.white,
                              backgroundImage: imageUrl.isNotEmpty ? NetworkImage(imageUrl) : null,
                              child: imageUrl.isEmpty
                                  ? const Icon(Icons.person, size: 75, color: Colors.grey)
                                  : null,
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 20),
                  Text(
                    fullName,
                    style: const TextStyle(
                      fontSize: 30,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      shadows: [
                        Shadow(
                          blurRadius: 8.0,
                          color: Colors.black26,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    position,
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.white.withOpacity(0.9),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),

            // Player Information
            Padding(
              padding: const EdgeInsets.all(20.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Basic Info Section
                  Text(
                    'Grunnleggende informasjon',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A1931),
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (team.isNotEmpty)
                    _buildInfoRow(Icons.shield, 'Lag', team),
                  
                  if (jerseyNumber.isNotEmpty)
                    _buildInfoRow(Icons.tag, 'Draktnummer', jerseyNumber),
                  
                  if (nationality.isNotEmpty)
                    _buildInfoRow(Icons.flag, 'Nasjonalitet', nationality),
                  
                  if (birthDate.isNotEmpty)
                    _buildInfoRow(Icons.cake, 'Fødselsdato', birthDate.toString()),

                  const SizedBox(height: 32),

                  // Physical Stats Section
                  Text(
                    'Fysiske egenskaper',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0A1931),
                    ),
                  ),
                  const SizedBox(height: 20),

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
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1931).withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: const Color(0xFF0A1931), size: 24),
          ),
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
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF0A1931),
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
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.grey[700],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF0A1931).withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: Color(0xFF0A1931),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
