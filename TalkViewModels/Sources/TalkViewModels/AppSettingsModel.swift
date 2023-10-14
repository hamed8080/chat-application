//
//  AppSettingsModel.swift
//  TalkViewModels
//
//  Created by hamed on 10/22/22.
//
import Foundation
import Combine

public struct AppSettingsModel: Codable, Hashable {
    public static func == (lhs: AppSettingsModel, rhs: AppSettingsModel) -> Bool {
        lhs.hashValue == rhs.hashValue
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(isSyncOn)
        hasher.combine(notificationSettings.data)
    }
    static let key = "AppSettingsKey"
    public var isSyncOn: Bool = false
    public var notificationSettings: NotificationSettingModel = .init()

    public func save() {
        UserDefaults.standard.setValue(codable: self, forKey: AppSettingsModel.key)
    }

    public static func restore() -> AppSettingsModel {
        let value: AppSettingsModel? = UserDefaults.standard.codableValue(forKey: AppSettingsModel.key)
        return value ?? .init()
    }
}

public struct NotificationSettingModel: Codable {
    public var soundEnable: Bool = true
    public var showDetails: Bool = true
    public var vibration: Bool = true
    public var privateChat: ChatSettings = .init()
    public var channel: ChannelSettings = .init()
    public var group: GroupSettings = .init()

    public struct ChatSettings: Codable {
        public var showNotification: Bool = true
        public var sound = true
    }

    public struct ChannelSettings: Codable {
        public  var showNotification: Bool = false
        public  var sound = false
    }

    public struct GroupSettings: Codable {
        public var showNotification: Bool = false
        public var sound = false
    }

    public func reset() {

    }
}
