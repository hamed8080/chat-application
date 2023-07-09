//
//  SendContainer.swift
//  ChatApplication
//
//  Created by hamed on 3/13/23.
//

import AdditiveUI
import ChatAppUI
import ChatAppViewModels
import SwiftUI

struct SendContainer: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var deleteMessagesDialog: Bool
    @State var text: String = ""
    @State var isRecording = false
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    let threadId: Int?

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                if viewModel.isInEditMode {
                    SelectionView(deleteMessagesDialog: $deleteMessagesDialog)
                } else {
                    ReplyMessageViewPlaceholder()
                    MentionList(text: $text)
                        .frame(maxHeight: 320)
                    EditMessagePlaceholderView()
                    AudioRecordingView()
                        .environmentObject(viewModel.audioRecoderVM)
                    HStack {
                        if isRecording == false {
                            GradientImageButton(image: "paperclip", title: "Voice Recording") {
                                viewModel.sheetType = .attachment
                                viewModel.animatableObjectWillChange()
                            }
                        }

                        MultilineTextField(text.isEmpty == true ? "Type message here ..." : "", text: $text, textColor: Color.black, mention: true)
                            .cornerRadius(16)
                            .onChange(of: viewModel.textMessage ?? "") { newValue in
                                viewModel.sendStartTyping(newValue)
                            }
                        if isRecording == false {
                            GradientImageButton(image: "mic.fill", title: "Voice Recording") {
                                viewModel.audioRecoderVM.toggle()
                                viewModel.animatableObjectWillChange()
                            }
                            .keyboardShortcut(.init("r"), modifiers: [.command])
                        }

                        GradientImageButton(image: "arrow.up.circle.fill", title: "Send") {
                            if isRecording {
                                viewModel.audioRecoderVM.stopAndSend()
                            } else if !text.isEmpty {
                                viewModel.sendTextMessage(text)
                            }
                            text = ""
                            viewModel.sheetType = nil
                            viewModel.animatableObjectWillChange()
                            UserDefaults.standard.removeObject(forKey: "draft-\(viewModel.threadId)")
                        }
                        .keyboardShortcut(.return, modifiers: [.command])
                    }
                }
            }
            .opacity(viewModel.thread?.disableSend ?? false ? 0.3 : 1.0)
            .disabled(viewModel.thread?.disableSend ?? false)
            .padding(.bottom, 4)
            .padding([.leading, .trailing], 8)
            .padding(.top, 18)
            .background(
                VStack {
                    Spacer()
                    Rectangle()
                        .fill(Color.clear)
                        .background(.ultraThinMaterial)
                        .cornerRadius(24, corners: [.topRight, .topLeft])
                }
                .ignoresSafeArea()
            )
            .onReceive(viewModel.$editMessage) { editMessage in
                text = editMessage?.message ?? ""
            }
            .onChange(of: text) { newValue in
                viewModel.searchForParticipantInMentioning(newValue)
                viewModel.textMessage = newValue
                if !newValue.isEmpty {
                    UserDefaults.standard.setValue(newValue, forKey: "draft-\(viewModel.threadId)")
                } else {
                    UserDefaults.standard.removeObject(forKey: "draft-\(viewModel.threadId)")
                }
            }
            .onReceive(viewModel.audioRecoderVM.$isRecording) { isRecording in
                self.isRecording = isRecording
            }
            .onAppear {
                if let threadId = threadId, let draft = UserDefaults.standard.string(forKey: "draft-\(threadId)"), !draft.isEmpty {
                    text = draft
                }
            }
        }
    }

    private func animation(appear: Bool) -> Animation {
        appear ? .spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2) : .easeOut(duration: 0.13)
    }
}

struct SelectionView: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var deleteMessagesDialog: Bool

    var body: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.blue)
                .onTapGesture {
                    viewModel.isInEditMode = false
                    viewModel.selectedMessages = []
                    viewModel.animatableObjectWillChange()
                }

            Text("\(viewModel.selectedMessages.count) selected \(viewModel.forwardMessage != nil ? "to forward" : "")")
                .offset(x: 8)
            Spacer()
            Image(systemName: "trash.fill")
                .font(.system(size: 20))
                .foregroundColor(.redSoft)
                .padding()
                .onTapGesture {
                    deleteMessagesDialog.toggle()
                }

            Image(systemName: "arrowshape.turn.up.right.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.blue)
                .padding()
                .onTapGesture {
                    viewModel.sheetType = .threadPicker
                    viewModel.animatableObjectWillChange()
                }
        }
    }
}

struct ReplyMessageViewPlaceholder: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if let replyMessage = viewModel.replyMessage {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.blue)
                    .onTapGesture {
                        viewModel.replyMessage = nil
                        viewModel.selectedMessages = []
                        viewModel.animatableObjectWillChange()
                    }
                Text(replyMessage.message ?? replyMessage.fileMetaData?.name ?? "")
                    .font(.iransansBody)
                    .offset(x: 8)
                    .onTapGesture {
                        // TODO: Go to reply message location
                    }
                Spacer()
                Image(systemName: "arrowshape.turn.up.left.fill")
                    .font(.system(size: 16))
                    .scaledToFit()
                    .foregroundColor(Color.gray)
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .padding(8)
        }
    }
}

struct EditMessagePlaceholderView: View {
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if let editMessage = viewModel.editMessage {
            HStack {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 24))
                    .foregroundColor(Color.blue)
                    .onTapGesture {
                        viewModel.isInEditMode = false
                        viewModel.editMessage = nil
                        viewModel.textMessage = nil
                        viewModel.animatableObjectWillChange()
                    }

                Text("\(editMessage.message ?? "")")
                    .font(.iransansBody)
                    .offset(x: 8)
                Spacer()
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .padding(.bottom)
        }
    }
}

struct SendContainer_Previews: PreviewProvider {
    static var previews: some View {
        SendContainer(deleteMessagesDialog: .constant(true), threadId: 0)
            .environmentObject(ThreadViewModel())
    }
}

struct GradientImageButton: View {
    var image: String
    var title: String
    var action: () -> Void

    var body: some View {
        Button {
            action()
        } label: {
            ZStack {
                Text(title)
                    .frame(width: 0, height: 0)
                    .allowsHitTesting(false)
                    .disabled(true)
                LinearGradient(gradient: Gradient(colors: [.blue, .purple]), startPoint: .top, endPoint: .bottom)
                    .mask {
                        Image(systemName: image)
                            .resizable()
                            .scaledToFit()
                            .frame(width: 24, height: 24)
                    }
                    .frame(maxWidth: 24, maxHeight: 24)
            }
        }
    }
}
