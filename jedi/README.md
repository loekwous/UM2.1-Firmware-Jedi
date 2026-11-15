# Ultimaker Jedi firmware

Fork of [Ultimaker/UM2.1-Firmware](https://github.com/Ultimaker/UM2.1-Firmware) (UM2+, codename "JarJar")
for the Ultimaker **Jedi**: an internal UM2+ prototype whose Z lead screw needs **400 steps/mm** (UM2+: 200).

## Branches and tags

| | contents |
|---|---|
| `jedi-2018` / tag `jedi-2018-06-16` | Reconstruction of the build that ran on the Jedi from 2018-06-16: UM2.1 release of 2018-03-15 (`34672d2`) + Z 400. Verified against a flash dump (all firmware strings identical). |
| `jedi` | Latest UM2.1_JarJar (2018-10-07; among others hardened material import and an end-of-print retract fix) + Z 400 + material commands over USB (read, apply and write presets). |

`jedi/jedi-flash-2026-11-15.hex` is the flash dump of the printer from 2026-11-15 (including the bootloader), kept as
a fallback.

## Material over USB

The material stays configured in the printer menu (EEPROM). Over USB:

| command | does |
|---|---|
| `M12000 [T0]` | reports the loaded material: `MATERIAL: T0 name=PLA bed=60 fan=100 flow=100 diameter=2.85 change_temp=70 nozzle0.40=205/6.50/25.00 ...` (temperature / retraction length / retraction speed in mm/s per nozzle size) |
| `M12001` | reports all presets, one `PRESET: n/total ...` line per material |
| `M12002 [T0] [S0.4] [V0\|1]` | applies the loaded material like an UltiGCode print from SD: nozzle (for nozzle size S) and bed target temperatures, fan %, flow %, retraction for `G10`/`G11`; `V1` = volumetric E values (UltiGCode). Does not wait: follow with `M190` and `M109` without `S`. |
| `M12003` | back to the defaults for classic G-code (fan 100%, flow 100%, E in mm) |
| `M12004 P<n> [S0.4] [H<temp>] [B<bed>] [F<fan %>] [W<flow %>] [D<diameter>] [L<retract mm>] [R<retract mm/s>] [C<change temp>]` | modifies preset `n` (1-based, as listed by `M12001`); `H`, `L`, `R` apply to nozzle size `S` (default 0.4). Answers with the updated `PRESET:` line. Does not touch the loaded material: follow with `M12007`. |
| `M12005 P<n> <name>` or `M12005 P<n> X<hex>` | renames preset `n` (1-8 printable characters). Use the hex form (two hex digits per character, e.g. `X4E696E6A61203835` = `Ninja 85`) for names with an uppercase `N`, `*` or `;`: without a line number the serial parser takes the first `N` as one, and `*` / `;` start a checksum or comment. |
| `M12006 [P<n>]` | adds a preset as a copy of preset `n` (default 1), named `CUSTOM<k>` (max. 16 presets) |
| `M12007 P<n> [T0]` | loads preset `n` as the current material (settings only, no filament move; stored like a menu selection) |
| `M12008 P<n>` | deletes preset `n` (at least 2 presets remain) |

Every written value is checked against the firmware's own boot-time validation (`lcd_material_verify_material_settings`):
one invalid value there makes the printer reset all presets to factory defaults on the next start. A rejected command
changes nothing and answers with an `echo:M120xx: ...` line (never `Error:`, which OctoPrint treats as fatal). Limits:
nozzle 150 to max-15 C, bed 0 to max-15 C, fan 0-100 %, flow 50-200 %, diameter 1.0-3.5 mm, retraction 0-20 mm at
1-45 mm/s.

Example start G-code (Marlin flavor, sliced without temperatures, firmware retraction):

```
M12002 S0.4   ; material from the printer
M190          ; wait for the bed
M109          ; wait for the nozzle
```
and `M12003` in the end G-code.

Note: firmware from before 2018-06 truncated the stored name of the loaded material to 7 characters
("ToughPL"); it is complete again after selecting a material in the menu with this firmware.

## Build and flash

```bash
jedi/build.sh          # -> jedi/out/MarlinJedi-<version>.hex
```

Flash from the Pi (disconnect OctoPrint first):

```bash
avrdude -p m2560 -c wiring -P /dev/ttyACM0 -b 115200 -D -U flash:w:MarlinJedi.hex:i
```

Read back / backup: `-U flash:r:dump.hex:i`. Reading the EEPROM through the bootloader is not supported.
