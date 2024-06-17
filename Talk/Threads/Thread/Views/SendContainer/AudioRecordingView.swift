//
//  AudioRecordingView.swift
//  TalkUI
//
//  Created by hamed on 10/22/22.
//

import SwiftUI
import TalkViewModels
import DSWaveformImage
import Combine
import TalkUI

public final class AudioRecordingView: UIStackView {
    private let recordedAudioView: RecordedAudioView
    private let recordingAudioView: RecordingAudioView
    private weak var viewModel: ThreadViewModel?
    fileprivate static let height: CGFloat = 36

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        recordedAudioView = RecordedAudioView(viewModel: viewModel)
        recordingAudioView = RecordingAudioView(viewModel: viewModel?.audioRecoderVM)
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        axis = .vertical
        spacing = 0
        
        recordedAudioView.isHidden = false
        recordingAudioView.isHidden = false
        addArrangedSubview(recordedAudioView)
        addArrangedSubview(recordingAudioView)

        recordingAudioView.onSubmitRecord = { [weak self] in
            self?.onSubmitRecord()
        }

        recordedAudioView.onSendOrClose = { [weak self] in
            guard let self = self else { return }
            recordedAudioView.isHidden = true
            recordingAudioView.isHidden = true
            viewModel?.delegate?.showRecording(false)
        }
    }

    public func show(_ show: Bool) {
        recordedAudioView.isHidden = true
        recordingAudioView.isHidden = !show
        recordingAudioView.alpha = 1.0
        recordedAudioView.alpha = 0.0
        if show {
            recordingAudioView.startCircleAnimation()
        }
    }

    public func onSubmitRecord() {
        UIView.animate(withDuration: 0.2) {
            self.recordingAudioView.alpha = 0.0
            self.recordingAudioView.isHidden = true
            self.recordedAudioView.alpha = 1.0
            self.recordedAudioView.isHidden = false
            self.recordedAudioView.setup()
        }
    }
}

public final class RecordedAudioView: UIStackView {
    private let btnSend = UIImageButton(imagePadding: .init(all: 8))
    private let lblTimer = UILabel()
    private let waveImageView = UIImageView()
    private let btnTogglePlayer = UIButton(type: .system)
    private var cancellableSet = Set<AnyCancellable>()
    private weak var viewModel: ThreadViewModel?
    var onSendOrClose: (()-> Void)?
    private var audioRecoderVM: AudioRecordingViewModel? { viewModel?.audioRecoderVM }
    private var audioPlayerVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }

    public init(viewModel: ThreadViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
        registerObservers()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        axis = .horizontal
        spacing = 8
        alignment = .center
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        let image = UIImage(systemName: "arrow.up") ?? .init()
        btnSend.translatesAutoresizingMaskIntoConstraints = false
        btnSend.imageView.tintColor = Color.App.textPrimaryUIColor!
        btnSend.imageView.contentMode = .scaleAspectFit
        btnSend.imageView.image = image
        btnSend.backgroundColor = Color.App.accentUIColor!
        btnSend.action = { [weak self] in
            self?.onSendOrClose?()
            Task { [weak self] in
                await self?.viewModel?.sendMessageViewModel.sendTextMessage()
            }
        }

        let btnDelete = UIButton(type: .system)
        btnDelete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        btnDelete.translatesAutoresizingMaskIntoConstraints = false
        let deleteImage = UIImage(systemName: "trash")
        btnDelete.setImage(deleteImage, for: .normal)
        btnDelete.tintColor = Color.App.textPrimaryUIColor

        lblTimer.textColor = Color.App.textPrimaryUIColor
        lblTimer.font = .uiiransansCaption2

        waveImageView.translatesAutoresizingMaskIntoConstraints = false

        btnTogglePlayer.translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(btnSend)
        addArrangedSubview(lblTimer)
        addArrangedSubview(waveImageView)
        addArrangedSubview(btnDelete)

        NSLayoutConstraint.activate([
            waveImageView.heightAnchor.constraint(equalToConstant: AudioRecordingView.height / 2),
            btnSend.heightAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnSend.widthAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnDelete.widthAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnDelete.heightAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnTogglePlayer.widthAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnTogglePlayer.heightAnchor.constraint(equalToConstant: AudioRecordingView.height),
        ])
    }

    func setup() {
        Task { [weak self] in
            guard let self = self else { return }
            do {
                guard let url = audioPlayerVM.fileURL else { return }
                let waveformImageDrawer = WaveformImageDrawer()
                let image = try await waveformImageDrawer.waveformImage(
                    fromAudioAt: url,
                    with: .init(
                        size: .init(width: 250, height: AudioRecordingView.height),
                        style: .striped(
                            .init(
                                color: UIColor.white.withAlphaComponent(0.7),
                                width: 3,
                                spacing: 2,
                                lineCap: .round
                            )
                        ),
                        shouldAntialias: true
                    ),
                    renderer: LinearWaveformRenderer()
                )
                await MainActor.run {
                    self.waveImageView.image = image
                }
            } catch {}
        }
    }

    private func registerObservers() {
        audioRecoderVM?.$timerString.sink { [weak self] timerString in
            self?.lblTimer.text = timerString
        }
        .store(in: &cancellableSet)

        audioPlayerVM.$isPlaying.sink { [weak self] isPlaying in
            let image = UIImage(systemName: isPlaying ? "pause.fill" : "play.fill")
            self?.btnTogglePlayer.setImage(image, for: .normal)
        }
        .store(in: &cancellableSet)
    }

    @objc private func deleteTapped(_ sender: UIButton) {
        audioRecoderVM?.cancel()
        audioPlayerVM.close()
        onSendOrClose?()
    }

    @objc private func onTogglePlayerTapped(_ sender: UIButton) {
        audioPlayerVM.toggle()
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        btnSend.layer.cornerRadius = btnSend.bounds.width / 2
    }
}

