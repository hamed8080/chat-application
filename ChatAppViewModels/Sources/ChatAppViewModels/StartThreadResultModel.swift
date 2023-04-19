import Combine
import Chat
import ChatModels
import ChatExtensions
import Foundation

public class StartThreadResultModel: ObservableObject {
    @Published public var selectedContacts: [Contact]
    @Published public var type: ThreadTypes
    @Published public var title: String
    @Published public var isPublic: Bool
    @Published public var isGroup: Bool
    @Published public var isInMultiSelectMode: Bool
    @Published public var isPublicNameAvailable: Bool
    @Published public var isCehckingName: Bool = false
    public var showGroupTitleView: Bool { isGroup || type == .channel }
    public var hasError: Bool { !titleIsValid }
    public private(set) var canceableSet: Set<AnyCancellable> = []

    public init(selectedContacts: [Contact] = [],
         type: ThreadTypes = .normal,
         title: String = "",
         isPublic: Bool = false,
         isGroup: Bool = false,
         isInMultiSelectMode: Bool = false,
         isPublicNameAvailable: Bool = false)
    {
        self.selectedContacts = selectedContacts
        self.type = type
        self.title = title
        self.isPublic = isPublic
        self.isGroup = isGroup
        self.isInMultiSelectMode = isInMultiSelectMode
        self.isPublicNameAvailable = isPublicNameAvailable

        $title
            .debounce(for: 0.5, scheduler: RunLoop.main)
            .filter { $0.count > 1 }
            .removeDuplicates()
            .sink { [weak self] publicName in
                self?.checkPublicName(publicName)
            }
            .store(in: &canceableSet)
    }

    public var titleIsValid: Bool {
        if showGroupTitleView, title.isEmpty { return false }
        if !isPublic { return true }
        let regex = try! Regex("^[a-zA-Z0-9]\\S*$")
        return title.contains(regex)
    }

    public var computedType: ThreadTypes {
        if !isPublic {
            return type
        } else if type == .channel, isPublic {
            return .publicChannel
        } else if isGroup, isPublic {
            return .publicGroup
        } else {
            return .normal
        }
    }

    public var build: StartThreadResultModel { StartThreadResultModel(selectedContacts: selectedContacts, type: computedType, title: showGroupTitleView ? title : "", isPublic: isPublic, isGroup: isGroup) }

    public func setSelfThread() {
        type = .selfThread
        resetSelection()
    }

    public func toggleGroup() {
        if isGroup {
            resetSelection()
        } else {
            isInMultiSelectMode = true
            isGroup = true
            type = .normal
        }
    }

    public func toggleChannel() {
        if type == .channel {
            type = .normal
            resetSelection()
        } else {
            type = .channel
            isInMultiSelectMode = true
        }
    }

    public func resetSelection() {
        selectedContacts = []
        isInMultiSelectMode = false
        isGroup = false
        isPublic = false
    }

    public func checkPublicName(_ title: String) {
        if titleIsValid {
            isCehckingName = true
            ChatManager.activeInstance?.isThreadNamePublic(.init(name: title)) { [weak self] result in
                if title == result.result?.name {
                    self?.isPublicNameAvailable = true
                }
                self?.isCehckingName = false
            }
        }
    }
}
