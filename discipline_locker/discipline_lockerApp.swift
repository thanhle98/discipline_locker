import SwiftUI

@main
struct discipline_lockerApp: App {
    @State private var store = ScheduleStore()
    @State private var alertManager = AlertManager()

    var body: some Scene {
        Window("Discipline Locker", id: "settings") {
            ContentView()
                .environment(store)
                .onAppear {
                    syncState()
                    store.applyDockPolicy()
                    if store.isActive {
                        alertManager.start(store: store)
                    }
                }
                .onChange(of: store.isActive) { _, isActive in
                    if isActive {
                        alertManager.start(store: store)
                    } else {
                        alertManager.stop()
                    }
                }
        }
        .windowResizability(.contentSize)
        .defaultPosition(.center)

        MenuBarExtra {
            MenuBarPopover()
                .environment(store)
        } label: {
            Image(systemName: store.isActive ? "lock.fill" : "lock.open")
        }
        .menuBarExtraStyle(.window)
    }

    private func syncState() {
        if ShutdownDaemonManager.isInstalled() && !store.isActive {
            store.isActive = true
        } else if !ShutdownDaemonManager.isInstalled() && store.isActive {
            store.isActive = false
        }
    }
}
