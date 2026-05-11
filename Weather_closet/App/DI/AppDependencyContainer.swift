import Foundation

@MainActor
final class AppDependencyContainer {

    // MARK: - Infrastructure
    private lazy var apiClient = APIClient()
    private lazy var persistenceStack = PersistenceStack()

    // MARK: - Data Sources
    private lazy var weatherRemoteDataSource = WeatherRemoteDataSource(apiClient: apiClient)
    private lazy var closetLocalDataSource = ClosetLocalDataSource(persistence: persistenceStack)
    private lazy var userLocalDataSource = UserLocalDataSource(persistence: persistenceStack)
    private lazy var calendarLocalDataSource = CalendarLocalDataSource(persistence: persistenceStack)

    // MARK: - Repositories
    private lazy var weatherRepository: WeatherRepositoryProtocol =
        WeatherRepository(remoteDataSource: weatherRemoteDataSource)
    private lazy var closetRepository: ClosetRepositoryProtocol =
        ClosetRepository(localDataSource: closetLocalDataSource)
    private lazy var calendarRepository: CalendarRepositoryProtocol =
        CalendarRepository(localDataSource: calendarLocalDataSource)
    private lazy var userRepository: UserRepositoryProtocol =
        UserRepository(localDataSource: userLocalDataSource)

    // MARK: - Use Cases
    private lazy var fetchWeatherUseCase = FetchWeatherUseCase(repository: weatherRepository)
    private lazy var checkUmbrellaUseCase = CheckUmbrellaUseCase(repository: weatherRepository)
    private lazy var addClothingUseCase = AddClothingUseCase(repository: closetRepository)
    private lazy var getClothingListUseCase = GetClothingListUseCase(repository: closetRepository)
    private lazy var recordOutfitUseCase = RecordOutfitUseCase(repository: calendarRepository)
    private lazy var getCalendarEventsUseCase = GetCalendarEventsUseCase(repository: calendarRepository)
    private lazy var getAnalysisUseCase = GetAnalysisUseCase(
        closetRepository: closetRepository,
        calendarRepository: calendarRepository
    )

    // MARK: - ViewModels
    func makeHomeViewModel() -> HomeViewModel {
        HomeViewModel(
            fetchWeatherUseCase: fetchWeatherUseCase,
            checkUmbrellaUseCase: checkUmbrellaUseCase
        )
    }

    func makeCalendarViewModel() -> CalendarViewModel {
        CalendarViewModel(
            recordOutfitUseCase: recordOutfitUseCase,
            getCalendarEventsUseCase: getCalendarEventsUseCase
        )
    }

    func makeClosetViewModel() -> ClosetViewModel {
        ClosetViewModel(
            addClothingUseCase: addClothingUseCase,
            getClothingListUseCase: getClothingListUseCase
        )
    }

    func makeAnalysisViewModel() -> AnalysisViewModel {
        AnalysisViewModel(getAnalysisUseCase: getAnalysisUseCase)
    }

    func makeProfileViewModel() -> ProfileViewModel {
        ProfileViewModel(userRepository: userRepository)
    }
}
