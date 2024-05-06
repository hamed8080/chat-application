//
//  DetailCellPhoneNumberSection.swift
//  Talk
//
//  Created by hamed on 5/6/24.
//

import SwiftUI
import TalkViewModels

struct DetailCellPhoneNumberSection: View {
    @EnvironmentObject var viewModel: ParticipantDetailViewModel

    var body: some View {
        if let cellPhoneNumber = viewModel.cellPhoneNumber.validateString {
            SectionRowContainer(key: "Participant.Search.Type.cellphoneNumber", value: cellPhoneNumber)
        }
    }
}

struct DetailCellPhoneNumberSection_Previews: PreviewProvider {
    static var previews: some View {
        DetailCellPhoneNumberSection()
    }
}
