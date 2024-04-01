//
//  AudioRecordingView.swift
//  TalkUI
//
//  Created by hamed on 10/22/22.
//

import SwiftUI
import TalkViewModels
import ChatModels
import DSWaveformImage
import Combine

public final class AudioRecordingView: UIStackView {
    private let recordedAudioView: RecordedAudioView
    private let recordingAudioView: RecordingAudioView

    public init(viewModel: ThreadViewModel) {
        recordedAudioView = RecordedAudioView(viewModel: viewModel)
        recordingAudioView = RecordingAudioView(viewModel: viewModel.audioRecoderVM)
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        axis = .horizontal
        spacing = 0

        addArrangedSubview(recordedAudioView)
        addArrangedSubview(recordingAudioView)
    }
}

public final class RecordedAudioView: UIStackView {
    private let btnSend = CircularUIButton()
    private let lblTimer = UILabel()
    private let waveImageView = UIImageView()
    private let btnTogglePlayer = UIButton(type: .system)
    private var cancellableSet = Set<AnyCancellable>()
    private let viewModel: ThreadViewModel
    private var audioRecoderVM: AudioRecordingViewModel { viewModel.audioRecoderVM }
    private var audioPlayerVM: AVAudioPlayerViewModel { AppState.shared.objectsContainer.audioPlayerVM }
    @State var image: UIImage = .init()

    public init(viewModel: ThreadViewModel) {
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
        spacing = 0
        alignment = .leading

        let image = UIImage(systemName: "arrow.up") ?? .init()
        btnSend.setup(image: image) { [weak self] in
            self?.viewModel.sendMessageViewModel.sendAudiorecording()
        }

        let btnDelete = UIButton(type: .system)
        btnDelete.addTarget(self, action: #selector(deleteTapped), for: .touchUpInside)
        btnDelete.translatesAutoresizingMaskIntoConstraints = false
        let deleteImage = UIImage(systemName: "trash")
        btnDelete.setImage(deleteImage, for: .normal)
        btnDelete.tintColor = Color.App.textPrimaryUIColor

        lblTimer.textColor = Color.App.textPrimaryUIColor
        lblTimer.font = .uiiransansCaption2

        btnTogglePlayer.translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(btnSend)
        addArrangedSubview(lblTimer)
        addArrangedSubview(waveImageView)
        addArrangedSubview(btnDelete)

        NSLayoutConstraint.activate([
            btnSend.widthAnchor.constraint(equalToConstant: 48),
            btnSend.heightAnchor.constraint(equalToConstant: 48),
            btnSend.widthAnchor.constraint(equalToConstant: 48),
            btnDelete.widthAnchor.constraint(equalToConstant: 48),
            btnDelete.heightAnchor.constraint(equalToConstant: 48),
            btnTogglePlayer.widthAnchor.constraint(equalToConstant: 48),
            btnTogglePlayer.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func setup() {
        Task {
            do {
                guard let url = audioPlayerVM.fileURL else { return }
                let waveformImageDrawer = WaveformImageDrawer()
                let image = try await waveformImageDrawer.waveformImage(
                    fromAudioAt: url,
                    with: .init(
                        size: .init(width: 250, height: 48),
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
        audioRecoderVM.$timerString.sink { [weak self] timerString in
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
        audioRecoderVM.cancel()
        audioPlayerVM.close()
    }

    @objc private func onTogglePlayerTapped(_ sender: UIButton) {
        audioPlayerVM.toggle()
    }
}

public final class RecordingAudioView: UIStackView {
    private let btnMic = CircularUIButton()
    private let lblTimer = UILabel()
    private let dotRecordingIndicator = UIImageView()
    private let viewModel: AudioRecordingViewModel
    @State var opacity: Double = 0
    @State var scale: CGFloat = 0.5

    public init(viewModel: AudioRecordingViewModel) {
        self.viewModel = viewModel
        super.init(frame: .zero)
        configureView()
    }

    required init(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func configureView() {
        axis = .horizontal
        spacing = 0

        btnMic.translatesAutoresizingMaskIntoConstraints = false
        let micImage = UIImage(systemName: "mic.fill")!
        btnMic.setup(image: micImage, forgroundColor: Color.App.textPrimaryUIColor!)

        let lblStaticRecording = UILabel()
        lblStaticRecording.text = "Thread.isVoiceRecording".localized()
        lblStaticRecording.font = .uiiransansCaption
        lblStaticRecording.textColor = Color.App.textSecondaryUIColor

        lblTimer.font = .uiiransansBody
        lblTimer.textColor = Color.App.textPrimaryUIColor

        dotRecordingIndicator.image = UIImage(systemName: "circle.fill")
        dotRecordingIndicator.tintColor = Color.App.redUIColor
        dotRecordingIndicator.translatesAutoresizingMaskIntoConstraints = false

        addArrangedSubview(btnMic)
        addArrangedSubview(lblStaticRecording)
        addArrangedSubview(lblTimer)
        addArrangedSubview(dotRecordingIndicator)

        NSLayoutConstraint.activate([
            dotRecordingIndicator.widthAnchor.constraint(equalToConstant: 6),
            dotRecordingIndicator.heightAnchor.constraint(equalToConstant: 6),
            btnMic.widthAnchor.constraint(equalToConstant: 48),
            btnMic.heightAnchor.constraint(equalToConstant: 48),
        ])
    }

    private func micTapped(_ sender: UIButton) {
        viewModel.stop()
        if let fileURL = viewModel.recordingOutputPath {
            try? AppState.shared.objectsContainer.audioPlayerVM.setup(fileURL: fileURL,
                                                                      ext: fileURL.fileExtension,
                                                                      title: fileURL.fileName,
                                                                      subtitle: "")
        }
    }

    private func circleAnimation() {
        Timer.scheduledTimer(withTimeInterval: 1.5, repeats: true) { _ in
            withAnimation(.interpolatingSpring(mass: 0.5, stiffness: 0.8, damping: 0.8, initialVelocity: 3)) {
//                scale = scale == 1 ? 0.5 : 1
            }
        }
    }
}

struct AudioRecordingView_Previews: PreviewProvider {
    @Namespace static var id
    static var threadVM = ThreadViewModel(thread: MockData.thread)
    static var viewModel: AudioRecordingViewModel {
        let viewModel = AudioRecordingViewModel()
        viewModel.threadViewModel = threadVM
        return viewModel
    }

    struct AudioRecordingViewWrapper: UIViewRepresentable {
        let viewModel: ThreadViewModel
        func makeUIView(context: Context) -> some UIView { AudioRecordingView(viewModel: viewModel) }
        func updateUIView(_ uiView: UIViewType, context: Context) {}
    }

    static var previews: some View {
        AudioRecordingViewWrapper(viewModel: threadVM)
    }
}
