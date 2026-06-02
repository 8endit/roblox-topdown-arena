# Room-, Stage- und Fate-Content-Plan (Builder)

Status: Content-/Design-Plan fuer die Room/Stage/Gate-Architektur. Builder-Sicht.
Codex baut parallel RoomService, Gate-System, Stage/Room-State, WaveService- und
HUD-Anpassung. Dieses Dokument aendert KEINEN Gameplay-Code und kein `Config.lua`.
Alle Config-Bloecke sind Vorschlaege (Struktur, keine Logik).

Loest [CLAUDE_FLOOR_CONTENT_PLAN.md](CLAUDE_FLOOR_CONTENT_PLAN.md) ab (altes Floor=Raum=Teleporter-Modell).
Bezug: [docs/GAMEPLAY_ROADMAP.md](../docs/GAMEPLAY_ROADMAP.md).

Designziel: dieselben Spielprinzipien des Vorbilds sauber uebernehmen, in eigenem Thema und
ohne fremde Namen/Assets: Raum-zu-Raum-Fortschritt, Stage-Teleporter, Fates, Panic-Buttons,
Powerup-Chaos, Boss-Meilensteine, klare Top-down-Steuerung.

Grundlage ist der aktuelle Inhalt: Gegner Runner, Bruiser, Spitter, Exploder, Tank;
Waffen Pistol, SMG, Shotgun, Rifle, Burst Rifle, Beam; Powerups Health, Damage Boost,
Rapid Fire, Speed Boost, Shield, Nuke, Freeze, Magnet; Maps Depot, Courtyard, Bunker,
Crucible, Galleries; Rarities Common, Rare, Epic.

---

## Aktualisierung 2026-06-01 (nach erstem Studio-Test)

Nach dem Test von Codex' erstem RoomService steht das Routen-Modell fest (bestaetigt vom User):
- Vorwaerts-only, keine Wiederkehr: kein Room wird zweimal betreten, keine Rueck-Gates.
- Tor-Anzahl deterministisch aus dem Template (`node.next`), nicht zufaellig.
- Spezial-Raeume als Fork-Merge-Detour: ein Abzweig fuehrt nach Clear vorwaerts auf den
  naechsten Hauptraum (kein Sackgassen-/Rueckkehr-Modell mehr).
- Pro Stage garantierte Verteilung: mindestens 1 TreasureRoom, ab Stage 2 mindestens 1 FateRoom.
- Fate-Angebot-Mechanik definiert (Abschnitt 7.1).

Konkrete Aenderungen am aktuellen RoomService (fuer Codex):
1. Gate-Anzahl nicht mehr zufaellig: genau ein Gate pro Eintrag in `node.next`.
2. Rueck-Gates entfernen: Detour-Spuren mergen vorwaerts auf den naechsten Hauptraum.
3. Beim Durchlaufen eines Forks die uebrigen Gates schliessen (commit, keine Wiederkehr).
4. Verteilungs-Garantie pro Stage umsetzen (Treasure immer, Fate ab Stage 2).
5. FateRoom: Drei-aus-Pool-Auswahl-Mechanik (Abschnitt 7.1).

---

## 1. Vokabular und Service-Schnitt

| Begriff         | Bedeutung                                                        |
|-----------------|------------------------------------------------------------------|
| Run             | ein Durchlauf vom Start bis Game-Over                            |
| Stage           | ein Gebiet/Biome, besteht aus mehreren Rooms                     |
| Room            | einzelner Kampf-/Spezialraum (nutzt ein Arena-Layout)           |
| RoomGraph       | Vorwaerts-Graph der Rooms einer Stage (Hauptpfad plus Detours)  |
| Gate            | Ausgang an einer Raumseite, oeffnet nach Room-Clear              |
| StageTeleporter | erscheint nur am Stage-Ende (ExitRoom oder nach BossRoom)        |

Service-Schnitt (Codex baut, ich liefere nur Daten/Design):
- RoomService: laedt Rooms, fuehrt Room-Logik aus, meldet Clear.
- GateService: zeigt nach Clear Gates an den Seiten, laedt Nachbarraum bei Durchlauf.
- RunService/StageService: haelt Run-, Stage- und Room-State, waehlt Graph und Biome.
- WaveService: spawnt pro Room nach Room-Typ-Regeln (statt pro Welle/Floor).
- HUD: zeigt Stage und Room (z. B. "Stage 2 / Room 3"), Banner bei Stage-Wechsel.

Was ich von diesen Services als Hooks brauche, steht in Abschnitt 11.

---

## 2. Run- und Stage-Struktur

