//
//  ReactionRowContextMenuCofiguration.swift
//  Talk
//
//  Created by hamed on 7/22/24.
//

import Foundation
import SwiftUI
import UIKit
import TalkViewModels
import TalkModels

class ReactionRowContextMenuCofiguration {
    static func config(interaction: UIContextMenuInteraction) -> UIContextMenuConfiguration? {
        let config = UIContextMenuConfiguration(identifier: nil, previewProvider: nil)  { _ in
            let closeAction = UIAction(title: "General.close".bundleLocalized(), image: UIImage(systemName: "xmark.circle")) { _ in
                interaction.dismissMenu()
            }
            return UIMenu(title: "", children: [closeAction])
        }
        return config
    }

    static func targetedView(view: UIView, row: ReactionRowsCalculated.Row?, viewModel: MessageRowViewModel?) -> UITargetedPreview? {
        let targetedView = UIPreviewTarget(container: view, center: view.center)
        let params = UIPreviewParameters()
        params.backgroundColor = .clear
        params.shadowPath = UIBezierPath()

        guard let viewModel = viewModel else { return nil }
        let tabView = getTabDetailView(viewModel: viewModel,
                                       row: row,
                                       isDark: view.traitCollection.userInterfaceStyle == .dark)

        let vc = UIHostingController(rootView: tabView)
        vc.view.frame = .init(origin: .zero, size: .init(width: 300, height: 400))
        vc.view.backgroundColor = .clear
        vc.preferredContentSize = vc.view.frame.size

        return UITargetedPreview(view: vc.view, parameters: params, target: targetedView)
    }

    static func getTabDetailView(viewModel: MessageRowViewModel, row: ReactionRowsCalculated.Row?, isDark: Bool) -> some View {
        let tabVm = ReactionTabParticipantsViewModel(messageId: viewModel.message.id ?? -1)
        tabVm.viewModel = viewModel.threadVM?.reactionViewModel

        let swiftUIReactionTabs = VStack(alignment: viewModel.calMessage.isMe ? .leading : .trailing) {
            if let row = row {
                SwiftUIReactionCountRowWrapper(row: row, isMe: viewModel.calMessage.isMe)
                    .frame(width: 42, height: 32)
                    .fixedSize()
                    .environment(\.colorScheme, isDark ? .dark : .light)
                    .disabled(true)
                MessageReactionDetailView(message: viewModel.message, row: row)
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            }
        }
            .environmentObject(tabVm)

        return swiftUIReactionTabs
    }
}
