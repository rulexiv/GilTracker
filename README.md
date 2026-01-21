# Gil Tracker for FFXIVMinion

A minimalistic, high-performance Gil tracking addon for FFXIVMinion that sits unobtrusively at the bottom right of your screen.

## Features
- **Detailed Statistics**: Hover over the bar to see a detailed tooltip with:
  - Session Start Gil / Current Gil
  - Total Profit
  - Hourly / Daily Rates
  - Max Drawdown / Max Drawup
  - 12-Hour Profit History
- **Context Menu**: Right-click the bar to reset the tracker.
- **Visual Indicators**:
  - Green for Gil increase.
  - Pink for Gil decrease.
- **Performance Optimized**: Updates once per second with minimal CPU footprint.

## Installation
1. Copy the `GilTracker` folder to your FFXIVMinion LuaMods directory:
   `C:\MINIONAPP\Bots\FFXIVMinion64\LuaMods\`
2. In the Minion menu, go to **Reload Lua**.
3. The tracked bar will appear at the bottom right of the game window.

## Usage
The tracker runs automatically.
- **Main Bar**: Shows session duration and net Gil change.
- **Hover**: Reveal detailed statistics and history.
- **Right-Click**: Open menu to **Reset Tracker**.

## Requirements
- FFXIVMinion (64-bit)

## Changelog
### v2.0
- **Added Detailed Tooltip**: Hovering over the bar now shows detailed stats (Rates, Drawdown, Profit History).
- **Added Reset Functionality**: Right-click the bar to reset session stats.
- **UI Improvements**: Optimized padding, colors, and layout for better readability.
- **Extended History**: Now tracks up to 12 hours of profit history.
