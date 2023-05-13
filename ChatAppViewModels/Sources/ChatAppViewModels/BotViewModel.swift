//
//  BotViewModel.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import Combine
import ChatModels
import ChatCore
import SwiftUI
import ChatAppModels

public final class BotViewModel: ObservableObject {
    @Published public var bots: [BotInfo] = []
    @Published public var selectedBot: BotInfo?
    @Published public var isLoading = false
    public private(set) var cancellableSet: Set<AnyCancellable> = []
    public private(set) var firstSuccessResponse = false

    public init() {
        AppState.shared.$connectionStatus
            .sink(receiveValue: onConnectionStatusChanged)
            .store(in: &cancellableSet)
        getBotList()
    }

    public func onConnectionStatusChanged(_ status: Published<ConnectionStatus>.Publisher.Output) {
        if firstSuccessResponse == false, status == .connected {
            getBotList()
        }
    }

    public func onServerResponse(_ response: ChatResponse<[BotInfo]>) {
        if let bots = response.result {
            firstSuccessResponse = true
            appendBots(bots: bots)
        }
        isLoading = false
    }

    public func getBotList() {
        ChatManager.activeInstance?.getUserBots(.init(), completion: onServerResponse)
    }

    public func stopBot(_ bot: BotInfo, threadId: Int) {
        guard let name = bot.name else { return }
        ChatManager.activeInstance?.stopBot(.init(botName: name, threadId: threadId)) { [weak self] response in
            if response.result != nil, let self = self {
                self.removeBot(bot)
            }
        }
    }

    public func startBot(_ bot: BotInfo, threadId: Int) {
        guard let name = bot.name else { return }
        ChatManager.activeInstance?.startBot(.init(botName: name, threadId: threadId)) { [weak self] response in
            if response.result != nil, let self = self {
                self.removeBot(bot)
            }
        }
    }

    public func refresh() {
        clear()
        getBotList()
    }

    public func clear() {
        bots = []
        selectedBot = nil
    }

    public func createBot(name: String) {
        isLoading = true
        ChatManager.activeInstance?.createBot(.init(botName: name)) { [weak self] response in
            if response.result != nil, let self = self {
                self.appendBots(bots: [.init(name: name, botUserId: AppState.shared.user?.id)])
            }
            self?.isLoading = false
        }
    }

    public func appendBots(bots: [BotInfo]) {
        // remove older data to prevent duplicate on view
        bots.forEach { bot in
            if let oldIndex = self.bots.firstIndex(where: { $0.botUserId == bot.botUserId }) {
                self.bots[oldIndex] = bot
            } else {
                self.bots.append(bot)
            }
        }
    }

    public func setSelectedBot(bot: BotInfo?, isSelected _: Bool) {
        selectedBot = bot
    }

    public func removeBot(_ bot: BotInfo) {
        bots.removeAll(where: { $0.botUserId == bot.botUserId })
    }

}
