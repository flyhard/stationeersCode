# Solar Tracking Documentation

## Overview
The Solar Tracking (SolarTracking.ic10) script automatically adjusts solar panels to follow the sun's position throughout the day. It reads sensor data to determine the sun's location and commands all solar panels in a grid to maintain optimal orientation.

## Configuration

### Required Ports
- **solarPowerPort** (default: 0) - Port number of the day/night sensor that provides sun position data
- **daySensorPort** (default: 180) - Sensor facing direction (0-360°) used as reference for angle calculations

### Day/Night Sensor (Daylight Sensor 0)
- **Position**: Opposite to power port (180° offset)
- **Horizontal Angle Range**: -180° to 180° (clockwise), where:
  - 0° = straight ahead
  - 90° = directly right
  - -90° = directly left
  - ±180° = directly behind
- **Vertical Angle Range**: 0° to 180°, where:
  - 0° = toward horizon level
  - 90° = straight up
  - 180° = straight down

### Supported Solar Panel Types
The script works with four panel types via hash matching:
- `StructureSolarPanel` - Basic solar panel
- `StructureSolarPanelDual` - Dual solar panel
- `StructureSolarPanelReinforced` - Reinforced solar panel
- `StructureSolarPanelDualReinforced` - Dual reinforced solar panel

## How the Math Works

### Coordinate System
The script uses a 2D directional system where angles represent compass directions:
- **Horizontal (-180° to 180°)**: Pan angle; both horizontal and vertical angles wrap around (-90° = 270°)
- **Vertical (0-180°)**: Elevation angle; 0° = toward horizon, 90° = straight up, 180° = straight down

### Angle Correction Calculation
```
correction = solarPowerPort + 90 - daySensorPort
```

**Purpose**: Normalizes the sensor readings to a common reference frame.

**Explanation**:
- Solar panel's power port is +90° offset from its 0° reference point
- The day sensor is mounted at a specific direction (`daySensorPort`)
- Adding 90° accounts for this power port offset
- Subtracting `daySensorPort` rotates the coordinate system so the sensor's orientation becomes the reference
- This ensures that raw sensor angles map correctly to actual panel positions

### Sunrise Detection
The script tracks when the sun rises to capture the morning horizontal angle:
- When `Vertical < 90°` (sun above horizon): `isDay = 1` (daytime)
- When `Vertical ≥ 90°` (sun at or below horizon): `isDay = 0` (nighttime)
- **Sunrise moment**: Transition from `prevDay=0` to `isDay=1`
- At sunrise: `morningHoriz = Horizontal - correction`
  - This baseline angle is used during nighttime to position panels safely

### Nighttime Panel Positioning
When the sun is down (`isDay = 0`):
- **Horizontal**: Set to `morningHoriz` (morning sun position)
- **Vertical**: Set to 15° (minimum safe angle)
- This "safe" orientation prepares panels for sunrise (note: vertical angles below 15° are ignored)

### Daytime Panel Positioning
When the sun is up (`isDay = 1`):
- **Horizontal**: `hPos = Horizontal - correction` (sun's current compass direction)
- **Vertical**: `vPos = 90 - Vertical` (transforms sensor elevation to panel angle)
  - When Vertical=0° (sun toward horizon): vPos=90° (panel faces straight up)
  - When Vertical=90° (sun straight up): vPos=0° (panel faces toward horizon)

### Panel Commands
For each solar panel in the stack:
```
sb currPanelType Horizontal hPos
sb currPanelType Vertical vPos
```

The `sb` command (Set Batch) updates all devices of the specified type with the same position values.

### Solar Panel Constraints
- **Angle wrapping**: Both horizontal and vertical angles wrap around (e.g., -90° = 270°)
- **Vertical minimum**: 15° is the practical minimum; setting values below 15° has no effect
- **Sunset behavior**: The sun goes down at the horizon (Vertical=0°), not at 15°. The 15° minimum is just a safe parking angle for nighttime.

## Algorithm Flow

```
1. Initialize:
   - Load all 4 panel types onto stack
   - Calculate angle correction factor
   - Set prevDay = 0

2. Main Loop:
   a. Read current sun position (Horizontal, Vertical) from sensor
   b. Determine if it's day (Vertical < 90°)
   
   c. Sunrise Detection:
      - If sun just rose: capture morningHoriz = Horizontal - correction
   
   d. Set panel targets:
      - If night: hPos=morningHoriz, vPos=15°
      - If day: hPos=Horizontal-correction, vPos=90-Vertical
   
   e. Update all panels to target position
   
   f. Yield twice (allow other processes to run)
   
   g. Repeat
```

## Variable Map

| Variable | Alias | Register | Purpose |
|----------|-------|----------|---------|
| Day Sensor | DaySensor | d0 | Input sensor reading |
| Horizontal angle | horiz | r0 | Current sun horizontal angle |
| Vertical angle | vert | r1 | Current sun vertical angle |
| Morning horizontal | morningHoriz | r3 | Captured sunrise position |
| Is daytime | isDay | r4 | 1=day, 0=night |
| Day/night mode | mode | r5 | Temporary mode flag |
| Angle correction | correction | r6 | Calculated offset |
| Panel type hash | currPanelType | r7 | Stack item: current panel type |
| Horizontal position | hPos | r8 | Target horizontal angle |
| Vertical position | vPos | r9 | Target vertical angle |
| Stack size | stackSize | r10 | Number of panel types (4) |
| Previous day state | prevDay | r11 | Last frame's day/night state |

## Performance Considerations

- **Yield statements**: Two `yield` instructions per loop allow other scripts to execute
- **Batch updates**: `sb` (Set Batch) command updates all panels of each type efficiently
- **Stack-based loop**: Iterates through 4 panel types without nested structures

## Example Scenario

**Time: Morning, sun rising in the east**
- Sensor reads: Horizontal=85°, Vertical=92° (sun below horizon)
- `isDay=0` → panels point to safe position (morningHoriz, 15°)

**Time: Later morning, sun visible**
- Sensor reads: Horizontal=95°, Vertical=75° (sun above horizon)
- `isDay=1` → sunrise detected, `morningHoriz` captured
- Panels adjust to: Horizontal=95°-correction, Vertical=90°-75°=15°
- Panels face towards the sun

**Time: Noon, sun high**
- Sensor reads: Horizontal=180°, Vertical=20° (high in sky)
- Panels adjust to: Horizontal=180°-correction, Vertical=90°-20°=70°
- Panels face up and south (following sun)
