# Wick's Travel Form — Changelog

## 0.2.2 — 2026-05-10

### Fixed

- Flight form now works in Shattrath City (flagged indoors by WoW but flyable — now uses a `[nocombat]` clause without the `outdoors` guard)

## 0.2.1 — 2026-05-10

### Fixed

- Travel Form now casts correctly in Azeroth when flight form is learned (flight clause was matching `[nocombat,outdoors]` and failing silently, blocking Travel Form)
- Pressing the button while in Cat Form, Travel Form, or Aquatic Form now cancels the form instead of powershifting

## 0.2.0 — 2026-05-10

### Fixed

- Flight form now activates correctly in Outlands when the macro was last built in Azeroth (e.g. logged in Azeroth, zoned in while in combat)
- Pressing the button while airborne now cancels flight form instead of powershifting back into it

## 0.1.0 — 2026-05-09

### Initial release

Smart shapeshift binding for druids. One key picks Flight, Travel, Aquatic, or Cat by context.

- Hard-coded TBC flyable-zone whitelist (works around `IsFlyableArea` reporting Azeroth as flyable)
- Picks Swift Flight Form when trained, Flight Form otherwise
- In-combat or in non-flyable zones, falls back to Travel Form outdoors
- Indoors falls back to Cat Form (no speed; just for the aesthetic)
- Underwater always switches to Aquatic Form
- Contextual icon button (draggable) showing the next form and bound key
- Slash commands: `/wstf` or `/wtravel` (`unlock | lock | reset | debug`)
