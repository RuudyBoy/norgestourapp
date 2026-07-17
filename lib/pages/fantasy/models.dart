import '../stats_logic.dart';

class FantasyPlayer {
  final String id;
  final String name;
  final String team;
  final double price;
  final int totalPoints;
  final String imageUrl;

  // Stats for the radar chart or details
  final int blocks;
  final int digs;
  final int attacks;
  final int sets;
  final int receives;
  final int aces;

  // Rå sesongstatistikk — kilden for rollelåst fantasypoengberegning
  // (se fantasy_point_matrix.dart). Null for spillere uten registrerte kamper.
  final PlayerMatchStats? stats;

  FantasyPlayer({
    required this.id,
    required this.name,
    required this.team,
    required this.price,
    required this.totalPoints,
    this.imageUrl = '',
    this.blocks = 0,
    this.digs = 0,
    this.attacks = 0,
    this.sets = 0,
    this.receives = 0,
    this.aces = 0,
    this.stats,
  });
}

class FantasyRole {
  static const String block = 'Blokk';
  static const String defense = 'Forsvar';
  static const String attack = 'Angrep';
  static const String set = 'Legg';
  static const String receive = 'Mottak';
  static const String serve = 'Serv';

  static const List<String> all = [
    block,
    defense,
    attack,
    set,
    receive,
    serve,
  ];
}
