# Tracker Proximity Documentation

## Overview
The Tracker Proximity (trackerProximity.ic10) script activates beacons when NO players are detected within range of a proximity sensor. This provides an "all clear" or "unoccupied" indicator system, useful for showing when areas are vacant, marking safe zones, or alerting when an area becomes unguarded.

## Configuration

### Device Requirements
- At least one **StructureProximitySensor** connected to the data network
- At least one **StructureBeacon** connected to the data network

### Initial Settings
- **Proximity Range**: 30 meters (configured in line 5: `s prox Setting 30`)
- **Update Interval**: 30 ticks (approximately 30 seconds)

## Device Details

### StructureProximitySensor (Proximity Sensor)
- **Hash**: 568800213
- **Prefab Name**: StructureProximitySensor
- **Power Usage**: 0W
- **Detection Range**: Configurable via `Setting` parameter (0-250m)
- **Built From**: Kit (Sensors) placed on small grid or frames

#### How It Works
- Detects players within a spherical zone centered on the sensor
- Radius set by the `Setting` parameter (max 250m)
- Does NOT detect thrown items or portable devices (player-only detection)
- Can be configured with Access Controller cartridge to filter by access card
- Manual adjustment: Use quantity change key for increments of 10 instead of 1

#### Data Properties
- **Setting** (Input): Detection radius in meters (0-250)
- **Activate** (Output, Boolean): 1 when player detected, 0 when clear
- **Maximum** (Output): Returns the highest activation state across multiple sensors (used with `lb` command)

### StructureBeacon (Beacon)
- **Hash**: -188177083
- **Prefab Name**: StructureBeacon
- **Power Usage**: 300W (requires power to operate)
- **Built From**: Kit (Beacon) placed on small grid

#### How It Works
- Emits a bright visible flare when powered and active
- Visible from indefinite distance (unless obstructed by terrain/objects)
- Can be renamed with Labeller tool (name appears on Tablet with Tracker Cartridge)
- Provides both tracking functionality and visual waypoint

#### Data Properties
- **On** (Input, Boolean): 1 = turn on, 0 = turn off
- **Lock** (Input, Boolean): 1 = lock controls, 0 = unlock
- **Color** (Input, Integer): Sets beacon color (see Data Network Colors)
- **Power** (Output, Boolean): Returns whether beacon has power
- **RequiredPower** (Output, Integer): Current power consumption in watts (300W)

## How the Math Works

### Logic Flow

This system inverts the proximity sensor state to create "vacant" indicators:

```
1. Set proximity sensor detection radius to 30m
2. Read activation state from ALL proximity sensors (lb = Load Batch)
3. Invert the state using seqz (0→1, 1→0)
4. Write inverted state to ALL beacons (sb = Set Batch)
5. Wait 30 ticks
6. Repeat
```

**Result**: Beacons ON when area is vacant, OFF when occupied.

### Load Batch (lb) Operation
```
lb presens prox Activate Maximum
```

**Behavior**:
- `lb` (Load Batch) reads a property from ALL devices of the specified type
- `Maximum` aggregation returns the highest value across all sensors
- Result: `presens = 1` if ANY proximity sensor detects a player
- Result: `presens = 0` if ALL proximity sensors are clear

**Why Maximum?**
- With multiple sensors, we want beacons ON if ANY sensor detects someone
- `Maximum` aggregation means: "If at least one sensor returns 1, presens = 1"
- Alternative would be `Average`, but that could give fractional values

### Set Equal to Zero (seqz) Operation
```
seqz presens presens
```

**Behavior**:
- Inverts the boolean value: 0 becomes 1, 1 becomes 0
- If `presens = 1` (player detected), result = 0 (turn beacons OFF)
- If `presens = 0` (no player), result = 1 (turn beacons ON)
- This creates the "vacant indicator" behavior

### Set Batch (sb) Operation
```
sb beacon On presens
```

**Behavior**:
- `sb` (Set Batch) writes a value to ALL devices of the specified type
- Directly passes the boolean state from sensors to beacons
- All beacons turn on/off simultaneously based on sensor state

