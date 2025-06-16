https://github.com/K-Anator/KN8R_Utils for serverside support utilities
# MP Freeroam Events

To Add Freeroam Events To A Map:

1. Add the race_data.json file to the map's level folder.

### Race Configuration Guide

```json
{
    "races": {
        "track": {  // Internal race ID (no spaces/special chars)
            "bestTime": 140,      // Base target time in seconds
            "reward": 2500,       // Base cash reward ($)
            "label": "Track",     // Display name (supports localization)
            "checkpointRoad": "trackloop",  // Road name for auto-checkpoints
            "hotlap": 125,        // Hotlap target time (seconds)
            "apexOffset": 1,      // Checkpoint positioning offset (meters)
            "runningStart": true, // Allow rolling start vs standing start
            "altRoute": {         // Alternative path configuration
                "bestTime": 110,  // Alt route target time
                "reward": 2000,   // Alt route reward
                "label": "Short Track",  // Alt display name
                "checkpointRoad": "trackalt",  // Alt road name
                "mergeCheckpoints": [1, 10],  // [start merge, end merge]
                "hotlap": 95,     // Alt route hotlap time
            },
            "type": ["motorsport", "apexRacing"]  // Race categories
        }
    }
}
```

**Key Properties Explained:**

1. **bestTime**  
   - Base target time for bronze medal (seconds)
   - Example: 140 = 2:20 minute target
   - Adjust based on track length/difficulty

2. **checkpointRoad**  
   - Name of spline road in level editor
   - Auto-generates checkpoints along this path
   - Use `"roadName"` or `["startRoad", "endRoad"]` for combined paths

3. **altRoute** (Optional)  
   - Alternative path configuration:
   - `mergeCheckpoints`: [start_index, end_index] for route merging
   - Requires matching checkpoints in main route
   - Reward scaled between main/alt based on merge points

4. **type**  
   - Race categories for filtering:
   - Valid options: `motorsport`, `drift`, `drag`, `apexRacing`, `offroad`
   - Affects available vehicles and HUD elements

**Advanced Configuration Tips:**

- **Hotlap Timing**:  
  Set `hotlap` 10-15% faster than `bestTime` for expert challenge

- **Apex Offset**:  
  Adjust `apexOffset` to move checkpoints forward or backward in corners they move up the amount of nodes specified.

- **Reward Scaling**:  
  Base reward × (1 - (actualTime / bestTime)) × difficulty factor

- **Merge Logic**:  
  Alt routes require at least 2 shared checkpoints with main route

- **Reverse Logic**:  
  If the race is reversed, the checkpoints will be flipped. Use this if the checkpoints are in the wrong order.

**Example Configurations:**

```json
"drag": {
    "bestTime": 12.5,
    "reward": 1500,
    "checkpointRoad": ["drag_start", "drag_finish"],
    "type": ["drag"]
}

"drift": {
    "bestTime": 60,
    "reward": 3500,
    "driftGoal": 50000,  // Optional score target
    "checkpointRoad": "drift_course",
    "type": ["drift"]
}

"rally": {
    "bestTime": 70,
    "reward": 2000,
    "checkpointRoad": "rally",
    "reverse": true,
    "type": ["motorsport"]
}
```
