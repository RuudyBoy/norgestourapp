import '../stats_logic.dart';
import 'models.dart';

/// EV-justert poengmatrise for rollelåst fantasy.
///
/// Brukeren låser en spiller til ÉN rolle, og spilleren gir kun poeng for
/// handlinger som hører til den rollen — alt annet ignoreres. Poengverdiene
/// er kalibrert slik at en gjennomsnittlig prestasjon i enhver rolle gir
/// ca. 100 poeng per sett (derfor er sjeldne handlinger som blokk og ess
/// verdt mye mer enn hyppige handlinger som angrep).

/// Alle handlinger som kan gi eller trekke fantasypoeng.
enum FantasyAction {
  kill('Vellykket angrep'),
  setAssist('Vellykket legg'),
  attackError('Angrepsfeil'),
  doubleHit('Ballbehandlingsfeil'),
  perfectReception('Vellykket mottak'),
  goodReception('Godt mottak'),
  receptionError('Mottaksfeil'),
  kontra('Forsvar-til-Poeng (Kontra)'),
  stuffBlock('Poenggivende blokk'),
  netFault('Nettfeil / overtråkk'),
  ace('Serveess'),
  serveInPlay('Ordinær serv i spill'),
  serviceError('Servefeil');

  final String label;
  const FantasyAction(this.label);
}

/// Rolle → (handling → poeng). Rollens map ER rollelåsen: en handling som
/// ikke finnes i spillerens tildelte rolle-map teller aldri.
const Map<String, Map<FantasyAction, int>> fantasyPointMatrix = {
  FantasyRole.attack: {
    FantasyAction.kill: 21,
    FantasyAction.attackError: -12,
  },
  FantasyRole.set: {
    FantasyAction.setAssist: 18,
    FantasyAction.doubleHit: -15,
  },
  FantasyRole.receive: {
    FantasyAction.perfectReception: 11,
    FantasyAction.goodReception: 11,
    FantasyAction.receptionError: -15,
  },
  FantasyRole.defense: {
    FantasyAction.kontra: 48,
  },
  FantasyRole.block: {
    FantasyAction.stuffBlock: 75,
    FantasyAction.netFault: -15,
  },
  FantasyRole.serve: {
    FantasyAction.ace: 115,
    FantasyAction.serveInPlay: 5,
    FantasyAction.serviceError: -30,
  },
};

/// Antall forekomster av en handling i spillerens statistikk.
int actionCount(PlayerMatchStats stats, FantasyAction action) {
  switch (action) {
    case FantasyAction.kill:
      return stats.kills;
    case FantasyAction.setAssist:
      return stats.setAssists;
    case FantasyAction.attackError:
      return stats.attackErrors;
    // Livescore-appen logger i dag doble og nettfeil i én felles bøtte
    // ('Technical Error'). Rollen avgjør tolkningen; begge koster -15.
    case FantasyAction.doubleHit:
      return stats.technicalErrors;
    case FantasyAction.netFault:
      return stats.technicalErrors;
    case FantasyAction.perfectReception:
      return stats.perfectReceptions;
    case FantasyAction.goodReception:
      return stats.goodReceptions;
    case FantasyAction.receptionError:
      return stats.receptionErrors;
    case FantasyAction.kontra:
      return stats.overgangsPoeng;
    case FantasyAction.stuffBlock:
      return stats.blocks;
    case FantasyAction.ace:
      return stats.aces;
    case FantasyAction.serveInPlay:
      return stats.servesInPlay;
    case FantasyAction.serviceError:
      return stats.serviceErrors;
  }
}

/// Netto fantasypoeng for en spiller i den tildelte rollen.
///
/// Teller kun handlinger definert i rollens matrise (rollelåsen), trekker
/// feilpoeng, og kan gå under null. [multiplier] er klargjort for fremtidige
/// bonuser (f.eks. kaptein = 2.0) og ganges på nettosummen før avrunding.
int calculatePlayerPoints(
  PlayerMatchStats? matchStats,
  String assignedRole, {
  double multiplier = 1.0,
}) {
  if (matchStats == null) return 0;
  final roleMatrix = fantasyPointMatrix[assignedRole];
  if (roleMatrix == null) return 0;

  int net = 0;
  roleMatrix.forEach((action, points) {
    net += actionCount(matchStats, action) * points;
  });
  return (net * multiplier).round();
}

/// Én linje i poengregnskapet for en rolle — til visning i UI
/// ("Poenggivende blokk 2 × 75 = 150").
class FantasyPointLine {
  final FantasyAction action;
  final int count;
  final int pointsPerAction;

  const FantasyPointLine(this.action, this.count, this.pointsPerAction);

  int get subtotal => count * pointsPerAction;
}

/// Poengregnskapet linje for linje for spillerens tildelte rolle.
List<FantasyPointLine> calculatePointBreakdown(
  PlayerMatchStats? matchStats,
  String assignedRole,
) {
  if (matchStats == null) return const [];
  final roleMatrix = fantasyPointMatrix[assignedRole];
  if (roleMatrix == null) return const [];
  return [
    for (final e in roleMatrix.entries)
      FantasyPointLine(e.key, actionCount(matchStats, e.key), e.value),
  ];
}
