import SwiftUI

struct MainTabView: View {
    var body: some View {
        TabView {
            HomeView()
                .tabItem { Image(systemName: "house.fill") }

            CalendarView()
                .tabItem { Image(systemName: "calendar") }

            ClosetView()
                .tabItem { Image(systemName: "tshirt.fill") }

            AnalysisView()
                .tabItem { Image(systemName: "chart.bar.fill") }

            ProfileView()
                .tabItem { Image(systemName: "person.fill") }
        }
        .background(TabBarIconConfigurator())
    }
}

// UITabBarController에 직접 접근해 아이콘 크기 설정
private struct TabBarIconConfigurator: UIViewControllerRepresentable {
    func makeUIViewController(context: Context) -> TabBarIconController {
        TabBarIconController()
    }
    func updateUIViewController(_ controller: TabBarIconController, context: Context) {
        controller.configure()
    }
}

private final class TabBarIconController: UIViewController {
    private let iconNames = ["house.fill", "calendar", "tshirt.fill", "chart.bar.fill", "person.fill"]

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        configure()
    }

    func configure() {
        guard let items = tabBarController?.tabBar.items else { return }
        let config = UIImage.SymbolConfiguration(pointSize: 26, weight: .medium)
        zip(items, iconNames).forEach { item, name in
            let image = UIImage(systemName: name, withConfiguration: config)
            item.image = image
            item.selectedImage = image
            item.title = nil
        }
    }
}

#Preview {
    MainTabView()
}
