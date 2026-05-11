import Foundation
import Combine

@MainActor
final class AnalysisViewModel: ObservableObject {
    @Published var analysisResult: AnalysisResult?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let getAnalysisUseCase: GetAnalysisUseCase

    init(getAnalysisUseCase: GetAnalysisUseCase) {
        self.getAnalysisUseCase = getAnalysisUseCase
    }

    func loadAnalysis() async {
        isLoading = true
        do {
            analysisResult = try await getAnalysisUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }
}
