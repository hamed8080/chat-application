//
//  MentionList.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkExtensions

struct MentionList: View {
    @EnvironmentObject var threadVM: ThreadViewModel
    @EnvironmentObject var viewModel: MentionListPickerViewModel

    var body: some View {
        if viewModel.mentionList.count > 0 {
            List(viewModel.mentionList) { participant in
                HStack {
                    let config = ImageLoaderConfig(url: participant.image ?? "", userName: String.splitedCharacter(participant.name ?? participant.username ?? ""))
                    ImageLoaderView(imageLoader: .init(config: config))
                        .id("\(participant.image ?? "")\(participant.id ?? 0)")
                        .font(.iransansBoldBody)
                        .foregroundColor(.white)
                        .frame(width: 24, height: 24)
                        .background(Color(uiColor: String.getMaterialColorByCharCode(str: participant.name ?? participant.username ?? "")))
                        .clipShape(RoundedRectangle(cornerRadius:(22)))
                    Text(participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")")
                        .font(.iransansCaption2)
                    Spacer()
                }
                .onTapGesture {
                    threadVM.sendContainerViewModel.addMention(participant)
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
