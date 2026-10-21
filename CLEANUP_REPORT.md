# Kodeopprydding – Spikedunk spillerapp (norgestourapp)

> **Mål:** samme jobb som i admin. Koden skal bli ryddig, oversiktlig og lett å lese, **uten å endre en eneste funksjon**. Appen skal se ut og oppføre seg som i dag, og lese og skrive de samme feltene i Firebase.
>
> **Status:** jeg har bare lest og analysert. Ingen filer er endret, bortsett fra denne rapporten.
>
> **Utgangspunkt:** `flutter analyze` gir ingen merknader. `flutter test` kjører **ikke i det hele tatt** i dag (se 3.5), så kontrollen etter hvert steg blir analyse pluss at du tester manuelt på telefon eller emulator.

## 1. Sammendrag

Appen er i bedre forfatning enn admin var: analysen er ren, og felles byggesteiner finnes allerede i `widgets/nt_ui.dart`. Det som trekker ned:

- **Kopier av ferdige byggesteiner.** `oppsett_page.dart` har egne kopier av hjelpere og widgets som allerede finnes i `nt_ui.dart`. `StatsCategoryCard` (240 linjer) finnes i to nesten like versjoner.
- **Kode som aldri vises.** To sider kan ikke åpnes fra noe sted i appen, og det finnes ubrukte tema-deler, 2 ubrukte pakker og 6 ubrukte bilder (ca. 8,5 MB).
- **Rester fra kodechat.** Kommentarer som «HER ER ENDRINGEN:», «Lim inn sorterings-blokken vi lagde sist her» og «Sjekk at mappen din heter 'pages' eller 'screens'».
- **Ødelagte tester.** Den ene testfilen er lagret i feil tegnkoding og krasjer testkjøreren. Den andre er Flutters standard teller-test, som ikke passer til denne appen.
- **Store filer og flat struktur.** `oppsett_page.dart` (1 472 linjer), `fantasy_squad_view.dart` (1 361) og `home_page.dart` (1 048). Alle sidene ligger flatt i `pages/`.

Alt nedenfor er ren omstrukturering. Der to kopier ser like ut, men gir **ulik** tekst eller ulikt utseende, slår jeg dem **ikke** sammen. De er listet for seg i §4.2.

## 2. Plan – fire steg, tryggest først

Arbeidet gjøres på en egen branch `kodeopprydding`, med én commit per steg, slik som i admin. Jeg kjører ikke `dart format`.

| Steg | Hva | Risiko |
|---|---|---|
| **1** | Slette død kode, ubrukt tema, pakker, bilder og ødelagte tester (§3) | Trygg |
| **2** | Bruke de felles byggesteinene i stedet for kopiene, og samle duplikater (§4.1) | Trygg (identisk utdata) |
| **3** | Ryddigere mappestruktur, og dele opp `oppsett_page.dart` (§5) | Lav (ren flytting) |
| **4** | Rydde kommentarer og lesbarhet (§6) | Trygg |

---

## 3. Steg 1 – Død kode

Jeg har søkt i hele `lib/` og `test/`. Appen har ingen navngitte ruter og ingen dynamiske imports, så søkeresultatene er pålitelige.

### 3.1 Sider som ikke kan åpnes fra appen
| Fil | Linjer | Bevis |
|---|---|---|
| `lib/pages/claim_player_page.dart` | 189 | Importeres ingen steder. Brukerne kan ikke nå siden for å gjøre krav på en spillerprofil |
| `lib/pages/fantasy/fantasy_highlights_view.dart` | 240 | Importeres ingen steder |

> Dette er trolig **uferdige funksjoner**, ikke søppel. README sier at koblingen mellom bruker og spiller ikke er ferdig. **Se spørsmål S1**, før noe slettes her.

### 3.2 Ubrukte deler i koden
- `widgets/nt_ui.dart:197`: `ntRoundOrder` brukes ikke. Den blir tatt i bruk i steg 2 (erstatter en kopi i `oppsett_page.dart`), så den blir stående.
- `theme/app_text_styles.dart`: `dispScoreLight` og `dispH1Light` brukes ikke.
- `theme/app_colors.dart`: `coralGlow`, `heroCoral` og `heroMix` brukes ikke.
- `theme/README.dart` (112 linjer) består av bare kommentarer, med eksempelkode og gammel installasjonsveiledning. Den er ikke en del av appen.

### 3.3 Pakker
- `cupertino_icons`: ingen `CupertinoIcons` i koden.
- `google_sign_in`: importeres ingen steder. Innloggingen bruker bare e-post og passord.

