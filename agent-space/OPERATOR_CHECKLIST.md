# Operator Checklist

## Vor Review

- Ist der Scope eingehalten?
- Sind Aenderungen in `src/` statt direkt in der `.rbxl`?
- Wurden keine COD-/fremden Assets/Namen eingefuehrt?
- Sind neue Gameplay-Inhalte in `Config.lua` datengetrieben?
- Bleibt Serverautoritaet fuer Schaden, Drops und Powerups erhalten?

## Build

```powershell
npx rojo build default.project.json --output afterlife-arena-check.rbxl
```

Wenn Studio geschlossen ist:

```powershell
npx rojo build default.project.json --output afterlife-arena.rbxl
```

## Smoke-Test In Studio

- Projekt startet ohne Output-Errors.
- Top-Down-Kamera funktioniert.
- Wellen starten nach Countdown.
- Alle Gegnertypen koennen spawnen und sterben.
- Drops lassen sich aufsammeln.
- Waffen wechseln und laufen korrekt ab.
- Powerups aktivieren und laufen korrekt ab.
- HUD bleibt lesbar.
- Maprotation funktioniert.

## Risiken Beobachten

- Gegner laufen aktuell ohne Pathfinding und koennen durch Deckung wirken.
- Pickups koennen trotz Positionskorrektur an schlechten Stellen landen.
- Powerup-Stapelung kann Balancing brechen.
- Zu viele Parts/Tracers/Pickups koennen Performance belasten.
