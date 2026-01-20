# Gil Tracker for FFXIVMinion

A lightweight, high-performance Gil tracking addon for FFXIVMinion.

## Features
- **Real-time Gil Tracking**: Displays current Gil, net change, and session duration.
- **Performance Optimized**: Updates only once per second and uses caching to minimize CPU usage.
- **Session Estimates**: Calculates estimated hourly and daily Gil earnings based on current session performance.
- **Zero Configuration**: Just install and run. No persistent data or complex setup.

## Installation
1. Copy the `GilTracker` folder to your FFXIVMinion LuaMods directory:
   `C:\MINIONAPP\Bots\FFXIVMinion64\LuaMods\`
2. In the Minion menu, go to **Lua Mods** > **Reload Lua**.
3. The Gil Tracker window should appear.

## Usage
- **Time**: Elapsed time since the addon started tracking this session.
- **Current**: Your current total Gil.
- **Change**: Net increase (Green) or decrease (Red) in Gil during this session.
- **1h Est**: Extrapolated hourly earnings.
- **24h Est**: Extrapolated daily earnings.
- **Reload Button**: Resets the session timer and tracking data.

## Requirements
- FFXIVMinion (64-bit)
- `Inventory:GetCurrencyCountByID` API availability (Standard in FFXIVMinion)
