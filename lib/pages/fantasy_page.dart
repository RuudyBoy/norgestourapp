import 'package:flutter/material.dart';
import 'fantasy/models.dart';
import 'fantasy/fantasy_squad_view.dart';
import 'fantasy/fantasy_leagues_view.dart';
import 'fantasy/fantasy_player_selection.dart';
import 'fantasy/mock_data.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'auth/login_page.dart';
import '../widgets/profile_avatar_widget.dart';
import 'fantasy/league_logic.dart';
import '../theme/app_colors.dart';
import '../theme/app_text_styles.dart';

class FantasyPage extends StatefulWidget {
  const FantasyPage({super.key});

  @override
  State<FantasyPage> createState() => _FantasyPageState();
}

class _FantasyPageState extends State<FantasyPage> {
  Map<String, String?> selectedPlayers = {
    FantasyRole.block: null,
    FantasyRole.defense: null,
    FantasyRole.attack: null,
    FantasyRole.set: null,
    FantasyRole.receive: null,
    FantasyRole.serve: null,
  };

  late Future<List<FantasyPlayer>> _playersFuture;
  late Future<Map<String, double>> _ownershipFuture;
  String? _linkedPlayerId;

  Future<List<dynamic>>? _combinedFuture;
  String? _currentUserId;
  String? _teamName;

  Map<String, String?> _initialSquad = {};
  String? _captainId;
  String? _initialCaptainId;
  int _transfersUsed = 0;
  DateTime? _lastConfirmed;

  @override
  void initState() {
    super.initState();
    _playersFuture = fetchFantasyPlayers();
  }