- Ein Run laeuft ueber fortlaufende Stages, bis die Leben aufgebraucht sind.
- Jede Stage ist ein Vorwaerts-Graph aus 4 bis 7 Hauptraeumen plus optionalen Detour-Spuren.
- Genau ein Terminal-Room pro Stage spawnt den StageTeleporter beim Clear (ExitRoom in
  normalen Stages, BossRoom in Boss-Stages).
- Garantierte Verteilung pro Stage: mindestens 1 TreasureRoom-Detour, ab Stage 2 mindestens
  1 FateRoom-Detour. Spezial-Raeume sind erreichbar, aber optional (Detour-Entscheidung).
- Progression der Stages:

| Stage | Rooms (Hauptpfad) | Boss am Ende | Spezial-Detours       | Gegner-Mix           |
|-------|-------------------|--------------|-----------------------|----------------------|
| 1     | 3 bis 4           | nein         | Treasure              | leicht, Runner-lastig|
| 2     | 4 bis 5           | optional     | Treasure und Fate     | staerker, gemischt   |
| 3+    | 5 bis 7           | ja           | Fate, Treasure, Bonus | voller Mix, Elites   |

- Schwierigkeit skaliert mit der Stage-Nummer (multiplikativ, sanft), nicht pro Room
  hart hochspringend. Details in Boss-Abschnitt und Config-Vorschlag.

---

## 3. Room-Typen im Detail

Erste sieben Typen (mehr spaeter). "Clear" beschreibt, wann die Gates aufgehen.

### 3.1 StartRoom
- Zielgefuehl: Ankommen, kurz orientieren.
- Clear: keine oder triviale Gegner, Gate(s) oeffnen sofort oder nach kurzem Stage-Banner.
- Loot/Powerup: keins oder ein kleiner Common.
- Layout: beliebig (Archetyp egal).
- Risiko/Belohnung: keins, reiner Einstieg.

### 3.2 CombatRoom
- Zielgefuehl: Brot-und-Butter-Gefecht, alle Rollen lesbar.
- Clear: alle Gegner tot, dann Gates auf.
- Gegner-Mix: Runner als Rueckgrat, Bruiser, Spitter, ab Stage 2 Exploder. Budget nach
  Stage skaliert.
- Loot: Standard-Rarities, Common-lastig, normale Drop-Chance.
- Powerup: voller Pool, keine Bevorzugung.
- Layout: jeder Archetyp.
- Risiko/Belohnung: ausgeglichen, Referenz fuers Balancing.

### 3.3 RushRoom
- Zielgefuehl: Adrenalin, Maehen, Combo laeuft heiss.
- Clear: alle Gegner tot.
- Gegner-Mix: schwerer Runner-Schwarm, wenige Exploder als Wuerze. Kein Tank, kein Bruiser.
  Hohe Stueckzahl, niedrige Einzel-HP.
- Loot: pro Kill weniger, durch Masse hoher Echoes/Combo-Durchsatz. Garantierter Magnet zu
  Beginn.
- Powerup: Double-Score und Magnet bevorzugt.
- Layout: offen (Courtyard, Crucible), damit man im Kreis kiten kann.
- Risiko/Belohnung: Umzingeltwerden gegen Combo- und Echoes-Spike.

### 3.4 TreasureRoom
- Zielgefuehl: Belohnung, leichte Gier.
- Clear: Loot eingesammelt oder kurze Timer-/Fallenwelle ueberstanden, dann Gate auf.
- Gegner-Mix: keine oder eine kleine Fallenwelle Runner beim Aufnehmen des Hauptpreises.
- Loot: vorplatziertes garantiertes Rare, Chance auf Epic, plus Echoes.
- Powerup: ein garantiertes nuetzliches Powerup.
- Layout: eng/umschlossen (Galleries, Bunker), damit Loot zentriert liegt.
- Risiko/Belohnung: gering bis mittel, optionale Detour.
- Spaeter: BonusRoom als Gier-Variante (mehr Loot, dafuer Ausgangs-Welle, die mit der Gier skaliert).

### 3.5 FateRoom
- Zielgefuehl: Entscheidung, Run-Identitaet formen.
- Clear: ein Fate aus drei Angeboten gewaehlt, dann Vorwaerts-Gate auf. Mechanik in Abschnitt 7.1.
- Gegner-Mix: keine.
- Loot/Powerup: keins (der Fate ist die Belohnung).
- Layout: ruhig, beliebig, ohne Gefahr.
- Risiko/Belohnung: kein Risiko, dafuer eine bewusste Build-Entscheidung.

### 3.6 BossRoom
- Zielgefuehl: Showdown, Meilenstein.
- Clear: Boss tot. Terminal-Room, spawnt danach den StageTeleporter.
- Gegner-Mix: Tank als Boss plus begrenzte Support-Adds (Runner, selten Spitter). Adds
  gedeckelt, stoppen bei niedriger Boss-HP. Details Abschnitt 6.
