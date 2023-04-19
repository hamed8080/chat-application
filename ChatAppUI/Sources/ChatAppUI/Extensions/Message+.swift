import SwiftUI
import ChatExtensions
import ChatModels

public extension Message {
    static let clockImage = UIImage(named: "clock")
    static let sentImage = UIImage(named: "single_chekmark")
    static let seenImage = UIImage(named: "double_checkmark")

    var footerStatus: (image: UIImage, fgColor: Color) {
        if seen == true {
            return (Message.seenImage!, .darkGreen.opacity(0.8))
        } else if delivered == true {
            return (Message.seenImage!, Color.gray)
        } else if id != nil {
            return (Message.sentImage!, .darkGreen.opacity(0.8))
        } else {
            return (Message.clockImage!, .darkGreen.opacity(0.8))
        }
    }
}
