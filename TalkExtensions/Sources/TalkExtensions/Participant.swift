import Foundation
import ChatModels

public extension Participant {
    var notSeenString: String? {
        if let notSeenDuration = notSeenDuration {
            let milisecondIntervalDate = Date().millisecondsSince1970 - Int64(notSeenDuration)
            return Date(milliseconds: milisecondIntervalDate).timeAgoSinceDateCondense
        } else {
            return nil
        }
    }
}
