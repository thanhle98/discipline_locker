import SwiftUI

struct DayScheduleRow: View {
    @Binding var schedule: DaySchedule

    var body: some View {
        HStack(spacing: 16) {
            Toggle(isOn: $schedule.isEnabled) {
                Text(schedule.day.fullName)
                    .frame(width: 100, alignment: .leading)
                    .font(schedule.isEnabled ? .body.bold() : .body)
            }
            .toggleStyle(.checkbox)

            if schedule.isEnabled {
                Picker("Hour", selection: $schedule.hour) {
                    ForEach(0..<24, id: \.self) { h in
                        Text(String(format: "%02d", h)).tag(h)
                    }
                }
                .labelsHidden()
                .frame(width: 60)

                Text(":")

                Picker("Minute", selection: $schedule.minute) {
                    ForEach(Array(stride(from: 0, to: 60, by: 5)), id: \.self) { m in
                        Text(String(format: "%02d", m)).tag(m)
                    }
                }
                .labelsHidden()
                .frame(width: 60)
            } else {
                Text("--:--")
                    .foregroundStyle(.secondary)
            }

            Spacer()
        }
        .padding(.vertical, 4)
    }
}