- Loot: garantiert Rare/Epic (Boss-Tier vorhanden), Vorschlag plus garantiertes Fate-Angebot.
- Powerup: Adds koennen selten ein defensives Powerup droppen (Shield, Freeze).
- Layout: offen oder center-risk (Courtyard, Crucible), Kiting muss moeglich sein. Keine
  Choke-Maps (man wird gestellt).
- Risiko/Belohnung: hohe Einzelbedrohung gegen garantierten Top-Drop und Fate.

### 3.7 ExitRoom
- Zielgefuehl: letzter Druck vor dem Stage-Sprung.
- Clear: leichte Welle tot, dann StageTeleporter. Terminal-Room in Nicht-Boss-Stages.
- Gegner-Mix: kleine, schnelle Welle (reduziertes Budget).
- Loot: ein garantierter Drop als Belohnung vor dem Sprung.
- Powerup: optional ein Panic-Button (Nuke/Freeze) als Vorrat fuer die naechste Stage.
- Layout: beliebig.
- Risiko/Belohnung: niedrig, markiert das Stage-Ende.

---

## 4. RoomGraph-Designs (Fork-Merge, vorwaerts-only)

Modell: Eine Stage ist ein Hauptpfad aus Rooms (Start bis Terminal). Jeder Knoten deklariert
seine Vorwaerts-Ziele als `next = { ZielId = "Richtung" }`. Nach Clear oeffnet GateService
genau ein Gate pro Eintrag (deterministisch, nicht zufaellig). Der Spieler laeuft durch ein
Gate, der Zielraum wird zum aktuellen Room. Kein Backtracking, keine Wiederkehr: beim
Durchlaufen eines Forks werden die uebrigen Gates geschlossen, ein Room wird nie zweimal betreten.

Spezial-Raeume (Treasure/Fate/Bonus) sind Fork-Merge-Detours: am Fork waehlt der Spieler den
Abzweig oder den direkten Weg. Der Abzweig fuehrt nach seinem Clear VORWAERTS auf denselben
naechsten Hauptraum (Merge). Echte Entscheidung (Detour fuer Loot/Fate gegen Tempo), aber nie zurueck.

Terminal-Room (Exit/Boss) hat `next = {}` und spawnt beim Clear den StageTeleporter.

Knoten-Form: `id = { type = "...", next = { ZielId = "Dir", ... }, terminal = true? }`.
Gate-Anzahl = Anzahl der Eintraege in `next` (1 linear, 2 am Fork).
Richtungs-Mapping-Vorschlag fuer GateService: N = -Z, S = +Z, E = +X, W = -X.

### Stage 1 (Foundry): kein Boss, kein Fate, eine Treasure-Detour

```
                        .--E--> (Treasure t) --E--.
                        | Detour                    v Merge
(Start s) --E--> (Combat c1) --------E--------> (Combat c2) --E--> (Exit x)
   Fork an c1: E weiter zu c2, N Detour zu t; t fuehrt per E vorwaerts zu c2
```

```lua
start = "s",
s  = { type = "StartRoom",    next = { c1 = "E" } },
c1 = { type = "CombatRoom",   next = { c2 = "E", t = "N" } },   -- Fork
t  = { type = "TreasureRoom", next = { c2 = "E" } },            -- Detour, merged vorwaerts
c2 = { type = "CombatRoom",   next = { x = "E" } },
x  = { type = "ExitRoom",     next = {}, terminal = true },
```

### Stage 2 (Garden): Fate- und Treasure-Detour, Exit-Terminal

```
   (Fate f) Detour, merge -> r        (Treasure t) Detour, merge -> x
      ^N                                  ^S
(Start s)-E-(Combat c1)-E-(Rush r)-E-(Exit x)
```

```lua
start = "s",
s  = { type = "StartRoom",    next = { c1 = "E" } },
c1 = { type = "CombatRoom",   next = { r = "E", f = "N" } },   -- Fork
f  = { type = "FateRoom",     next = { r = "E" } },            -- Detour, merge vorwaerts
r  = { type = "RushRoom",     next = { x = "E", t = "S" } },   -- Fork
t  = { type = "TreasureRoom", next = { x = "E" } },            -- Detour, merge vorwaerts
x  = { type = "ExitRoom",     next = {}, terminal = true },
```

### Stage 3 (Deep): Boss-Terminal, Fate- und Treasure-Detour

```
   (Fate f)              (Treasure t)
      ^N                     ^S
(Start s)-E-(Combat c1)-E-(Combat c2)-E-(Rush r)-E-(Boss B)
```

