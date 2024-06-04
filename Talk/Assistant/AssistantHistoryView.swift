//
//  AssistantHistoryView.swift
//  Talk
//
//  Created by hamed on 6/27/22.
//

import Chat
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

    var body: some View {
        HStack {
            let config = ImageLoaderConfig(url: action.participant?.image ?? "", userName: action.participant?.name)
            ImageLoaderView(imageLoader: .init(config: config))
                .frame(width: 28, height: 28)
                .background(.blue.opacity(0.8))
                .clipShape(RoundedRectangle(cornerRadius:(18)))

            VStack(alignment: .leading) {
                Text(action.participant?.name ?? "")
                    .font(.iransansCaption)
                Text(action.actionTime?.date.localFormattedTime ?? "")
                    .font(.iransansBoldCaption3)
                    .foregroundStyle(.secondary)
            }

            Spacer()
            Text(action.actionType?.stringValue ?? "unknown")
                .frame(width: 72)
                .font(.iransansCaption2)
                .padding(EdgeInsets(top: 2, leading: 6, bottom: 2, trailing: 6))
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
