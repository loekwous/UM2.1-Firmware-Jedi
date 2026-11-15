# Ultimaker Jedi firmware

Fork of [Ultimaker/UM2.1-Firmware](https://github.com/Ultimaker/UM2.1-Firmware) (UM2+, codename "JarJar")
for the Ultimaker **Jedi**: an internal UM2+ prototype whose Z lead screw needs **400 steps/mm** (UM2+: 200).

## Branches and tags

| | contents |
|---|---|
| `jedi-2018` / tag `jedi-2018-06-16` | Reconstruction of the build that ran on the Jedi from 2018-06-16: UM2.1 release of 2018-03-15 (`34672d2`) + Z 400. Verified against a flash dump (all firmware strings identical). |
| `jedi` | Latest UM2.1_JarJar (2018-10-07; among others hardened material import and an end-of-print retract fix) + Z 400 + material commands over USB. Flashed on 2026-11-15. |

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
