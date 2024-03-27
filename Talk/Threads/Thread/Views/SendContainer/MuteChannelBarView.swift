//
//  MuteChannelBarView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import Chat

public final class MuteChannelBarView: UIButton {
    var viewModel: ThreadViewModel

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        translatesAutoresizingMaskIntoConstraints = false
        titleLabel?.font = UIFont.uiiransansSubheadline
        setTitleColor(Color.App.accentUIColor, for: .normal)
        addGestureRecognizer(UITapGestureRecognizer(target: self, action: #selector(muteTapped)))
        layoutMargins = .init(all: 10)

        NSLayoutConstraint.activate([
            heightAnchor.constraint(equalToConstant: 48)
        ])
        set()
    }

    public func set() {
        isHidden = !viewModel.sendContainerViewModel.canShowMute
        let isMute = viewModel.thread.mute == true
        let title = isMute ? "Thread.unmute".localized() : "Thread.mute".localized()
        setTitle(title, for: .normal)
    }

    @objc private func muteTapped(_ sender: UIButton) {
        viewModel.threadsViewModel?.toggleMute(viewModel.thread)
    }
}

struct MuteChannelViewPlaceholder_Previews: PreviewProvider {
    struct MuteChannelBarViewWrapper: UIViewRepresentable {
        let viewModel: ThreadViewModel
        func makeUIView(context: Context) -> some UIView { MuteChannelBarView(viewModel: viewModel) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    static var previews: some View {
        MuteChannelBarViewWrapper(viewModel: .init(thread: .init(type: .channel)))
    }
}