public final class RecordingAudioView: UIStackView {
    private let btnMic = UIImageButton(imagePadding: .init(all: 8))
    private let dotRecordingIndicator = UIImageView()
    private let lblTimer = UILabel()
    private weak var viewModel: AudioRecordingViewModel?
    private var dotTimer: Timer?
    private var cancellableSet = Set<AnyCancellable>()
    var onSubmitRecord: (()-> Void)?

    public init(viewModel: AudioRecordingViewModel?) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        axis = .horizontal
        spacing = 12
        alignment = .center
        layoutMargins = .init(horizontal: 8, vertical: 4)
        isLayoutMarginsRelativeArrangement = true

        btnMic.translatesAutoresizingMaskIntoConstraints = false
        let micImage = UIImage(systemName: "mic.fill")!
        btnMic.imageView.image = micImage
        btnMic.imageView.tintColor = Color.App.textPrimaryUIColor!
        btnMic.imageView.contentMode = .scaleAspectFit
        btnMic.backgroundColor = Color.App.accentUIColor!
        btnMic.action = { [weak self] in
            self?.micTapped()
        }

        let lblStaticRecording = UILabel()
        lblStaticRecording.text = "Thread.isVoiceRecording".localized()
        lblStaticRecording.font = .uiiransansCaption
        lblStaticRecording.textColor = Color.App.textSecondaryUIColor

        lblTimer.font = .uiiransansBody
        lblTimer.textColor = Color.App.textPrimaryUIColor
        viewModel?.$timerString.sink { [weak self] newValue in
            UIView.animate(withDuration: 0.2) {
                self?.lblTimer.text = newValue
            }
        }
        .store(in: &cancellableSet)

        dotRecordingIndicator.image = UIImage(systemName: "circle.fill")
        dotRecordingIndicator.tintColor = Color.App.redUIColor
        dotRecordingIndicator.translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(btnMic)
        addArrangedSubview(lblStaticRecording)
        addArrangedSubview(lblTimer)
        addArrangedSubview(dotRecordingIndicator)

        NSLayoutConstraint.activate([
            dotRecordingIndicator.widthAnchor.constraint(equalToConstant: 8),
            dotRecordingIndicator.heightAnchor.constraint(equalToConstant: 8),
            btnMic.widthAnchor.constraint(equalToConstant: AudioRecordingView.height),
            btnMic.heightAnchor.constraint(equalToConstant: AudioRecordingView.height),
        ])
    }

    private func micTapped() {
        Task { [weak self] in
            guard let self = self else { return }
            viewModel?.stop()
            if let fileURL = viewModel?.recordingOutputPath {
                let playerVM = AppState.shared.objectsContainer.audioPlayerVM
                try? playerVM.setup(fileURL: fileURL,
                                    ext: fileURL.fileExtension,
                                    title: fileURL.fileName,
                                    subtitle: "")
            }
        }
        stopAnimation()
        onSubmitRecord?()
    }

    func startCircleAnimation() {
        dotTimer = Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            UIView.animate(withDuration: 1.0) {
                let alpha = self.dotRecordingIndicator.alpha
                self.dotRecordingIndicator.alpha = alpha == 1.0 ? 0.2 : 1.0
            }
        }
    }

    private func stopAnimation() {
        dotTimer?.invalidate()
        dotTimer = nil
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        btnMic.layer.cornerRadius = btnMic.bounds.width / 2
    }
}
