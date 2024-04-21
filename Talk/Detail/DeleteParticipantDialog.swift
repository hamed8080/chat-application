//
//  DeleteParticipantDialog.swift
//  Talk
//
//  Created by hamed on 2/27/24.
//

import Foundation
import ChatModels
import TalkViewModels
import SwiftUI
import TalkUI

struct DeleteParticipantDialog: View {
    let participant: Participant
    @EnvironmentObject var viewModel: ParticipantsViewModel

    var body: some View {
        VStack(alignment: .trailing, spacing: 16) {
            Text(attributedString)
                .foregroundStyle(Color.App.textPrimary)
                .font(.iransansSubheadline)
                .multilineTextAlignment(.leading)
                .frame(minWidth: 0, maxWidth: .infinity, alignment: .leading)

            HStack {
                Button {
                    withAnimation {
                        viewModel.removePartitipant(participant)
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                    }
                } label: {
                    Text("General.delete")
                        .foregroundStyle(Color.App.accent)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }

                Button {
                    withAnimation {
                        AppState.shared.objectsContainer.appOverlayVM.dialogView = nil
                    }
                } label: {
                    Text("General.cancel")
                        .foregroundStyle(Color.App.textPlaceholder)
                        .font(.iransansBody)
                        .frame(minWidth: 48, minHeight: 48)
                        .fontWeight(.medium)
                }
            }
        }
        .frame(maxWidth: 320)
        .padding(EdgeInsets(top: 12, leading: 16, bottom: 12, trailing: 16))
        .background(MixMaterialBackground())
    }

    private var attributedString: AttributedString {
        let type = viewModel.thread?.type?.isChannelType == true ? "Thread.channel" : "Thread.group"
        let locaizedType = String(localized: .init(type)).lowercased()
        let key = String(localized: .init("DeleteParticipantDialog.title"))
        let participantName = participant.contactName ?? participant.name ?? ""
        let string = String(format: key, participantName, locaizedType)
        let attr = NSMutableAttributedString(string: string)
        let range = (attr.string as NSString).range(of: participantName)
        attr.addAttributes([NSAttributedString.Key.foregroundColor: UIColor(named: "accent")!], range: range)
        return AttributedString(attr)
    }
}

struct DeleteParticipantDialog_Previews: PreviewProvider {
    static var previews: some View {
        DeleteParticipantDialog(participant: .init(id: 1))
            .environmentObject(ContactsViewModel())
    }
}
