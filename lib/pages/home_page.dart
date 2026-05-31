import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'fantasy_page.dart';
import 'tours_page.dart';
import 'tournament_stats_page.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // The vibrant global background gradient matching the design
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFEFE9E5), // Light beige at top matching the header
              Color(0xFFFF66C4), // Vibrant pink
              Color(0xFF3B82F6), // Bright blue
            ],
            stops: [0.3, 0.6, 1.0],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            child: Column(
              children: [
                _buildHeader(),
                const SizedBox(height: 10),
                _buildCards(context),
                const SizedBox(height: 30),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return SizedBox(
      height: 200,
      width: double.infinity,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // If there's a background texture or pattern for the header, it goes here
          // We use the logo in the center
          Positioned(
            top: 20,
            child: Image.asset(
              'assets/images/logo.png',
              height: 140,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) => Text(
                'NORGES TOUR',
                style: GoogleFonts.bangers(fontSize: 48, color: const Color(0xFF185ADB)),
              ),
            ),
          ),
          // We can add placeholders for player cutouts on left/right if needed
          // For now, the logo is the main focus as in the reference.
        ],
      ),
    );
  }

  Widget _buildCards(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0),
      child: Column(
        children: [
          _buildActionCard(
            context: context,
            title: "FANTASY",
            subtitle: "VELKOMMEN TIL FANTASY",
            description:
                "Premier League Fantasy er et populært online spill som lar fotballfans over hele verden sette sammen sine egne drømmelag basert på spillere fra den engelske Premier League. Deltakerne får et budsjett og bruker det til å 'kjøpe' spillere til sine lag...",
            buttonText: "go to fantasy",
            gradientColors: [
              const Color(0xFFA7F3D0), // Light green
              const Color(0xFF93C5FD), // Light blue
            ],
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FantasyPage()),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildActionCard(
            context: context,
            title: "SE STATISTIKK FOR ÅRETS NT SESONG",
            subtitle: "",
            description:
                "Premier League Fantasy er et populært online spill som lar fotballfans over hele verden sette sammen sine egne drømmelag basert på spillere fra den engelske Premier League. Deltakerne får et budsjett og bruker det til å 'kjøpe' spillere til sine lag...",
            buttonText: "go to Stats",
            gradientColors: [
              const Color(0xFFBAE6FD), // Light sky blue
              const Color(0xFF7DD3FC), // Cyan
            ],
            titleStyle: GoogleFonts.bangers(fontSize: 22, color: const Color(0xFFE04036), letterSpacing: 1.2),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const TournamentStatsPage(
                    tournamentId: 'nt-season',
                    tournamentName: 'Årets NT sesong',
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 20),
          _buildActionCard(
            context: context,
            title: "Norges tour 26/27",
            subtitle: "TURNERING OG RESULTATER",
            description:
                "Premier League Fantasy er et populært online spill som lar fotballfans over hele verden sette sammen sine egne drømmelag basert på spillere fra den engelske Premier League. Deltakerne får et budsjett og bruker det til å 'kjøpe' spillere til sine lag...",
            buttonText: "go to fantasy", // Using text from the mockup image for tours
            gradientColors: [
              const Color(0xFFBFDBFE), // Blue 200
              const Color(0xFFC4B5FD), // Purple 300
            ],
            titleStyle: GoogleFonts.caveat(fontSize: 32, fontWeight: FontWeight.bold, color: const Color(0xFF1D4ED8)),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ToursPage()),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required String title,
    required String subtitle,
    required String description,
    required String buttonText,
    required List<Color> gradientColors,
    required VoidCallback onTap,
    TextStyle? titleStyle,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: gradientColors,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.15),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Background shapes or phone mockups can be added here
          // We leave some padding on the left to simulate the space for the phone image
          Padding(
            padding: const EdgeInsets.only(left: 120.0, top: 24, bottom: 24, right: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title.isNotEmpty)
                  Text(
                    title,
                    style: titleStyle ??
                        GoogleFonts.bangers(
                          fontSize: 32,
                          color: const Color(0xFF1D4ED8), // Deep blue
                          letterSpacing: 1.5,
                        ),
                  ),
                if (subtitle.isNotEmpty)
                  Padding(
                    padding: const EdgeInsets.only(top: 4.0, bottom: 8.0),
                    child: Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: const Color(0xFFE04036), // Vibrant red/orange
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                const SizedBox(height: 4),
                Text(
                  description,
                  maxLines: 6,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.inter(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                InkWell(
                  onTap: onTap,
                  borderRadius: BorderRadius.circular(30),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF04A22), // Vibrant orange button
                      borderRadius: BorderRadius.circular(30),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF04A22).withValues(alpha: 0.4),
                          blurRadius: 8,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Text(
                      buttonText,
                      style: GoogleFonts.caveat(
                        fontSize: 22,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          // Placeholder for the phone mockup image on the left
          Positioned(
            left: -20,
            top: 20,
            bottom: 20,
            width: 130,
            child: Container(
              decoration: BoxDecoration(
                color: Colors.black87,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.grey.shade800, width: 4),
                boxShadow: [
                  BoxShadow(color: Colors.black.withValues(alpha: 0.3), blurRadius: 10, offset: const Offset(5, 5))
                ]
              ),
              child: Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.sports_volleyball, color: Colors.white54, size: 40),
                    const SizedBox(height: 8),
                    Text('App Preview', style: TextStyle(color: Colors.white54, fontSize: 10))
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}