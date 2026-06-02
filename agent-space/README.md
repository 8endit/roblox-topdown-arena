# Agent Space

Gemeinsamer Arbeitsbereich fuer Operator und Builder-Agenten.

## Rollen

- Operator: haelt Scope, prueft Risiken, validiert Builds, fuehrt Review/Closeout.
- Builder: implementiert Gameplay-Verbesserungen in kleinen, testbaren Schritten.

## Aktueller Projektzustand

- Projekt: `C:\dev\roblox-topdown-arena`
- Rojo-Projektdatei: `default.project.json`
- Gebaute Studio-Datei: `afterlife-arena.rbxl`
- Live-Server: `localhost:34872`, falls der Rojo-Prozess noch laeuft.
- Roblox Studio kann die `.rbxl` offen halten; in diesem Fall die `.rbxl` nicht direkt ersetzen, sondern Rojo-Sourcen in `src/` bearbeiten.

## Arbeitsregeln

- Gameplay-Code liegt unter `src/`.
- Konfiguration zuerst in `src/ReplicatedStorage/AfterlifeArcade/Config.lua` erweitern.
- Serverautoritaet behalten: Schaden, Loot, Powerups und Wellen bleiben serverseitig.
- Keine Call-of-Duty-Namen, Assets oder 1:1-Mapkopien verwenden.
- Jede groessere Aenderung mit `npx rojo build default.project.json --output afterlife-arena.rbxl` pruefen, sofern Studio die Datei nicht sperrt.
- Wenn die `.rbxl` gesperrt ist, Build unter anderem Namen testen, z. B. `afterlife-arena-check.rbxl`.

## Closeout

Am Ende jeder Builder-Runde:

- geaenderte Dateien auflisten
- Gameplay-Aenderungen kurz beschreiben
- Build-/Teststatus melden
- bekannte Risiken und naechste sinnvolle Schritte notieren
