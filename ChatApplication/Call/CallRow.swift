//
//  CallRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct CallRow: View {
	
	private (set) var call:Call
	@State private (set) var showActionSheet:Bool = false
	private var viewModel:CallsHistoryViewModel

	init(call: Call , viewModel:CallsHistoryViewModel) {
		self.call = call
		self.viewModel = viewModel
	}
	
	var body: some View {
		
		Button(action: {}, label: {
			HStack{
                Text(call.partnerParticipant?.name ?? "")
                    .foregroundColor(.black)
                Spacer()
                VStack(alignment:.trailing){
                    if let createTime = call.createTime, let date = Date(milliseconds: Int64(createTime)){
                        Text(date.timeAgoSinceDate())
                            .font(.system(size: 14))
                            .foregroundColor(.gray)
                    }
                    Image(systemName: "phone")
                        .resizable()
                        .padding(12)
                        .rotationEffect(Angle(degrees: 270))
                        .frame(width: 48, height: 48)
                }
                
			}
			.contentShape(Rectangle())
			.padding([.leading , .trailing] , 16)
			.padding([.top , .bottom] , 4)
		})
		.onTapGesture {
			print("on tap gesture")
		}.onLongPressGesture {
			print("long press triggred")
			showActionSheet.toggle()
		}
//		.actionSheet(isPresented: $showActionSheet){
//			ActionSheet(title: Text("Manage Thread"), message: Text("you can mange thread here"), buttons: [
//				.cancel(Text("Cancel").foregroundColor(Color.red)),
//							.default(Text((call.pin ?? false) ? "UnPin" : "Pin")){
//					viewModel.pinUnpinThread(call)
//				},
//				.default(Text( (thread.mute ?? false) ? "Unmute" : "Mute" )){
//					viewModel.muteUnMuteThread(thread)
//				},
//				.default(Text("Delete")){
//					viewModel.deleteThread(thread)
//				}
//			])
//		}
	}
}

struct CallRow_Previews: PreviewProvider {
	static var call:Call{
        let partnerParticipant = Participant(admin:nil,
                                             auditor:nil,
                                             blocked: false,
                                             cellphoneNumber: nil,
                                             contactFirstName: "Hamed",
                                             contactId:nil,
                                             contactName: nil,
                                             contactLastName: nil,
                                             coreUserId: nil,
                                             email: nil,
                                             firstName: nil,
                                             id: 18478,
                                             image: nil,
                                             keyId: nil,
                                             lastName: nil,
                                             myFriend: nil,
                                             name: "Hamed Hosseini",
                                             notSeenDuration: nil,
                                             online: false,
                                             receiveEnable: nil,
                                             roles: nil,
                                             sendEnable: nil,
                                             username: nil,
                                             chatProfileVO: nil)
	let call = Call(id: 1763,
                    creatorId: 18478,
                    type: 1,
                    isGroup: false,
                    createTime: 1612076744136,
                    startTime: nil,
                    endTime: 1612076779373,
                    status: .DECLINED,
                    callParticipants: nil,
                    partnerParticipant: partnerParticipant)
		return call
	}
	
	static var previews: some View {
		CallRow(call: call,viewModel: CallsHistoryViewModel())
	}
}
