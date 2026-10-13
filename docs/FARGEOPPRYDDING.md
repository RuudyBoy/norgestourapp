# Oppdrag: Rydd opp i fargene i hovedappen (norgestourapp)

## Mål
Appen skal bare bruke fargene i `lib/theme/app_colors.dart`. I dag finnes det ca. 80 steder
med hardkodede farger (`Colors.blue[900]`, `Color(0xFF0A1931)` osv.) utenom designsystemet.
De skal byttes ut med tokens fra `AppColors`, slik at appen går fra ca. 56 ulike farger til ca. 14.

**Designet skal se likt ut etterpå.** Dette er en opprydding, ikke et redesign.

## Regler for jobben
1. Ikke endre layout, avstander, tekster, logikk eller Firebase-kode. Bare farger.
2. Ikke slett eller endre eksisterende tokens i `app_colors.dart`. Du får bare legge til de tre nye under.
3. `Colors.white`, `Colors.black` og `Colors.transparent` får stå.
4. Jobb én fil om gangen. Kjør `flutter analyze` etter hver fil; ingen nye warnings eller errors.
5. Hvis en erstatning gir synlig annen farge enn før (mer enn en nyanse), stopp og spør i stedet for å gjette.
6. Avslutt med en kort rapport: hvilke filer som er endret, og eventuelle steder du lot stå og hvorfor.
7. Commit med en beskrivende melding, f.eks. `Fargeopprydding: <filnavn> bruker AppColors`.

## Steg 1: Legg til tre tokens i `lib/theme/app_colors.dart`
Legg dem under `// ── Semantic ──`:

```dart
/// Advarsel / frist / venteliste / 1. plass-medalje
static const Color warning     = Color(0xFFC98A1B);
/// Farlig handling / feil / avvist / trekk påmelding
static const Color danger      = Color(0xFFC62828);
/// Suksess på mørk bakgrunn (fantasy). `green` er for mørk på navy.
static const Color greenBright = Color(0xFF36C87A);
```

## Steg 2: Erstatningstabell

| Gammel verdi | Ny verdi | Kommentar |
| --- | --- | --- |
| `Color(0xFF0A1931)` | `AppColors.ink` | Nesten identisk navy |
| `Color(0xFF1A1A2E)` | `AppColors.nightSurface1` | App bar i mørk modus |
| `Color(0xFF0B1220)` | `AppColors.nightSurface1` | Mørk bakgrunn |
| `Color(0xFF111C30)` | `AppColors.nightSurface0` | Mørk flate |
| `Color(0xFF18253E)` | `AppColors.nightSurface0` | Mørk flate (litt lysere) |
| `Color(0xFF1E2E48)` | `AppColors.nightSurface2` | Mørk ramme/skille |
| `Color(0xFFE85D4E)` | `AppColors.coral` | |
| `Color(0xFFD64A35)` | `AppColors.coralDeep` | |
| `Color(0xFF36C87A)` | `AppColors.greenBright` | Nytt token |
| `Color(0xFFF0F0F0)` | `AppColors.sand0` | Lyst kort |
| `Color(0xFF111111)` | `AppColors.ink` | Tekst på lyst kort |
| `Color(0xFF666666)` | `AppColors.ink2` | Sekundærtekst på lyst kort |
| `Colors.grey`, `Colors.grey[600]` | `AppColors.ink2` | Sekundærtekst/ikon |
| `Colors.grey[500]`, `Colors.grey[400]` | `AppColors.ink3` | Hint, deaktivert |
| `Colors.grey[300]`, `Colors.grey[200]`, `Colors.grey.shade200`, `Colors.grey.shade300` | `AppColors.sand2` (flate) eller `AppColors.line` (ramme) | Velg etter bruk |
| `Colors.blue[900]` (app bar, knapp) | `AppColors.ink` | |
| `[Colors.blue[900]!, Colors.blue[700]!]` (gradient) | `AppColors.heroNavy` (bruk `gradient: AppColors.heroNavy`) | |
| `Colors.blue[800]`, `Colors.blue[600]`, `Colors.blue` | `AppColors.blue` | |
| `Colors.blue[50]` | `AppColors.blue.withValues(alpha: 0.08)` | Lys blå bakgrunn |
| `Colors.blue[200]`, `Colors.blue.shade200`, `Colors.blue.shade300` | `AppColors.blue.withValues(alpha: 0.3)` | Blå ramme/skille |
| `Colors.orange` | `AppColors.warning` | |
| `Colors.amber.shade700` | `AppColors.warning` | 1. plass |
| `Colors.red`, `Colors.redAccent` | `AppColors.danger` | |
| `Colors.green` | `AppColors.green` | |

