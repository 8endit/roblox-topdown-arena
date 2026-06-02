# Essenzielle Bausteine (ohne Grafik/VFX) und Run-System-Spec

Status: Builder-Backlog und Spec. Beantwortet "was muessen wir noch essenziell einbauen".
Ich aendere hier keinen Service-Code und kein `Config.lua`. Alle Config-Bloecke sind
einsetzbare Vorschlaege, die Codex zusammen mit dem jeweiligen Service-Hook landet.

Bezug: [docs/GAMEPLAY_ROADMAP.md](../docs/GAMEPLAY_ROADMAP.md),
[CLAUDE_ROOM_STAGE_PLAN.md](CLAUDE_ROOM_STAGE_PLAN.md).

Stand: nach Commit `2c54263` (Stages 1-7 + Rotation 8+, MaxStacks, Storm Vein live).

---

## Aktualisierung 1: Run-System-v1 umgesetzt

Codex hat das wichtigste offene Stueck gebaut:
- Neuer `RunService` als Lebenszyklus-Orchestrator.
- Gemeinsamer Lebens-Pool nach Empfehlung: `Config.Run.StartLives = 3`.
- Tod reduziert Lives, respawnt mit kurzen I-Frames solange Lives uebrig sind.
- Bei 0 Lives: Game Over, Wave/Room/Gegner stoppen, Summary an HUD, danach frischer Run.
- Neue Remotes: `UpdateRunState`, `RunSummary`.
- Reset-Hooks: `RoomService.ResetRun/StopRun`, `WaveService.ResetRun`, `EnemyService.ClearAll`,
  `WeaponService.ResetPlayer`, `PlayerService.ResetPlayer/GrantIFrames`.
- HUD zeigt Lives/Kills und Game-Over-Summary.
- Bonus-Score aus `Config.Score` ist live: RoomClear, TreasureDetour, StageClear, BossBonus.

Offen nach diesem Pass:
- Co-op ist nur Shared-Lives-v1, noch kein Downed-/Revive-System.
- SecondBreath kann jetzt auf RunService aufbauen, ist aber noch nicht live.
- Persistente Bestwerte/DataStore sind weiterhin offen.

---

## 1. Essenzielles Backlog (priorisiert)

Owner: "Service" = Codex (Gameplay-Code), "Config/Spec" = Builder (Daten/Design), "geteilt" = beides.

| # | System | Warum essenziell | Owner | Haengt ab von | Status |
|---|--------|------------------|-------|---------------|--------|
| 1 | **Run-System** (Lives, Death, Game Over, Reset) | Ohne das ist es ein Testmodus, kein Arcade-Run | Service + Config/Spec | nichts | v1 umgesetzt |
| 2 | Score-Events + Run-Summary | Summary und Belohnung brauchen Run-Ende + Bonus-Score | geteilt | 1 | v1 umgesetzt |
| 3 | TreasureRoom datengetrieben | Loot aus Config statt hartkodiert, sonst kein echtes Loot-Design | Service (klein) + Config | nichts | offen (hardcoded) |
| 4 | Fates komplett (EchoMagnet, LastWard; SecondBreath spaeter) + HUD-Lesbarkeit | Run-Identitaet, aktuell 5/8 | Service-Hooks + Config | SecondBreath -> 1 | teilweise |
| 5 | Gegnerrollen (Leaper/Charger, Splitter, Warden, Elites) | Mehr Varianz pro Stage, klarere Rollen | Service + Config/Spec | nichts | teilweise (5 Rollen) |
| 6 | Gegner-Navigation (Hindernis-Vermeidung) | Gegner laufen aktuell durch Deckung, fuehlt billig | Service | nichts | offen |
| 7 | Co-op-Skalierung (Budget, Boss-HP, Drop-Fairness, Lives-Modell) | Roblox lebt von Multiplayer | Service + Config | 1 (Lives) | offen |
| 8 | Prozedurale Stage-Generierung ab Stage 8 | Langzeit statt feste Rotation 4-7 | Service + Regeln | nichts | teilweise (Rotation) |
| 9 | Waffen-/Loot-Oekonomie (Drop-Tables pro Room-Typ, Panic-Drops) | Drops gezielter, Raeume fuehlen sich anders an | Config + Service-Hooks | 3 | teilweise |
| 10 | Steuerung/Feel (Dash-CD-Anzeige, Weapon-Timer, Controller/Mobile) | Lesbarkeit und Reichweite der Spielerbasis | Service (HUD/Input) | nichts | teilweise (Dash da) |
| 11 | Persistenz (Level, Echoes, Unlocks, leichte Perks) | Wiederkommen, Roblox-Meta | Service + Config | 1, 2 | offen (real erst nach Publishing) |
| 12 | Technische Qualitaet (Studio-Smoke-Test, Luau-Checks, README, Test-Map) | Damit mehrere sauber weiterbauen | geteilt | nichts | laufend |

