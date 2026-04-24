# Discipline Locker

A macOS app that enforces work-hour discipline: **warns before cutoff** and **auto shuts down** your Mac at a scheduled time for each day of the week. No snooze, no dismissing — the shutdown is fired by a system-level LaunchDaemon, so it runs even if the app is closed.

## Features

- Per-day shutdown schedule (Mon–Sun), each day independently on/off
- Notification warnings at **10 minutes** and **5 minutes** before shutdown
- Shutdown executed by `launchd` (`/sbin/shutdown -h now`) — persists across app quits and reboots
- Menu bar extra showing current lock state (🔒 / 🔓)
- Option to hide the app from the Dock (menu-bar-only mode)

## Architecture

| File | Role |
|---|---|
| `discipline_lockerApp.swift` | Entry point, sets up Window + MenuBarExtra |
| `ScheduleStore.swift` | State + persistence via `UserDefaults` |
| `DaySchedule.swift` | Model for a single day (weekday, hour, minute, enabled) |
| `AlertManager.swift` | 30s polling timer that fires the 10-min / 5-min notifications |
| `ShutdownDaemonManager.swift` | Installs/uninstalls the LaunchDaemon via `osascript` (requires admin) |
| `ContentView.swift` / `MenuBarPopover.swift` / `DayScheduleRow.swift` | SwiftUI views |

The LaunchDaemon is written to:
```
/Library/LaunchDaemons/socfam.discipline-locker.shutdown.plist
```
with label `socfam.discipline-locker.shutdown`.

## Build & run

- Requires: macOS + Xcode (Swift 5.9+, SwiftUI, `@Observable`)
- Open `discipline_locker.xcodeproj` → Run
- The first time you activate a schedule, macOS will prompt for your admin password to install the LaunchDaemon.

## Dev vs production

In `ShutdownDaemonManager.buildPlist`, `ProgramArguments` is currently set to:

```swift
<string>/sbin/shutdown</string>
<string>-h</string>
<string>now</string>
```

For safe local testing (without actually shutting down), swap to `/usr/bin/logger` with a message and tail the log via:

```sh
log show --predicate 'process == "logger"' --last 1h
```

Revert before committing.

## Uninstalling the daemon manually

If you need to remove the daemon without the app:
```sh
sudo launchctl bootout system/socfam.discipline-locker.shutdown
sudo rm /Library/LaunchDaemons/socfam.discipline-locker.shutdown.plist
```
