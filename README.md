# Spikedunk – Spillerapp

Mobilappen for spillere og publikum i Spikedunk, et hobbyprosjekt som digitaliserer norske sandvolleyballturneringer fra påmelding til resultat.

Spikedunk består av tre Flutter-apper som deler én Firebase-database:

| App | Repo | Brukes av |
| --- | --- | --- |
| Admin | [norgestouradmin](https://github.com/RuudyBoy/norgestouradmin) | Arrangører |
| Dommerapp | [norgestourlivescore](https://github.com/RuudyBoy/norgestourlivescore) | Dommere ved banen |
| **Spillerapp** (dette repoet) | [norgestourapp](https://github.com/RuudyBoy/norgestourapp) | Spillere og publikum |

Case study: [cjrportfolio.netlify.app/spikedunk](https://cjrportfolio.netlify.app/spikedunk)

## Hva appen gjør

- **Hjem:** sesongoversikt, live-kamper og eget fantasylag.
- **Tours:** turneringer, klasser, påmeldte lag, kampprogram og resultater i sanntid, og påmelding til turnering.
- **Statistikk:** statistikk per spiller, kamp og turnering, regnet ut fra hendelsene dommeren registrerer.
- **Fantasy:** velg spillere, lås hver spiller til én rolle (angrep, legg, mottak, forsvar, blokk eller serv), og se plasseringen din i en felles poengtabell. Private ligaer er ikke laget ennå.
- Innlogging og registrering med Firebase Auth (e-post og passord).

## Hvordan det fungerer

Dommerappen lagrer hver handling i en kamp som et dokument i `matches/{id}/events`. Spillerappen leser hendelsene og regner ut statistikk (`lib/pages/stats_logic.dart`) og fantasypoeng fra samme kilde.

Fantasy bruker en kalibrert poengmatrise (`lib/pages/fantasy/fantasy_point_matrix.dart`): en spiller gir bare poeng for handlinger i rollen den er låst til, og poengene er satt slik at en gjennomsnittlig prestasjon gir omtrent 100 poeng per sett i alle roller. Sjeldne handlinger som blokk og ess er derfor verdt mer enn hyppige angrep.

## Struktur

```
lib/
  main.dart           App-oppstart og bunnmeny (Hjem, Fantasy, Tours, Statistikk)
  pages/
    auth/             Innlogging og registrering
    fantasy/          Lagvalg, ligaer, poengmatrise og modeller
    stats_logic.dart  Utregning av statistikk fra kamphendelser
    tour_detail_page.dart, matches_page.dart, tournament_registration_page.dart, …
  theme/              Farger, typografi og tema (designsystem)
  widgets/            Gjenbrukbare UI-komponenter
docs/FARGEOPPRYDDING.md  Oppdrag for å samle fargene i designsystemet
```

## Teknologi

Flutter og Dart · Firebase Auth · Cloud Firestore · Google Fonts

## Kjør lokalt

Krever Flutter (Dart SDK 3.9 eller nyere) og en Android- eller iOS-enhet eller emulator.

```bash
flutter pub get
flutter run
```

## Status

Fungerende prototype, ikke publisert i App Store eller Google Play. Påmelding og kobling mellom bruker og spillerprofil er ikke ferdig, og Firestore-reglene må strammes inn før ekte brukere slippes inn. Neste steg er riktige sikkerhetsregler, forhåndsberegnet statistikk i Cloud Functions, betaling med Vipps og klargjøring for app-butikkene.

Laget av Christian Jørgensen Ruud.
