//
//  MessageRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct MessageRow: View {
	
	private (set) var message:Message
	@State private (set) var showActionSheet:Bool = false
	@State private (set) var showParticipants:Bool = false
	private var viewModel:ThreadViewModel

    init(message: Message, viewModel:ThreadViewModel) {
		self.message = message
		self.viewModel = viewModel
	}
	
	var body: some View {
		
		Button(action: {}, label: {
			HStack{
				VStack(alignment: .leading, spacing:8){
					Text(message.message ?? "")
						.font(.headline)
				}
				Spacer()
			}
			.contentShape(Rectangle())
			.padding([.leading , .trailing] , 8)
			.padding([.top , .bottom] , 4)
		})
		.onTapGesture {
			print("on tap gesture")
		}.onLongPressGesture {
			print("long press triggred")
			showActionSheet.toggle()
		}
		.actionSheet(isPresented: $showActionSheet){
			ActionSheet(title: Text("Manage Thread"), message: Text("you can mange thread here"), buttons: [
				.cancel(Text("Cancel").foregroundColor(Color.red)),
							.default(Text((message.pinned ?? false) ? "UnPin" : "Pin")){
					viewModel.pinUnpinMessage(message)
				},
				.default(Text("Delete")){
                    withAnimation {
                        viewModel.deleteMessage(message)
                    }
				}
			])
		}
	}
}

struct MessageRow_Previews: PreviewProvider {
	static var message:Message{
		let message = Message(threadId: 0,
                              deletable: true,
                              delivered: true,
                              editable: true,
                              edited: true,
                              id: 12,
                              mentioned: false,
                              message: "Hello",
                              messageType: 0,
                              metadata: nil,
                              ownerId: nil,
                              pinned: true,
                              previousId: 0,
                              seen: true,
                              systemMetadata: nil,
                              time: 0,
                              timeNanos: 0,
                              uniqueId: nil,
                              conversation: nil,
                              forwardInfo: nil,
                              participant: nil,
                              replyInfo: nil)
		return message
	}
	
	static var previews: some View {
        MessageRow(message: message,viewModel: ThreadViewModel(thread: ThreadRow_Previews.thread))
	}
}
