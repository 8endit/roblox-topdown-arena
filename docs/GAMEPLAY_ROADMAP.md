# Gameplay-Roadmap: Arcade-Survival + Persistente Progression

Status: Plan / Vorschlag fuer den Operator. Builder-Sicht, noch nicht implementiert.
Ziel: Den Spielstil eines runden- und etagenbasierten Top-down-Arcade-Survival-Shooters
(Vorbild: Black-Ops-1-Arcade-Modus) tasteful adaptieren und spaeter um ein persistentes
Level-System erweitern. Eigenes Thema "Afterlife Arcade" (Neon/Seelen), keine fremden
Namen, Assets oder 1:1-Kopien.

## 1. Design-Pillars

Das Vorbild fuehlt sich gut an wegen sechs Dingen. Die uebernehmen wir, in eigener Form:

1. **Flow und Jagd.** Aggressives, schnelles Spiel wird belohnt: ein Combo-Multiplikator
   auf den Score, plus Pickups, denen man hinterherjagt. Stillstand bestraft sich selbst.
2. **Eskalierende Etagen.** Nicht nur endlose Wellen am selben Ort. Floor raeumen, durch
   einen Teleporter in die naechste, tiefere Etage. Jede Etage haerter, gelegentlich ein
   Sonder-Floor.
3. **Power-Up-Chaos.** Kurze, maechtige Spikes: Screen-Clear, Temp-Godwaffe, Freeze, Magnet,
   Double-Score. Viel davon haben wir bereits.
4. **Risiko gegen Belohnung.** Extra-Leben-Jagd ins offene Feld, Bonus-Vault mit Zeitlimit,
   riskante offene Mitte (Crucible-Map deckt das schon ab).
5. **Run-Struktur mit Leben.** Ein Run hat ein Lebens-Budget, ein Game-Over und einen
   Run-Summary-Screen. Score-Chasing ueber Runs hinweg.
6. **Persistente Meta-Progression.** Zwischen Runs: Account-Level, Waehrung, Perks, Unlocks.
   Ausschliesslich ueber Spielzeit verdient, keine Monetarisierung.

## 2. Mapping auf die bestehende Architektur

Kein Rewrite. Alles additiv: neue Services + Config-Tabellen, bestehende Pfade erweitern.

| Vorbild-Element            | Unser System                          | Status                          |
|----------------------------|---------------------------------------|---------------------------------|
| Twin-stick Move + Aim      | TopDownController                     | vorhanden                       |
| Dash / Dodge               | TopDownController                     | in Arbeit (Operator)            |
| Wellen mit Budget          | WaveService                           | vorhanden, zu Etagen erweitern  |
| Gegnerrollen + Telegraphs  | EnemyService / Config.EnemyTypes      | vorhanden, Elites ergaenzen     |
| Temp-Waffen-Drops          | WeaponService / PickupService         | vorhanden                       |
| Power-Up-Roster            | PickupService / Config.Powerups       | vorhanden, ergaenzen            |
| Loot-Rarities              | PickupService / Config.Loot           | vorhanden                       |
| Score                      | PlayerService (leaderstats)           | vorhanden, Combo darueber legen |
| Combo / Multiplikator      | (neu) ScoreService oder PlayerService | neu (Phase 1)                   |
| Leben / Run-Lebenszyklus   | (neu) RunService-Logik                | neu (Phase 1)                   |
| Stage/Room/Gate-Fortschritt| (neu) RunService/RoomService/GateService | neu (Phase 1)                |
| Extra-Leben-Jagd           | PickupService (neuer Pickup-Typ)      | neu (Phase 1)                   |
| Boss-Feedback              | EnemyService (Boss-Bar)               | vorhanden                       |
| Spezial-Rooms (Rush/Treasure/Fate/Boss) | RoomService + MapBuilder | neu (Phase 2)                   |
| Profile / Level / Perks    | (neu) ProfileService + Config         | neu (Phase 3)                   |
| Leaderboard                | OrderedDataStore (nur live)           | neu (Phase 3)                   |

## 3. Phasenplan

Reihenfolge nach Abhaengigkeit, nicht nach Aufwand. Jede Phase ist fuer sich testbar.

### Phase 0: Gamefeel verdichten (laeuft beim Operator)

Dash, faire Spawns weg vom Spieler, leichte Gegner-Trennung, Shield-als-Shield-Health.
Builder fasst diese Dateien nicht parallel an, um Kollisionen zu vermeiden.

### Phase 1: Run-Kern (Flow-Engine, ohne Persistenz)

Der wichtigste Block. Macht aus "Wellen-Sandbox" einen echten Run mit Sog.

1. **Combo-Multiplikator.**
   - Jeder Kill erhoeht eine Combo-Zahl; Multiplikator-Stufen (x1, x2, x4, x8) abhaengig von
     der Combo. Multiplikator skaliert Score und spaeter Waehrung.
   - Decay: ohne Kill innerhalb von `ComboWindow` faellt die Combo zurueck.
   - Dateien: neue `ScoreService.lua` (oder in PlayerService), Hook in
     `WaveService.enemyDiedCallback` statt direktem AddScore; Heartbeat-Decay; HUD-Anzeige.
   - Config: `Config.Combo = { Window, Tiers = {kills -> multiplier}, ... }`.