### 3.4 Bilder i `assets/images/`
Disse brukes ikke noe sted: **`1.png`, `3.png`, `5.png`, `8.png`, `ntbanner.png` og `splash_bg.png`** (til sammen ca. 8,5 MB).
Disse beholdes: `2`, `4`, `7`, `bakgrunn`, `card_bg`, `hero_bg`, `hero_card_bg` og `player_action` brukes i koden. `ntlogo.png` brukes av `flutter_launcher_icons` til app-ikonet.

### 3.5 Tester som ikke fungerer
- `test/dummy_test.dart` er en tom fil lagret i UTF-16. Den krasjer hele `flutter test` («Failed to decode data using encoding 'utf-8'»), så ingen tester kjører.
- `test/widget_test.dart` er Flutters standardtest for teller-appen (trykk «+», forvent «1»). Den passer ikke til denne appen og ville feilet.

Forslaget er å slette begge. **Se spørsmål S3**: vil du ha én enkel test som faktisk kjører i stedet?

---

## 4. Steg 2 – Samle duplisert kode

### 4.1 Det som slås sammen (gir nøyaktig samme utdata)

| # | Kopi | Erstattes med |
|---|---|---|
| 4.1.1 | `oppsett_page.dart`: `_isPlaceholderId`, `_sets`, `_setScores`, `_timeOf` | `ntIsPlaceholderId`, `ntSets`, `ntSetScores`, `ntMatchTime` i `nt_ui.dart` (linje for linje like) |
| 4.1.2 | `oppsett_page.dart`: `_roundOrder`, `_roundShort` | `ntRoundOrder`, `ntRoundShort` (samme verdier) |
| 4.1.3 | `oppsett_page.dart`: `_Segmented`, `_Card` | `NtSegmented`, `NtCard` (samme mål, farger og skygger) |
| 4.1.4 | `StatsCategoryCard` i både `stats_root_page.dart:278` og `tournament_stats_page.dart:278` (240 linjer hver) | Én felles widget i `widgets/stats_category_card.dart`. Eneste forskjell i dag er tittelfargen (mørk på sesongstatistikk, hvit på turneringsstatistikk). Den blir et parameter, så begge sidene ser ut som før |
| 4.1.5 | `tour_detail_page.dart:27` `_isRegistrationOpen` | `ntRegistrationOpen` i `nt_ui.dart` (samme regel: status `open` og frist ikke passert kl. 23:59) |
| 4.1.6 | `fantasy_squad_view.dart:88` `_roleAccent` returnerer alltid `AppColors.coral` | Bruk `AppColors.coral` direkte |
| 4.1.7 | Overflødige tomme linjer og hjelpere | Ryddes der de står |

### 4.2 Det som ser likt ut, men **ikke** slås sammen (fordi teksten eller utseendet er ulikt)
- **Plassnavn.** `oppsett_page.dart` viser «Treer/Firer pulje A», mens `nt_ui.dart` viser «3. plass/4. plass pulje A».
- **LIVE-merket.** `_LivePill` har 3 px luft, mens `NtLivePill` har 4 px.
- **Seksjonsoverskrift.** `_SectionHeader` gjør ikke om til store bokstaver og har tekst til høyre. `NtSectionHeader` gjør om til store bokstaver og har en widget til høyre.
- **Baneetikett.** `_courtLabel` gir «BANE 3», mens `ntCourtNumber` gir «3».
- **Lag-oppslag.** `_Ctx`/`_Slot` i oppsett har seed-etikett og egen tekst når kildekampen mangler nummer. `NtMatchCtx` mangler begge deler.
- **Fargepalett.** `_P` i oppsett har to farger (`strip`, `greenTint`) som `NtPalette` ikke har.
- **Påmeldingsfrist i tours-listen** (`tours_page.dart:70`). Den regner en *ugyldig* frist som åpen, mens `ntRegistrationOpen` regner den som stengt. For gyldige datoer er de like, men jeg lar den stå for å være helt sikker.
- **Statistikkutregningen** finnes i tre varianter: `stats_root_page`, `tournament_stats_page` og `fantasy/mock_data.dart`. De slår sammen spillernavn litt ulikt og tar med ulike detaljfelt. Å samle dem kan endre tallene, så det venter.

Hvis du vil, kan noen av disse gjøres like senere. Det endrer i så fall noe synlig, så det er ikke en del av denne jobben.

---

## 5. Steg 3 – Struktur

### 5.1 Mapper
I dag ligger 20 sider flatt i `pages/`. Forslaget grupperer dem etter fanene i bunnmenyen:

```
lib/
  main.dart
  logic/            stats_logic.dart (flyttes ut av pages/, det er utregning og ikke en side)
  pages/
    auth/           login_page, register_page                       (som i dag)
    home/           home_page
    tours/          tours_page, tour_detail_page, matches_page, oppsett/ (se 5.2),
                    teams_page, tournament_registration_page
    stats/          stats_root_page, tournament_stats_page, stats_details_page,
                    match_stats_page, players_list_page, player_detail_page
    fantasy/        fantasy_page + dagens fantasy/-mappe
    splash_page.dart, claim_player_page.dart (hvis den beholdes)
  widgets/          nt_ui, season_hero_widget, profile_avatar_widget, stats_category_card (ny)
  theme/
```

