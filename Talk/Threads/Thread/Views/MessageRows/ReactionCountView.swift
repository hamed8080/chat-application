//
//  ReactionCountView.swift
//  Talk
//
//  Created by hamed on 8/22/23.
//

import TalkExtensions
import TalkViewModels
import ChatModels
import SwiftUI
import Chat
import TalkUI
import TalkModels

//struct ReactionCountView: View {
//    @EnvironmentObject var viewModel: MessageReactionsViewModel
//
//    var body: some View {
//        ScrollView(.horizontal) {
//            HStack {
//                ForEach(viewModel.reactionCountList) { reactionCount in
//                    ReactionCountRow(reactionCount: reactionCount)
//                }
//            }
//        }
////        .frame(maxWidth: MessageRowViewModel.maxAllowedWidth)
//        .fixedSize(horizontal: true, vertical: false)
//        .animation(.easeInOut, value: viewModel.reactionCountList.count)
//        .padding(.horizontal, 6)
//    }
//}

//struct ReactionCountRow: View {
//    @EnvironmentObject var viewModel: MessageReactionsViewModel
//    let reactionCount: ReactionCount
//
//    var body: some View {
//        HStack {
//            if reactionCount.count ?? -1 > 0 {
//                if let sticker = reactionCount.sticker {
//                    Text(verbatim: sticker.emoji)
//                        .frame(width: 20, height: 20)
//                        .font(.system(size: 14))
//                }
//                AsyncReactionCountTextView(reactionCount: reactionCount)
//            }
//        }
//        .animation(.easeInOut, value: reactionCount.count ?? -1)
//        .padding(EdgeInsets(top: reactionCount.count ?? -1 > 0 ? 6 : 0, leading: reactionCount.count ?? -1 > 0 ? 8 : 0, bottom: reactionCount.count ?? -1 > 0 ? 6 : 0, trailing: reactionCount.count ?? -1 > 0 ? 8 : 0))
//        .background(
//            Rectangle()
//                .fill(isMyReaction ? Color.App.blue.opacity(0.7) : Color.App.primary.opacity(0.1))
//        )
//        .clipShape(RoundedRectangle(cornerRadius: 18))
//        .onTapGesture {
//            if let message = viewModel.message, let conversationId = message.threadId ?? message.conversation?.id, let tappedStciker = reactionCount.sticker {
//                AppState.shared.objectsContainer.reactions.reaction(tappedStciker, messageId: message.id ?? -1, conversationId: conversationId)
//            }
//        }
//        .customContextMenu(id: reactionCount.id, self: self.environmentObject(viewModel)) {
//            let selectedEmojiTabId = "\(reactionCount.sticker?.emoji ?? "all") \(reactionCount.count ?? 0)"
//            if let message = viewModel.message {
//                MessageReactionDetailView(message: message, selectedStickerTabId: selectedEmojiTabId)
//                    .frame(width: 300, height: 400)
//                    .clipShape(RoundedRectangle(cornerRadius:(12)))
//            }
//        }
//    }
//
//    var isMyReaction: Bool {
//        viewModel.currentUserReaction?.reaction?.rawValue == reactionCount.sticker?.rawValue
//    }
//}

struct AsyncReactionCountTextView: View {
    let reactionCount: ReactionCount
    @State private var countText = ""
    let isMyReaction: Bool

    var body: some View {
        Text(countText)
            .font(.iransansBody)
            .foregroundStyle(isMyReaction ? Color.App.white : Color.App.textPrimary)
            .task {
                Task {
                    let countText = reactionCount.count?.localNumber(locale: Language.preferredLocale) ?? ""
                    await MainActor.run {
                        self.countText = countText
                    }
                }
            }
    }
}

final class ReactionCountView: UIView {
    private let scrollView = UIScrollView()
    private let stack = UIStackView()

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        stack.axis = .horizontal
        scrollView.layoutMargins = .init(horizontal: 6)
        scrollView.addSubview(stack)
        addSubview(scrollView)
        scrollView.translatesAutoresizingMaskIntoConstraints = false

        NSLayoutConstraint.activate([
            scrollView.leadingAnchor.constraint(equalTo: leadingAnchor),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        let reactionsVM = viewModel.reactionsVM
        reactionsVM.reactionCountList.forEach { reactionCount in
            let row = ReactionCountRow()
            row.reactionCount = reactionCount
            stack.addArrangedSubview(row)
        }
    }
}

final class ReactionCountRow: UIView {
    private let stack = UIStackView()
    private let reactionLabel = UILabel()
    private let reactionCountLabel = UILabel()
    var reactionCount: ReactionCount!

    override init(frame: CGRect) {
        super.init(frame: frame)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {

        reactionLabel.font = .systemFont(ofSize: 14)

        reactionCountLabel.font = UIFont.uiiransansBody
        reactionCountLabel.textColor = Color.App.uitext

        stack.axis = .horizontal
        stack.addArrangedSubview(reactionLabel)
        stack.addArrangedSubview(reactionCountLabel)
        reactionLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            reactionLabel.widthAnchor.constraint(equalToConstant: 20),
            reactionLabel.heightAnchor.constraint(equalToConstant: 20),
        ])
    }

    public func setValues(viewModel: MessageRowViewModel) {
        if reactionCount.count ?? -1 > 0, let sticker = reactionCount.sticker {
            reactionCountLabel.text = sticker.emoji
            Task {
                let countText = reactionCount.count?.localNumber(locale: Language.preferredLocale) ?? ""
                await MainActor.run {
                    reactionCountLabel.text = countText
                }
            }
        }
    }
}

struct ReactionCountViewWapper: UIViewRepresentable {
    let viewModel: MessageRowViewModel

    func makeUIView(context: Context) -> some UIView {
        let view = ReactionCountView()
        view.setValues(viewModel: viewModel)
        return view
    }

    func updateUIView(_ uiView: UIViewType, context: Context) {

    }
}

struct ReactionCountView_Previews: PreviewProvider {
    static var previews: some View {
        ReactionCountViewWapper(viewModel: .init(message: .init(), viewModel: .init(thread: .init())))
    }
}
