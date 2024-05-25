//
//  DetailUserNameSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailUserNameSection: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel

    var body: some View {
        if let participantName = viewModel.participant.username.validateString {
            SectionRowContainer(key: "Settings.userName", value: participantName)
        }
    }
}

struct DetailUserNameSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailUserNameSection()
    }
}
