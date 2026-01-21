# Solar Tracking Documentation

## Overview
The Solar Tracking (SolarTracking.ic10) script automatically adjusts solar panels to follow the sun's position throughout the day. It reads sensor data to determine the sun's location and commands all solar panels in a grid to maintain optimal orientation.

## Configuration

### Required Ports
- **solarDataPort** (default: 180) - Direction the solar panel data port is facing (0-360°)
- **daySensorPort** (default: 180) - Sensor facing direction (0-360°) used as reference for angle calculations

### Day/Night Sensor (StructureDaylightSensor)
- **Position**: Data port opposite to power port (180° offset)
- **Horizontal Output**: -180° to 180° (clockwise reading from sensor), where:
  - 0° = straight ahead from sensor
  - 90° = directly right
  - -90° = directly left
  - ±180° = directly behind
- **Vertical Output**: 0° to 180° (sensor reading), where:
  - 0° = toward horizon level
  - 90° = straight up (zenith)
  - 180° = straight down (nadir)

### Supported Solar Panel Types
The script works with four built panel structures via hash matching:
- `StructureSolarPanel` - Solar Panel (combined power/data ports)
- `StructureSolarPanelDual` - Solar Panel (Dual) (opposite side split ports)
- `StructureSolarPanelReinforced` - Solar Panel (Heavy) (storm-resistant, combined ports)
- `StructureSolarPanelDualReinforced` - Solar Panel (Heavy Dual) (storm-resistant, split ports)

Note: Built from Kit (Solar Panel) or Kit (Solar Panel Heavy). Only structures with logic capability are supported.

## How the Math Works

### Coordinate System

**Daylight Sensor readings**:
- **Horizontal**: -180° to 180° (sensor perspective, sign indicates direction)
- **Vertical**: 0° to 180° (0° = horizon, 90° = zenith, 180° = nadir)

**Solar Panel commands**:
- **Horizontal**: 0° to 360° (wraps around; -90° = 270°). Data port reference: 270°
- **Vertical**: 15° to 165° (hardware limits). 15° = horizon, 90° = zenith, 165° = opposite horizon
  - Values outside this range are clamped by the panel hardware

### Angle Correction Calculation
```
correction = solarDataPort + 270 - daySensorPort
```

**Purpose**: Transforms sensor readings from the sensor's reference frame to the solar panel's reference frame.

**Explanation**:
- Solar panels use the **data port** as a reference point at 270° (per wiki)
- The sensor has its own directional reference (`daySensorPort`)
- We need to account for the difference between where the sensor is pointing and where the panel data port is pointing
- Formula breakdown:
  - `solarDataPort + 270`: Converts from panel data port reference (270°) to panel's 0° reference
  - `- daySensorPort`: Rotates coordinate system to align with sensor orientation
- This correction is applied to all sensor readings before commanding the panels

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
- **Horizontal**: `hPos = Horizontal - correction` (transforms sensor angle to panel coordinate frame)
- **Vertical**: `vPos = 90 - Vertical` (inverts sensor elevation to panel angle)
  - When sensor Vertical=0° (sun at horizon): vPos=90°, but clamped to 15° by hardware
  - When sensor Vertical=90° (sun at zenith): vPos=0°, but actually stays at 15° (hardware minimum)
  - When sensor Vertical=15° (sun slightly up): vPos=75° (panel tilts toward sun)
  - When sensor Vertical=75° (sun high): vPos=15° (panel near horizon orientation)
  
Note: The panel hardware automatically clamps vertical commands to the 15-165° range

### Panel Commands
For each solar panel in the stack:
```
sb currPanelType Horizontal hPos
sb currPanelType Vertical vPos
```

The `sb` command (Set Batch) updates all devices of the specified type with the same position values.

### Solar Panel Constraints (Per Wiki)
- **Horizontal wrapping**: Horizontal angles wrap around (e.g., -90° = 270°, 361° = 1°)
- **Vertical range**: Hardware enforces 15° to 165° range
  - 15° = panel faces horizon
  - 90° = panel faces straight up (zenith)
  - 165° = panel faces opposite horizon
- **Vertical clamping**: Values below 15° are clamped to 15°, values above 165° are clamped to 165°
- **Physical limitation**: "At extreme attitude settings (0/100) the solar panel still faces 15 degrees above the horizon. Thus the total arc of vertical rotation is only 150 degrees" (wiki quote)

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

**Time: Night**
- Sensor reads: Horizontal=85°, Vertical=120° (sun below horizon, Vertical ≥ 90°)
- `isDay=0` → panels point to safe position (morningHoriz, 15°)
- Panels rest at horizon level facing east

**Time: Sunrise**
- Sensor reads: Horizontal=95°, Vertical=85° (sun just above horizon, Vertical < 90°)
- `isDay=1` → sunrise detected, `morningHoriz = 95° - correction` captured
- Panels adjust to: Horizontal=95°-correction, Vertical=90°-85°=5° → clamped to 15°
- Panels track the rising sun

**Time: Noon, sun at zenith**
- Sensor reads: Horizontal=180°, Vertical=10° (sun high in sky)
- Panels adjust to: Horizontal=180°-correction, Vertical=90°-10°=80°
- Panels tilted up significantly to face the high sun

**Time: Late afternoon**
- Sensor reads: Horizontal=270°, Vertical=70°
- Panels adjust to: Horizontal=270°-correction, Vertical=90°-70°=20°
- Panels near horizon level, tracking setting sun
