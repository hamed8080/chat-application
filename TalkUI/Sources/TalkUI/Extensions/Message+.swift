import SwiftUI
import ChatModels

public extension Message {
    static let clockImage = UIImage(named: "clock")
    static let sentImage = UIImage(named: "single_chekmark")
    static let seenImage = UIImage(named: "double_checkmark")
    static let leadingTail = UIImage(named: "leading_tail")!
    static let trailingTail = UIImage(named: "trailing_tail")!

    var footerStatus: (image: UIImage, fgColor: Color) {
        if seen == true {
            return (Message.seenImage!, Color.main)
        } else if delivered == true {
            return (Message.seenImage!, Color.hint)
        } else if id != nil {
            return (Message.sentImage!, Color.main)
        } else {
            return (Message.clockImage!, Color.main)
        }
    }
}
