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

struct MainSendButtons: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var showActionButtons: Bool
    @Binding var text: String
    @State var isVideoRecordingSelected = false

    var body: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(animation(appear: !showActionButtons)) {
                    showActionButtons.toggle()
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.white, showActionButtons ? Color.App.hint.opacity(0.5) : Color.App.primary)
                    .frame(width: 26, height: 26)
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius:(24)))
            .buttonStyle(.borderless)
            .fontWeight(.light)

            MultilineTextField(
                text.isEmpty == true ? "Thread.SendContainer.typeMessageHere" : "",
                text: $text,
                textColor: UIColor(named: "message_text"),
                backgroundColor: Color.App.bgSecond,
                mention: true
            )
            .clipShape(RoundedRectangle(cornerRadius:(24)))
            .environment(\.layoutDirection, Locale.current.identifier.contains("fa") ? .rightToLeft : .leftToRight)
            .onChange(of: viewModel.textMessage ?? "") { newValue in
                viewModel.sendStartTyping(newValue)
            }

            let showAudio = text.isEmpty && !isVideoRecordingSelected
            Button {
                viewModel.attachmentsViewModel.clear()
                viewModel.setupRecording()
            } label: {
                Image(systemName: "mic.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: showAudio ? 26 : 0, height: showAudio ? 26 : 0)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.hint)
            }
            .frame(width: showAudio ? 48 : 0, height: showAudio ? 48 : 0)
            .buttonStyle(.borderless)
            .fontWeight(.light)
            .keyboardShortcut(.init("r"), modifiers: [.command])
            .highPriorityGesture(switchRecordingGesture)
            .transition(.asymmetric(insertion: .move(edge: .bottom).animation(.easeIn(duration: 0.2)), removal: .push(from: .top).animation(.easeOut(duration: 0.2))))

            let showCamera = text.isEmpty && isVideoRecordingSelected
            if showCamera {
                Button {
                    viewModel.setupRecording()
                } label: {
                    Image(systemName: "camera")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 26, height: 24)
                        .symbolRenderingMode(.palette)
                        .foregroundStyle(Color.App.hint)
                }
                .frame(width: 48, height: 48)
                .buttonStyle(.borderless)
                .fontWeight(.light)
                .keyboardShortcut(.init("r"), modifiers: [.command])
                .disabled(true)
                .opacity(0.2)
                .highPriorityGesture(switchRecordingGesture)
                .transition(.asymmetric(insertion: .move(edge: .bottom).animation(.easeIn(duration: 0.2)), removal: .push(from: .top).animation(.easeOut(duration: 0.2))))
            }

            Button {
                if showSendButton {
                    viewModel.sendTextMessage(text)
                }
                text = ""
                viewModel.sheetType = nil
                viewModel.animateObjectWillChange()
                UserDefaults.standard.removeObject(forKey: "draft-\(viewModel.threadId)")
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: showSendButton ? 26 : 0, height: showSendButton ? 26 : 0)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.white, Color.App.primary)
            }
            .frame(width: showSendButton ? 48 : 0, height: showSendButton ? 48 : 0)
            .buttonStyle(.borderless)
            .fontWeight(.light)
            .keyboardShortcut(.return, modifiers: [.command])
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.3), value: isVideoRecordingSelected)
    }

    private var showSendButton: Bool {
        !text.isEmpty || viewModel.attachmentsViewModel.attachments.count > 0 || AppState.shared.appStateNavigationModel.forwardMessageRequest != nil
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }

    private var switchRecordingGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onEnded { newValue in
                if abs(newValue.translation.height) > 32 {
                    isVideoRecordingSelected.toggle()
                }
            }
    }
}

struct MainSendButtons_Previews: PreviewProvider {
    static var previews: some View {
        MainSendButtons(showActionButtons: .constant(true), text: .constant("test"))
    }
}