Lokale imports skrives som `package:norges_tour_app/...`, slik at stiene blir like overalt.

### 5.2 Dele opp `oppsett_page.dart` (1 472 linjer)
Filen inneholder siden pluss ca. 20 små private widgets (kampkort, puljetabell, sluttspilltre, strektegner osv.). Widgetene flyttes til egne `part`-filer, `oppsett/group_view.dart`, `oppsett/bracket_view.dart` og `oppsett/widgets.dart`. Det er ren flytting.

### 5.3 Fil med misvisende navn
`fantasy/mock_data.dart` inneholder ikke testdata. Den har `fetchFantasyPlayers()`, som henter **ekte** spillere og statistikk fra Firestore. Forslaget er å endre navnet til `fantasy/fantasy_players_source.dart`.

### 5.4 Store filer som jeg foreslår å la være
`fantasy_squad_view.dart` (1 361) og `home_page.dart` (1 048) er store, men har én tilstandsklasse med mange byggemetoder. Oppdeling krever samme grep som i admin (part-filer med extension). Det kan gjøres, men gevinsten er mindre her. **Se spørsmål S4.**

---

## 6. Steg 4 – Lesbarhet

**Kommentarer som er rester fra kodechat (fjernes eller skrives om):**
| Sted | Kommentar |
|---|---|
| `main.dart:4, 16, 20` | «--- 1. NYTT: Importer Firebase-pakkene ---», «2. NYTT…», «3. NYTT…» |
| `main.dart:6` | «Denne filen ble laget av 'flutterfire configure'» |
| `main.dart:8-9` | «Import all your screen files», «Sjekk at mappen din heter 'pages' eller 'screens'» |
| `tournament_stats_page.dart:4` | «Husk å lage/oppdatere denne filen (se under)» |
| `tournament_stats_page.dart:128-129` | «… (Din sorterings-kode her …)», «… (Lim inn sorterings-blokken vi lagde sist her) …» |
| `tournament_stats_page.dart:155-159` | «HER ER ENDRINGEN:», «Kaller funksjonen under», «Viktig for at den skal kunne dras» |
| `tournament_stats_page.dart:34` | «Henter og slår sammen stats (Samme logikk som før)» |
| `splash_page.dart:90` | «Dark overlay removed per user request» |
| `season_hero_widget.dart:21` | «Endret til null som standard» |

**Annet:**
- **Poengtabellen** i regelboken (`fantasy_squad_view.dart:1321-1338`) er skrevet inn for hånd med de samme tallene som `fantasy_point_matrix.dart`. Tallene stemmer i dag. Jeg legger inn en kommentar om at de må holdes like, slik at de ikke glir fra hverandre senere.
- **Språk i kommentarer:** blanding av norsk og engelsk («Fixed height for carousel cards», «Dynamically fetch and compute…»). Kommentarene gjøres norske slik som resten av koden. UI-teksten røres ikke.
- **`debugPrint` i `catch`-blokkene** (`league_logic.dart:77, 104`, `home_page.dart:88`) er reell feillogging og beholdes.

---

## 7. Hva jeg bevisst ikke rører
- Funksjonalitet, UI-tekst, farger og layout.
- Firebase-felter, samlinger og spørringer.
- Det som ser likt ut, men ikke er det (§4.2).
- Sikkerhetsregler, påmelding (`kRegistrationEnabled`) og fantasy-logikk.
- `dart format`.

## 8. Spørsmål før jeg begynner

**S1.** `claim_player_page.dart` (gjøre krav på spillerprofil) og `fantasy_highlights_view.dart` kan ikke åpnes fra appen i dag. Skal de **beholdes** som uferdige funksjoner, eller **slettes**? Jeg anbefaler å beholde dem, siden koblingen mellom bruker og spiller er på planen.

**S2.** Er `docs/FARGEOPPRYDDING.md` (oppdraget om å samle fargene) ferdig? Da kan den slettes, og linjen om den fjernes fra README. Ellers lar jeg den stå.

**S3.** De to testfilene virker ikke. Skal jeg **bare slette dem**, eller også legge inn **én enkel test som faktisk kjører** (for eksempel at fantasy-poengmatrisen gir riktige poeng)? Testen endrer ikke appen, men gir et sikkerhetsnett for senere.

**S4.** Skal `fantasy_squad_view.dart` og `home_page.dart` også deles opp (§5.4), eller holder det med `oppsett_page.dart`?

Resten (steg 1–4 som beskrevet) kan jeg gjøre så snart du sier ja.