```lua
start = "s",
s  = { type = "StartRoom",    next = { c1 = "E" } },
c1 = { type = "CombatRoom",   next = { c2 = "E", f = "N" } },  -- Fork
f  = { type = "FateRoom",     next = { c2 = "E" } },           -- Detour, merge vorwaerts
c2 = { type = "CombatRoom",   next = { r = "E", t = "S" } },   -- Fork
t  = { type = "TreasureRoom", next = { r = "E" } },            -- Detour, merge vorwaerts
r  = { type = "RushRoom",     next = { B = "E" } },
B  = { type = "BossRoom",     next = {}, terminal = true },
```

### Stage 4+ (prozedural)

Ab Stage 4 generiert RunService statt fester Templates. Regel mit garantierter Verteilung:
- Hauptpfad-Laenge = clamp(4 + StageIndex, 5, 7) Rooms (Start bis Terminal).
- Garantierte Verteilung pro Stage: immer mindestens 1 TreasureRoom-Detour, ab Stage 2
  mindestens 1 FateRoom-Detour, ab Stage 4 zusaetzlich Chance auf 1 BonusRoom-Detour.
- Jede Detour ist Fork-Merge: Abzweig fuehrt nach Clear vorwaerts auf den naechsten Hauptraum.
- Mindestens 1 RushRoom im Hauptpfad ab Stage 2.
- Terminal = BossRoom ab Stage 3, sonst ExitRoom. Erster Room immer StartRoom.
- Kein Nicht-Combat-Raumtyp zweimal hintereinander im Hauptpfad.
- Tor-Anzahl deterministisch (= Eintraege in `next`): 1 linear, 2 am Fork. Nie zufaellig.

---

## 5. Gate-System-Semantik

- Vorwaerts-only, keine Wiederkehr: Rooms werden genau einmal betreten. Es gibt keine
  Rueck-Gates. Ein Knoten ist nach dem Verlassen nicht mehr erreichbar.
- Gate-Anzahl deterministisch: genau ein Gate pro Eintrag in `node.next` (1 linear, 2 am Fork).
  Nicht zufaellig.
- Fork: nach Clear oeffnen alle deklarierten Gates gleichzeitig. Der Spieler waehlt eines; beim
  Durchlaufen werden die uebrigen Gates des Forks geschlossen/entfernt (commit).
- Detour-Spur (Treasure/Fate/Bonus): nach Clear fuehrt ihr Gate VORWAERTS auf den naechsten
  Hauptraum (Merge), nicht zurueck. Nie Backtracking, aber eine echte Entscheidung am Fork.
- Optik: leuchtendes Neon-Tor mit Richtung und Ziel-Room-Typ-Markierung (Treasure golden,
  Fate violett, Boss rot, Exit cyan). So waehlt der Spieler informiert.
- Durchlaufen: aktueller Room wird entladen, Ziel-Room geladen, State wechselt (Room-Index hoch,
  Room-Typ, terminal-Flag).
- Terminal-Room: keine Gates, sondern StageTeleporter beim Clear.
- StageTeleporter: kurze Banner-Sequenz ("STAGE 1 CLEAR", dann "STAGE 2: GARDEN"), dann
  naechste Stage. Nach BossRoom zusaetzlich ein Fate-Angebot davor (Abschnitt 7.1).

---

## 6. Boss-Rooms im Detail

### Wann
- Ab Stage 3 jede Stage ein BossRoom als Terminal. Stage 1 nie, Stage 2 optional (Chance).
- Vorschlag spaeter: Mega-Boss alle drei Boss-Stages, haerter, garantiert Epic plus Fate-Wahl.

### Tank-/Boss-Tuning (Stage-skaliert, multiplikativ)
| Groesse      | Vorschlag                                              |
|--------------|--------------------------------------------------------|
| Basis-Health | `Tank.Health` als Boss-Basis der ersten Boss-Stage     |
| Health/Stage | ca. +10 % pro Boss-Stage (multiplikativ)               |
| Damage/Stage | leicht (+5 %), nicht eskalieren                        |
| Speed        | konstant langsam, Kiting muss moeglich bleiben         |
| Score/Echoes | hoher Fixwert plus kleiner Stage-Bonus                 |

Schwierigkeit lieber ueber Adds, Map und spaetere Boss-Varianten als ueber reine HP, sonst
wird der Boss ein zaeher Schwamm statt schwer.

### Spawn-Pattern
- Boss zuerst, mit bestehender Warnung ("TANK INCOMING"-Banner, Boss-Bar).
- Support-Adds in Intervallen (alle 12 bis 15 s ein kleiner Runner-Trupp), Deckel auf
  gleichzeitig lebende Adds (z. B. max 6).
- Adds stoppen, sobald der Boss unter ca. 25 % HP faellt, fuer eine saubere Endphase.

