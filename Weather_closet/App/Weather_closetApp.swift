import SwiftUI

@main
struct Weather_closetApp: App {
    @StateObject private var coordinator = AppCoordinator()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(coordinator.homeViewModel)
                .environmentObject(coordinator.calendarViewModel)
                .environmentObject(coordinator.closetViewModel)
                .environmentObject(coordinator.analysisViewModel)
                .environmentObject(coordinator.profileViewModel)
        }
    }
}