  void _openPlayerSelection(String role, List<FantasyPlayer> players, Map<String, double> ownershipPercentages) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => FantasyPlayerSelection(
          role: role,
          currentSelectedPlayers: selectedPlayers,
          players: players,
          ownershipPercentages: ownershipPercentages,
          linkedPlayerId: _linkedPlayerId,
          onSelect: (playerId) {
            setState(() { selectedPlayers[role] = playerId; });
          },
        ),
      ),
    );
  }

  Future<void> _loadSquad(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).collection('fantasy').doc('squad').get();
    if (doc.exists) {
      final data = doc.data()!;
      for (var key in selectedPlayers.keys) {
        if (data.containsKey(key)) {
          selectedPlayers[key] = data[key] as String?;
          _initialSquad[key] = data[key] as String?;
        }
      }
      _captainId = data['captainId'] as String?;
      _initialCaptainId = _captainId;
      _transfersUsed = data['transfersUsed'] as int? ?? 0;
      final ts = data['lastConfirmed'] as Timestamp?;
      if (ts != null) _lastConfirmed = ts.toDate();
    } else {
      _initialSquad = {};
    }
  }

  int _calculateChanges() {
    int changes = 0;
    for (var key in selectedPlayers.keys) {
      if (selectedPlayers[key] != _initialSquad[key]) {
        changes++;
      }
    }
    return changes;
  }

  Future<void> _confirmSquad() async {
    int changes = _calculateChanges();
    if (changes > 2) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text('Du kan maksimalt bytte 2 spillere!'),
        backgroundColor: AppColors.coral,
      ));
      return;
    }

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final data = Map<String, dynamic>.from(selectedPlayers);
      data['captainId'] = _captainId;
      data['transfersUsed'] = _transfersUsed + changes;
      data['lastConfirmed'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('fantasy')
          .doc('squad')
          .set(data, SetOptions(merge: true));

      setState(() {
        for (var key in selectedPlayers.keys) {
          _initialSquad[key] = selectedPlayers[key];
        }
        _initialCaptainId = _captainId;
        _transfersUsed += changes;
      });

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Laget er bekreftet!'),
          backgroundColor: Color(0xFF36C87A),
        ));
      }
    }
  }

  Future<void> _loadUserData(String uid) async {
    final doc = await FirebaseFirestore.instance.collection('users').doc(uid).get();
    if (doc.exists) {
      final data = doc.data()!;
      _linkedPlayerId = data['linkedPlayerId'] as String?;
      _teamName = data['teamName'] as String?;
    }
  }

  Widget _buildTeamNameForm(BuildContext context, String uid) {
    final TextEditingController controller = TextEditingController();
    bool isLoading = false;

    return StatefulBuilder(
      builder: (context, setState) {
        return Center(
          child: Padding(
            padding: const EdgeInsets.all(32),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.sports_volleyball, size: 64, color: AppColors.coral),
                const SizedBox(height: 24),
                Text('Velg et lagnavn', style: AppText.dispH2(24), textAlign: TextAlign.center),
                const SizedBox(height: 8),
                Text('Du må velge et navn for Fantasy-laget ditt for å fortsette.\n\nMERK: Dette kan kun gjøres én gang!',
                    style: AppText.uiCaption, textAlign: TextAlign.center),
                const SizedBox(height: 32),
                TextField(
                  controller: controller,
                  decoration: InputDecoration(
                    labelText: 'Lagnavn',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
                    onPressed: isLoading ? null : () async {
                      final name = controller.text.trim();
                      if (name.isEmpty) return;
                      setState(() => isLoading = true);
                      await FirebaseFirestore.instance.collection('users').doc(uid).update({'teamName': name});
                      this.setState(() {
                        _currentUserId = null; // force reload
                      });
                    },
                    child: isLoading ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)) : Text('Start sesongen!', style: AppText.uiCta.copyWith(color: Colors.white)),
                  ),
                ),
              ],
            ),
          ),
        );
      }
    );
  }

  @override
  Widget build(BuildContext context) {
    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          backgroundColor: Colors.transparent,
          foregroundColor: AppColors.ink,
          elevation: 0,
          scrolledUnderElevation: 0,
          actions: const [ProfileAvatarWidget()],
          bottom: TabBar(
            indicatorColor: AppColors.coral,
            indicatorWeight: 3,
            labelColor: AppColors.coral,
            unselectedLabelColor: AppColors.ink3,
            labelStyle: AppText.uiTab.copyWith(color: AppColors.coral, fontWeight: FontWeight.w800),
            unselectedLabelStyle: AppText.uiTab,
            tabs: const [
              Tab(icon: Icon(Icons.sports_volleyball, size: 18), text: 'Mitt Lag'),
              Tab(icon: Icon(Icons.leaderboard, size: 18), text: 'Ligaer'),
            ],
          ),
        ),
        body: StreamBuilder<User?>(
          stream: FirebaseAuth.instance.authStateChanges(),
          builder: (context, authSnapshot) {
            if (authSnapshot.connectionState == ConnectionState.waiting) {
              return const Center(child: CircularProgressIndicator(color: AppColors.coral));
            }
            if (!authSnapshot.hasData) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(32),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(20),
                        decoration: BoxDecoration(
                          color: AppColors.sand2,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(Icons.lock_outline, size: 40, color: AppColors.ink3),
                      ),
                      const SizedBox(height: 20),
                      Text('Logg inn for å spille Fantasy', style: AppText.dispH2(20), textAlign: TextAlign.center),
                      const SizedBox(height: 8),
                      Text('Sett opp laget ditt og konkurrér med andre.', style: AppText.uiCaption, textAlign: TextAlign.center),
                      const SizedBox(height: 28),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          style: ElevatedButton.styleFrom(backgroundColor: AppColors.coral),
                          onPressed: () => Navigator.push(context, MaterialPageRoute(builder: (context) => const LoginPage())),
                          child: Text('Logg inn', style: AppText.uiCta.copyWith(color: Colors.white)),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            final user = authSnapshot.data!;
            if (_currentUserId != user.uid) {
              _currentUserId = user.uid;
              _ownershipFuture = LeagueLogic.getPlayerOwnershipPercentages();
              _combinedFuture = Future.wait([
                _playersFuture,
                _loadSquad(user.uid),
                _loadUserData(user.uid),
                _ownershipFuture,
              ]);
            }

            return FutureBuilder<List<dynamic>>(
              future: _combinedFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator(color: AppColors.coral));
                }
                if (snapshot.hasError) {
                  return Center(child: Text('Feil ved innlasting: ${snapshot.error}', style: AppText.uiBody));
                }

                final players = (snapshot.data?[0] as List<FantasyPlayer>?) ?? [];
                final ownershipPercentages = (snapshot.data?[3] as Map<String, double>?) ?? {};

                if (_teamName == null || _teamName == 'Ukjent Lag' || _teamName!.isEmpty) {
                  return _buildTeamNameForm(context, user.uid);
                }

                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Fantasy', style: AppText.dispH2(28)),
                          const SizedBox(height: 2),
                          Text(
                            'Sett opp ditt drømmelag',
                            style: AppText.dispKicker(14).copyWith(color: AppColors.coral),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: TabBarView(
                        children: [
                          FantasySquadView(
                            selectedPlayers: selectedPlayers,
                            players: players,
                            ownershipPercentages: ownershipPercentages,
                            linkedPlayerId: _linkedPlayerId,
                            teamName: _teamName ?? 'Mitt Lag',
                            captainId: _captainId,
                            pendingChanges: _calculateChanges(),
                            onRoleTap: (role) => _openPlayerSelection(role, players, ownershipPercentages),
                            onCaptainChanged: (playerId) => setState(() => _captainId = playerId),
                            onConfirmSquad: _confirmSquad,
                          ),
                          FantasyLeaguesView(players: players),
                        ],
                      ),
                    ),
                  ],
                );
              },
            );
          },
        ),
      ),
    );
  }
}