### Drop
- Garantiert Rare/Epic (Boss-Tier vorhanden).
- Vorschlag: danach garantiertes Fate-Angebot (1 aus 3), beim ersten Boss eines Runs ein
  garantierter Lebensfunke.

### Boss-Varianten (spaeter)
Aktuell nur Tank. Ohne fremde Namen denkbar: Waechter (Frontschild, von hinten verwundbar),
Beschwoerer (ruft laufend Adds), Spalter (teilt sich bei Schwellen-HP).

---

## 7. Fates (finalisiert)

Run-scoped Boons, beim Tod verloren, getrennt von persistenten Perks (Phase 3).

### 7.1 Fate-Angebot (Mechanik)

- FateRoom betreten: keine Gegner. Server spawnt drei Auswahl-Saeulen (Neon-Pedestale) im Raum,
  je mit Name, Kurzbeschreibung und Tag-Farbe.
- Angebot: drei zufaellige Fates aus dem Pool, keine Duplikate im Angebot, keine bereits
  besessenen Unique-Fates.
- Auswahl: Spieler beruehrt/aktiviert eine Saeule. Der gewaehlte Fate kommt in den Run-State
  (RunService haelt `run.fates`). Die anderen zwei verschwinden, Banner/Toast bestaetigt, und
  Clear = chooseFate oeffnet das Vorwaerts-Gate.
- Nach BossRoom: zusaetzliches garantiertes Fate-Angebot mit demselben Mechanismus, vor dem
  StageTeleporter.
- Effekt-Anwendung: RunService haelt die Menge der gewaehlten Fates; Effekte werden beim Spawn
  (PlayerService) und beim Schuss (WeaponService) angewandt (eigener ModifierService oder inline).
- Umsetzungsreihenfolge (leicht zuerst), damit das Angebot sofort etwas bewirkt:
  - Sofort billig (haengen an vorhandenen Systemen): Fleet Soul (Dash-CD), Heavy Hands
    (+Dmg/-Speed), Glass Flame (+Dmg/-MaxHP), Piercing Rite (+1 Pierce auf vorhandenes Pierce-Feld).
  - Etwas mehr: Echo Magnet (passiver Pull in PickupService), Last Ward (Health-Watch + Shield).
  - Komplex spaeter: Storm Vein (On-Kill-AoE), Second Breath (Auto-Revive, haengt am
    Lebens-/Run-Lebenszyklus aus Phase 1).
- v1-Vorschlag: FateRoom-Auswahl-Mechanik plus die vier billigen Effekte sofort, Rest inkrementell.

### 7.2 Fate-Pool

Angebot im FateRoom und nach BossRoom: 1 aus 3 aus dem Pool, keine Duplikate im selben Angebot.
Einige Fates sind einmalig (unique), wenige stapelbar mit Cap.

| Fate          | Wirkung (Startwerte)                                   | Stapelbar | Balancing-Risiko                                  | Spaeter betroffene Services                          |
|---------------|--------------------------------------------------------|-----------|---------------------------------------------------|------------------------------------------------------|
| Fleet Soul    | Dash-Cooldown -35 %                                    | nein      | Kiting sehr stark, v. a. mit Storm Vein           | Dash-Logik (TopDownController/PlayerService)         |
| Echo Magnet   | Schwacher, dauerhafter Loot-Sog (kleiner Radius)       | nein      | Trivialisiert Magnet-Powerup, Radius klein halten | PickupService (passiver Pull)                        |
| Piercing Rite | Alle Waffen durchschlagen +1 Gegner                    | ja, Cap 2 | Stapelt mit Beam und Echo, Schwarm-Konter zu stark| WeaponService (Pierce +1 global)                     |
| Last Ward     | Bei unter 30 % Leben automatisch ein Shield (CD 25 s)  | nein      | Sustain-Loop, Cooldown noetig                     | PlayerService (Health-Watch), WeaponService (Shield) |
| Storm Vein    | 12 % Chance auf kleinen AoE beim Kill                  | ja, Cap 3 | In RushRooms Dauer-AoE, Chance/Radius cappen      | EnemyService (On-Kill-AoE), ScoreService (Kill-Hook) |
| Heavy Hands   | +30 % Schaden, -15 % Movement-Speed                    | nein      | Speed-Verlust gefaehrlich in Rush, mit Fleet ok   | WeaponService (Damage), PlayerService (WalkSpeed)    |
| Glass Flame   | +40 % Schaden, -30 % Max-Leben                         | nein      | Starker Glass-Cannon-Snowball                     | WeaponService (Damage), PlayerService (MaxHealth)    |
| Second Breath | Einmal pro Stage Auto-Revive mit kurzem Screen-Clear   | nein      | Senkt Tod-Spannung, daher per Stage statt per Run | RunService (Revive), EnemyService (Clear)            |

