# TokenVisualizer

A native macOS menu bar app that shows your Claude Code rate limit usage at a glance.

![macOS](https://img.shields.io/badge/macOS-14%2B-blue) ![Swift](https://img.shields.io/badge/Swift-5.9-orange)

## Features

- **Menu bar icon** — always-visible bar chart icon in the macOS menu bar
- **Session usage** — current 5-hour session utilization % with color-coded progress bar
- **Weekly usage** — 7-day all-models utilization % with reset countdown
- **Real-time updates** — watches Claude Code's statusline output for instant usage changes
- **API polling** — fetches from Anthropic's OAuth usage API every 5 minutes as a fallback
- **Color thresholds** — green (<50%), orange (50-79%), red (80-100%)

## How It Works

TokenVisualizer pulls usage data from two sources:

1. **Statusline file watcher** — Claude Code pipes rate limit data into a statusline script on every interaction. The script writes to `/tmp/token-visualizer-usage.json`, and the app watches that file for instant updates.

2. **OAuth API** — Polls `https://api.anthropic.com/api/oauth/usage` every 5 minutes using your OAuth token from macOS Keychain. This covers periods when Claude Code isn't actively running.

## Requirements

- macOS 14 (Sonoma) or later
- Claude Code with an active Pro or Max subscription
- OAuth credentials stored in Keychain (automatic if you're logged into Claude Code)

## Setup

### Build

```bash
brew install xcodegen
xcodegen generate
xcodebuild -project TokenVisualizer.xcodeproj -scheme TokenVisualizer -configuration Release build
```

### Install

Copy the built app to Applications:

```bash
cp -R ~/Library/Developer/Xcode/DerivedData/TokenVisualizer-*/Build/Products/Release/TokenVisualizer.app /Applications/
```

### Statusline Integration

Add the following to your `~/.claude/statusline-command.sh` to enable real-time updates:

```bash
# Write rate_limits to file for TokenVisualizer menu bar app
rate_limits=$(echo "$input" | jq -c '.rate_limits // empty')
if [ -n "$rate_limits" ] && [ "$rate_limits" != "null" ]; then
  echo "$rate_limits" > /tmp/token-visualizer-usage.json
fi
```

## Project Structure

```
TokenVisualizer/
├── TokenVisualizerApp.swift          # App entry, MenuBarExtra
├── Views/
│   ├── UsagePopover.swift            # Main popover content
│   └── UsageBar.swift                # Color-coded progress bar
├── Models/
│   ├── UsageData.swift               # API response models
│   └── Credentials.swift             # OAuth credential model
├── Services/
│   ├── KeychainService.swift         # Reads OAuth token from Keychain
│   ├── UsageAPIService.swift         # Fetches usage from Anthropic API
│   ├── StatuslineWatcher.swift       # Watches statusline file for changes
│   └── LaunchAtLogin.swift           # SMAppService wrapper
└── Assets.xcassets/
```

## License

MIT
