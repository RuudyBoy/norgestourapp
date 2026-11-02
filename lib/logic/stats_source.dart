import 'package:cloud_firestore/cloud_firestore.dart';

// Felles henting av kamphendelser og spillere for statistikk og fantasy.
// Resultatet caches i minnet i [statsCacheTtl], slik at det ikke blir nye
// lesinger av å gå frem og tilbake mellom sidene.

const Duration statsCacheTtl = Duration(minutes: 10);

class _CacheEntry<T> {
  final Future<T> future;
  final DateTime fetchedAt = DateTime.now();

  _CacheEntry(this.future);

  bool get isFresh => DateTime.now().difference(fetchedAt) < statsCacheTtl;
}

typedef MatchEvents = List<Map<String, dynamic>>;
typedef PlayerDocs = List<QueryDocumentSnapshot<Map<String, dynamic>>>;

final Map<String, _CacheEntry<List<MatchEvents>>> _eventsCache = {};
_CacheEntry<PlayerDocs>? _playersCache;

// Hendelsene for hver ferdige kamp som har events, én liste per kamp.
// [tournamentId] = null gir alle turneringer.
Future<List<MatchEvents>> loadFinishedMatchEvents({String? tournamentId, bool forceRefresh = false}) {
  final key = tournamentId ?? '_all';
  final cached = _eventsCache[key];
  if (!forceRefresh && cached != null && cached.isFresh) return cached.future;

  final entry = _CacheEntry(_fetchFinishedMatchEvents(tournamentId));
  _eventsCache[key] = entry;
  // En feilet henting skal ikke ligge i cachen.
  entry.future.then<void>((_) {}, onError: (Object _) {
    if (_eventsCache[key] == entry) _eventsCache.remove(key);
  });
  return entry.future;
}

// Alle dokumentene i `players`.
Future<PlayerDocs> loadPlayerDocs({bool forceRefresh = false}) {
  final cached = _playersCache;
  if (!forceRefresh && cached != null && cached.isFresh) return cached.future;

  final entry = _CacheEntry(
    FirebaseFirestore.instance.collection('players').get().then((s) => s.docs),
  );
  _playersCache = entry;
  entry.future.then<void>((_) {}, onError: (Object _) {
    if (_playersCache == entry) _playersCache = null;
  });
  return entry.future;
}

Future<List<MatchEvents>> _fetchFinishedMatchEvents(String? tournamentId) async {
  Query<Map<String, dynamic>> query =
      FirebaseFirestore.instance.collection('matches').where('status', isEqualTo: 'finished');
  if (tournamentId != null) {
    query = query.where('tournament_id', isEqualTo: tournamentId);
  }
  final matchesSnapshot = await query.get();

  // Manuelle resultater og walkover har ingen events, så de hoppes over.
  final withEvents = matchesSnapshot.docs.where((m) {
    final d = m.data();
    return d['manual_result'] != true && d['walkover'] != true;
  });

  final eventSnapshots = await Future.wait(
    withEvents.map((m) => m.reference.collection('events').get()),
  );

  return [
    for (final s in eventSnapshots)
      if (s.docs.isNotEmpty) s.docs.map((d) => d.data()).toList(),
  ];
}