Designhinweise:
- Fates muessen mit Room-Typen interagieren: Storm Vein und Second Breath glaenzen in Rush,
  Glass Flame ist im BossRoom riskant. Das erzeugt Entscheidungstiefe.
- Vorsicht beim Stapeln auf derselben Achse (Glass Flame plus Heavy Hands plus Rapid Fire),
  spaeter Soft-Caps pruefen.
- Heavy Hands und Fleet Soul sind bewusst gegenlaeufig (Speed runter vs. Dash hoch), gute
  Kombi-Entscheidung fuer den Spieler.

---

## 8. Panic-Buttons und Powerup-Chaos

- Panic-Buttons sind die Sofort-Rettungen: Nuke (Screen-Clear) und Freeze (alle Gegner
  einfrieren). Beide vorhanden. Sie sollen in gefaehrlichen Rooms (Rush, Boss, ExitRoom)
  gezielt droppen koennen, damit der Spieler einen Notausgang aus Bedraengnis hat.
- Powerup-Chaos bleibt erhalten: voller Pool in CombatRooms, mit room-typ-spezifischer
  Bevorzugung (Rush: Magnet/Double-Score; Boss/Exit: defensive und Panic-Buttons).
- Vorschlag: pro Room hoechstens ein Panic-Button-Drop, damit es nicht trivialisiert.

---

## 9. Stage- und Biome-Progression

Jede Stage bekommt ein Biome (visuelles Thema), das die Arena-Layouts der Rooms einfaerbt
und aus einem Pool passender Layouts zieht. Die fuenf bestehenden Maps werden je nach
Room-Typ-Archetyp gezogen.

| Stage-Biome | Thema (Farb-Idee)            | Layout-Pool             |
|-------------|------------------------------|-------------------------|
| Foundry     | dunkles Metall, kuehl        | Depot, Bunker           |
| Garden      | gruenlich, offen             | Courtyard, Crucible     |
| Deep        | tief, eng, violett           | Bunker, Galleries       |
| (rotiert ab Stage 4 zyklisch durch die Biomes)                          |

Layout-Auswahl je Room: nimm aus dem Biome-Pool ein Layout, dessen Archetyp zum Room-Typ
passt (RushRoom braucht "open", TreasureRoom "tight", BossRoom "open"/"center-risk").

Archetyp-Tags der bestehenden Maps (additiv zu ergaenzen, bricht nichts):

| Layout    | Archetyp     | Gut fuer Room-Typen           |
|-----------|--------------|-------------------------------|
| Depot     | mixed        | Start, Combat, Exit           |
| Courtyard | open         | Combat, Rush, Boss            |
| Bunker    | choke        | Combat, Treasure, Exit        |
| Crucible  | center-risk  | Boss, Rush                    |
| Galleries | tight        | Treasure, Fate, Combat        |

---

## 10. Konkrete Config-Vorschlaege (Struktur, keine Logik)

Drop-in fuer `Config.lua`, sobald RoomService/State stehen. NICHT jetzt einsetzen
(Kollisionsvermeidung). Werte sind Startwerte zum Tunen.

### 10.1 Config.Rooms (Room-Typ-Definitionen)

```lua
-- VORSCHLAG, keine Logik. RoomService liest dies pro Room-Typ.
Config.Rooms = {
    StartRoom    = { DisplayName = "Start",   Clear = "instant",
                     LayoutTags = { "any" } },
    CombatRoom   = { DisplayName = "Combat",  Clear = "killAll",
                     EnemyWeights = { Runner = 8, Bruiser = 4, Spitter = 3, Exploder = 2 },
                     BudgetMult = 1.0, DropChanceMult = 1.0, LayoutTags = { "any" } },
    RushRoom     = { DisplayName = "Rush",    Clear = "killAll",
                     EnemyWeights = { Runner = 12, Exploder = 2 }, EnemyHealthMult = 0.8,
                     BudgetMult = 1.4, DropChanceMult = 0.6, GuaranteedPowerup = "Magnet",
                     PowerupBias = { Magnet = 2, DoubleScore = 2 }, LayoutTags = { "open" } },
    TreasureRoom = { DisplayName = "Treasure",Clear = "collectOrTimer",
                     PrePlacedLoot = { Rare = 2, Epic = 1 }, TrapWaveType = nil,
                     TimerSeconds = 18, GuaranteedPowerup = nil, LayoutTags = { "tight" } },
    FateRoom     = { DisplayName = "Fate",    Clear = "chooseFate",
                     FateOffer = 3, LayoutTags = { "any" } },
    BossRoom     = { DisplayName = "Boss",    Clear = "killBoss", Terminal = true,
                     Boss = "Tank", AddType = "Runner", AddInterval = 13, AddGroupSize = 3,
                     MaxAddsAlive = 6, AddStopAtBossHealthPct = 0.25,
                     GuaranteedFateAfter = true, LayoutTags = { "open", "center-risk" } },
    ExitRoom     = { DisplayName = "Exit",    Clear = "killAll", Terminal = true,
                     SpawnsTeleporter = true, BudgetMult = 0.6,
                     PanicButtonChance = 0.5, LayoutTags = { "any" } },
}
```

