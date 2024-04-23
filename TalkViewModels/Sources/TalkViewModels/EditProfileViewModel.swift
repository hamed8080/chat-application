//
//  EditProfileViewModel.swift
//  TalkViewModels
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Foundation
import Chat
import ChatCore
import ChatModels
import UIKit
import Photos
import Combine
import ChatDTO

public final class EditProfileViewModel: ObservableObject {
    @Published public var isLoading: Bool = false
    @Published public var firstName: String = ""
    @Published public var lastName: String = ""
    @Published public var userName: String = ""
    @Published public var bio: String = ""
    @Published public var showImagePicker: Bool = false
    @Published public var dismiss: Bool = false
    public var image: UIImage?
    public var assetResources: [PHAssetResource] = []
    public var temporaryDisable: Bool = true
    private var cancelable: Set<AnyCancellable> = []

    public init() {
        let user = AppState.shared.user
        firstName = user?.name ?? ""
        lastName = user?.lastName ?? ""
        userName = user?.username ?? ""
        bio = user?.chatProfileVO?.bio ?? ""

        NotificationCenter.user.publisher(for: .user)
            .compactMap { $0.object as? UserEventTypes }
            .sink{ [weak self] event in
                if case .setProfile(let response) = event {
                    self?.onUpdateProfile(response)
                }
            }
            .store(in: &cancelable)
    }

    public func submit() {
        let req = UpdateChatProfile(bio: bio)
        RequestsManager.shared.append(prepend: "Update-Thread-Info", value: req)
        ChatManager.activeInstance?.user.set(req)
    }

    private func onUpdateProfile(_ response: ChatResponse<Profile>) {
        self.bio = response.result?.bio ?? ""
        if response.error == nil, response.pop(prepend: "Update-Thread-Info") != nil {
            dismiss = true
        }
    }
}
