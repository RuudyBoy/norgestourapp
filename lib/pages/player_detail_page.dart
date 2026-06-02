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
    final imageUrl = playerData['image_url'] ?? '';
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
      backgroundColor: Colors.transparent,
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.5),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.arrow_back, color: Colors.white, size: 20),
          ),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Image.asset('assets/images/spikedunk_logo.png', height: 40, fit: BoxFit.contain),
          ),
        ],
      ),
      body: SingleChildScrollView(
        child: Column(
          children: [
            // --- PREMIUM HEADER ---
            Stack(
              alignment: Alignment.bottomCenter,
              children: [
                // Background Gradient or Image
                Container(
                  height: 380,
                  width: double.infinity,
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Color(0xFF1DD05D), // Bright Green
                        Color(0xFF0F9B43), // Darker Green
                      ],
                    ),
                  ),
                ),
                // Player Image (Large, central)
                if (imageUrl.isNotEmpty)
                  Positioned(
                    bottom: 0,
                    child: ShaderMask(
                      shaderCallback: (rect) {
                        return const LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.black, Colors.transparent],
                          stops: [0.6, 1.0],
                        ).createShader(Rect.fromLTRB(0, 0, rect.width, rect.height));
                      },
                      blendMode: BlendMode.dstIn,
                      child: Image.network(
                        imageUrl,
                        height: 340,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const SizedBox(),
                      ),
                    ),
                  ),
                // Overlay Info (Name, Position, Number)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
                  width: double.infinity,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.bottomCenter,
                      end: Alignment.topCenter,
                      colors: [
                        const Color(0xFF121212),
                        const Color(0xFF121212).withOpacity(0.8),
                        Colors.transparent,
                      ],
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  firstName.toUpperCase(),
                                  style: GoogleFonts.inter(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[400],
                                    letterSpacing: 2,
                                  ),
                                ),
                                Text(
                                  lastName,
                                  style: GoogleFonts.montserrat(
                                    fontSize: 42,
                                    fontWeight: FontWeight.w900,
                                    color: Colors.white,
                                    height: 1.1,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          if (jerseyNumber.isNotEmpty)
                            Text(
                              jerseyNumber,
                              style: GoogleFonts.montserrat(
                                fontSize: 48,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFFF3B30), // App Primary Red
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          _buildTag(position),
                          const SizedBox(width: 8),
                          if (team.isNotEmpty) _buildTag(team),
                          const SizedBox(width: 8),
                          if (nationality.isNotEmpty) _buildTag(nationality),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),

            // --- STATS GRID ---
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'SESONG STATISTIKK',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  GridView.count(
                    crossAxisCount: 2,
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 1.1,
                    children: [
                      _buildPremiumStatCard('Kamper', matchesPlayed),
                      _buildPremiumStatCard('Poeng', goals),
                      _buildPremiumStatCard('Blokker', blocks),
                      _buildPremiumStatCard('Seiere', wins),
                    ],
                  ),
                  const SizedBox(height: 32),

                  // --- FYSISKE EGENSKAPER ---
                  Text(
                    'FYSISKE EGENSKAPER',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: Colors.grey[500],
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E1E1E),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.white10),
                    ),
                    child: Column(
                      children: [
                        if (height.isNotEmpty) _buildListTile('Høyde', '$height cm', Icons.height),
                        if (weight.isNotEmpty) ...[
                          const Divider(color: Colors.white10, height: 1),
                          _buildListTile('Vekt', '$weight kg', Icons.monitor_weight),
                        ],
                        if (birthDate.isNotEmpty) ...[
                          const Divider(color: Colors.white10, height: 1),
                          _buildListTile('Født', birthDate, Icons.cake),
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

  Widget _buildTag(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white24),
      ),
      child: Text(
        text,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildPremiumStatCard(String label, String value) {
    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF1DD05D), // Bright green like Image 1
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1DD05D).withOpacity(0.3),
            blurRadius: 10,
            offset: const Offset(0, 4),
          )
        ],
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w700,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: GoogleFonts.montserrat(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListTile(String title, String value, IconData icon) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Icon(icon, color: Colors.grey[500], size: 20),
          const SizedBox(width: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: Colors.grey[400],
              fontWeight: FontWeight.w500,
            ),
          ),
          const Spacer(),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 16,
              color: Colors.white,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
