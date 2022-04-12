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
            image         : "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png",
            pin           : false,
            title         : "Hamed Hosseini",
            type          : ThreadTypes.PUBLIC_GROUP.rawValue,
            lastMessageVO : lastMessageVO
        )
        return thread
    }
    
    
    static func generateThreads(count:Int = 50)->[Conversation]{
        var threads:[Conversation] = []
        for index in 0...count{
            let thread          = thread
            thread.title        = "Title \(index)"
            thread.description  = "Description \(index)"
            thread.id           = index
            threads.append(thread)
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
            image           : "http://www.careerbased.com/themes/comb/img/avatar/default-avatar-male_14.png",
            lastName        : "Hosseini",
            linkedUser      : nil,
            notSeenDuration : 1622969881,
            timeStamp       : nil,
            userId          : nil
        )
        return contact
    }
    
    
    static func generateContacts(count:Int = 50)->[Contact]{
        var contacts:[Contact] = []
        for index in 0...count{
            let contact       = MockData.contact
            contact.firstName = "Hamed"
            contact.lastName  = "Hosseini\(index)"
            contact.id        = index
            contacts.append(contact)
        }
        return contacts
    }
    
    ///Message
    static var message:Message{
        let message = Message(
            threadId    : 0,
            id          : 0,
            message     : "Hello",
            messageType : 1,
            seen        : false,
            time        : 1636807773
        )
        return message
    }
    
    static var forwardedMessage:Message{
        let ms = Message(
            threadId    : 0,
            id          : 12,
            message     : "Hello",
            messageType : 1,
            seen        : false,
            time        : 1636807773,
            forwardInfo : ForwardInfo(conversation : thread, participant : participant)
        )
        return ms
    }
    
    static var downloadMessageLongText:Message{
        let metaData = FileMetaData(
            file: .init(
                fileExtension : ".pdf",
                link          : "",
                mimeType      : "",
                name          : "Test File Name",
                originalName  : "tes",
                size          : 8240000
            )
        )
        let metaDataString = String(data: (try! JSONEncoder().encode(metaData)), encoding: .utf8)
        return Message(
            threadId    : 0,
            id          : 12,
            message     : "A SwiftUI view that has content, such as Text and Button, usually take the smallest space possible to wrap their content. But there is a time that we want these views to fill its container width or height. Let's learn a SwiftUI way to do that.",
            messageType : MessageType.FILE.rawValue,
            metadata    : metaDataString,
            time        : 1636807773
        )
    }
    
    static var downloadPersianMessageLongText:Message{
        let metaData = FileMetaData(
            file: .init(
                fileExtension : ".pdf",
                link          : "",
                mimeType      : "",
                name          : "Test File Name",
                originalName  : "tes",
                size          : 8240000
            )
        )
        let metaDataString = String(data: (try! JSONEncoder().encode(metaData)), encoding: .utf8)
        return Message(
            threadId               : 0,
                       id          : 14,
                       message     : "به‌نقل از appleinsider، یوتیوب ۹ ماه پس از شروع آزمایشی ویژگی Picture-in-Picture، اکنون آن را برای اپلیکیشن iOS غیرفعال کرده است. این شرکت ویژگی PiP در iOS را تحت عنوان یک ویژگی «آزمایشی» در اوت ۲۰۲۱ فعال کرد. این سرویس اشتراک ویدئو ظاهراً در آوریل ۲۰۲۲ نتیجه گرفت که ویژگی مذکور ارزش حفظ کردن را ندارد",
                       messageType : MessageType.FILE.rawValue,
                       metadata    : metaDataString,
                       time        : 1636807773
        )
    }
    
    static var downloadMessageSmallText:Message{
        let metaData = FileMetaData(
            file: .init(
                fileExtension : ".pdf",
                link          : "",
                mimeType      : "",
                name          : "Test File Name",
                originalName  : "tes",
                size          : 8240000
            )
        )
        let metaDataString = String(data: (try! JSONEncoder().encode(metaData)), encoding: .utf8)
        return Message(
            threadId    : 0,
            id          : 13,
            message     : nil,
            messageType : MessageType.FILE.rawValue,
            metadata    : metaDataString,
            time        : 1636807773
        )
    }
    
    static var uploadMessage:UploadFileMessage{
        let msg = UploadFileMessage(uploadFileUrl: URL(string: "http://www.google.com")!, textMessage: "Test")
        msg.message = "Film.mp4"
        return msg
    }
    
    static func generateMessages(count:Int = 50)->[Message]{
        var messages:[Message] = []
        for index in 0...count{
            let message          = message
            message.message      = "Message Body \(index)"
            message.time         = (message.time ?? 0) * 10
            message.id           = index
            messages.append(message)
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
            lastName         : "Hosseini",
            name             : "Hamed",
            online           : true,
            username         : "hamed8080"
        )
        return participant
    }
    
    static func generateParticipants(count:Int = 50)->[Participant]{
        
        var participants:[Participant] = []
        for index in 0...count{
            let participant          = participant
            participant.name         = "Name \(index)"
            participant.online       = Bool.random()
            participant.id           = index
            participants.append(participant)
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
    
}



