# CLAUDE.md

Hướng dẫn cho Claude khi làm việc trong repo này.

## Dự án

App macOS SwiftUI ép kỷ luật giờ nghỉ: cảnh báo notification + auto shutdown qua LaunchDaemon. Xem `README.md` để biết tổng quan tính năng và kiến trúc file.

## Build / chạy

- Dùng Xcode (`discipline_locker.xcodeproj`) — không có CLI build script. Nếu cần build headless: `xcodebuild -project discipline_locker.xcodeproj -scheme discipline_locker build`.
- Không có test target.
- Target: macOS, SwiftUI, yêu cầu Swift có `@Observable` (Swift 5.9+) và `Observation` framework.

## Quy ước code

- **State management**: dùng `@Observable` macro (không dùng `ObservableObject`/`@Published`). Inject qua `.environment(store)` và đọc bằng `@Environment(ScheduleStore.self)`.
- **Persistence**: schedules + flags lưu trong `UserDefaults` (key: `daySchedules`, `isActive`, `hideFromDock`). Không có Core Data/SwiftData.
- **Concurrency**: dùng Swift Concurrency (`Task`, `async/await`). `ShutdownDaemonManager` là `enum` với static methods đánh dấu `nonisolated`.
- **UI**: SwiftUI thuần, không UIKit/AppKit view (nhưng có dùng `NSApp.setActivationPolicy` cho dock hiding).

## Điểm cần cẩn thận

### LaunchDaemon / quyền admin

- `ShutdownDaemonManager.install` ghi plist vào `/Library/LaunchDaemons/socfam.discipline-locker.shutdown.plist` bằng `osascript do shell script ... with administrator privileges` → sẽ bật prompt nhập mật khẩu macOS.
- Plist được truyền qua shell bằng **base64** để tránh escape hell. Khi sửa `buildPlist`, không cần lo quote shell — chỉ cần XML hợp lệ.
- Label daemon: `socfam.discipline-locker.shutdown`. Đổi label = phải đổi cả `plistPath` và `launchctl bootout` command.
- `launchctl bootstrap/bootout` (macOS 10.11+) — không dùng `launchctl load/unload` (deprecated).

### Dev mode vs production

`ShutdownDaemonManager.buildPlist` hard-code `ProgramArguments = [/sbin/shutdown, -h, now]`. Khi test trên máy thật mà chưa sẵn sàng để bị shutdown: tạm đổi sang `/usr/bin/logger` với message để verify daemon có fire đúng giờ (xem log: `log show --predicate 'process == "logger"' --last 1h`). **Đừng quên đổi lại trước khi commit.**

### Weekday mapping

`Weekday.sunday = 0`, còn `Calendar.weekday` của Apple trả 1-based với Sunday=1. Convert qua `Weekday.from(calendarWeekday:)` (đã trừ 1). LaunchDaemon `StartCalendarInterval.Weekday` cũng theo chuẩn Sunday=0, Saturday=6 — vừa khớp với `rawValue` của enum này nên `s.day.rawValue` ghi thẳng vào plist được.

### Sync state App ↔ Daemon

`discipline_lockerApp.syncState()` gọi khi app mở: nếu daemon có trên disk mà `isActive=false` (hoặc ngược lại) thì sync theo disk. Nghĩa là **source of truth cho "active" là sự tồn tại của plist**, không phải `UserDefaults`.

## Git

- `.gitignore` đã cover `xcuserdata/`, `.DS_Store`, build artifacts. Đừng commit lại các file trong `xcuserdata/`.
- Không có remote được cấu hình (tại thời điểm setup).

## Khi sửa code

- Sửa `DaySchedule` struct → phải cân nhắc migration trong `ScheduleStore.init` (hiện fallback về `defaultSchedules()` khi decode fail, nên thêm field optional thì an toàn).
- Sửa `buildPlist` → test install thủ công và check `sudo launchctl print system/socfam.discipline-locker.shutdown` để verify daemon load được.
- Thêm notification mới trong `AlertManager` → chú ý flag `notified10Min`/`notified5Min` được reset khi `remaining > 600`; nếu thêm mốc khác, thêm flag tương ứng và reset cùng chỗ.
