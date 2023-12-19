//
//  MentionList.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkViewModels
import TalkUI

struct MentionList: View {
    @EnvironmentObject var threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: MentionListPickerViewModel

    var body: some View {
        if viewModel.mentionList.count > 0 {
            List(viewModel.mentionList) { participant in
                HStack {
                    ImageLaoderView(imageLoader: ImageLoaderViewModel(), url: participant.image, userName: participant.name ?? participant.username)
                        .id("\(participant.image ?? "")\(participant.id ?? 0)")
                        .font(.iransansBoldBody)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color.App.blue.opacity(0.4))
                        .clipShape(RoundedRectangle(cornerRadius:(22)))
                    Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                        .font(.iransansCaption2)
                    Spacer()
                }
                .onTapGesture {
                    let userName = (participant.username ?? "")
                    threadVM.sendContainerViewModel.textMessage = "\(threadVM.sendContainerViewModel.textMessage)\(userName) " // To hide participants dialog
                    threadVM.animateObjectWillChange()
                }
                .listRowBackground(Color.clear)
                .listRowSeparator(.hidden)
            }
            .listStyle(.plain)
            .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .bottom)))
            .frame(maxHeight: min(196, CGFloat(viewModel.mentionList.count) * 48))
            .animation(.easeInOut, value: viewModel.mentionList.count)
        } else {
            EmptyView()
        }
    }
}

struct MentionList_Previews: PreviewProvider {
    static var previews: some View {
        MentionList()
    }
}
