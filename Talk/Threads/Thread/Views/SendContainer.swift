//
//  SendContainer.swift
//  Talk
//
//  Created by hamed on 3/13/23.
//

import AdditiveUI
import ChatModels
import Combine
import SwiftUI
import TalkUI
import TalkViewModels

struct SendContainer: View {
    @State private var isInEditMode: Bool = false
    let viewModel: ThreadViewModel
    @Binding var deleteMessagesDialog: Bool
    @State private var text: String = ""
    @State private var isRecording = false
    /// We will need this for UserDefault purposes because ViewModel.thread is nil when the view appears.
    private var threadId: Int? { viewModel.thread.id }
    @Namespace var id

    var body: some View {
        VStack {
            Spacer()
            VStack(spacing: 0) {
                if isInEditMode {
                    SelectionView(viewModel: viewModel, deleteMessagesDialog: $deleteMessagesDialog)
                } else {
                    ReplyMessageViewPlaceholder()
                        .environmentObject(viewModel)
                    MentionList(text: $text)
                        .frame(maxHeight: 320)
                        .environmentObject(viewModel)
                    EditMessagePlaceholderView()
                        .environmentObject(viewModel)
                    if let recordingVM = viewModel.audioRecoderVM {
                        AudioRecordingView(isRecording: $isRecording, nameSpace: id)
                            .environmentObject(recordingVM)
                    }
                    HStack {
                        if isRecording == false {
                            GradientImageButton(image: "paperclip", title: "Thread.SendContainer.attachment") {
                                viewModel.sheetType = .attachment
                                viewModel.animateObjectWillChange()
                            }
                            .matchedGeometryEffect(id: "PAPERCLIPS", in: id)
                        }

                        MultilineTextField(text.isEmpty == true ? "Thread.SendContainer.typeMessageHere" : "", text: $text, textColor: Color.black, mention: true)
                            .cornerRadius(16)
                            .onChange(of: viewModel.textMessage ?? "") { newValue in
                                viewModel.sendStartTyping(newValue)
                            }
                        if isRecording == false {
                            GradientImageButton(image: "mic.fill", title: "Thread.SendContainer.voiceRecording") {
                                viewModel.setupRecording()
                                isRecording = true
                            }
                            .keyboardShortcut(.init("r"), modifiers: [.command])
                        }

                        GradientImageButton(image: "arrow.up.circle.fill", title: "General.send") {
                            if isRecording {
                                viewModel.audioRecoderVM?.stopAndSend()
                                isRecording = false
                            } else if !text.isEmpty {
                                viewModel.sendTextMessage(text)
                            }
                            text = ""
                            viewModel.sheetType = nil
                            viewModel.animateObjectWillChange()
                            UserDefaults.standard.removeObject(forKey: "draft-\(viewModel.threadId)")
                        }
                        .keyboardShortcut(.return, modifiers: [.command])
                    }
                }
            }
            .opacity(disableSend ? 0.3 : 1.0)
            .disabled(disableSend)
            .padding(.bottom, 4)
            .padding([.leading, .trailing], 8)
            .padding(.top, 18)
            .animation(isRecording ? .spring(response: 0.5, dampingFraction: 0.5, blendDuration: 0.3) : .linear, value: isRecording)
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
            .onReceive(viewModel.$isInEditMode) { newValue in
                if newValue != isInEditMode {
                    isInEditMode = newValue
                }
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

    private var disableSend: Bool { viewModel.thread.disableSend && isInEditMode == false }
}

struct SelectionView: View {
    let viewModel: ThreadViewModel
    @State private var selectedCount: Int = 0
    @Binding var deleteMessagesDialog: Bool

    var body: some View {
        HStack {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 24))
                .foregroundColor(Color.blue)
                .onTapGesture {
                    viewModel.isInEditMode = false
                    viewModel.clearSelection()
                    viewModel.animateObjectWillChange()
                }

            HStack(spacing: 2) {
                Text("\(selectedCount)")
                    .fontWeight(.bold)
                Text("General.selected")
                if viewModel.forwardMessage != nil {
                    Text("Thread.SendContainer.toForward")
                }
            }
            .offset(x: 8)
            Spacer()

            /// Disable showing the delete button when forwarding in a conversation where we are not the admin and we just want to forward messages, so the delete button should be hidden.
            if !viewModel.thread.disableSend {
                Image(systemName: "trash.fill")
                    .font(.system(size: 20))
                    .foregroundColor(.redSoft)
                    .padding()
                    .onTapGesture {
                        deleteMessagesDialog.toggle()
                    }
            }

            Image(systemName: "arrowshape.turn.up.right.fill")
                .font(.system(size: 20))
                .foregroundColor(Color.blue)
                .padding()
                .onTapGesture {
                    viewModel.sheetType = .threadPicker
                    viewModel.animateObjectWillChange()
                }
        }
        .onReceive(viewModel.objectWillChange) { _ in
            withAnimation {
                selectedCount = viewModel.selectedMessages.count
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
                        viewModel.clearSelection()
                        viewModel.animateObjectWillChange()
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
                        viewModel.animateObjectWillChange()
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
        SendContainer(viewModel: ThreadViewModel(thread: Conversation(id: 0)), deleteMessagesDialog: .constant(true))
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
            Text(String(localized: .init(title)))
                .frame(width: 0, height: 0)
                .hidden()
                .allowsHitTesting(false)
                .disabled(true)
            LinearGradient(gradient: Gradient(colors: [.blue, .teal]), startPoint: .topLeading, endPoint: .bottomTrailing)
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
