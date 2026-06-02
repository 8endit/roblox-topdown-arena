# Prompt Fuer Claude

Du arbeitest im Projekt `C:\dev\roblox-topdown-arena`. Du bist der Builder-Agent. Codex/Operator haelt Scope und Review. Baue die naechste Gameplay-Verbesserungsrunde fuer ein eigenstaendiges Roblox Top-Down-Arena-Spiel.

## Ziel

Verbessere das Spielgefuehl deutlich: mehr Abwechslung pro Welle, bessere Gegnerrollen, interessantere Loot-/Powerup-Entscheidungen, klareres Feedback und weniger rohe Prototyp-Anmutung. Baue gezielt und testbar, keine breite Neuschreibung.

## Aktueller Stand

Es gibt bereits:

- Rojo-Projekt unter `default.project.json`
- Config in `src/ReplicatedStorage/AfterlifeArcade/Config.lua`
- MapBuilder, EnemyService, WaveService, WeaponService, PickupService, PlayerService
- Top-Down-Kamera und HUD
- Gegner: Runner, Bruiser, Spitter, Exploder, Tank
- Maps: Depot, Courtyard, Bunker
- Waffen: Pistol, SMG, Shotgun, Rifle
- Powerups: Health, DamageBoost, RapidFire, SpeedBoost, Shield, Nuke

## Harte Grenzen

- Keine COD-/Dead-Ops-Namen, Assets oder 1:1-Kopien.
- Keine komplette Architektur neu bauen.
- Kein Publishing.
- Keine Monetarisierung.
- Kein Mobile/Controller-Polish in dieser Runde.
- Server bleibt autoritativ fuer Schaden, Drops, Powerups und Wellen.

## Aufgaben In Reihenfolge

1. Stabilitaet und Codepfade pruefen
   - Lies `README.md`, `agent-space/README.md` und die Services unter `src/ServerScriptService/AfterlifeArcade`.
   - Finde offensichtliche Runtime-Risiken: nil-Zugriffe, gesperrte `.rbxl`, falsche Remote-Namen, Race Conditions.
   - Behebe nur konkrete Probleme.

2. Gegnerrollen verfeinern
   - Gib jedem Gegnertyp eine klarere Rolle.
   - Runner: Schwarmdruck.
   - Bruiser: blockiert Raum und haelt Schaden aus.
   - Spitter: muss auf Distanz bleiben und telegrafierte Fernangriffe haben.
   - Exploder: klar sichtbare Warnphase vor Explosion.
   - Tank: Boss-Feedback, mehr Score, garantierter besserer Drop.
   - Vermeide Pathfinding-Komplexitaet, solange direkte Bewegung reicht.

3. Loot-System verbessern
   - Fuege Seltenheitsstufen hinzu: Common, Rare, Epic.
   - Pickups sollen optisch unterscheidbar sein.
   - Boss/Tank soll garantiert Rare/Epic droppen.
   - Normale Gegner sollen selten droppen.
   - Loot-Drops sollen nicht direkt in Waenden/Deckung landen; einfache Positionskorrektur reicht.

4. Waffen interessanter machen
   - Fuege mindestens eine neue Waffe hinzu, z. B. `BurstRifle` oder `Beam`.
   - Balanciere bestehende Waffen so, dass keine strikt besser ist.
   - HUD soll aktuelle Waffe und Restdauer lesbar anzeigen.
   - Waffenlogik bleibt serverseitig.

5. Powerups verbessern
   - Fuege mindestens ein neues Powerup hinzu, z. B. `Freeze` oder `Magnet`.
   - Aktive Powerups duerfen nicht kaputt stapeln.
   - Powerup-Dauer und Ablauf im HUD klar halten.

6. Map-Gameplay verbessern
   - Fuege mindestens ein viertes Layout hinzu.
   - Jedes Layout braucht andere Kampf-Dynamik: offen, eng, Chokepoints, riskante Mitte.
   - Spawnpunkte muessen sinnvoll verteilt sein.

7. Feedback verbessern
   - Trefferfeedback, Boss-Warnung, Wave-Start und Pickup-Feedback staerken.
   - Keine riesigen UI-Rewrites; HUD soll knapp bleiben.

## Validierung

Fuehre am Ende aus:

```powershell
npx rojo build default.project.json --output afterlife-arena-check.rbxl
```

Wenn das klappt, optional danach:

```powershell
npx rojo build default.project.json --output afterlife-arena.rbxl
```

Falls Studio `afterlife-arena.rbxl` sperrt, nur `afterlife-arena-check.rbxl` bauen und das melden.

Pruefe ausserdem:

```powershell
rg -n "TODO|FIXME|Config\\.Enemy\\.|Config\\.Weapon\\.FireRate" src README.md agent-space
```

## Erwarteter Output

Am Ende kurz berichten:

- geaenderte Dateien
- neue Gameplay-Features
- Build-Ergebnis
- was nicht live getestet wurde
- naechste 3 sinnvolle Verbesserungen
