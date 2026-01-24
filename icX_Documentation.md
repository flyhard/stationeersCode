# icX Documentation

## Overview

**icX** is a higher-level programming language that compiles to **ic10** bytecode for Stationeers microprocessors. It simplifies microprocessor programming by providing variables, functions, loops, and cleaner syntax while the compiler automatically generates optimized ic10 code.

- **File Extension**: `.icx` 
- **Compiles To**: `.ic10` (standard Stationeers microprocessor code)
- **VS Code Extension**: [Stationeers ic10](https://marketplace.visualstudio.com/items?itemName=Traineratwot.stationeers-ic10)
- **Official Wiki**: https://icx.traineratwot.site/wiki/icx

## Quick Start

1. Install the [VS Code extension](https://marketplace.visualstudio.com/items?itemName=Traineratwot.stationeers-ic10)
2. Create a file with `.icx` extension
3. Write your program:
   ```icx
   use loop
   var on = d1.Open
   d0.On = on
   ```
4. Save the file (Ctrl+S) - this automatically generates a corresponding `.ic10` file
5. Copy the generated ic10 code into a Stationeers microprocessor

## Features

### Comments

Text after `#` is ignored to the end of the line:

```icx
# This is a comment
var x = 5  # inline comment
```

### Variables

Variables automatically map to registers (r0, r1, r2, etc.) and can be used intuitively:

```icx
var a = 10
var b = 20
var result = a + b
```

**Compiled to ic10:**
```ic10
move r0 10
move r1 20
add r2 r0 r1
```

#### Using Aliases

Enable with `use aliases` to see variable names directly:

```icx
use aliases
var a = 10
```

**Compiled to ic10:**
```ic10
alias a r0
move a 10
```

### Constants

Define compile-time constants with `use constants`:

```icx
use constants
const PI = 3.14
const BUFFER_SIZE = 128
var area = PI * 5 * 5
```

Constants are calculated at compile time, so `area` will directly equal the computed value.

## Math Operations

### Unary Operations (++, --)

```icx
var a = 0
a++  # increment
a--  # decrement
```

**Compiled to ic10:**
```ic10
move r0 0
add r0 r0 1   # increment
sub r0 r0 1   # decrement
```

### Binary Operations (+, -, *, /, %)

icX automatically calculates constant expressions:

```icx
var x = 5 + 5 * 2  # calculated as 15 at compile time
```

**Compiled to ic10:**
```ic10
move r0 15
```

With variables, operations compile to ic10 instructions:

```icx
var k = 2
var y = 5
var x = y + y * k
```

**Compiled to ic10:**
```ic10
move r0 2
move r1 5
mul r15 r1 r0
add r2 r1 r15
```

## Control Flow

### If - Else

**Logical operators**: `<`, `>`, `==`, `!=`, `<=`, `>=`, `&`, `|`, `~=`

```icx
var a = 0
var b = 0
if a >= 0
  b = 1
else
  b = 0
end
```

**Compiled to ic10:**
```ic10
move r0 0
move r1 0
sgez r15 r0
beqz r15 if0else
beq r15 1 if0
if0:
   move r1 1
   j if0exit
if0else:
   move r1 0
if0exit:
```

### While Loops

```icx
var a = 0
while a < 10
  a++
end
```

**Compiled to ic10:**
```ic10
move r0 0
while0:
  slt r15 r0 10
  beqz r15 while0exit
  add r0 r0 1
  j while0
while0exit:
```

## Device Interaction

### Reading and Writing Device Parameters

```icx
d0.Setting = 1                      # Set device parameter
var a = d0.Setting                  # Read device parameter
var b = d0.slot(a).PrefabHash       # Access slot of device
```

**Compiled to ic10:**
```ic10
s d0 Setting 1
l r0 d0 Setting
ls r1 d0 r0 PrefabHash
```

### Batch Operations (Multiple Devices of Same Type)

Access all devices of a type using hash:

```icx
var a = d(5438547545).Setting(Sum)  # Load from all devices, use Sum aggregation
d(5438547545).Setting = b           # Set all devices of this type
```

**Compiled to ic10:**
```ic10
lb r0 5438547545 Setting Sum
sb 5438547545 Setting r1
```

**Aggregation modes**:
- `Sum` - Sum all values
- `Average` - Average all values
- `Maximum` - Highest value
- `Minimum` - Lowest value

### Device Aliases

Make code more readable with aliases:

```icx
alias SolarSensor d0
alias SolarPanel d1
var vertical = 180
SolarPanel.Vertical = vertical
```

## Functions

Define reusable code blocks with the `function` keyword:

```icx
use loop
var a = 0
example()

function example
  a = 1
end
```

**Compiled to ic10:**
```ic10
move r0 0
jal example
j 0
example:
move r0 1
j ra
```

Functions automatically handle jumping and returning.

## Stack Operations

### Push Values to Stack

```icx
stack 342423 432423 54534 6567
```

**Compiled to ic10:**
```ic10
push 342423
push 432423
push 54534
push 6567
```

### Iterate Over Stack (foreach)

```icx
var value = 0
foreach value
  if value == 6567
    var b = 5
  end
end
```

**Compiled to ic10:**
```ic10
move sp 0  # reset stack pointer
while0:
   peek r0  # get stack value
   seq r15 r0 6567
   beqz r15 if0exit
   move r1 5
   if0exit:
   breqz r0 2  # end of loop
   add sp sp 1  # increment counter
j while0
```

## Advanced Features

### Use Statements

Control compilation behavior:

#### `use loop`

Wraps your code in a main loop that restarts from the beginning:

```icx
use loop
var counter = 0
counter++
```

This automatically creates an infinite loop in ic10.

#### `use aliases`

Show variable names instead of registers in generated code.

#### `use constants`

Enable constant folding for compile-time calculations.

#### `use comments`

Preserve your icX comments in the generated ic10 code:

```icx
use comments
# Initialize sensor
var sensor_value = d0.Temperature
# Process value
var adjusted = sensor_value * 2
```

## Environment Configuration

Configure hardware simulations for debugging by creating `.toml` files:

**Naming convention**:
- For single script: `scriptname.icx.toml` (e.g., `solar.icx.toml` for `solar.icx`)
- For entire folder: `.toml` (applies to all scripts)

**Example configuration** (`environment.toml`):
```toml
[d0]
PrefabHash = "StructureAdvancedPackagingMachine"
Setting = 18

[d0.slot.0]
Quantity = 5

[d0.Reagents.Contents]
Iron = 1
Copper = 3
```

This allows testing code without being in-game.

## Debugger

Launch VS Code debugger for icX/ic10 code:

**`.vscode/launch.json`:**
```json
{
  "version": "0.2.0",
  "configurations": [
    {
      "type": "ic10",
      "request": "launch",
      "name": "Debug ic10",
      "program": "${fileWorkspaceFolder}${pathSeparator}${fileBasenameNoExtension}.ic10",
      "stopOnEntry": true,
      "trace": false
    }
  ]
}
```

## Complete Example

A practical example combining multiple features:

```icx
use loop
use aliases

alias SolarSensor d0
alias SolarPanel d1
alias LedVertical d2
alias LedHorizontal d3

var SOLAR_HASH = d1.PrefabHash

var vertical = 180
var horizontal = 180

main:
  updateLED()
  setSolarPanels()
  yield

j main

function setSolarPanels
  d(SOLAR_HASH).Vertical = vertical
  d(SOLAR_HASH).Horizontal = horizontal
end

function updateLED
  d2.Setting = vertical
  d3.Setting = horizontal
end
```

## Device Property Reference

### Common Read/Write Properties

- **On** - Power state (0 or 1)
- **Setting** - Generic configuration parameter
- **Open** - Door open state
- **Temperature** - Temperature reading
- **Pressure** - Pressure reading
- **Horizontal** - Horizontal angle
- **Vertical** - Vertical angle
- **Power** - Power output
- **Activate** - Activation state

Access with: `d{number}.{property}` or `d({hash}).{property}`

## Tips & Best Practices

1. **Use aliases** for readability - it's much clearer than `d0`, `d1`, `d2`
2. **Organize with functions** - breaks complex logic into manageable pieces
3. **Use comments** in your icX code to explain logic
4. **Test with environment files** - configure `.toml` files for offline testing
5. **Leverage compile-time constants** - reduces runtime overhead
6. **Use meaningful variable names** - makes code maintenance easier
7. **Batch operations** - use hashes for bulk device control

## Common Patterns

### Sensor Reading and Action

```icx
use loop
alias Sensor d0
alias Actuator d1

main:
  var reading = Sensor.Temperature
  if reading > 300
    Actuator.On = 1
  else
    Actuator.On = 0
  end
  yield
j main
```

### Device State Inversion

```icx
alias Proximity d0
alias Beacon d1

var state = d0.Activate
seqz state state        # invert: 0->1, 1->0
d1.On = state
```

### Multi-Device Batch Control

```icx
const DOOR_HASH = 12345678
d(DOOR_HASH).Open = 1   # open all doors of this type
```

## Resources

- **Official Repository**: https://github.com/Stationeers-ic/vscode-stationeers-ic10
- **Sample Project**: https://github.com/Stationeers-ic/Ic10-and-Icx-Sample
- **VS Code Extension**: https://marketplace.visualstudio.com/items?itemName=Traineratwot.stationeers-ic10
- **Discord Community**: https://discord.gg/KSVjXufkA9
- **Stationeers Wiki**: https://stationeers-wiki.com/

## Troubleshooting

### Generated ic10 file not updating
- Save the icX file again (Ctrl+S)
- Check that the file has `.icx` extension
- Ensure the VS Code extension is properly installed

### Code size exceeds 4096 bytes
- The compiled ic10 must fit in microprocessor memory
- Simplify logic or break into separate microprocessors
- Use constants to reduce generated code
- Check with the size verification script in your project

### Unexpected register usage
- Register variables are automatically assigned (r0, r1, etc.)
- The compiler optimizes allocation - this is intentional
- Use `use aliases` to see which registers correspond to your variables

## Version History

- **Latest**: icX 2.1.7+
- Supports all modern ic10 commands: `lr`, `sra`, `sds`, `ss`, etc.
- Active development and community support
