import Foundation
import Combine

@MainActor
final class ClosetViewModel: ObservableObject {
    @Published var clothingList: [ClothingEntity] = []
    @Published var outfits: [OutfitEntity] = []
    @Published var selectedCategory: ClothingCategory?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let addClothingUseCase: AddClothingUseCase
    private let getClothingListUseCase: GetClothingListUseCase

    init(addClothingUseCase: AddClothingUseCase, getClothingListUseCase: GetClothingListUseCase) {
        self.addClothingUseCase = addClothingUseCase
        self.getClothingListUseCase = getClothingListUseCase
    }

    var filteredList: [ClothingEntity] {
        guard let category = selectedCategory else { return clothingList }
        return clothingList.filter { $0.category == category }
    }

    func loadClothing() async {
        isLoading = true
        do {
            clothingList = try await getClothingListUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
        isLoading = false
    }

    func addClothing(_ clothing: ClothingEntity) async {
        do {
            try await addClothingUseCase.execute(clothing)
            await loadClothing()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
