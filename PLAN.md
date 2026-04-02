# Token Visualizer — macOS Menu Bar App

## What

A native macOS menu bar app that shows Claude Code rate limit usage at a glance — session %, weekly %, reset timers. Inspired by Tokenio.

## Data Source

- **OAuth Usage API:** `GET https://api.anthropic.com/api/oauth/usage`
- Auth via OAuth token stored in macOS Keychain (`"Claude Code-credentials"`)
- Returns `five_hour` (session) and `seven_day` (weekly) with `utilization` (0-100) and `resets_at` (ISO8601)
- Poll every 5 min with cache to avoid 429s (endpoint rate limits aggressively)

## Tech Stack

| Choice | Rationale |
|--------|-----------|
| Swift + SwiftUI | Native macOS, small binary, direct Keychain/MenuBarExtra access |
| macOS 14+ (Sonoma) | MenuBarExtra API, modern SwiftUI features |
| No external deps | Foundation + Security + SwiftUI cover everything |

## MVP Features

1. **Menu bar icon** with color based on highest usage (green/yellow/red)
2. **Click popover** showing:
   - Current session — % bar + "Resets in Xh Ym"
   - Weekly all models — % bar + "Resets in Xd Yh"
3. **Auto-refresh** every 5 min + "Updated X mins ago" label
4. **Manual refresh** button
5. **Launch at Login** toggle
6. **Quit** button

## Color Thresholds

| Range | Color |
|-------|-------|
| 0–49% | Green |
| 50–79% | Yellow/Orange |
| 80–100% | Red |

## File Structure

```
TokenVisualizer/
├── TokenVisualizerApp.swift       # App entry, MenuBarExtra
├── Views/
│   ├── MenuBarIcon.swift          # Dynamic menu bar icon
│   ├── UsagePopover.swift         # Main popover content
│   └── UsageBar.swift             # Reusable progress bar component
├── Models/
│   ├── UsageData.swift            # API response model
│   └── Credentials.swift          # OAuth token model
├── Services/
│   ├── KeychainService.swift      # Read OAuth token from Keychain
│   ├── UsageAPIService.swift      # Fetch from /api/oauth/usage
│   └── TokenRefreshService.swift  # Handle token refresh
├── Info.plist
└── Assets.xcassets
```

## Build Order

1. Xcode project setup (SwiftUI, menu bar only)
2. KeychainService — read + parse OAuth credentials
3. UsageAPIService — fetch + cache usage data
4. UsageBar — reusable colored progress bar
5. UsagePopover — compose bars + reset timers
6. MenuBarExtra — icon + popover wiring
7. Auto-refresh timer
8. Launch at Login (SMAppService)
9. UI polish — dark theme matching inspo

## Post-MVP

- Notifications at 80%/95% thresholds
- Historical chart from `~/.claude/stats-cache.json`
- Keyboard shortcut to toggle popover
- Extra usage / cost display (for Max plan users)