Empfohlene Reihenfolge: 1 -> 2 -> 3 -> 4 (EchoMagnet/LastWard) -> 5 + 6 zusammen -> 7 -> 8 -> 11.
Begruendung: 1 ist der groesste Hebel und Voraussetzung fuer 2, 7, 11. 5 und 6 zusammen, weil
beide die Gegner-Bewegung in EnemyService anfassen. 11 zuletzt, da real erst nach Publishing testbar.

---

## 2. Run-System (Prioritaet 1, Detail-Spec)

Ziel: aus dem Dauer-Sandbox einen echten Run machen. Leben, Tod, Game Over, sauberer Reset,
Summary. Empfehlung: ein eigener `RunService`, der den Lebenszyklus haelt und die anderen
Services beim Reset koordiniert. RoomService bleibt fuer Graph/Rooms zustaendig.

### 2.1 Zustandsmaschine

```
WAITING  -> (Spieler da)        -> ACTIVE
ACTIVE   -> (Lives > 0, Tod)    -> ACTIVE (Respawn am Room-Spawn + I-Frames)
ACTIVE   -> (Lives == 0, Tod)   -> GAMEOVER
GAMEOVER -> (Summary-Zeit)      -> ACTIVE (frischer Run)
```

### 2.2 Lebenszyklus im Detail

- **Run-Start:** `lives = Config.Run.StartLives`, `score = 0`, `kills = 0`, `startClock` setzen,
  Fates leeren, Waffe auf Pistol, Powerups leeren, MaxHealth/WalkSpeed auf Basis. Dann
  `RoomService.StartRun()` (Stage 1 ab dem Start-Node).
- **Tod (Humanoid.Died je Spieler):** `lives -= 1` (shared pool, siehe 2.5).
  - Lives > 0: Respawn. Beim naechsten CharacterAdded an den aktuellen Room-Spawn teleportieren
    und kurze Unverwundbarkeit (`Config.Run.RespawnIFrames`, via ForceField).
  - Lives == 0: GAMEOVER.
- **Game Over:** Spawns stoppen, alle Gegner entfernen (`EnemyService.ClearAll()`), Gates/Teleporter/
  Fate-Saeulen entfernen, Run-Summary an alle Clients senden, `Config.Run.SummarySeconds` warten,
  dann frischen Run starten.
- **Reset:** Run-State zuruecksetzen (siehe Reset-Matrix), neuer Run ab Stage 1.

### 2.3 Reset-Matrix (was beim neuen Run passiert, und welcher Hook fehlt)

| System | Reset | Noetiger Hook |
|--------|-------|---------------|
| RoomService | `currentStage = 0`, `clearedRooms = {}`, `runFates = {}`, dann Stage 1 starten | `RoomService.ResetRun()` (heute nur `StartNextStage`, das hochzaehlt) |
| WeaponService | Waffe -> Pistol, Powerups leeren, Fates leeren | `WeaponService.ResetPlayer(player)` plus `ApplyRunFates({})` |
| PlayerService | MaxHealth/WalkSpeed auf Basis, volle Health beim Respawn | MaxHealth-Reset bei Run-Reset (Fate-Penalty faellt mit leerem Fate-State weg) |
| EnemyService | alle aktiven Gegner entfernen ohne Score/Drop | `EnemyService.ClearAll()` (heute nur `NukeDamage`, das Score/Drops ausloest) |
| RunService | lives/score/kills/startClock zuruecksetzen | eigener State |

### 2.4 Run-Summary (Payload)

Server sendet bei Game Over an alle (eigenes Remote `RunSummary` oder ueber `Announce`):

```lua
{
    stage = 7,          -- erreichte Stage
    score = 4820,
    kills = 213,
    timeSeconds = 642,
    fates = { "Glass Flame x2", "Storm Vein x3" },
    newBest = true,     -- spaeter aus Persistenz
}
```

HUD (Codex): eine Lives-Zeile im Panel (z. B. "Lives: 3") plus ein Text-Overlay beim Game Over
mit obiger Summary. Kein Grafik-Asset noetig, reine TextLabels. Nach `SummarySeconds` ausblenden.

### 2.5 Offene Entscheidung: Lives-Modell

- **Empfehlung (Default): gemeinsamer Lebens-Pool** (vorbildtreu, Co-op-Spannung). Tod eines
  Spielers zieht vom geteilten Pool, Respawn solange Pool > 0.
