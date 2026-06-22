import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../theme/app_colors.dart';

class TournamentRegistrationPage extends StatefulWidget {
  final String tournamentId;
  final Map<String, dynamic> tournamentData;
  final String categoryId;
  final String categoryName;

  const TournamentRegistrationPage({
    super.key,
    required this.tournamentId,
    required this.tournamentData,
    required this.categoryId,
    required this.categoryName,
  });

  @override
  State<TournamentRegistrationPage> createState() =>
      _TournamentRegistrationPageState();
}

class _TournamentRegistrationPageState
    extends State<TournamentRegistrationPage> {
  // Valgte spillere
  DocumentSnapshot? _player1;
  DocumentSnapshot? _player2;

  // Søk
  final _searchCtrl = TextEditingController();
  String _searchQuery = '';
  bool _isSubmitting = false;

  // Eksisterende påmelding for innlogget bruker
  DocumentSnapshot? _existingRegistration;
  bool _checkingExisting = true;

  @override
  void initState() {
    super.initState();
    _preloadCurrentUser();
    _checkExistingRegistration();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  // Last inn innlogget brukers spillerprofil automatisk som spiller 1
  Future<void> _preloadCurrentUser() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) return;

    final snap = await FirebaseFirestore.instance
        .collection('players')
        .where('claimed_by_uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (snap.docs.isNotEmpty && mounted) {
      setState(() => _player1 = snap.docs.first);
    }
  }

  Future<void> _checkExistingRegistration() async {
    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      setState(() => _checkingExisting = false);
      return;
    }

    final snap = await FirebaseFirestore.instance
        .collection('registrations')
        .where('tournament_id', isEqualTo: widget.tournamentId)
        .where('category_id', isEqualTo: widget.categoryId)
        .where('submitted_by_uid', isEqualTo: uid)
        .limit(1)
        .get();

    if (mounted) {
      setState(() {
        _existingRegistration =
            snap.docs.isNotEmpty ? snap.docs.first : null;
        _checkingExisting = false;
      });
    }
  }

  int get _combinedRanking {
    final p1pts = (_player1?.data() as Map<String, dynamic>?)?['ranking_points'] ?? 0;
    final p2pts = (_player2?.data() as Map<String, dynamic>?)?['ranking_points'] ?? 0;
    return (p1pts as num).toInt() + (p2pts as num).toInt();
  }

  String _playerName(DocumentSnapshot? snap) {
    if (snap == null) return '';
    final d = snap.data() as Map<String, dynamic>;
    return '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'.trim();
  }

  int _playerRanking(DocumentSnapshot? snap) {
    if (snap == null) return 0;
    final d = snap.data() as Map<String, dynamic>;
    return (d['ranking_points'] as num?)?.toInt() ?? 0;
  }

  String _playerClub(DocumentSnapshot? snap) {
    if (snap == null) return '';
    final d = snap.data() as Map<String, dynamic>;
    return d['club'] ?? d['team'] ?? '';
  }

  Future<void> _submit() async {
    if (_player1 == null || _player2 == null) {
      _snack("Velg begge spillerne!");
      return;
    }
    if (_player1!.id == _player2!.id) {
      _snack("Spiller 1 og 2 kan ikke være den samme!");
      return;
    }

    final uid = FirebaseAuth.instance.currentUser?.uid;
    if (uid == null) {
      _snack("Du må være innlogget for å melde på.");
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final p1d = _player1!.data() as Map<String, dynamic>;
      final p2d = _player2!.data() as Map<String, dynamic>;

      await FirebaseFirestore.instance.collection('registrations').add({
        'tournament_id': widget.tournamentId,
        'tournament_name': widget.tournamentData['name'] ?? '',
        'category_id': widget.categoryId,
        'category_name': widget.categoryName,
        'player1_id': _player1!.id,
        'player1_name':
            '${p1d['first_name'] ?? ''} ${p1d['last_name'] ?? ''}'.trim(),
        'player1_club': p1d['club'] ?? p1d['team'] ?? '',
        'player1_ranking': (p1d['ranking_points'] as num?)?.toInt() ?? 0,
        'player2_id': _player2!.id,
        'player2_name':
            '${p2d['first_name'] ?? ''} ${p2d['last_name'] ?? ''}'.trim(),
        'player2_club': p2d['club'] ?? p2d['team'] ?? '',
        'player2_ranking': (p2d['ranking_points'] as num?)?.toInt() ?? 0,
        'combined_ranking': _combinedRanking,
        'status': 'pending', // pending | accepted | waitlist | rejected
        'submitted_by_uid': uid,
        'wildcard_requested': false,
        'created_at': FieldValue.serverTimestamp(),
      });

      if (mounted) {
        _snack("Påmelding sendt! Du vil få beskjed når den er godkjent.");
        Navigator.pop(context, true);
      }
    } catch (e) {
      if (mounted) {
        _snack("Feil ved påmelding: $e");
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _snack(String msg) =>
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(msg)));

  // ─── Spillersøk-dialog ──────────────────────────────────────────────────
  void _showPlayerSearch({required bool isPlayer1}) {
    _searchCtrl.clear();
    _searchQuery = '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheet) => Container(
          height: MediaQuery.of(ctx).size.height * 0.85,
          decoration: BoxDecoration(
            color: Theme.of(ctx).scaffoldBackgroundColor,
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              // Header
              Container(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                child: Column(
                  children: [
                    Container(
                      width: 40,
                      height: 4,
                      decoration: BoxDecoration(
                        color: Colors.grey[300],
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      isPlayer1 ? "Velg Spiller 1" : "Velg Spiller 2",
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _searchCtrl,
                      autofocus: true,
                      decoration: InputDecoration(
                        hintText: "Søk på navn eller klubb...",
                        prefixIcon: const Icon(Icons.search),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                      ),
                      onChanged: (v) =>
                          setSheet(() => _searchQuery = v.toLowerCase()),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),
              // Spillerliste
              Expanded(
                child: StreamBuilder<QuerySnapshot>(
                  stream: FirebaseFirestore.instance
                      .collection('players')
                      .orderBy('last_name')
                      .snapshots(),
                  builder: (ctx, snap) {
                    if (!snap.hasData) {
                      return const Center(
                          child: CircularProgressIndicator());
                    }
                    final all = snap.data!.docs;
                    final filtered = _searchQuery.isEmpty
                        ? all
                        : all.where((doc) {
                            final d =
                                doc.data() as Map<String, dynamic>;
                            final name =
                                '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'
                                    .toLowerCase();
                            final club = (d['club'] ?? d['team'] ?? '')
                                .toString()
                                .toLowerCase();
                            return name.contains(_searchQuery) ||
                                club.contains(_searchQuery);
                          }).toList();

                    if (filtered.isEmpty) {
                      return const Center(
                          child: Text("Ingen spillere funnet"));
                    }

                    return ListView.builder(
                      itemCount: filtered.length,
                      itemBuilder: (ctx, i) {
                        final doc = filtered[i];
                        final d = doc.data() as Map<String, dynamic>;
                        final name =
                            '${d['first_name'] ?? ''} ${d['last_name'] ?? ''}'
                                .trim();
                        final club =
                            d['club'] ?? d['team'] ?? 'Ukjent klubb';
                        final pts =
                            (d['ranking_points'] as num?)?.toInt() ?? 0;

                        // Ikke vis allerede valgt spiller
                        final otherPlayer =
                            isPlayer1 ? _player2 : _player1;
                        if (otherPlayer != null &&
                            otherPlayer.id == doc.id) {
                          return const SizedBox.shrink();
                        }

                        return ListTile(
                          leading: CircleAvatar(
                            backgroundColor: AppColors.coral.withOpacity(0.15),
                            child: Text(
                              name.isNotEmpty ? name[0].toUpperCase() : '?',
                              style: TextStyle(
                                  color: AppColors.coral,
                                  fontWeight: FontWeight.bold),
                            ),
                          ),
                          title: Text(name,
                              style: const TextStyle(
                                  fontWeight: FontWeight.w600)),
                          subtitle: Text(club.toString()),
                          trailing: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: AppColors.coral.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              "$pts pts",
                              style: TextStyle(
                                color: AppColors.coral,
                                fontWeight: FontWeight.bold,
                                fontSize: 12,
                              ),
                            ),
                          ),
                          onTap: () {
                            setState(() {
                              if (isPlayer1) {
                                _player1 = doc;
                              } else {
                                _player2 = doc;
                              }
                            });
                            Navigator.pop(ctx);
                          },
                        );
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final tourName = widget.tournamentData['name'] ?? '';
    final tourType = widget.tournamentData['tournament_type_label'] ?? '';
    final deadline = widget.tournamentData['registration_deadline'] ?? '';

    if (_checkingExisting) {
      return Scaffold(
        appBar: AppBar(title: const Text("Påmelding")),
        body: const Center(child: CircularProgressIndicator()),
      );
    }

    // Hvis allerede påmeldt, vis status
    if (_existingRegistration != null) {
      final reg = _existingRegistration!.data() as Map<String, dynamic>;
      final status = reg['status'] as String? ?? 'pending';
      return _buildExistingRegistrationView(reg, status, isDark);
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text("Meld på"),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ── Turnering-info-banner ──────────────────────────────────
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.blue[900]!, Colors.blue[700]!],
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(tourName,
                      style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.bold)),
                  const SizedBox(height: 4),
                  Row(children: [
                    if (tourType.isNotEmpty) ...[
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(tourType,
                            style: const TextStyle(
                                color: Colors.white, fontSize: 11)),
                      ),
                      const SizedBox(width: 8),
                    ],
                    Text(widget.categoryName,
                        style: const TextStyle(
                            color: Colors.white70, fontSize: 13)),
                  ]),
                  if (deadline.isNotEmpty) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      const Icon(Icons.lock_clock,
                          color: Colors.orange, size: 14),
                      const SizedBox(width: 4),
                      Text("Frist: $deadline",
                          style: const TextStyle(
                              color: Colors.orange, fontSize: 12)),
                    ]),
                  ],
                ],
              ),
            ),

            const SizedBox(height: 24),

            // ── Spillervalg ────────────────────────────────────────────
            const Text("Velg spillere",
                style:
                    TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            const SizedBox(height: 4),
            Text(
              "Ditt lag består av 2 spillere. Seeding = sum av rankingpoeng.",
              style:
                  TextStyle(fontSize: 12, color: Colors.grey[600]),
            ),
            const SizedBox(height: 16),

            _buildPlayerCard(
              isPlayer1: true,
              player: _player1,
              label: "Spiller 1",
            ),
            const SizedBox(height: 12),
            _buildPlayerCard(
              isPlayer1: false,
              player: _player2,
              label: "Spiller 2",
            ),

            // ── Kombinert ranking-visning ──────────────────────────────
            if (_player1 != null && _player2 != null) ...[
              const SizedBox(height: 20),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark
                      ? Colors.white.withOpacity(0.05)
                      : Colors.blue[50],
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _statCol("Lag-ranking",
                        "$_combinedRanking pts", Colors.blue[800]!),
                    Container(width: 1, height: 40, color: Colors.blue[200]),
                    _statCol(
                        "Spiller 1",
                        "${_playerRanking(_player1)} pts",
                        Colors.blue[600]!),
                    Container(width: 1, height: 40, color: Colors.blue[200]),
                    _statCol(
                        "Spiller 2",
                        "${_playerRanking(_player2)} pts",
                        Colors.blue[600]!),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Text(
                "Seeding baseres på de 5 beste resultatene siste 365 dager per spiller.",
                style:
                    TextStyle(fontSize: 11, color: Colors.grey[500]),
                textAlign: TextAlign.center,
              ),
            ],

            const SizedBox(height: 32),

            // ── Send inn ───────────────────────────────────────────────
            SizedBox(
              height: 52,
              child: ElevatedButton.icon(
                onPressed:
                    _isSubmitting ? null : _submit,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                            strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.send),
                label: Text(
                    _isSubmitting ? "Sender..." : "SEND PÅMELDING"),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue[900],
                  foregroundColor: Colors.white,
                  textStyle: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.bold),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              "Påmeldingen er ikke bekreftet før admin godkjenner den. "
              "Status vises i turnerings-siden.",
              style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPlayerCard({
    required bool isPlayer1,
    required DocumentSnapshot? player,
    required String label,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasPlayer = player != null;

    return GestureDetector(
      onTap: () => _showPlayerSearch(isPlayer1: isPlayer1),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: hasPlayer
              ? (isDark
                  ? Colors.white.withOpacity(0.07)
                  : Colors.blue[50])
              : (isDark ? Colors.white.withOpacity(0.04) : Colors.grey[50]),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: hasPlayer ? Colors.blue.shade300 : Colors.grey.shade300,
            width: hasPlayer ? 1.5 : 1,
          ),
        ),
        child: Row(
          children: [
            CircleAvatar(
              radius: 22,
              backgroundColor: hasPlayer
                  ? AppColors.coral.withOpacity(0.15)
                  : Colors.grey[200],
              child: hasPlayer
                  ? Text(
                      _playerName(player)[0].toUpperCase(),
                      style: TextStyle(
                          color: AppColors.coral,
                          fontWeight: FontWeight.bold,
                          fontSize: 16),
                    )
                  : Icon(Icons.person_add,
                      color: Colors.grey[400], size: 20),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: hasPlayer
                  ? Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500)),
                        Text(_playerName(player),
                            style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 15)),
                        Text(
                          "${_playerClub(player)} • ${_playerRanking(player)} pts",
                          style: TextStyle(
                              fontSize: 12, color: Colors.grey[600]),
                        ),
                      ],
                    )
                  : Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(label,
                            style: TextStyle(
                                fontSize: 10,
                                color: Colors.grey[500],
                                fontWeight: FontWeight.w500)),
                        Text("Trykk for å velge spiller",
                            style: TextStyle(color: Colors.grey[500])),
                      ],
                    ),
            ),
            Icon(
              Icons.chevron_right,
              color: Colors.grey[400],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statCol(String label, String value, Color color) => Column(
        children: [
          Text(value,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 16)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  TextStyle(color: Colors.grey[600], fontSize: 10)),
        ],
      );

  Widget _buildExistingRegistrationView(
      Map<String, dynamic> reg, String status, bool isDark) {
    final statusConfig = _statusConfig(status);

    return Scaffold(
      appBar: AppBar(
        title: const Text("Påmelding"),
        backgroundColor: isDark ? const Color(0xFF1A1A2E) : Colors.blue[900],
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            const SizedBox(height: 40),
            Icon(statusConfig['icon'] as IconData,
                size: 72, color: statusConfig['color'] as Color),
            const SizedBox(height: 20),
            Text(statusConfig['title'] as String,
                style: const TextStyle(
                    fontSize: 22, fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            Text(statusConfig['subtitle'] as String,
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.grey[600])),
            const SizedBox(height: 32),
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    _regRow("Turnering", reg['tournament_name'] ?? ''),
                    _regRow("Klasse", reg['category_name'] ?? ''),
                    _regRow("Spiller 1", reg['player1_name'] ?? ''),
                    _regRow("Spiller 2", reg['player2_name'] ?? ''),
                    _regRow("Lag-ranking",
                        "${reg['combined_ranking'] ?? 0} pts"),
                  ],
                ),
              ),
            ),
            const Spacer(),
            if (status == 'pending' || status == 'waitlist')
              OutlinedButton.icon(
                icon: const Icon(Icons.cancel, color: Colors.red),
                label: const Text("Trekk påmelding",
                    style: TextStyle(color: Colors.red)),
                style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: Colors.red)),
                onPressed: _confirmWithdraw,
              ),
          ],
        ),
      ),
    );
  }

  Widget _regRow(String label, String value) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style: TextStyle(color: Colors.grey[600], fontSize: 13)),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.w600, fontSize: 13)),
          ],
        ),
      );

  Map<String, dynamic> _statusConfig(String status) {
    switch (status) {
      case 'accepted':
        return {
          'icon': Icons.check_circle,
          'color': Colors.green,
          'title': 'Påmelding godkjent!',
          'subtitle':
              'Dere er bekreftet deltakere. Sjekk kampoppsettet etter påmeldingsfristen.',
        };
      case 'waitlist':
        return {
          'icon': Icons.hourglass_top,
          'color': Colors.orange,
          'title': 'På venteliste',
          'subtitle':
              'Turneringen er full, men dere er på ventelisten. Dere vil bli kontaktet ved ledig plass.',
        };
      case 'rejected':
        return {
          'icon': Icons.cancel,
          'color': Colors.red,
          'title': 'Påmelding avvist',
          'subtitle':
              'Beklager, påmeldingen ble ikke godkjent. Kontakt arrangør for mer info.',
        };
      default:
        return {
          'icon': Icons.pending,
          'color': Colors.blue,
          'title': 'Påmelding mottatt',
          'subtitle':
              'Påmeldingen er sendt og venter på godkjenning fra arrangør.',
        };
    }
  }

  Future<void> _confirmWithdraw() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Trekk påmelding"),
        content: const Text(
            "Er du sikker på at du vil trekke påmeldingen? Dette kan ikke angres."),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: const Text("Avbryt")),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red, foregroundColor: Colors.white),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text("Trekk"),
          ),
        ],
      ),
    );

    if (confirm == true && _existingRegistration != null) {
      await FirebaseFirestore.instance
          .collection('registrations')
          .doc(_existingRegistration!.id)
          .delete();
      if (mounted) Navigator.pop(context);
    }
  }
}
