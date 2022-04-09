//
//  ParticipantRow.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 5/27/21.
//

import SwiftUI
import FanapPodChatSDK

struct ParticipantRow: View {
    
    private (set) var participant:Participant
    var style:StyleConfig
    
    init(participant: Participant, style:StyleConfig = StyleConfig()) {
        self.participant = participant
        self.style = style
    }
    
    struct StyleConfig{
        var avatarConfig: Avatar.StyleConfig = Avatar.StyleConfig()
        var textFont:Font = .subheadline
    }
    
    var body: some View {
        
        Button(action: {}, label: {
            HStack{
                Avatar(url:participant.image ,userName: participant.username?.uppercased(), fileMetaData: nil, style: style.avatarConfig)
                HStack(alignment: .center, spacing:8){
                    VStack(alignment:.leading, spacing:6){
                        Text(participant.name ?? "")
                            .font(style.textFont)
                        Text(participant.cellphoneNumber ?? "092321298")
                            .font(.caption2)
                            .foregroundColor(.primary.opacity(0.5))
                        if participant.online == true{
                            Text("online")
                                .font(.caption2)
                        }
                    }
                    
                    if participant.admin == true{
                        Spacer()
                        
                        Text("Admin")
                            .padding(4)
                            .foregroundColor(Color.blue)
                            .font(style.textFont)
                            .overlay(
                                RoundedRectangle(cornerRadius: 4)
                                    .stroke(Color.blue, lineWidth: 1)
                            )
                    }
                }
                Spacer()
            }
            .contentShape(Rectangle())
            .padding([.leading , .trailing] , 8)
            .padding([.top , .bottom] , 4)
        })
    }
}

struct ParticipantRow_Previews: PreviewProvider {
    static var participant:Participant{
        let participant = Participant(admin: true, cellphoneNumber: "+989369161601", contactFirstName: "Hamed", contactName: "Hamed", contactLastName: "Hosseini", firstName: "Hamed", id: 123, lastName: "Hosseini", name: "Hamed", online: true, username: "hamed8080")
        return participant
    }
    
    static var previews: some View {
        ParticipantRow(participant: participant)
            
        
    }
}
