//
//  UserDefaultsEX.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 11/22/21.
//

import Foundation
extension UserDefaults {
    static let group = UserDefaults(suiteName: AppGroup.group)

    func setValue(codable: Codable, forKey: String) {
        if let data = try? JSONEncoder().encode(codable) {
            setValue(data, forKey: forKey)
        }
    }

    func codableValue<T: Codable>(forKey: String) -> T? {
        if let data = value(forKey: forKey) as? Data, let codable = try? JSONDecoder().decode(T.self, from: data) {
            return codable
        } else { return nil }
    }
}
