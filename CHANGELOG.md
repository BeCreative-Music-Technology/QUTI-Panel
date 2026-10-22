# Changelog

## Unreleased: engine integration, built-in presets and laser strings

### Communication with the engine (PickupProcessor)
- Delay, reverb and low-pass now reach the engine. The panel sent wrong or missing parameter keys (`frequency` for delay, no `decay`/`dampening` for reverb, no `q_factor` for low-pass), so only gain worked.
- Parameter keys, ranges and units live in one place, `ModuleRegistry`, and are used by the tiles, the config panel, sending and loading.
- Sliders show real units: gain in dB (-6 to +18), cutoff in Hz, room size in m, delay time in ms (10–2000).
- The bridge reconnects automatically every 3 s. "Sent to Guitar" only shows when the data was actually sent.
- The engine address can be overridden with `QUTI_ENGINE_HOST` / `QUTI_ENGINE_PORT`.
- `ModuleRegistry` is a proper QML singleton instead of a context property.

### Hardware controls and laser strings
- Hardware mappings list the guitar's real controls: Rotary and Laser 1–3 (engine ids `rotary_0`, `laser_0`..`laser_2`). "Button" was removed (no such input in the engine).
- Targets are only parameters the engine can change while playing: Gain/Mix, Cutoff/Mix, and Mix for reverb and delay. The non-functional "Enabled" target was removed.
- Several controls can be mapped on one effect.
- With no effect selected, the mappings card shows what every control drives.

### Presets
- Built-in presets in `presets/builtin_presets.json`, bundled with the app and shown first with a BUILT-IN tag: Clean, Warm Lead, Slapback, Ambient Wash, Filter Sweep, Laser Strings.
- Loading a preset restores the bus on/off switches.
- Fixed: renaming a preset to its own name deleted it.
- Fixed: saving under an existing name created a duplicate entry.
- Fixed: names with dots ("v1.2") were cut short.
- Fixed: toasts from the presets panel never showed.