- Alternative: individuelle Lives pro Spieler, Game Over erst wenn alle aus sind.
- Downed/Revive-Mechanik ist eine spaetere Co-op-Schicht (Prioritaet 7), nicht Teil von v1.

### 2.6 RunService-Interface (Vorschlag fuer Codex)

```
RunService.Init(remotes, roomService, weaponService, playerService, enemyService)
RunService.StartRun()          -- frischer Run, koordiniert alle Resets
RunService.OnPlayerDied(player)-- Lives--, Respawn oder GameOver
RunService.GameOver()          -- Summary, Pause, dann StartRun()
RunService.RegisterKill(player)-- kills++ (vom Enemy-Died-Callback)
RunService.AddScore(amount)    -- optional, oder weiter ueber PlayerService
RunService.GetRunFates()       -- damit Pickup/Player den Fate-State lesen koennen (EchoMagnet/LastWard)
```

### 2.7 Einsetzbare Config-Bloecke

```lua
-- VORSCHLAG. RunService liest dies.
Config.Run = {
    StartLives = 3,
    SharedLives = true,        -- false = individuelle Lives pro Spieler
    RespawnIFrames = 2.0,      -- Sekunden Unverwundbarkeit nach Respawn
    SummarySeconds = 8,        -- Anzeigedauer der Game-Over-Summary
    ResetWeaponOnRun = true,
    ResetMaxHealthOnRun = true,
}

-- VORSCHLAG. Bonus-Score zusaetzlich zum Score pro Gegner (EnemyTypes.Score bleibt).
Config.Score = {
    RoomClear = 50,
    StageClear = 200,
    BossBonus = 300,           -- zusaetzlich zum Tank-Score
    TreasureDetour = 75,       -- beim Clear eines TreasureRoom
}
```

Award-Punkte: RoomService.OnRoomCleared vergibt RoomClear, am Terminal zusaetzlich StageClear;
TreasureRoom-Clear vergibt TreasureDetour; WaveService-Boss-Died vergibt BossBonus; kills++ im
Enemy-Died-Callback. Werte sind Startwerte zum Tunen.

---

## 3. TreasureRoom datengetrieben (Prioritaet 3, klein)

Heute ist `RoomService.spawnTreasure` hartkodiert (immer Rare Medkit + Rare SMG). Vorschlag:
`PrePlacedLoot` als Liste lesen und durchlaufen.

```lua
-- VORSCHLAG in Config.Rooms.TreasureRoom:
PrePlacedLoot = {
    { Kind = "Powerup", Id = "Health", Rarity = "Rare", Offset = Vector3.new(-8, 1, 0) },
    { Kind = "Weapon",  Id = "Rifle",  Rarity = "Epic", Offset = Vector3.new(8, 1, 0) },
},
```

spawnTreasure (Codex, ~10 Zeilen): ueber die Liste iterieren, je nach Kind
`pickupService.SpawnWeapon`/`SpawnPowerup` mit Rarity und Offset aufrufen. Damit kann ich pro
Room-Typ und spaeter pro Stage echtes Loot kuratieren.

---

## 4. Fates fertig (Prioritaet 4)

Schema additiv wie etabliert (`fateCount(id) * Effect`). EchoMagnet und LastWard gehen ohne
Lebenssystem, SecondBreath braucht Run-System (Prioritaet 1). **Erst in den Live-Pool aufnehmen,
wenn der Hook steht**, sonst sind es tote Auswahl-Saeulen.

```lua
-- VORSCHLAG (nach Hook in Config.Fates.Pool aufnehmen).
EchoMagnet = {
    DisplayName = "Echo Magnet",
    Description = "Loot drifts to you",
    Color = Color3.fromRGB(255, 120, 235),
    Unique = true,
    Effects = { PassiveMagnetRange = 26, PassiveMagnetSpeed = 16 },
},
LastWard = {
    DisplayName = "Last Ward",
    Description = "Shield when low",
    Color = Color3.fromRGB(143, 132, 255),
    Unique = true,
    Effects = { LowHealthPct = 0.3, ShieldSeconds = 2.5, Cooldown = 22 },
},
SecondBreath = {
    DisplayName = "Second Breath",
    Description = "Revive once per stage",
    Color = Color3.fromRGB(120, 230, 200),
    Unique = true,
    Effects = { RevivesPerStage = 1, ReviveClearDamage = 280 },
},
```

Hooks:
- EchoMagnet: PickupService-Magnet-Loop laeuft schon fuer das Magnet-Powerup. Ergaenzen: wenn ein
  Spieler den EchoMagnet-Fate hat (ueber `RunService.GetRunFates()` lesbar), schwacher Dauer-Pull
  mit kleinem Radius. MaxStacks 1.
