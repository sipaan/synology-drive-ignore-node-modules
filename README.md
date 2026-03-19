# Synology Drive - Exclude node_modules

Adds `node_modules` to Synology Drive Client's blacklist filter for all sync sessions on Windows. Prevents `node_modules` from being synced across devices — run `npm install` on each device instead.

## Usage

Double-click **`RUN ME.bat`** and follow the prompts.

## What it does

1. Finds your Synology Drive installation
2. Asks for confirmation before making changes
3. Stops Synology Drive
4. Adds `node_modules` to the directory exclusion list for all sync sessions
5. Restarts Synology Drive

## Requirements

- Windows 10 or higher
- Synology Drive Client installed with at least one sync task configured

## Files

- `RUN ME.bat` — Launcher, double-click to run
- `synology-exclude-node-modules.ps1` — Script logic

## Notes

- No admin privileges required
- Re-run after Synology Drive updates if the exclusion gets reset
- Safe to run multiple times — already excluded sessions are skipped
