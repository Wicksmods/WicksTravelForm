# Wick's Travel Form — Changelog

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
