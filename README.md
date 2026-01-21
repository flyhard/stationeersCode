Shell function for calculating hashes

needs `rhash` 
```shell
stationeers.hash() { 
    rhash -m $1 -p '16dio [100000000-]sn %Cp Ao d80000000!>n p' | dc
}
```
   
## Agent Instructions (IC10)

- **File size limit:** Each `.ic10` file must be ≤ 4096 bytes. Keep changes within this hard cap.
- **Documentation policy:** Aim for clear in-code documentation. If size pressure requires trimming, reduce code comments first; only then reduce usage/how-to notes.
- **Debug output format:** Use the `db` channel with short, consistent messages, e.g. `s db Setting <value>`.

### Markdown Documentation Standards

**Every IC10 script must have a corresponding `.md` documentation file** with the following sections:

1. **Overview** - Clear explanation of what the script does
2. **Configuration** - All configurable parameters and their purposes
3. **Device Details** - Specifications of any hardware devices used (see Device Reference section below)
4. **How the Math Works** - Detailed mathematical explanations and formulas
5. **Algorithm Flow** - Step-by-step execution logic
6. **Variable Map** - All variables/registers with their purposes
7. **Performance Considerations** - Notes on efficiency and optimization
8. **Examples** - Real-world scenario walkthroughs

#### Device Reference Resources
For detailed information about Stationeers devices, check the [Stationeers Wiki](https://stationeers-wiki.com/):
- [Daylight Sensor](https://stationeers-wiki.com/Daylight_Sensor) - Sun position detection
- [Solar Panel](https://stationeers-wiki.com/Solar_Panel) - Power generation device specifications
- [Device Networking](https://stationeers-wiki.com/Device_Networking) - How devices communicate
- [IC10 Reference](https://stationeers-wiki.com/IC10) - IC10 instruction set and capabilities

### Checking file sizes

Use the helper script to verify the 4096-byte limit across all `.ic10` files:

```sh
# From repo root
bash scripts/check_ic10_size.sh

# Or make it executable once, then run directly
chmod +x scripts/check_ic10_size.sh
scripts/check_ic10_size.sh
```

To run automatically before commits, add this to `.git/hooks/pre-commit`:

```sh
#!/usr/bin/env sh
bash scripts/check_ic10_size.sh || exit 1
```
