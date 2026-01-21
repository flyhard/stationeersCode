# Stationeers IC10 Code

Collection of IC10 scripts for Stationeers automation.

## Hash Calculator

Shell function for calculating hashes (needs `rhash`):

```shell
stationeers.hash() { 
    rhash -m $1 -p '16dio [100000000-]sn %Cp Ao d80000000!>n p' | dc
}
```

## File Size Checking

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
