//
//  SelectionView.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels
import Combine

public final class SelectionView: UIStackView {
    private let btnForward = UIButton(type: .system)
    private let btnDelete = UIButton(type: .system)
    private let lblCount = UILabel()
    private let lblStatic = UILabel()
    private let lblStaticForwardTO = UILabel()
    private let closeButton = CloseButtonView()
    private let viewModel: ThreadViewModel
    private var cancellable = Set<AnyCancellable>()

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
        registerObserver()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        btnForward.translatesAutoresizingMaskIntoConstraints = false
        btnDelete.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 4
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        btnDelete.setImage(UIImage(named: "ic_delete"), for: .normal)
        btnDelete.tintColor = Color.App.iconSecondaryUIColor
        btnDelete.addTarget(self, action: #selector(deleteSelectedMessageTapped), for: .touchUpInside)

        let image = UIImage(systemName: "arrow.turn.up.right")
        btnForward.setImage(image, for: .normal)
        btnForward.tintColor = Color.App.accentUIColor
        btnForward.addTarget(self, action: #selector(forwardSelectedMessageTapped), for: .touchUpInside)

        lblCount.font = UIFont.uiiransansBoldBody
        lblCount.textColor = Color.App.accentUIColor

        lblStatic.text = "General.selected".localized()
        lblStatic.font = UIFont.uiiransansBody
        lblStatic.textColor = Color.App.textSecondaryUIColor

        lblStaticForwardTO.text = "Thread.SendContainer.toForward".localized()
        lblStaticForwardTO.font = UIFont.uiiransansBody
        lblStaticForwardTO.textColor = Color.App.textSecondaryUIColor

        closeButton.action = { [weak self] in
            self?.onClose()
        }

        let spacer = UIView(frame: .init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 0))

        addArrangedSubview(btnForward)
        addArrangedSubview(lblCount)
        addArrangedSubview(lblStatic)
        addArrangedSubview(lblStaticForwardTO)
        addArrangedSubview(spacer)
        addArrangedSubview(btnDelete)
        addArrangedSubview(closeButton)

        NSLayoutConstraint.activate([
            btnForward.widthAnchor.constraint(equalToConstant: 36),
            btnForward.heightAnchor.constraint(equalToConstant: 36),
            btnDelete.widthAnchor.constraint(equalToConstant: 36),
            btnDelete.heightAnchor.constraint(equalToConstant: 36),
        ])
    }

    @objc private func forwardSelectedMessageTapped(_ sender: UIButton) {
        viewModel.delegate?.openForwardPicker()
    }

    @objc private func deleteSelectedMessageTapped(_ sender: UIButton) {
        AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(DeleteMessageDialog(viewModel: .init(threadVM: viewModel)))
    }

    private func set() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            isHidden = !viewModel.selectedMessagesViewModel.isInSelectMode
            lblStaticForwardTO.isHidden = viewModel.forwardMessage != nil
            btnDelete.isHidden = viewModel.thread.disableSend
        }
    }

    public func updateCount() {
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            let count = viewModel.selectedMessagesViewModel.selectedMessages.count
            lblCount.text = count.localNumber(locale: Language.preferredLocale) ?? ""
        }
    }

    private func deleteMessagesTapped(_ sender: UIButton) {
//        appOverlayVM.dialogView = AnyView(DeleteMessageDialog(viewModel: .init(threadVM: threadVM)))
    }

    private func onClose() {
        lblCount.text = ""
        viewModel.delegate?.setSelection(false)
        viewModel.selectedMessagesViewModel.clearSelection()
    }

    private func registerObserver() {
        viewModel.selectedMessagesViewModel.objectWillChange.sink { [weak self] _ in
            self?.set()
        }
        .store(in: &cancellable)
    }
}

struct SelectionView_Previews: PreviewProvider {

    struct SelectionViewWrapper: UIViewRepresentable {
        let viewModel: ThreadViewModel
        func makeUIView(context: Context) -> some UIView { SelectionView(viewModel: viewModel) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    static var previews: some View {
        SelectionViewWrapper(viewModel: .init(thread: .init(id: 1)))
    }
}
