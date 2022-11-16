//
//  MockDatas.swift
//  ChatApplication
//
//  Created by hamed on 4/12/22.
//

import Foundation
import FanapPodChatSDK

final class MockData{
    
    ///Threads
    static var thread:Conversation{
        
        let lastMessageVO = Message(
            message: "Hi hamed how are you? are you ok? and what are you ding now. And i was thinking you are sad for my behavoi last night."
        )
        let thread = Conversation(
            description   : "description",
            id            : 123,
            image         : "avatar1",
            pin           : false,
            title         : "Hamed Hosseini",
            type          : ThreadTypes.publicGroup,
            lastMessageVO : lastMessageVO
        )
        return thread
    }
    
    
    static func generateThreads(count:Int = 50)->[Conversation]{
        var threads:[Conversation] = mockDataModel.threads.map { thread in
            thread.lastMessageVO = Message(message:thread.lastMessage)
            return thread
        }
        if threads.count < count{
            var lastIndex = threads.count + 1
            for _ in 0...count{
                let thread             = thread
                thread.title           = mockDataModel.threads[Int.random(in: 1...15)].title
                thread.description     = mockDataModel.threads[Int.random(in: 1...15)].description
                thread.image           = mockDataModel.threads[Int.random(in: 1...15)].image
                thread.lastMessageVO   = Message(message:mockDataModel.threads[Int.random(in: 1...15)].lastMessage ?? "")
                thread.id              = lastIndex
                lastIndex              += 1
                threads.append(thread)
            }
        }
        return threads
    }
    
    ///Contacts
    static var contact:Contact{
        let contact = Contact(
            blocked         : false,
            cellphoneNumber : "+989369161601",
            email           : nil,
            firstName       : "Hamed",
            hasUser         : true,
            id              : 0,
            image           : "avatar4",
            lastName        : "Hosseini",
            linkedUser      : nil,
            notSeenDuration : 1622969881,
            timeStamp       : nil,
            userId          : nil
        )
        return contact
    }
    
    
    static func generateContacts(count:Int = 50)->[Contact]{
        var contacts:[Contact] = mockDataModel.contacts
        
        if contacts.count < count{
            var lastIndex = contacts.count + 2
            for _ in 0...count{
                let contact       = contact
                contact.firstName = mockDataModel.contacts[Int.random(in: 1...15)].firstName
                contact.lastName  = mockDataModel.contacts[Int.random(in: 1...15)].lastName
                contact.image     = mockDataModel.contacts[Int.random(in: 1...15)].image
                contact.id        = lastIndex
                lastIndex         += 1
                contacts.append(contact)
            }
        }
        return contacts
    }
    
    ///Message
    static var message:Message{
        let message = Message(
            threadId    : 0,
            id          : 0,
            message     : "Hello sahdkf ashfdl sad div exit \nHello",
            messageType : .text,
            seen        : false,
            time        : 1636807773
        )
        return message
    }
    
    static var uploadMessage:UploadFileMessage{
        let msg = UploadFileMessage(uploadFileRequest: UploadFileRequest(data: Data()), textMessage: "Test")
        msg.message = "Film.mp4"
        return msg
    }
    
    static func generateMessages(count:Int = 50)->[Message]{
        var messages:[Message] = mockDataModel.messages.map { message in
            message.uniqueId = UUID().uuidString
            return message
        }
        if messages.count < count{
            var lastIndex = messages.count + 1
            for _ in 0...count{
                let message          = message
                message.message      = mockDataModel.messages[Int.random(in: 1...2)].message
                message.time         = UInt.random(in: 0...UInt.max)
                message.ownerId      = lastIndex
                message.id           = lastIndex
                message.uniqueId     = UUID().string
                message.participant  = participant
                lastIndex            += 1
                messages.append(message)
            }
        }
        return messages
    }
    
    ///Participants
    static var participant:Participant{
        let participant = Participant(
            admin            : true,
            cellphoneNumber  : "+989369161601",
            contactFirstName : "Hamed",
            contactName      : "Hamed",
            contactLastName  : "Hosseini",
            firstName        : "Hamed",
            id               : 0,
            image            : "avatar4",
            lastName         : "Hosseini",
            name             : "Hamed",
            online           : true,
            username         : "hamed8080"
        )
        return participant
    }
    
    static func generateParticipants(count:Int = 50)->[Participant]{
        
        var participants:[Participant] = mockDataModel.participants
        
        if participants.count < count{
            var lastIndex = participants.count + 1
            for _ in 0...count{
                let participant       = participant
                participant.firstName = mockDataModel.participants[Int.random(in: 1...15)].firstName
                participant.lastName  = mockDataModel.participants[Int.random(in: 1...15)].lastName
                participant.image     = mockDataModel.participants[Int.random(in: 1...15)].image
                participant.id        = lastIndex
                lastIndex             += 1
                participants.append(participant)
            }
        }
        return participants
    }
    
    ///TAG
    static var tag:Tag{
        let owner = participant
        let tag = Tag(
            id              : 0,
            name            : "Social",
            owner           : owner,
            active          : true,
            tagParticipants : generateTagParticipant()
        )
        return tag
    }
    
    static func generateTags(count:Int = 50)->[Tag]{
        var tags:[Tag] = []
        for index in 0...count{
            var tag          = tag
            tag.name         = "Tag Name \(index)"
            tag.id           = index
            tag.active       = Bool.random()
            tags.append(tag)
        }
        return tags
    }
    
    ///Tag Participant
    static var tagParticipant:TagParticipant{
        let tagParticipant = TagParticipant(
            id           : 0,
            active       : true,
            tagId        : 0,
            threadId     : thread.id,
            conversation : thread
        )
        return tagParticipant
    }
    
    static func generateTagParticipant(count:Int = 50)->[TagParticipant]{
        var tagParticipants:[TagParticipant] = []
        for index in 0...count{
            let thread = generateThreads().randomElement()
            let tagParticipant = TagParticipant(
                id           : index,
                active       : Bool.random(),
                tagId        : index,
                threadId     : thread?.id,
                conversation : thread
            )
            tagParticipants.append(tagParticipant)
        }
        return tagParticipants
    }
    
    static var mockDataModel:MockDataModel = {
        guard let path = Bundle.main.path(forResource: "MockData", ofType: ".json") else{
            return MockDataModel(threads:[], messages:[], contacts:[], tags:[], participants:[])
        }
        let data = try! Data(contentsOf: URL(fileURLWithPath: path), options: .mappedIfSafe)
        return try! JSONDecoder().decode(MockDataModel.self, from: data)
    }()
    
}

struct MockDataModel :Decodable{
    let threads:[Conversation]
    let messages:[Message]
    let contacts:[Contact]
    let tags:[Tag]
    let participants:[Participant]
}