- LastWard: PlayerService ueberwacht Health; faellt sie unter `LowHealthPct * MaxHealth` und der
  Cooldown ist frei, kurzer Shield (ForceField/Shield-Health) fuer `ShieldSeconds`, dann Cooldown.
  MaxStacks 1.
- SecondBreath: RunService prueft bei Tod die Revives dieser Stage; wenn vorhanden, Auto-Revive
  (volle Health + I-Frames) plus kleiner `RadialDamage`-Burst, Zaehler -1, Reset pro Stage.
  MaxStacks 1.

Offer-Balance: aktuell rein zufaellig aus dem Pool. Wenn der Pool waechst, optional Gewichte
(`Weight` pro Fate) oder Vermeidung, dasselbe Angebot zweimal hintereinander zu zeigen. HUD soll
Fates klarer zeigen (eigene Zeile, Stack-Anzahl, Farbe nach Fate.Color statt grau).

---

## 5. Gegnerrollen und Navigation (Prioritaet 5 und 6)

Neue Rollen (Config + EnemyService-Branch). Builder liefert Config + Verhaltens-Spec, Codex baut
die Bewegungs-/Effekt-Logik:
- **Charger/Leaper:** periodischer Dash/Sprung auf den Spieler (kurzer Telegraph, dann schneller
  Satz nach vorn). Feld-Vorschlag: `AttackMode = "Charge"`, `ChargeWindup`, `ChargeSpeed`, `ChargeRange`.
- **Splitter:** beim Tod in zwei kleinere Gegner teilen. Feld: `SplitInto = "Runner"`, `SplitCount = 2`.
  Hook im Enemy-Died-Pfad (Vorsicht: Splits zaehlen fuer Score/Drop, aber kein Endlos-Split, Tiefe 1).
- **Warden:** bufft nahe Gegner (z. B. Schadensreduktion in Radius) oder schirmt sie ab.
  Feld: `AuraRadius`, `AuraDamageReduction`. Braucht eine Aura-Abfrage im Damage-Pfad.
- **Elites:** Stat-Varianten vorhandener Rollen (mehr HP/Speed/Score) ueber `Config.EnemyTypes`,
  die ab hoeherer Stage in `Config.Rooms[type].EnemyWeights` auftauchen. Diese funktionieren sofort
  mit der bestehenden Melee-/Ranged-Logik, gut als erster Schritt.

Navigation (Prioritaet 6): Gegner laufen direkt und durch Deckung. Kein volles PathfindingService
noetig; ein billiger Schritt reicht meist: vor dem Bewegungsschritt einen kurzen Ray in
Bewegungsrichtung gegen die Cover-Parts, bei Treffer seitlich ausweichen (steering). Das behebt das
"durch die Wand laufen" ohne teure Pfadberechnung. Spec-Owner Builder, Logik EnemyService.

---

## 6. Co-op-Skalierung (Prioritaet 7)

```lua
-- VORSCHLAG. WaveService/EnemyService/Run lesen dies.
Config.Coop = {
    BudgetPerExtraPlayer = 0.35,     -- +35 % Room-Budget je zusaetzlichem Spieler
    BossHealthPerExtraPlayer = 0.5,  -- +50 % Boss-HP je zusaetzlichem Spieler
    SharedLives = true,              -- konsistent mit Config.Run.SharedLives
}
```

Regeln: Room-Budget und Boss-HP fair mit Spielerzahl skalieren; Drops gehoeren dem Aufsammler
(kein Wegschnappen ueber Distanz); Lives-Modell aus Config.Run. Downed/Revive als spaetere Schicht.

---

## 7. Was ich (Builder) als Naechstes liefern kann

Sobald die jeweiligen Hooks stehen, liefere ich fertige, getunte Config-Bloecke:
- Run-Summary-Feinheiten und Score-Tuning, sobald RunService steht.
- TreasureRoom-Loot-Tabellen pro Room-Typ/Stage, sobald spawnTreasure datengetrieben ist.
- EchoMagnet/LastWard in den Live-Pool, sobald PickupService/PlayerService die Felder lesen.
- Elite-Gegner-Definitionen und Room-EnemyWeights, sobald die neue Bewegungslogik steht.

Bis dahin fasse ich keine Service-Dateien und kein Config.lua an, um Codex' Pass nicht zu stoeren.

---

## 8. Offene Entscheidungen

1. Lives-Modell: gemeinsamer Pool (Empfehlung) oder individuell?
2. Score-Werte (RoomClear/StageClear/Boss/Treasure): die Startwerte oben okay?
3. Owner des Run-State: eigener `RunService` (Empfehlung) oder in RoomService integrieren?
4. Waehrungsname "Echoes" fuer die spaetere Persistenz bestaetigt?
