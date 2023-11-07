//
//  SelectThreadRow.swift
//  Talk
//
//  Created by Hamed Hosseini on 5/27/21.
//

import Chat
import ChatModels
import Combine
import SwiftUI
import TalkUI
import TalkViewModels

struct SelectThreadRow: View {
    var thread: Conversation

    init(thread: Conversation) {
        self.thread = thread
    }

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: thread.computedImageURL, userName: thread.title)
                .id("\(thread.computedImageURL ?? "")\(thread.id ?? 0)")
                .font(.iransansSubtitle)
                .foregroundColor(.white)
                .frame(width: 36, height: 36)
                .background(Color.App.blue.opacity(0.4))
                .cornerRadius(18)
            Text(thread.computedTitle)
                .font(.iransansSubheadline)
            Spacer()
        }
        .contentShape(Rectangle())
        .padding([.leading, .trailing], 8)
        .padding([.top, .bottom], 4)
    }
}

struct SelectContactRow: View {
    var contact: Contact

    init(contact: Contact) {
        self.contact = contact
    }

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: contact.image ?? contact.user?.image, userName: contact.firstName)
                .id("\(contact.image ?? "")\(contact.id ?? 0)")
                .font(.iransansBoldBody)
                .foregroundColor(.white)
                .frame(width: 24, height: 24)
                .background(Color.App.blue.opacity(0.4))
                .cornerRadius(12)
            VStack(alignment: .leading, spacing: 4) {
                Text("\(contact.firstName ?? "") \(contact.lastName ?? "")")
                    .padding(.leading, 4)
                    .lineLimit(1)
                    .font(.iransansCaption)
                if let notSeenDuration = contact.notSeenDuration?.localFormattedTime {
                    Text(notSeenDuration)
                        .padding(.leading, 4)
                        .font(.iransansCaption3)
                        .foregroundColor(Color.App.gray1)
                }
            }
        }
        .contentShape(Rectangle())
    }
}

struct SelectThreadRow_Previews: PreviewProvider {
    static var previews: some View {
        SelectThreadRow(thread: MockData.thread)
    }
}