2. **Lebens-System + Run-Lebenszyklus.**
   - Run startet mit `Lives` (Solo-Default 3). Tod: ein Leben weg, Respawn am Spawn mit
     kurzer Unverwundbarkeit. 0 Leben: Run-Ende.
   - Run-Ende: Summary-Banner (Score, Floor, Kills), kurze Pause, dann Reset auf Floor 1.
   - Hook: Humanoid.Died je Spieler; Server zaehlt Leben autoritativ.
   - Dateien: neue Run-Logik (in einem `ProgressionService.lua` oder WaveService), HUD-Leben.
   - → haengt von nichts ab, kann parallel zu Combo entstehen.

3. **Extra-Leben-Pickup (die Jagd).**
   - Seltener, fluechtiger Pickup ("Lebensfunke"), der ein Leben gibt. Optional: bewegt sich
     leicht oder hat kurze Lebensdauer, damit man Risiko eingeht.
   - Dateien: PickupService (neuer kind/Effekt), Config.Loot.
   - → haengt von (2) ab.

4. **Stage/Room/Gate-Fortschritt (verfeinert).**
   - Struktur: Run besteht aus Stages, Stage aus mehreren raeumlich verbundenen Rooms. Nach
     Room-Clear oeffnen sich Gates an den Seiten zu Nachbar-Rooms; ein StageTeleporter
     erscheint nur am Stage-Ende (ExitRoom oder nach BossRoom). Ersetzt das fruehere
     "Teleporter nach jedem Floor"-Modell.
   - Dateien: neue `RunService`/`RoomService`/`GateService`, WaveService spawnt pro Room,
     MapBuilder (Gate-Parts, StageTeleporter), HUD ("Stage X / Room Y").
   - Config: `Config.Rooms`, `Config.Stages` (Graph-Templates), `Config.Biomes`.
   - Voller Content-/Graph-/Balancing-Plan: siehe Room-/Stage-Plan unten.
   - → unabhaengig, aber sinnvoll nach (1) und (2).

### Phase 2: Encounter-Vielfalt (die Wuerze)

Detaillierter Content-, Graph- und Balancing-Plan fuer Room-/Stage-Typen, RoomGraphs,
Boss-Tuning und das run-scoped Fate-System (getrennt von den persistenten Perks aus Phase 3):
[agent-space/CLAUDE_ROOM_STAGE_PLAN.md](../agent-space/CLAUDE_ROOM_STAGE_PLAN.md).


1. **Elite-/Spezialgegner.** Varianten bestehender Rollen: Splitter (teilt sich bei Tod),
   Warden (Schild vorn, von hinten verwundbar), Leaper (Sprung-Closer). Config-getrieben in
   `Config.EnemyTypes`, Logik als kleine Branches in EnemyService.
2. **Spezial-Rooms.** Eigene Room-Typen statt einfacher Wellen:
   - **RushRoom:** sehr dichte, schnelle Gegner, offen, hoher Combo-/Echoes-Anreiz.
   - **TreasureRoom:** Loot mit geringer Gefahr (optional kurze Fallenwelle), Risiko/Belohnung.
   - **FateRoom:** ein Run-Upgrade aus drei waehlen.
   - Dateien: RoomService (Room-Typ-Logik), MapBuilder (Layout-Varianten), PickupService.
3. **Power-Up-Roster runden.** Eigene Namen fuer die Klassiker:
   - Double-Score ("Score Surge"), Overdrive (kurze Top-Tier-Waffe), Arsenal (verlaengert/upgradet
     aktuelle Temp-Waffe). Nuke, Freeze, Magnet sind vorhanden.
   - Dateien: Config.Powerups, WeaponService.ApplyPowerup, PickupService-Tiers.
   - → haengt von Phase 1 Combo ab (Double-Score wirkt auf Multiplikator).

### Phase 3: Persistente Meta-Progression (das "spaeter")

Der Teil, den du fuer "am Ende" willst. Wichtig: laeuft hinter einer Backend-Abstraktion,
damit man die Logik ohne Publishing lokal bauen und testen kann (siehe Abschnitt 4).

1. **ProfileService + Backend-Abstraktion.**
   - Laedt/speichert ein Profil pro Spieler. Backend: DataStore wenn live, In-Memory-Mock im
     Studio ohne API-Zugriff (Fallback per pcall-Erkennung, mit Warnung im Output).
   - Session-Lock + Retry beim echten DataStore, damit Profile nicht korrumpieren.
2. **Account-XP und Level.** XP aus Run-Leistung (Score, geschaffte Floors, Boss-Kills).
   Level schaltet Inhalte frei.
3. **Waehrung + Perks.** Pro Run wird Waehrung ("Echoes") gebankt. Perks sind permanente,
   gekaufte Raenge: Max-Health, Dash-Cooldown, Drop-Luck, Start-Waffen-Tier, Revive-Token,
   Combo-Decay-Schutz. Perks werden beim Spawn/Run-Start angewandt (`ModifierService` oder in
   ProgressionService).
