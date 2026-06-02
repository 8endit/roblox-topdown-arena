# Roblox Top-Down Arena Prototype

Ein kleiner Roblox-Prototyp fuer ein eigenes Top-Down-Zombie-Arena-Spiel.

## Scope

- Eigene Arena-Map, keine Call-of-Duty-Kopie.
- Top-Down-Kamera und eigene WASD-Bewegung.
- Maus-Zielen und Schiessen.
- Mehrere Map-Layouts, Gegner-Typen, Wellenlogik, Punkte und HUD.
- Room-/Gate-/Stage-Struktur: Raum raeumen, Gate waehlen, naechsten Raum betreten, Stage-Teleporter nur am Stage-Ende.
- Waffen-Drops, Powerups und Loot-Drops.
- Lokale Projektdateien fuer Roblox Studio oder Rojo.

## Neu in dieser Runde

- Gegnerrollen geschaerft: Spitter kitet und laedt sichtbar auf, Exploder hat eine blinkende Warnphase, Tank ist ein Boss mit Health-Bar und Spawn-Warnung.
- Loot mit Seltenheitsstufen Common, Rare, Epic (Farbe, Groesse, Aura, Label). Boss droppt garantiert Rare oder Epic, normale Gegner nur selten.
- Zwei neue Waffen: Burst Rifle (3er-Burst) und Beam (durchschlaegt mehrere Gegner).
- Zwei neue Powerups: Freeze (friert alle Gegner ein) und Magnet (zieht Loot an).
- Zwei neue Maps: Crucible (riskante offene Mitte) und Galleries (enges Pfeilerlabyrinth). Insgesamt 5 Layouts in Rotation.
- Mehr Feedback: zentrale Banner fuer Wave-Start, Boss-Warnung und Boss-Down, Toasts beim Aufsammeln, Waffenfarbe im HUD.
- Gamefeel-Pass: Dash per `Space` oder `LeftShift`, faire Spawns weg vom Spieler, leichte Gegner-Trennung und Shield als echte Shield-Health statt Voll-Unverwundbarkeit.
- Room/Stage-Pass: Stages bestehen aus vorwaerts gerichteten Fork-Merge-Rooms. Nach normalen Rooms oeffnen genau die deklarierten Gates; nur terminale Rooms spawnen den Stage-Teleporter.
- FateRoom-v1: Fate-Raeume zeigen drei zufaellige Auswahl-Saeulen. Eine Wahl cleared den Room, oeffnet das Vorwaerts-Gate und aktiviert einen Run-Fate.
- Erste echte Fate-Effekte: Fleet Soul senkt Dash-Cooldown, Heavy Hands gibt Schaden gegen Speed, Glass Flame gibt Schaden gegen Max-HP, Piercing Rite erhoeht Pierce.

## Mit Rojo starten

Rojo ist in diesem Projekt lokal als npm-Tool installiert.

1. Oeffne Roblox Studio mit einer leeren Baseplate.
2. Starte im Projektordner:

```powershell
npx rojo serve default.project.json --port 34872
```

3. Verbinde Roblox Studio mit dem Rojo-Plugin zu `localhost:34872`.
4. Druecke Play.

## Ohne Rojo manuell einfuegen

Lege diese Struktur in Roblox Studio an:

- `ReplicatedStorage/AfterlifeArcade/Config` als ModuleScript
- `ServerScriptService/AfterlifeArcade/Init` als Script
- `ServerScriptService/AfterlifeArcade/MapBuilder` als ModuleScript
- `ServerScriptService/AfterlifeArcade/EnemyService` als ModuleScript
- `ServerScriptService/AfterlifeArcade/WaveService` als ModuleScript
- `ServerScriptService/AfterlifeArcade/WeaponService` als ModuleScript
- `ServerScriptService/AfterlifeArcade/PlayerService` als ModuleScript
- `StarterPlayer/StarterPlayerScripts/TopDownController` als LocalScript
- `StarterGui/AfterlifeHud` als LocalScript

Kopiere jeweils den Inhalt aus `src`.

## Testkriterien

- Beim Play-Test wird automatisch eine Arena in `Workspace/AfterlifeArcadeMap` erstellt.
- Die Kamera bleibt von oben ueber dem Charakter.
- WASD bewegt den Charakter relativ zur Karte.
- `Space` oder `LeftShift` fuehrt einen kurzen Dash aus.
- Linksklick feuert in Richtung Maus.
- Gegner-Typen spawnen: Runner, Bruiser, Spitter, Exploder und Tank (Boss mit Health-Bar).
- Gegner spawnen bevorzugt mit Abstand zum Spieler und trennen sich leicht voneinander.
- Wellen nutzen ein Budget-System und rotieren alle paar Wellen durch 5 Map-Layouts.
- Nach dem Raeumen eines normalen Rooms oeffnet genau ein Gate pro `node.next`-Eintrag.
- Gate-Beruehrung laedt den verbundenen Zielraum und entfernt alle uebrigen Fork-Gates.
- Treasure-/Fate-Detours fuehren vorwaerts zum naechsten Hauptraum, nicht zurueck.
- FateRooms spawnen drei Auswahl-Saeulen; nach einer Wahl oeffnet das Vorwaerts-Gate.
- Aktive Fates werden im HUD angezeigt und wirken serverseitig auf Dash, Schaden, Pierce, Speed oder MaxHealth.
- Terminale Exit-/Boss-Rooms spawnen nach dem Clear den Stage-Teleporter.
- Stage 3 ist aktuell das erste Boss-Stage-Template.
- Gegner laufen zum naechsten Spieler, greifen an, explodieren mit Warnphase oder kiten und laden Fernangriffe sichtbar auf.
- Waffen-Drops koennen aufgehoben und zeitlich begrenzt genutzt werden (Pistol, SMG, Shotgun, Rifle, Burst Rifle, Beam).
- Powerups aktivieren Heal, Damage Boost, Rapid Fire, Speed Boost, Shield, Nuke, Freeze oder Magnet.
- Shield absorbiert Schaden als Shield-Health, statt komplett unverwundbar zu machen.
- Loot zeigt die Seltenheit per Farbe, Groesse und Aura; Boss-Drops sind garantiert Rare oder Epic.
- Das HUD zeigt Stage, Room, Gegner, Map, Waffe, Powerups, Score und Status, dazu Banner und Pickup-Toasts.

## Bekannte Grenzen

- Ich habe die Dateien lokal statisch validiert, aber nicht in Roblox Studio live getestet.
- Fate-Effekte sind v1 und run-scoped im Server-State; es gibt noch keine Persistenz und keinen Run-Reset-/Game-Over-Service.
- Gegner sind bewusst einfache Parts statt fertiger Rigs, damit der Prototyp klein und kontrollierbar bleibt.
- Mobile/Controller-Steuerung ist noch nicht ausgebaut.
- Gegner verwenden noch direkte Zielbewegung statt Pathfinding, koennen also durch Deckung laufen.
