import Foundation
import Combine

@MainActor
final class ClosetViewModel: ObservableObject {
    @Published var clothingList: [ClothingEntity] = []
    @Published var outfits: [OutfitEntity] = []
    @Published var selectedCategory: ClothingCategory?
    @Published var selectedSubCategory: String?
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let addClothingUseCase: AddClothingUseCase
    private let getClothingListUseCase: GetClothingListUseCase
    private let deleteClothingUseCase: DeleteClothingUseCase
    private let updateClothingUseCase: UpdateClothingUseCase
    private let addOutfitUseCase: AddOutfitUseCase
    private let getOutfitListUseCase: GetOutfitListUseCase
    private let updateOutfitUseCase: UpdateOutfitUseCase
    private let deleteOutfitUseCase: DeleteOutfitUseCase

    init(
        addClothingUseCase: AddClothingUseCase,
        getClothingListUseCase: GetClothingListUseCase,
        deleteClothingUseCase: DeleteClothingUseCase,
        updateClothingUseCase: UpdateClothingUseCase,
        addOutfitUseCase: AddOutfitUseCase,
        getOutfitListUseCase: GetOutfitListUseCase,
        updateOutfitUseCase: UpdateOutfitUseCase,
        deleteOutfitUseCase: DeleteOutfitUseCase
    ) {
        self.addClothingUseCase = addClothingUseCase
        self.getClothingListUseCase = getClothingListUseCase
        self.deleteClothingUseCase = deleteClothingUseCase
        self.updateClothingUseCase = updateClothingUseCase
        self.addOutfitUseCase = addOutfitUseCase
        self.getOutfitListUseCase = getOutfitListUseCase
        self.updateOutfitUseCase = updateOutfitUseCase
        self.deleteOutfitUseCase = deleteOutfitUseCase
    }

    var filteredList: [ClothingEntity] {
        var list = clothingList
        if let category = selectedCategory {
            list = list.filter { $0.category == category }
        }
        if let sub = selectedSubCategory {
            list = list.filter { $0.subCategory == sub }
        }
        return list
    }

    var availableSubCategories: [String] {
        guard let category = selectedCategory else { return [] }
        let existing = Set(clothingList
            .filter { $0.category == category && !$0.subCategory.isEmpty }
            .map { $0.subCategory })
        return category.subCategories.filter { existing.contains($0) }
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

    func deleteClothing(id: UUID) async {
        do {
            try await deleteClothingUseCase.execute(id: id)
            await loadClothing()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveBackgroundRemovedURL(_ path: String, for id: UUID) async {
        guard let idx = clothingList.firstIndex(where: { $0.id == id }) else { return }
        clothingList[idx].backgroundRemovedImageURL = path
        do { try await updateClothingUseCase.execute(clothingList[idx]) } catch {}
    }

    func updateClothing(_ clothing: ClothingEntity) async {
        do {
            try await updateClothingUseCase.execute(clothing)
            await loadClothing()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func loadOutfits() async {
        do {
            outfits = try await getOutfitListUseCase.execute()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func saveOutfit(_ outfit: OutfitEntity) async {
        do {
            try await addOutfitUseCase.execute(outfit)
            await loadOutfits()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func updateOutfit(_ outfit: OutfitEntity) async {
        do {
            try await updateOutfitUseCase.execute(outfit)
            await loadOutfits()
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func deleteOutfit(id: UUID) async {
        do {
            try await deleteOutfitUseCase.execute(id: id)
            await loadOutfits()
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