## Algorithm Flow

```
1. Initialize:
   - Configure all proximity sensors to 30m detection radius
   
2. Main Loop:
   a. Read activation state from proximity sensors (Maximum across all)
      - If ANY sensor detects player: presens = 1
      - If NO sensor detects player: presens = 0
   
   b. Invert the state
      - presens = 1 becomes 0
      - presens = 0 becomes 1
   
   c. Set all beacons to inverted state
      - Inverted value = 1 (no player detected): All beacons turn ON
      - Inverted value = 0 (player detected): All beacons turn OFF
   
   d. Sleep for 30 ticks (≈30 seconds)
   
   e. Repeat from step a
```

## Variable Map

| Variable | Alias | Register | Purpose |
|----------|-------|----------|---------|
| Proximity sensor state | presens | r0 | Stores aggregated activation state from sensors (0 or 1) |
| N/A | prox | - | Hash constant for StructureProximitySensor |
| N/A | beacon | - | Hash constant for StructureBeacon |

## Performance Considerations

- **Batch operations**: Uses `lb` and `sb` for efficient multi-device updates
- **Sleep interval**: 30 ticks reduces CPU load while maintaining responsiveness
- **No loops**: Single pass-through per cycle keeps code simple and efficient
- **Network overhead**: Minimal - only two network commands per cycle

## Use Cases

1. **Vacancy Indicator**: Show when base is unoccupied/available
2. **Safe Zone Marker**: Beacons light up when area is clear of players
3. **Security "All Clear"**: Visual confirmation that perimeter is clear
4. **Auto-lighting**: Turn on waypoint beacons when nobody is home
5. **Away Detection**: Signal when an area has been abandoned
6. **Power Management**: Combine with other systems to shut down non-essential equipment when area is occupied

## Example Scenarios

### Scenario 1: Single Sensor, Single Beacon
- Player approaches base from 40m away → No detection, beacon ON (area vacant)
- Player enters 30m radius → Sensor activates, beacon turns OFF (area occupied)
- Player stays within range → Beacon remains OFF
- Player leaves 30m radius → Sensor deactivates, beacon turns ON (area vacant again)

### Scenario 2: Multiple Sensors, Multiple Beacons
- Three sensors positioned around base (North, East, West)
- Four beacons positioned at base corners
- No players in range → All sensors return 0, inverted to 1, all beacons ON (base vacant)
- Player enters East sensor range → East sensor returns 1
- `lb Maximum` returns 1 (highest across all sensors)
- `seqz` inverts 1 to 0
- All four beacons turn OFF simultaneously (base now occupied)
- Player moves to North sensor range (still in East range) → Both sensors return 1
- Player exits all sensor ranges → All sensors return 0, inverted to 1, all beacons turn ON (vacant)

### Scenario 3: Adjusting Detection Range
To change detection radius, modify line 5:
```ic10
s prox Setting 50  # Increases range to 50 meters
```
Or use batch command:
```ic10
sb prox Setting 50  # Sets ALL proximity sensors to 50m
```

## Limitations

- **Player-only detection**: Does not detect objects, items, or portable devices
- **Power requirement**: Beacons consume 300W each - ensure adequate power supply
- **Update delay**: 30-tick sleep means up to 30 seconds delay before beacon response
- **No access filtering**: Detects all players unless sensors are manually configured with access cards
- **Line of sight**: Proximity detection is spherical but beacon visibility can be blocked by terrain

## Configuration Tips

### Reduce Response Time
Change sleep duration for faster updates (at cost of more CPU usage):
```ic10
sleep 10  # Check every 10 ticks (≈10 seconds)
```

### Increase Detection Range
Proximity sensors support up to 250m:
```ic10
s prox Setting 250  # Maximum detection range
```

### Filter by Access Card
1. Use Handheld Tablet with Access Controller Cartridge
2. Configure each proximity sensor with required access card
3. Only players with matching cards will trigger detection
