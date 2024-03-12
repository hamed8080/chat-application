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
        reactionCountLabel.textColor = Color.App.textPrimaryUIColor

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
