import Foundation

@MainActor
final class AppCoordinator: ObservableObject {
    private let container: AppDependencyContainer

    let homeViewModel: HomeViewModel
    let calendarViewModel: CalendarViewModel
    let closetViewModel: ClosetViewModel
    let analysisViewModel: AnalysisViewModel
    let profileViewModel: ProfileViewModel

    init() {
        let c = AppDependencyContainer()
        container = c
        homeViewModel = c.makeHomeViewModel()
        calendarViewModel = c.makeCalendarViewModel()
        closetViewModel = c.makeClosetViewModel()
        analysisViewModel = c.makeAnalysisViewModel()
        profileViewModel = c.makeProfileViewModel()
    }
}
