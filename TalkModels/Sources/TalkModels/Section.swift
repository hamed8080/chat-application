import Foundation
public struct Section: Hashable, Identifiable {
    public var id = UUID()
    public var title: String
    public var items: [SideBarItem]

    public init(id: UUID = UUID(), title: String, items: [SideBarItem]) {
        self.id = id
        self.title = title
        self.items = items
    }
}
