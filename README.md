# Discipline Locker

App macOS giúp ép kỷ luật giờ làm việc: **cảnh báo trước giờ nghỉ** và **auto shutdown** máy vào khung giờ đã đặt cho từng ngày trong tuần. Không snooze, không né được — vì shutdown được chạy bởi LaunchDaemon cấp hệ thống.

## Tính năng

- Cấu hình giờ shutdown riêng cho từng ngày (Mon–Sun)
- Cảnh báo notification **10 phút** và **5 phút** trước giờ shutdown
- Shutdown tự động qua `launchd` (`/sbin/shutdown -h now`) — chạy kể cả khi app đã đóng
- Menu bar extra hiển thị trạng thái khóa (🔒 / 🔓)
- Tùy chọn ẩn app khỏi Dock (chỉ chạy ở menu bar)

## Kiến trúc

| File | Vai trò |
|---|---|
| `discipline_lockerApp.swift` | Entry point, quản lý Window + MenuBarExtra |
| `ScheduleStore.swift` | State + persist schedules qua `UserDefaults` |
| `DaySchedule.swift` | Model cho từng ngày (weekday, hour, minute, enabled) |
| `AlertManager.swift` | Timer 30s để bắn notification 10p/5p trước shutdown |
| `ShutdownDaemonManager.swift` | Install/uninstall LaunchDaemon qua `osascript` (cần admin) |
| `ContentView.swift` / `MenuBarPopover.swift` / `DayScheduleRow.swift` | UI SwiftUI |

LaunchDaemon được ghi tại:
```
/Library/LaunchDaemons/socfam.discipline-locker.shutdown.plist
```
với label `socfam.discipline-locker.shutdown`.

## Build & chạy

- Yêu cầu: macOS + Xcode (Swift 5.9+, SwiftUI, `@Observable`)
- Mở `discipline_locker.xcodeproj` → Run
- Khi bật lịch lần đầu, macOS sẽ hỏi mật khẩu admin để cài LaunchDaemon

## Chế độ dev vs production

Trong `ShutdownDaemonManager.buildPlist`, `ProgramArguments` hiện đang dùng:

```swift
<string>/sbin/shutdown</string>
<string>-h</string>
<string>now</string>
```

Nếu muốn test an toàn (không shutdown thật), đổi sang `/usr/bin/logger` với một message và xem log qua `log show --predicate 'process == "logger"'`.

## Gỡ daemon thủ công

Nếu cần xóa daemon khi chưa có app:
```sh
sudo launchctl bootout system/socfam.discipline-locker.shutdown
sudo rm /Library/LaunchDaemons/socfam.discipline-locker.shutdown.plist
```
