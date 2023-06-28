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
                    EditMessagePlaceholderView()
                    HStack {
                        Image(systemName: "paperclip")
                            .resizable()
                            .frame(width: 24, height: 24)
                            .font(.system(size: 24))
                            .foregroundColor(.orange)
                            .onTapGesture {
                                viewModel.sheetType = .attachment
                            }

                        MultilineTextField(text.isEmpty == true ? "Type message here ..." : "", text: $text, textColor: Color.black, mention: true)
                            .cornerRadius(16)
                            .onChange(of: viewModel.textMessage ?? "") { newValue in
                                viewModel.sendStartTyping(newValue)
                            }

                        AudioRecordingView(viewModel: .init(threadViewModel: viewModel))

                        if viewModel.audioRecoderVM.isRecording == false {
                            Button {
                                viewModel.sendTextMessage(text)
                                text = ""
                                viewModel.sheetType = nil
                                UserDefaults.standard.removeObject(forKey: "draft-\(viewModel.threadId)")
                            } label: {
                                ZStack {
                                    Text("Send")
                                        .frame(width: 0, height: 0)
                                        .allowsHitTesting(false)
                                        .disabled(true)
                                    Image(systemName: "arrow.up.circle.fill")
                                        .font(.system(size: 24))
                                        .foregroundColor(Color.blue)
                                }
                            }
                            .keyboardShortcut(.return, modifiers: [.command])
                        }
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
            .animation(.easeInOut, value: viewModel.mentionList.count)
            .animation(.easeInOut, value: viewModel.selectedMessages.count)
            .animation(.easeInOut, value: viewModel.isInEditMode)
            .animation(.easeInOut, value: viewModel.replyMessage)
            .onReceive(viewModel.$editMessage) { editMessage in
                if let editMessage = editMessage {
                    text = editMessage.message ?? ""
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
            .animation(.easeInOut, value: viewModel.replyMessage)
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
                    }

                Text("\(editMessage.message ?? "")")
                    .font(.iransansBody)
                    .offset(x: 8)
                Spacer()
            }
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
            .padding(.bottom)
            .animation(.easeInOut, value: viewModel.editMessage)
        }
    }
}

struct SendContainer_Previews: PreviewProvider {
    static var previews: some View {
        SendContainer(deleteMessagesDialog: .constant(true), threadId: 0)
    }
}
