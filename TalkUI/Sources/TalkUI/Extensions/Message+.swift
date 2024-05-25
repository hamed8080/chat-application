import SwiftUI
import ChatModels

public extension Message {
    static let clockImage = UIImage(named: "clock")
    static let sentImage = UIImage(named: "ic_single_check_mark")
    static let seenImage = UIImage(named: "ic_double_check_mark")
    static let leadingTail = UIImage(named: "leading_tail")!
    static let trailingTail = UIImage(named: "trailing_tail")!
    static let emptyImage = UIImage(named: "empty_image")!

    var footerStatus: (image: UIImage, fgColor: Color) {
        if seen == true {
            return (Message.seenImage!, Color.App.accent)
//        } else if delivered == true {
//            return (Message.seenImage!, Color.App.textPrimary.opacity(0.6))
        } else if id != nil {
            return (Message.sentImage!, Color.App.textPrimary.opacity(0.6))
        } else {
            return (Message.clockImage!, Color.App.textPrimary.opacity(0.6))
        }
    }

    var uiFooterStatus: (image: UIImage, fgColor: UIColor) {
        if seen == true {
            return (Message.seenImage!, Color.App.textPrimaryUIColor!)
        } else if delivered == true {
            return (Message.seenImage!, Color.App.textSecondaryUIColor!)
        } else if id != nil {
            return (Message.sentImage!, Color.App.textSecondaryUIColor!)
        } else {
            return (Message.clockImage!, Color.App.textSecondaryUIColor!)
        }
    }
}
