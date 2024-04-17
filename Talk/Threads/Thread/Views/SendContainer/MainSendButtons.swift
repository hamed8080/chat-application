//
//  MainSendButtons.swift
//  Talk
//
//  Created by hamed on 11/3/23.
//

import SwiftUI
import TalkViewModels
import TalkExtensions
import TalkUI
import TalkModels

struct MainSendButtons: View {
    @EnvironmentObject var viewModel: SendContainerViewModel
    @EnvironmentObject var threadVM: ThreadViewModel
    @State private var showCaptureImageView = false
    @State private var showCaptureVideoView = false
    @State private var showPopover = false

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            actionButtonsToggleView
            textFieldView
            micOrCameraView
            sendButtonView
        }
        .animation(.easeInOut, value: viewModel.isVideoRecordingSelected)
        .fullScreenCover(isPresented: $showCaptureImageView) {
            CameraCapturer(isVideo: false) { image, _, asset in
                onImageCapture(image)
            }
            .ignoresSafeArea()
        }
        .fullScreenCover(isPresented: $showCaptureVideoView) {
            CameraCapturer(isVideo: true) { _, videoURL, asset in
                onVideoCapture(videoURL)
            }
            .ignoresSafeArea()
        }
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }

    private func onImageCapture(_ image: UIImage?) {
        guard let image = image else { return }
        let item = ImageItem(data: image.jpegData(compressionQuality: 80) ?? Data(),
                             width: Int(image.size.width),
                             height: Int(image.size.height),
                             originalFilename: "Talk-\(Date().millisecondsSince1970).jpg")
        threadVM.attachmentsViewModel.addSelectedPhotos(imageItem: item)
        threadVM.animateObjectWillChange()
    }

    private func onVideoCapture(_ videoURL: URL?) {
        guard let videoURL = videoURL else { return }
        threadVM.attachmentsViewModel.addFileURL(url: videoURL)
        threadVM.animateObjectWillChange()
    }

    private var micOrCameraView: some View {
        ZStack {
            HStack {
                Image(systemName: "mic")
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: viewModel.showAudio ? 20 : 0, height: viewModel.showAudio ? 20 : 0)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.textSecondary)
            }
            .frame(width: viewModel.showAudio ? 48 : 0, height: viewModel.showAudio ? 48 : 0)
            .fontWeight(.light)
            .onTapGesture {
                viewModel.isVideoRecordingSelected.toggle()
            }
            .onLongPressGesture {
                threadVM.attachmentsViewModel.clear()
                threadVM.setupRecording()
            }
            .transition(.opacity)

            if viewModel.showCamera {
                HStack {
                    Image(systemName: "camera")
                        .interpolation(.none)
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 24)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.App.textSecondary)
                }
                .frame(width: 48, height: 48)
                .fontWeight(.light)
                .popover(isPresented: $showPopover) {
                    VStack(alignment: .leading, spacing: 32) {
                        Button {
                            showPopover.toggle()
                            showCaptureVideoView.toggle()
                        } label: {
                            Label("Video", systemImage: "video")
                        }

                        Button {
                            showPopover.toggle()
                            showCaptureImageView.toggle()
                        } label: {
                            Label("Photo", systemImage: "photo.fill.on.rectangle.fill")
                        }
                    }
                    .buttonStyle(.borderless)
                    .foregroundStyle(Color.App.accent)
                    .font(.headline)
                    .fontWeight(.medium)
                    .padding()
                    .presentationCompactAdaptation(.popover)
                }
                .onTapGesture {
                    viewModel.isVideoRecordingSelected.toggle()
                }
                .onLongPressGesture {
                    showPopover.toggle()
                }
                .transition(.opacity)
            }
        }
    }

    @ViewBuilder
    private var sendButtonView: some View {
        if viewModel.showSendButton {
            Button {
                if viewModel.showSendButton {
                    threadVM.sendMessageViewModel.sendTextMessage()
                }
                threadVM.mentionListPickerViewModel.text = ""
                threadVM.sheetType = nil
                threadVM.animateObjectWillChange()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .interpolation(.none)
                    .resizable()
                    .scaledToFit()
                    .frame(width: viewModel.showSendButton ? 26 : 0, height: viewModel.showSendButton ? 26 : 0)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.white, Color.App.accent)
            }
            .frame(width: viewModel.showSendButton ? 48 : 0, height: viewModel.showSendButton ? 48 : 0)
            .buttonStyle(.borderless)
            .fontWeight(.light)
        }
    }

    private var actionButtonsToggleView: some View {
        Button {
            withAnimation(animation(appear: !viewModel.showActionButtons)) {
                viewModel.showActionButtons.toggle()
            }
        } label: {
            Image(systemName: viewModel.showActionButtons ? "chevron.down" : "paperclip")
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: viewModel.showActionButtons ? 16 : 20, height: viewModel.showActionButtons ? 16 : 20)
                .symbolRenderingMode(.palette)
                .foregroundStyle(Color.App.accent)
                .fontWeight(.medium)
        }
        .frame(width: 42, height: 42)
        .background(Color.App.bgSendInput)
        .clipShape(RoundedRectangle(cornerRadius:(22)))
        .buttonStyle(.borderless)
        .fontWeight(.light)
    }

    private var textFieldView: some View {
        MultilineTextField(
            "Thread.SendContainer.typeMessageHere",
            text: $viewModel.textMessage,
            textColor: UIColor(named: "text_primary"),
            backgroundColor: Color.App.bgSendInput,
            placeholderColor: Color.App.textPrimary.opacity(0.7),
            mention: true,
            focus: $viewModel.focusOnTextInput
        )
        .clipShape(RoundedRectangle(cornerRadius:(24)))
        .environment(\.layoutDirection, Locale.current.identifier.contains("fa") ? .rightToLeft : .leftToRight)
    }
}

struct MainSendButtons_Previews: PreviewProvider {
    static var previews: some View {
        MainSendButtons()
    }
}
