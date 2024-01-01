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

    var body: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(animation(appear: !viewModel.showActionButtons)) {
                    viewModel.showActionButtons.toggle()
                }
            } label: {
                Image(systemName: "plus.circle.fill")
                    .resizable()
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.white, viewModel.showActionButtons ? Color.App.hint.opacity(0.5) : Color.App.primary)
                    .frame(width: 26, height: 26)
            }
            .frame(width: 48, height: 48)
            .clipShape(RoundedRectangle(cornerRadius:(24)))
            .buttonStyle(.borderless)
            .fontWeight(.light)

            MultilineTextField(
                viewModel.textMessage.isEmpty == true ? "Thread.SendContainer.typeMessageHere" : "",
                text: $viewModel.textMessage,
                textColor: UIColor(named: "message_text"),
                backgroundColor: Color.App.bgSecond,
                mention: true,
                focus: $viewModel.focusOnTextInput
            )
            .clipShape(RoundedRectangle(cornerRadius:(24)))
            .environment(\.layoutDirection, Locale.current.identifier.contains("fa") ? .rightToLeft : .leftToRight)
            .onChange(of: viewModel.textMessage) { newValue in
                if Language.isRTL && newValue.first != "\u{200f}" {
                    viewModel.textMessage = "\u{200f}\(viewModel.textMessage)"
                }
                threadVM.sendStartTyping(newValue)
            }

            Button {
                threadVM.attachmentsViewModel.clear()
                threadVM.setupRecording()
            } label: {
                Image(systemName: "mic.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: viewModel.showAudio ? 26 : 0, height: viewModel.showAudio ? 26 : 0)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.hint)
            }
            .frame(width: viewModel.showAudio ? 48 : 0, height: viewModel.showAudio ? 48 : 0)
            .buttonStyle(.borderless)
            .fontWeight(.light)
            //            .keyboardShortcut(.init("r"), modifiers: [.command]) // if enabled we may have memory leak when press the back button in ThreadView check if it works properly.
            .highPriorityGesture(switchRecordingGesture)
            .transition(.asymmetric(insertion: .move(edge: .bottom).animation(.easeIn(duration: 0.2)), removal: .push(from: .top).animation(.easeOut(duration: 0.2))))
            
            if viewModel.showCamera {
                Button {
                    threadVM.setupRecording()
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
                //                .keyboardShortcut(.init("r"), modifiers: [.command]) // if enabled we may have memory leak when press the back button in ThreadView check if it works properly.
                .disabled(true)
                .opacity(0.2)
                .highPriorityGesture(switchRecordingGesture)
                .transition(.asymmetric(insertion: .move(edge: .bottom).animation(.easeIn(duration: 0.2)), removal: .push(from: .top).animation(.easeOut(duration: 0.2))))
            }

            Button {
                if viewModel.showSendButton {
                    threadVM.sendTextMessage(viewModel.textMessage)
                }
                viewModel.textMessage = ""
                threadVM.mentionListPickerViewModel.text = ""
                threadVM.sheetType = nil
                threadVM.animateObjectWillChange()
                UserDefaults.standard.removeObject(forKey: "draft-\(threadVM.threadId)")
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .resizable()
                    .scaledToFit()
                    .frame(width: viewModel.showSendButton ? 26 : 0, height: viewModel.showSendButton ? 26 : 0)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.white, Color.App.primary)
            }
            .frame(width: viewModel.showSendButton ? 48 : 0, height: viewModel.showSendButton ? 48 : 0)
            .buttonStyle(.borderless)
            .fontWeight(.light)
            //            .keyboardShortcut(.return, modifiers: [.command]) // if enabled we may have memory leak when press the back button in ThreadView check if it works properly.
        }
        .animation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.3), value: viewModel.isVideoRecordingSelected)
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }

    private var switchRecordingGesture: some Gesture {
        DragGesture(minimumDistance: 10, coordinateSpace: .local)
            .onEnded { newValue in
                if abs(newValue.translation.height) > 32 {
                    viewModel.isVideoRecordingSelected.toggle()
                }
            }
    }
}

struct MainSendButtons_Previews: PreviewProvider {
    static var previews: some View {
        MainSendButtons()
    }
}
