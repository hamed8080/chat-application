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
    @Binding var isRecording: Bool
    @Binding var text: String

    var body: some View {
        HStack(spacing: 0) {
            if isRecording == false {
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
                .cornerRadius(24)
                .buttonStyle(.borderless)
                .fontWeight(.light)
            }

            MultilineTextField(text.isEmpty == true ? "Thread.SendContainer.typeMessageHere" : "",
                               text: $text,
                               textColor: UIColor(named: "message_text"),
                               backgroundColor: Color.App.bgSecond,
                               mention: true)
            .cornerRadius(24)
            .environment(\.layoutDirection, Locale.current.identifier.contains("fa") ? .rightToLeft : .leftToRight)
            .onChange(of: viewModel.textMessage ?? "") { newValue in
                viewModel.sendStartTyping(newValue)
            }

            if isRecording == false {
                Button {
                    viewModel.setupRecording()
                    isRecording = true
                } label: {
                    Image(systemName: "mic.fill")
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
            }

            Button {
                viewModel.setupRecording()
                isRecording = true
            } label: {
                Image(systemName: "camera")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 26, height: 26)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.hint)
            }
            .frame(width: 48, height: 48)
            .buttonStyle(.borderless)
            .fontWeight(.light)
            .keyboardShortcut(.init("r"), modifiers: [.command])
            .disabled(true)
            .opacity(0.2)

            Button {
                if isRecording {
                    viewModel.audioRecoderVM?.stopAndAddToAttachments()
                    viewModel.sendAttachmentsMessage()
                    isRecording = false
                } else if !text.isEmpty || viewModel.attachmentsViewModel.attachments.count > 0 {
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
                    .frame(width: 26, height: 26)
                    .symbolRenderingMode(.palette)
                    .foregroundStyle(Color.App.white, Color.App.primary)
            }
            .frame(width: 48, height: 48)
            .buttonStyle(.borderless)
            .fontWeight(.light)
            .keyboardShortcut(.return, modifiers: [.command])
        }
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }
}

struct MainSendButtons_Previews: PreviewProvider {
    static var previews: some View {
        MainSendButtons(showActionButtons: .constant(true), isRecording: .constant(false), text: .constant("test"))
    }
}
