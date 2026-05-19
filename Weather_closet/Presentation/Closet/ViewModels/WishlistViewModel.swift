import Foundation
import Combine

@MainActor
final class WishlistViewModel: ObservableObject {
    @Published var items: [WishlistItemEntity] = []
    @Published var isLoading = false
    @Published var errorMessage: String?

    private let getWishlistUseCase: GetWishlistUseCase
    private let addWishlistItemUseCase: AddWishlistItemUseCase
    private let updateWishlistItemUseCase: UpdateWishlistItemUseCase
    private let deleteWishlistItemUseCase: DeleteWishlistItemUseCase

    init(
        getWishlistUseCase: GetWishlistUseCase,
        addWishlistItemUseCase: AddWishlistItemUseCase,
        updateWishlistItemUseCase: UpdateWishlistItemUseCase,
        deleteWishlistItemUseCase: DeleteWishlistItemUseCase
    ) {
        self.getWishlistUseCase = getWishlistUseCase
        self.addWishlistItemUseCase = addWishlistItemUseCase
        self.updateWishlistItemUseCase = updateWishlistItemUseCase
        self.deleteWishlistItemUseCase = deleteWishlistItemUseCase
    }

    func load() async {
        isLoading = true
        do { items = try await getWishlistUseCase.execute() }
        catch { errorMessage = error.localizedDescription }
        isLoading = false
    }

    func add(_ item: WishlistItemEntity) async {
        do { try await addWishlistItemUseCase.execute(item); await load() }
        catch { errorMessage = error.localizedDescription }
    }

    func update(_ item: WishlistItemEntity) async {
        do { try await updateWishlistItemUseCase.execute(item); await load() }
        catch { errorMessage = error.localizedDescription }
    }

    func delete(id: UUID) async {
        do { try await deleteWishlistItemUseCase.execute(id: id); await load() }
        catch { errorMessage = error.localizedDescription }
    }

    func move(from source: IndexSet, to destination: Int) async {
        var reordered = items
        reordered.move(fromOffsets: source, toOffset: destination)
        for (idx, var item) in reordered.enumerated() { item.sortOrder = idx; reordered[idx] = item }
        items = reordered
        do { try await updateWishlistItemUseCase.executeOrder(reordered) }
        catch { errorMessage = error.localizedDescription }
    }
}
