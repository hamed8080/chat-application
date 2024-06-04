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

public final class SelectionView: UIStackView {
    private let btnDelete = UIButton(type: .system)
    private let lblCount = UILabel()
    private let lblStatic = UILabel()
    private weak var viewModel: ThreadViewModel?

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureViews()
    }

    public required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureViews() {
        btnDelete.translatesAutoresizingMaskIntoConstraints = false

        axis = .horizontal
        spacing = 4
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        btnDelete.setImage(UIImage(named: "ic_delete"), for: .normal)
        btnDelete.tintColor = Color.App.iconSecondaryUIColor
        btnDelete.addTarget(self, action: #selector(deleteSelectedMessageTapped), for: .touchUpInside)

        let btnForward = UIButton(type: .system)
        let image = UIImage(systemName: "arrow.turn.up.right")
        btnForward.setImage(image, for: .normal)
        btnForward.tintColor = Color.App.accentUIColor
        btnForward.addTarget(self, action: #selector(forwardSelectedMessageTapped), for: .touchUpInside)
        btnForward.translatesAutoresizingMaskIntoConstraints = false

        lblCount.font = UIFont.uiiransansBoldBody
        lblCount.textColor = Color.App.accentUIColor

        lblStatic.text = "General.selected".localized()
        lblStatic.font = UIFont.uiiransansBody
        lblStatic.textColor = Color.App.textSecondaryUIColor

        let closeButton = CloseButtonView()
        closeButton.action = { [weak self] in
            self?.onClose()
        }

        let spacer = UIView(frame: .init(x: 0, y: 0, width: CGFloat.greatestFiniteMagnitude, height: 0))

        addArrangedSubview(btnForward)
        addArrangedSubview(lblCount)
        addArrangedSubview(lblStatic)
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
        viewModel?.delegate?.openForwardPicker()
    }

    @objc private func deleteSelectedMessageTapped(_ sender: UIButton) {
        guard let viewModel = viewModel else { return }
        Task {
            let deleteVM = DeleteMessagesViewModelModel()
            await deleteVM.setup(viewModel: viewModel)
            let dialog = DeleteMessageDialog(viewModel: deleteVM)
            AppState.shared.objectsContainer.appOverlayVM.dialogView = AnyView(dialog)
        }
    }

    private func set() {
        guard let viewModel = viewModel else { return }
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            let show = viewModel.selectedMessagesViewModel.isInSelectMode
            isHidden = false
            UIView.animate(withDuration: 0.2) {
                self.alpha = show ? 1.0 : 0.0
                self.isHidden = !show
            }
            btnDelete.isHidden = viewModel.thread.disableSend
            updateCount()
        }
    }

    private func updateCount() {
        guard let viewModel = viewModel else { return }
        UIView.animate(withDuration: 0.3) { [weak self] in
            guard let self = self else { return }
            let count = viewModel.selectedMessagesViewModel.getSelectedMessages().count
            lblCount.text = count.localNumber(locale: Language.preferredLocale) ?? ""
        }
    }

    private func onClose() {
        lblCount.text = ""
        viewModel?.delegate?.setSelection(false)
        viewModel?.selectedMessagesViewModel.clearSelection()
    }

    public func update() {
        set()
    }
}
