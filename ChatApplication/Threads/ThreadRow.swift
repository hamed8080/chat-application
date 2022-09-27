//
//  ThreadRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct ThreadRow: View {
	
	var thread:Conversation
	@State private (set) var showParticipants:Bool = false
	
    @StateObject
    var viewModel:ThreadsViewModel
    
    @State
    var isTypingText:String? = nil
	
    @Environment(\.isPreview)
    var isPreview
    
	var body: some View {
        let token = isPreview ? "FAKE_TOKEN" : TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken
		Button(action: {}, label: {
			HStack{
                Avatar(url:thread.image ,userName: thread.inviter?.username?.uppercased(), fileMetaData: thread.metadata, imageSize: .SMALL , token: token, previewImageName: thread.image ?? "avatar")
				VStack(alignment: .leading, spacing:8){
                    HStack{
                        Text(thread.title ?? "")
                            .font(.headline)
                        if thread.mute == true{
                            Image(systemName: "speaker.slash.fill")
                                .resizable()
                                .frame(width: 12, height: 12)
                                .scaledToFit()
                                .foregroundColor(Color.gray)
                        }
                    }

					if let message = thread.lastMessageVO?.message?.prefix(100){
						Text(message)
							.lineLimit(1)
							.font(.subheadline)
					}
                    if viewModel.model.typingThreadIds.contains(where: {$0 == thread.id }){
                        Text(isTypingText ?? "")
                            .frame(width: 72, alignment: .leading)
                            .lineLimit(1)
                            .font(.subheadline.bold())
                            .foregroundColor(Color.orange)
                            .onAppear{
                                withAnimation {
                                    "typing".isTypingAnimationWithText { startText in
                                        self.isTypingText = startText
                                    } onChangeText: { text, timer in
                                        if viewModel.model.typingThreadIds.contains(where: {$0 == thread.id }) == true{
                                            self.isTypingText = text
                                        }else{
                                            timer.invalidate()
                                        }
                                    } onEnd: {
                                        self.isTypingText = nil
                                    }
                                }
                            }
                    }
				}
				Spacer()
				if thread.pin == true{
					Image(systemName: "pin.fill")
						.foregroundColor(Color.orange)
				}
				if let unreadCount = thread.unreadCount ,let unreadCountString = String(unreadCount){
					let isCircle = unreadCount < 10 // two number and More require oval shape
					let computedString = unreadCount < 1000 ? unreadCountString : "\(unreadCount / 1000)K+"
					Text(computedString)
						.font(.system(size: 13))
						.padding(8)
						.frame(height: 24)
						.frame(minWidth:24)
						.foregroundColor(Color.white)
						.background(Color.orange)
						.cornerRadius(isCircle ? 16 : 8, antialiased: true)
				}
			}
			.contentShape(Rectangle())
			.padding([.leading , .trailing] , 8)
			.padding([.top , .bottom] , 4)
		})
        .contextMenu{
            Button {
                viewModel.pinUnpinThread(thread)
            } label: {
                Label((thread.pin ?? false) ? "UnPin" : "Pin", systemImage: "pin")
            }

            Button {
                viewModel.clearHistory(thread)
            } label: {
                Label("Clear History", systemImage: "clock")
            }

            Button {
                viewModel.muteUnMuteThread(thread)
            } label: {
                Label((thread.mute ?? false) ? "Unmute" : "Mute", systemImage: "speaker.slash")
            }

            Button {
                viewModel.showAddThreadToTag(thread)
            } label: {
                Label("Add To Folder", systemImage: "folder.badge.plus")
            }

            Button {
                viewModel.spamPVThread(thread)
            } label: {
                Label("Spam", systemImage: "ladybug")
            }

            Button(role:.destructive) {
                viewModel.leaveThread(thread)
            } label: {
                Label("Leave", systemImage: "rectangle.portrait.and.arrow.right")
            }
            
            if thread.admin == true{
                Button(role:.destructive) {
                    viewModel.deleteThread(thread)
                } label: {
                    Label("Delete", systemImage: "trash")
                }
            }
            
            if let type = thread.type, type == .CHANNEL_GROUP || type == .PUBLIC_GROUP{
                Button {
                    viewModel.showAddParticipants(thread)
                } label: {
                    Label("Invite", systemImage: "person.crop.circle.badge.plus")
                }
            }
        }
    }
}

struct ThreadRow_Previews: PreviewProvider {
	
	static var previews: some View {
        ThreadRow(thread: MockData.thread,viewModel: ThreadsViewModel())
	}
}