### 10.2 Config.Stages (Graph-Templates + Prozedural + Skalierung)

```lua
-- VORSCHLAG, keine Logik. RunService/StageService liest dies.
-- Knoten-Form: id = { type, next = { ZielId = "Dir" }, terminal? }. Gate-Anzahl = #next.
Config.Stages = {
    Scaling = {
        HealthMultPerStage = 1.10,
        SpeedMultPerStage = 1.02,
        BudgetAddPerStage = 4,
    },
    BiomeByStage = { "Foundry", "Garden", "Deep" },   -- ab Stage 4 zyklisch rotieren
    BossFromStage = 3,                                 -- ab hier Terminal = BossRoom
    Templates = {
        [1] = {
            start = "s",
            nodes = {
                s  = { type = "StartRoom",    next = { c1 = "E" } },
                c1 = { type = "CombatRoom",   next = { c2 = "E", t = "N" } },   -- Fork
                t  = { type = "TreasureRoom", next = { c2 = "E" } },            -- Detour, merge
                c2 = { type = "CombatRoom",   next = { x = "E" } },
                x  = { type = "ExitRoom",     next = {}, terminal = true },
            },
        },
        [2] = {
            start = "s",
            nodes = {
                s  = { type = "StartRoom",    next = { c1 = "E" } },
                c1 = { type = "CombatRoom",   next = { r = "E", f = "N" } },    -- Fork
                f  = { type = "FateRoom",     next = { r = "E" } },             -- Detour, merge
                r  = { type = "RushRoom",     next = { x = "E", t = "S" } },    -- Fork
                t  = { type = "TreasureRoom", next = { x = "E" } },             -- Detour, merge
                x  = { type = "ExitRoom",     next = {}, terminal = true },
            },
        },
        [3] = {
            start = "s",
            nodes = {
                s  = { type = "StartRoom",    next = { c1 = "E" } },
                c1 = { type = "CombatRoom",   next = { c2 = "E", f = "N" } },   -- Fork
                f  = { type = "FateRoom",     next = { c2 = "E" } },            -- Detour, merge
                c2 = { type = "CombatRoom",   next = { r = "E", t = "S" } },    -- Fork
                t  = { type = "TreasureRoom", next = { r = "E" } },             -- Detour, merge
                r  = { type = "RushRoom",     next = { B = "E" } },
                B  = { type = "BossRoom",     next = {}, terminal = true },
            },
        },
    },
    Procedural = {
        FromStage = 4,
        MainPathMin = 5,
        MainPathMax = 7,
        GuaranteedDetours = { TreasureRoom = 1 },          -- immer
        GuaranteedDetoursFromStage2 = { FateRoom = 1 },     -- ab Stage 2
        OptionalDetoursFromStage4 = { BonusRoom = 0.5 },    -- Chance ab Stage 4
        BranchPool = { FateRoom = 3, TreasureRoom = 4, BonusRoom = 2 },
    },
}
```

### 10.3 Config.Fates (finalisiert)