## Steg 3: Filer og linjer (sjekket 13.10.2026, linjenumre kan ha flyttet seg)

### `lib/pages/tournament_registration_page.dart` (flest avvik, ta denne først)
Linjer: 204, 364, 377, 413, 417, 434, 458, 460, 466, 467, 471, 472, 476, 484, 507, 518, 545, 549, 559,
569, 580, 589, 599, 602, 608, 626, 637, 654, 674, 676, 678, 693, 706, 714, 722, 730.
- Linje 364 og 637: `isDark ? Color(0xFF1A1A2E) : Colors.blue[900]` → `isDark ? AppColors.nightSurface1 : AppColors.ink`.
- Linje 706–730 er statusfarger for påmelding: godkjent → `green`, venteliste → `warning`, avvist → `danger`, venter → `blue`.
- Siden bruker også mange egne `TextStyle(...)`. Bytt dem til `AppText` der det finnes en tilsvarende stil, men bare hvis det ikke endrer utseendet merkbart.

### `lib/pages/fantasy/fantasy_squad_view.dart`
- Linje 9–12 definerer en privat palett (`_bg`, `_surface`, `_surface2`, `_border`). Slett de fire konstantene og bytt de 27 bruksstedene etter tabellen.
- Linje 142, 1134, 1357: `Color(0xFF36C87A)` → `AppColors.greenBright`.
- Linje 302, 373: `Colors.grey.shade200` → `AppColors.line`.
- Linje 317, 388: `Colors.grey[600]` → `AppColors.ink2`.
- Linje 511, 616, 629, 642: lyst kort → `sand0` / `ink` / `ink2`.

### `lib/pages/fantasy/fantasy_player_selection.dart`
- Linje 316: `Colors.redAccent` → `AppColors.danger`.
- Linje 332, 438, 450, 463: lyst kort → `sand0` / `ink` / `ink2`.

### `lib/pages/fantasy/player_stats_sheet.dart`
- Linje 9, 27, 37, 82: mørke flater etter tabellen.

### `lib/pages/fantasy/fantasy_highlights_view.dart`
- Linje 126: `[AppColors.coral, Color(0xFFD64A35)]` → `[AppColors.coral, AppColors.coralDeep]`.

### `lib/pages/fantasy_page.dart`
- Linje 135: `Color(0xFF36C87A)` → `AppColors.greenBright`.

### `lib/pages/teams_page.dart`
- Linje 43: `Colors.grey` → `AppColors.ink3`.
- Linje 90: `Color(0xFFE85D4E)` / `Color(0xFF0A1931)` → `AppColors.coral` / `AppColors.ink`.
- Linje 118: → `AppColors.ink`.

### `lib/pages/matches_page.dart`
- Linje 130: `Colors.grey` → `AppColors.ink2`. Linje 155: → `AppColors.ink`.

### `lib/pages/oppsett_page.dart`
- Linje 151: → `AppColors.ink`.

### `lib/pages/splash_page.dart`
- Linje 126–128: `Color(0xFF0B1220)` → `AppColors.nightSurface1` (behold alpha-verdiene).

### `lib/pages/player_detail_page.dart`
- Linje 197: `Colors.amber.shade700` → `AppColors.warning`.

### `lib/pages/tour_detail_page.dart`
- Linje 61: `Colors.grey[600]` → `AppColors.ink2`.

### `lib/main.dart`
- Linje 26: `Color(0xFF0A1931)` → `AppColors.ink` (husk import av `theme/app_colors.dart`).

## Steg 4: Sjekk at det er ferdig
Kjør dette fra `lib/`. Begge skal gi 0 treff utenfor `theme/`:

```bash
grep -rnE "Color\(0x" --include=*.dart --exclude-dir=theme .
grep -rnE "(^|[^A-Za-z])Colors\.[a-zA-Z]+" --include=*.dart --exclude-dir=theme . | grep -vE "Colors\.(white|black|transparent)"
```

Start appen og se gjennom: Hjem, Fantasy (lag, spillervalg, statistikkark), Tours → turnering → Meld på,
Lag, Kamper, Oppsett, spillerprofil og splash. Både lys og mørk modus.

## Ikke en del av denne jobben (senere)
- Bytte `withOpacity` til `withValues` (54 steder).
- Admin- og livescore-appen.
- Felles designpakke for alle tre appene.
