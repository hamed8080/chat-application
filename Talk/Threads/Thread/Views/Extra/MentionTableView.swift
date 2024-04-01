//
//  MentionTableView.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import SwiftUI
import TalkViewModels
import TalkUI
import TalkExtensions
import ChatModels
import Combine

public final class MentionTableView: UITableView {
    private let viewModel: ThreadViewModel
    private let cellIdentifier = String(describing: MentionCell.self)
    private var heightConstraint: NSLayoutConstraint!
    private var cancellableSet = Set<AnyCancellable>()

    public init(viewModel: ThreadViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero, style: .plain)
        configureView()
        registerObserver()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        register(MentionCell.self, forCellReuseIdentifier: cellIdentifier)
        delegate = self
        dataSource = self
        backgroundColor = .clear
        translatesAutoresizingMaskIntoConstraints = false
        heightConstraint = heightAnchor.constraint(equalToConstant: 0)
        NSLayoutConstraint.activate([heightConstraint])
    }

    private func registerObserver() {
        viewModel.mentionListPickerViewModel.objectWillChange.sink { [weak self] _ in
            let mentionList = self?.viewModel.mentionListPickerViewModel.mentionList ?? []
            self?.onMentionListChanged(mentionList)
        }
        .store(in: &cancellableSet)
    }

    private func onMentionListChanged(_ mentionList: ContiguousArray<Participant> ) {
        heightConstraint.constant = min(196, CGFloat(mentionList.count) * 48)
        reloadData()
    }
}

public final class MentionCell: UITableViewCell {
    private let lblName = UILabel()
    private let imgParticipant = ParticipantImageLoaderUIView()

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        configureView()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        backgroundColor = .clear
        let hStack = UIStackView()
        hStack.translatesAutoresizingMaskIntoConstraints = false
        hStack.axis = .horizontal
        hStack.spacing = 0
        hStack.alignment = .center
        hStack.layoutMargins = .init(all: 8)
        hStack.isLayoutMarginsRelativeArrangement = true

        lblName.font = .uiiransansCaption2
        lblName.textColor = Color.App.textPrimaryUIColor
        lblName.numberOfLines = 1

        imgParticipant.translatesAutoresizingMaskIntoConstraints = false
        imgParticipant.contentMode = .scaleAspectFit

        hStack.addArrangedSubview(imgParticipant)
        hStack.addArrangedSubview(lblName)

        contentView.addSubview(hStack)

        NSLayoutConstraint.activate([
            hStack.leadingAnchor.constraint(equalTo: contentView.leadingAnchor),
            hStack.trailingAnchor.constraint(equalTo: contentView.trailingAnchor),
            hStack.topAnchor.constraint(equalTo: contentView.topAnchor),
            hStack.bottomAnchor.constraint(equalTo: contentView.bottomAnchor),
            imgParticipant.widthAnchor.constraint(equalToConstant: 24),
            imgParticipant.heightAnchor.constraint(equalToConstant: 24),
        ])
    }

    public func setValues(_ viewModel: ThreadViewModel, _ participant: Participant) {
        lblName.text = participant.contactName ?? participant.name ?? "\(participant.firstName ?? "") \(participant.lastName ?? "")"
        let config = ImageLoaderConfig(url: participant.image ?? "", userName: String.splitedCharacter(participant.name ?? participant.username ?? ""))
        imgParticipant.setValues(config: config)
    }
}

extension MentionTableView: UITableViewDelegate {
    public func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let participant = viewModel.mentionListPickerViewModel.mentionList[indexPath.row]
        viewModel.sendContainerViewModel.addMention(participant)
        viewModel.animateObjectWillChange()
    }

    public func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 48
    }
}

extension MentionTableView: UITableViewDataSource {
    public func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let cell = tableView.dequeueReusableCell(withIdentifier: cellIdentifier) as? MentionCell else { return UITableViewCell() }
        let participant = viewModel.mentionListPickerViewModel.mentionList[indexPath.row]
        cell.setValues(viewModel, participant)
        return cell
    }

    public func numberOfSections(in tableView: UITableView) -> Int { 1 }

    public func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return viewModel.mentionListPickerViewModel.mentionList.count
    }
}

struct MentionList_Previews: PreviewProvider {

    struct MentionTableViewWrapper: UIViewRepresentable {
        let viewModel = ThreadViewModel(thread: .init(id: 1))
        func makeUIView(context: Context) -> some UIView { MentionTableView(viewModel: viewModel) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    static var previews: some View {
        MentionTableViewWrapper()
    }
}