```lua
-- VORSCHLAG, keine Logik. Run-scoped Boons.
Config.Fates = {
    OfferCount = 3,
    OfferOnRoomTypes = { "FateRoom" },
    OfferAfterBoss = true,
    Pool = {
        FleetSoul     = { DisplayName = "Fleet Soul",     Desc = "Dash laedt schneller.",
                          Effects = { DashCooldownMult = 0.65 }, Unique = true, Tags = {"mobility"} },
        EchoMagnet    = { DisplayName = "Echo Magnet",    Desc = "Loot zieht dauerhaft schwach an.",
                          Effects = { PassiveMagnetRange = 26, PassiveMagnetSpeed = 18 }, Unique = true, Tags = {"economy"} },
        PiercingRite  = { DisplayName = "Piercing Rite",  Desc = "Waffen durchschlagen +1 Gegner.",
                          Effects = { PierceBonus = 1 }, Unique = false, MaxStacks = 2, Tags = {"offense"} },
        LastWard      = { DisplayName = "Last Ward",      Desc = "Shield bei niedrigem Leben.",
                          Effects = { LowHealthPct = 0.3, ShieldCooldown = 25 }, Unique = true, Tags = {"defense"} },
        StormVein     = { DisplayName = "Storm Vein",     Desc = "Chance auf AoE beim Kill.",
                          Effects = { OnKillAoeChance = 0.12, OnKillAoeRadius = 10, OnKillAoeDamage = 40 }, Unique = false, MaxStacks = 3, Tags = {"offense"} },
        HeavyHands    = { DisplayName = "Heavy Hands",    Desc = "Mehr Schaden, langsamer.",
                          Effects = { DamageMult = 1.3, WalkSpeedMult = 0.85 }, Unique = true, Tags = {"offense","risky"} },
        GlassFlame    = { DisplayName = "Glass Flame",    Desc = "Viel Schaden, weniger Max-Leben.",
                          Effects = { DamageMult = 1.4, MaxHealthMult = 0.7 }, Unique = true, Tags = {"offense","risky"} },
        SecondBreath  = { DisplayName = "Second Breath",  Desc = "Einmal pro Stage Auto-Revive.",
                          Effects = { RevivesPerStage = 1, ReviveNukeDamage = 280 }, Unique = true, Tags = {"safety"} },
    },
}
```

### 10.4 Config.Biomes und Layout-Metadaten (Vorschlag)

```lua
-- VORSCHLAG. Biome faerbt Rooms und liefert den Layout-Pool.
Config.Biomes = {
    Foundry = { FloorColor = Color3.fromRGB(38, 43, 45),  WallColor = Color3.fromRGB(55, 65, 70),  Layouts = { "Depot", "Bunker" } },
    Garden  = { FloorColor = Color3.fromRGB(42, 51, 45),  WallColor = Color3.fromRGB(60, 80, 64),  Layouts = { "Courtyard", "Crucible" } },
    Deep    = { FloorColor = Color3.fromRGB(40, 36, 52),  WallColor = Color3.fromRGB(70, 58, 92),  Layouts = { "Bunker", "Galleries" } },
}

-- Ergaenzung je Config.MapLayouts-Eintrag (additiv):
-- Depot.Archetype = "mixed", Courtyard.Archetype = "open", Bunker.Archetype = "choke",
-- Crucible.Archetype = "center-risk", Galleries.Archetype = "tight"
```

---

## 11. Hooks, die ich von RoomService/Run brauche

Damit ich danach Config.Rooms/Stages/Fates real einsetzen und balancen kann, ohne Service-Code
anzufassen, brauche ich diese klar definierten Schnittstellen:
- Room-Typ-Aufloesung aus `Config.Rooms` (RoomService liest pro Room-Typ Mix/Loot/Layout).
- Graph-Aufloesung aus `Config.Stages.Templates` (`start` plus `nodes` mit `next`) und der
  Prozedural-Regel ab Stage 4.
- Vorwaerts-only / commit: beim Durchlaufen eines Gates die Geschwister-Gates schliessen, kein
  Room wird zweimal betreten, keine Rueck-Gates.
- Deterministische Gate-Anzahl: genau ein Gate pro Eintrag in `node.next`.
- Layout-Auswahl ueber Biome-Pool und Archetyp-Match.
- Run-/Stage-/Room-State, den HUD und WaveService lesen (aktuelle Stage, Room-Index, Room-Typ,
  terminal ja/nein).
- Clear-Signal pro Room-Typ (killAll, collectOrTimer, chooseFate, killBoss, instant), das die
  Gates oeffnet.
- Fate-Angebot-Mechanik (Abschnitt 7.1): Drei-aus-Pool-Auswahl im FateRoom und nach Boss,
  Auswahl landet in `run.fates`.
- StageTeleporter-Signal am Terminal-Room.

---

## 12. Offene Fragen

1. Besitzt RunService/StageService die Tabellen `Config.Rooms/Stages/Fates`, oder setze ich
   sie nach deinem Service-Pass ein? Ich liefere die Strukturen, gehe von "strukturell bei dir" aus.
2. GEKLAERT (2026-06-01): Routen-Modell = Fork-Merge-Detour, vorwaerts-only, keine Wiederkehr.
   Detour-Spuren mergen vorwaerts auf den naechsten Hauptraum.
3. GEKLAERT (2026-06-01): Gate-Anzahl deterministisch aus `node.next`. Am Fork oeffnen alle
   gleichzeitig, Durchlaufen committet und schliesst die uebrigen.
4. Stage-Anzahl pro Run begrenzt oder endlos bis Game-Over? Default: endlos mit Skalierung.
5. Fate-Angebot auch ausserhalb FateRoom (immer nach Boss)? Default: ja, nach Boss zusaetzlich.
6. Waehrungsname "Echoes" bestaetigt?