4. **Unlocks.** Level-gated: Maps, Charaktere/Skins (nur Farb-/Form-Varianten der Parts),
   Run-Modifier, hoehere Schwierigkeitsstufen.
5. **Persistenter High-Score / Leaderboard.** OrderedDataStore (nur live), im Studio Mock.
6. **Run-Modifier / Schwierigkeitsstufen.** Ab Level X waehlbar, fuer mehr Score/Waehrung.

### Phase 4: Politur und Co-op-Skalierung

1. **Co-op.** Enemy-Budget skaliert mit Spielerzahl. Gemeinsamer Lebens-Pool, Mitspieler-Revive
   im Fenster. Score/Combo-Modell fuer mehrere Spieler klaeren (geteilt vs. pro Spieler).
2. **Juice.** Trefferfunken, Camera-Shake bei Explosion/Boss, Audio-Hooks, Combo-Sound-Stufen.
   HUD bleibt knapp.

## 4. Persistenz-Datenmodell und Backend (no-publishing-tauglich)

Profil-Skizze (alles serverseitig autoritativ):

```
Profile = {
  version = 1,
  level = 1, xp = 0,
  currency = 0,                 -- "Echoes"
  perks = {                     -- gekaufte Raenge (0 = ungekauft)
    maxHealth = 0, dashCooldown = 0, luck = 0,
    startWeaponTier = 0, reviveTokens = 0, comboGuard = 0,
  },
  unlocks = { maps = {}, characters = {}, modifiers = {} },
  stats = { bestScore = 0, bestFloor = 0, runs = 0, kills = 0 },
}
```

Backend-Interface (`ProfileStore`): `Load(player)`, `Save(player, profile)`, `Flush(player)`.

- **DataStoreBackend:** DataStoreService + Session-Lock + Retry. Aktiv, sobald das Spiel
  veroeffentlicht ist bzw. Studio-API-Zugriff aktiviert wurde.
- **MemoryBackend:** reine Lua-Tabelle im Server-Speicher. Faellt automatisch ein, wenn ein
  DataStore-Probecall fehlschlaegt (kein API-Zugriff). Progression-Logik laeuft damit lokal
  voll, die Werte ueberleben nur den Studio-Lauf nicht. Das respektiert die Grenze "kein
  Publishing" und macht die gesamte Mechanik trotzdem entwickel- und testbar.

So bleibt Phase 3 baubar, ohne zu veroeffentlichen. Echte Persistenz wird ein reiner
Backend-Switch, sobald veroeffentlicht werden darf.

## 5. Balancing-Hebel (alle Config-getrieben)

Damit Balancing ohne Code-Aenderung passiert, alles in Config:
`Config.Combo`, `Config.Run` (Leben, Invuln-Fenster), `Config.Floors` (Skalierung, Sonder-Floor-
Haeufigkeit), `Config.Perks` (Raenge, Kosten, Effekte), `Config.Progression` (XP-Kurve,
Waehrungsraten), plus die bestehenden Enemy-/Weapon-/Loot-Tabellen.

## 6. Offene Design-Entscheidungen (mit empfohlenem Default)

Kein Blocker, ich schlage Defaults vor und ziehe sie, falls du nichts anderes sagst:

| Frage                       | Empfehlung (Default)                                              |
|-----------------------------|-------------------------------------------------------------------|
| Run-Struktur                | Etagen mit Teleporter (vorbildtreu), nicht rein endlos            |
| Leben im Co-op              | Gemeinsamer Lebens-Pool + Mitspieler-Revive; Solo 3 Leben         |
| Tod / Penalty               | Roguelite: Run-Fortschritt weg, Meta (Level/Waehrung/Perks) bleibt|
| Waehrungsname/Thema         | "Echoes" (Seelen-Echos), passt zu Afterlife-Neon                  |
| Persistenz jetzt            | MemoryBackend hinter DataStore-Abstraktion, live spaeter umschalten|
| Combo-Skalierung            | x1/x2/x4/x8, Decay-Fenster ca. 3 s, spaeter Perk-Schutz           |

## 7. Guardrails (harte Grenzen, gelten weiter)

- Keine COD-/Dead-Ops-Namen, -Assets oder 1:1-Maps. Inspiration ja, Kopie nein.
- Keine Monetarisierung: Progression ausschliesslich ueber Spielzeit, keine bezahlten Unlocks.
- Server bleibt autoritativ: Leben, Score, Combo, Drops, Floor-Wechsel und Profile-Saves
  laufen serverseitig.
- Kein kompletter Rewrite: additive Services + Config, bestehende Pfade erweitern.
- Persistenz hinter Abstraktion, weil "kein Publishing" gilt.

## 8. Empfohlener naechster konkreter Schritt

Sobald der Operator-Pass (Phase 0) gelandet ist: **Phase 1, Schritt 1 (Combo-Multiplikator)**.
Kleinster Eingriff, groesster Flow-Gewinn, und Fundament fuer Double-Score und Waehrung spaeter.
