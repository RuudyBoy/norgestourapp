import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

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
    final imageUrl = playerData['image_url'] ?? playerData['image'] ?? playerData['photoUrl'] ?? playerData['photo_url'] ?? playerData['picture'] ?? '';
    final jerseyNumber = playerData['jersey_number']?.toString() ?? '';
    final birthDate = playerData['birth_date'] ?? '';
    final nationality = playerData['nationality'] ?? '';
    final height = playerData['height']?.toString() ?? '';
    final weight = playerData['weight']?.toString() ?? '';

    // Mock stats if not available
    final matchesPlayed = playerData['matches_played']?.toString() ?? '0';
    final goals = playerData['goals']?.toString() ?? '0';
    final assists = playerData['assists']?.toString() ?? '0';
    final blocks = playerData['blocks']?.toString() ?? '0';
    final wins = playerData['wins']?.toString() ?? '0';

    return Scaffold(
      backgroundColor: const Color(0xFF0E0E10), // Deep dark background like the screenshot
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Colors.white, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.share, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.bookmark_border, color: Colors.white, size: 20),
            onPressed: () {},
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- PREMIUM HEADER ---
            SizedBox(
              height: 500, // Taller header to fit the player image properly
              child: Stack(
                alignment: Alignment.bottomCenter,
                children: [
                  // Huge Watermark Text (Team or Last Name)
                  Positioned(
                    top: 120,
                    child: Text(
                      (team.isNotEmpty ? team : lastName).toUpperCase(),
                      style: GoogleFonts.montserrat(
                        fontSize: 120,
                        fontWeight: FontWeight.w900,
                        color: Colors.white.withOpacity(0.03), // Very subtle watermark
                        letterSpacing: -5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.clip,
                    ),
                  ),

                  // Player Image (Transparent PNG)
                  if (imageUrl.isNotEmpty)
                    Positioned(
                      bottom: 40, // Floating slightly above the card
                      child: Image.network(
                        imageUrl,
                        height: 420,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),

                  // Top left Name & Team Info (like the Juve / Ronaldo text)
                  Positioned(
                    top: 100,
                    left: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (jerseyNumber.isNotEmpty)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: const Color(0xFFFF3B30),
                                  borderRadius: BorderRadius.circular(4),
                                ),
                                child: Text(
                                  jerseyNumber,
                                  style: GoogleFonts.montserrat(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    fontSize: 14,
                                  ),
                                ),
                              ),
                            const SizedBox(width: 8),
                            Text(
                              team.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: Colors.grey[400],
                                letterSpacing: 1.5,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          fullName,
                          style: GoogleFonts.montserrat(
                            fontSize: 32,
                            fontWeight: FontWeight.w900,
                            color: Colors.white,
                            height: 1.1,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          position.toUpperCase(),
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey[500],
                            letterSpacing: 2,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Floating Stats Card (Age, Games, Goals style)
                  Positioned(
                    bottom: 0,
                    left: 24,
                    right: 24,
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1C1C24), // Dark sleek card color
                        borderRadius: BorderRadius.circular(24),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.5),
                            blurRadius: 20,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceAround,
                        children: [
                          _buildTopStat('Kamper', matchesPlayed),
                          Container(width: 1, height: 40, color: Colors.white10),
                          _buildTopStat('Poeng', goals),
                          Container(width: 1, height: 40, color: Colors.white10),
                          _buildTopStat('Blokker', blocks),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 32),

            // --- DETAILED STATS SECTIONS ---
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle('DISCIPLINE & MORE'),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        _buildDetailedStat(wins, 'Seiere', Colors.white),
                        _buildDetailedStat(assists, 'Assists', Colors.white),
                        _buildDetailedStat('0', 'Gule kort', Colors.amber),
                        _buildDetailedStat('0', 'Røde kort', Colors.redAccent),
                      ],
                    ),
                  ),
                  
                  const SizedBox(height: 32),

                  _buildSectionTitle('FYSISKE EGENSKAPER'),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF16161C),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        if (height.isNotEmpty) _buildListTile('Høyde', '$height cm'),
                        if (weight.isNotEmpty) ...[
                          const Divider(color: Colors.white10, height: 1),
                          _buildListTile('Vekt', '$weight kg'),
                        ],
                        if (birthDate.isNotEmpty) ...[
                          const Divider(color: Colors.white10, height: 1),
                          _buildListTile('Født', birthDate),
                        ],
                        if (nationality.isNotEmpty) ...[
                          const Divider(color: Colors.white10, height: 1),
                          _buildListTile('Nasjonalitet', nationality),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTopStat(String label, String value) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: Colors.grey[500],
          ),
        ),
        const SizedBox(height: 8),
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 24,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  Widget _buildDetailedStat(String value, String label, Color valueColor) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.montserrat(
            fontSize: 22,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            color: Colors.grey[600],
            height: 1.2,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSectionTitle(String title) {
    return Text(
      title,
      style: GoogleFonts.inter(
        fontSize: 12,
        fontWeight: FontWeight.bold,
        color: Colors.white,
        letterSpacing: 2,
      ),
    );
  }

  Widget _buildListTile(String title, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}

