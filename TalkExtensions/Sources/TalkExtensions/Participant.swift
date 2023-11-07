import Foundation
import ChatModels

public extension Participant {
    var toContact: Contact {
        Contact(blocked: blocked,
                cellphoneNumber: cellphoneNumber,
                email: email,
                firstName: firstName,
                id: contactId,
                image: image,
                lastName: lastName,
                user: .init(
                    cellphoneNumber: cellphoneNumber,
                    coreUserId: coreUserId,
                    email: email,
                    id: id,
                    image: image,
                    name: name,
                    receiveEnable: receiveEnable,
                    sendEnable: sendEnable,
                    username: username,
                    ssoId: ssoId,
                    firstName: firstName,
                    lastName: lastName
                ),
                notSeenDuration: notSeenDuration
        )
    }
}
