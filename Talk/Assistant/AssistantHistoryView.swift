//
//  AssistantHistoryView.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
import ChatCore
import ChatDTO
import ChatModels
import Logger
import SwiftUI
import TalkExtensions
import TalkUI
import TalkViewModels

struct AssistantHistoryView: View {
    @StateObject var viewModel: AssistantHistoryViewModel = .init()

    var body: some View {
        List {
            ForEach(viewModel.histories) { action in
                AssistantActionRow(action: action)
                    .onAppear {
                        if action == viewModel.histories.last {
                            viewModel.loadMore()
                        }
                    }
            }
            .transition(.asymmetric(insertion: .move(edge: .leading), removal: .move(edge: .trailing)))
        }
        .environmentObject(viewModel)
        .navigationTitle("Assistant.History.title")
        .animation(.easeInOut, value: viewModel.histories.count)
    }
}

struct AssistantActionRow: View {
    let action: AssistantAction
    @StateObject var imageViewModel: ImageLoaderViewModel = .init()

    var body: some View {
        HStack {
            ImageLaoderView(imageLoader: imageViewModel, url: action.participant?.image, userName: action.participant?.name)
                .frame(width: 28, height: 28)
                .background(.blue.opacity(0.8))
                .cornerRadius(18)

            VStack(alignment: .leading) {
                Text(action.participant?.name ?? "")
                    .font(.iransansCaption)
                Text(action.actionTime?.date.localFormattedTime ?? "")
                    .font(.iransansBoldCaption3)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Text(.init(localized: .init(action.actionType?.stringValue ?? "General.unknown")))
                .frame(width: 72)
                .font(.iransansCaption2)
                .padding([.leading, .trailing], 6)
                .padding([.top, .bottom], 2)
                .foregroundColor(action.actionType?.actionColor ?? .gray)
                .overlay(
                    RoundedRectangle(cornerRadius: 4)
                        .stroke(action.actionType?.actionColor ?? .gray)
                )
            Image(systemName: action.actionType?.imageIconName ?? "questionmark.square")
                .resizable()
                .scaledToFit()
                .frame(width: 18, height: 18)
                .foregroundStyle(action.actionType?.actionColor ?? .gray)
        }
    }
}

struct AssistantHistoryView_Previews: PreviewProvider {
    static let participant = MockData.participant(1)
    static let activateAction = AssistantAction(actionTime: UInt(Date().timeIntervalSince1970), actionType: .activate, participant: participant)
    static let blockAction = AssistantAction(actionTime: UInt(Date().timeIntervalSince1970), actionType: .block, participant: participant)
    static let deactivateAction = AssistantAction(actionTime: UInt(Date().timeIntervalSince1970), actionType: .deactivate, participant: participant)
    static let registerAction = AssistantAction(actionTime: UInt(Date().timeIntervalSince1970), actionType: .register, participant: participant)
    static let unknownAction = AssistantAction(actionTime: UInt(Date().timeIntervalSince1970), actionType: .unknown, participant: participant)
    static var viewModel = AssistantHistoryViewModel()

    static var previews: some View {
        AssistantHistoryView(viewModel: viewModel)
            .onAppear {
                let response: ChatResponse<[AssistantAction]> = .init(result: [activateAction, blockAction, deactivateAction, registerAction, unknownAction])
                viewModel.onActions(response)
            }
    }
}
