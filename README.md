<p align="center"><img src="https://wicksmods.github.io/images/travel-form/thumb.png" alt="Wick's Travel Form"></p>

# Wick's Travel Form

> Smart shapeshift binding for druids. One key picks Flight, Travel, Aquatic, or Cat by context.

Part of the **[Wick suite](https://github.com/Wicksmods/WickSuite)** — precision TBC Classic addons with a shared fel-green-on-deep-purple aesthetic.

<!-- wick:suite-table:start -->
| Addon | GitHub | CurseForge |
|---|---|---|
| **Wick's TBC BIS Tracker** | [repo](https://github.com/Wicksmods/WickidsTBCBISTracker) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-tbc-bis-tracker) |
| **Wick's CD Tracker** | [repo](https://github.com/Wicksmods/WicksCDTracker) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-cd-tracker) |
| **Wick's Trade Hall** | [repo](https://github.com/Wicksmods/WicksTradeHall) | [CurseForge](https://www.curseforge.com/wow/addons/trade-hall) |
| **Wick's Macro Builder** | [repo](https://github.com/Wicksmods/WicksMacroBuilder) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-macro-builder) |
| **Wick's Combat Log** | [repo](https://github.com/Wicksmods/WicksCombatLog) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-combat-log) |
| **Wick's Stats** | [repo](https://github.com/Wicksmods/WicksStats) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-stats) |
| **Wick's Quest Key** | [repo](https://github.com/Wicksmods/WicksQuestKey) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-quest-key) |
| **Wick's Layers** | [repo](https://github.com/Wicksmods/WicksLayers) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-layers) |
| **Wick's Totems and Things** | [repo](https://github.com/Wicksmods/WicksTotemsAndThings) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-totems-and-things) |
| **Wick's Bags** | [repo](https://github.com/Wicksmods/WicksBags) | [CurseForge](https://www.curseforge.com/wow/addons/wicks-bags) |
| **Wick's Travel Form** | [repo](https://github.com/Wicksmods/WicksTravelForm) | [CurseForge](https://www.curseforge.com/wow/addons/travel-form) |
<!-- wick:suite-table:end -->

## What it does

Binds one key to the right druid form for where you are right now:

- **Swimming** → Aquatic Form
- **Outdoors, in an Outland flyable zone, out of combat** → Flight Form (Swift Flight Form if you've trained it)
- **Outdoors anywhere else, or in combat** → Travel Form
- **Indoors** → Cat Form (no speed boost; just looks right)

The macro stays correct in TBC Classic because the addon ignores Blizzard's `IsFlyableArea()` (which incorrectly reports Azeroth zones as flyable) and uses a hard-coded list of TBC's actual flyable zones. Swimming, outdoors, and combat checks are baked into the macro itself, so the bind always picks the right form at click time without polling.

A small contextual icon shows which form the next press will trigger and displays your bound key.

## Install

- **CurseForge:** [curseforge.com/wow/addons/travel-form](https://www.curseforge.com/wow/addons/travel-form)
- **Manual:** download the latest ZIP from [Releases](https://github.com/Wicksmods/WicksTravelForm/releases) and extract the `WicksTravelForm` folder into `World of Warcraft\_classic_\Interface\AddOns\`.

## Usage

1. **Bind a key** in `Esc → Key Bindings → Wick's Travel Form → Smart travel form`.
2. The icon shows up center-bottom of the screen by default.
3. Press the bound key anywhere — the addon picks the right form.

Slash commands (`/wstf` or `/wtravel`):

| | |
|---|---|
| `/wstf unlock` | unlock the icon for dragging |
| `/wstf lock` | lock it back |
| `/wstf reset` | move the icon back to default position |
| `/wstf debug` | print current zone, predicted form, and macro string |

Right-click the icon to toggle the lock.

## Compatibility

- **TBC Classic (Burning Crusade / Anniversary)** — Interface `20505`.
- **enUS only** at v0.1 — flyable zone names and form names are hard-coded in English.

## Brand

Uses the locked Wick palette and 10px/2px fel-green L-bracket chrome. See:
- `UI.lua` — tokens at the top of the file
- `CHANGELOG.md` — version history
- `logo.svg` — logomark source

## License

See `LICENSE` — MIT with a trademark carve-out for the Wick name, logomark, and visual system. Full trademark policy: [WickSuite/TRADEMARK.md](https://github.com/Wicksmods/WickSuite/blob/main/TRADEMARK.md).
