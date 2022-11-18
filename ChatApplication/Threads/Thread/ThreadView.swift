//
//  ThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import FanapPodChatSDK
import SwiftUI

struct ViewOffsetKey: PreferenceKey {
    typealias Value = CGFloat
    static var defaultValue = CGFloat.zero
    static func reduce(value: inout Value, nextValue: () -> Value) {
        value += nextValue()
    }
}

struct ThreadView: View {
    @ObservedObject
    var viewModel: ThreadViewModel

    @State
    var showThreadDetailButton = false

    @State
    var showAttachmentDialog: Bool = false

    @State
    var isInEditMode: Bool = false

    @State
    var showDeleteSelectedMessages: Bool = false

    @State
    var showSelectThreadToForward: Bool = false

    @Environment(\.colorScheme) var colorScheme

    @Environment(\.isPreview) var isPreview

    @State
    var showMoreButton = false

    @State
    var showDatePicker = false

    @State
    var showExportFileURL = false

    @State
    var scrollingUP = false

    var body: some View {
        let _ = Self._printChanges()
        ZStack {
            VStack {
                ScrollViewReader { scrollView in
                    ZStack {
                        threadMessages
                            .background(
                                background
                            )
                        goToBottomOfThread(scrollView: scrollView)
                    }
                }
                .onTapGesture {
                    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
                }

                SendContainer(viewModel: viewModel,
                              showAttachmentDialog: $showAttachmentDialog,
                              showDeleteSelectedMessages: $showDeleteSelectedMessages,
                              showSelectThreadToForward: $showSelectThreadToForward)

                NavigationLink(destination: ThreadDetailView().environmentObject(viewModel), isActive: $showThreadDetailButton) {
                    EmptyView()
                }
            }
            .background(Color.gray.opacity(0.15).edgesIgnoringSafeArea(.bottom))
            .customDialog(isShowing: $showDeleteSelectedMessages) {
                PrimaryCustomDialog(title: "Delete selected messages",
                                    message: "Are you sure you want to delete all selected messages?",
                                    systemImageName: "trash.fill",
                                    hideDialog: $showDeleteSelectedMessages) { _ in
                    viewModel.deleteMessages(viewModel.selectedMessages)
                }
                .padding()
            }
            AttachmentDialog(showAttachmentDialog: $showAttachmentDialog, viewModel: ActionSheetViewModel(threadViewModel: viewModel))

            if showDatePicker {
                DateSelectionView(showDialog: $showDatePicker) { startDate, endDate in
                    showDatePicker.toggle()
                    viewModel.exportMessagesVM.exportChats(startDate: startDate, endDate: endDate)
                }
            }
        }
        .toolbar {
            ToolbarItemGroup(placement: .navigationBarTrailing) {
                trailingToolbar
            }

            ToolbarItem(placement: .principal) {
                centerToolbarTitle
            }
        }
        .onChange(of: viewModel.seachableText, perform: { _ in
            viewModel.searchInsideThread()
        })
        .searchable(text: $viewModel.seachableText, placement: .toolbar, prompt: "Search inside this chat") {
            if viewModel.searchedMessages.count == 0 {
                Text("Nothing found.")
                    .foregroundColor(.gray.opacity(0.9))
            } else {
                ForEach(viewModel.searchedMessages, id: \.self) { message in
                    SearchMessageRow(message: message)
                        .onAppear {
                            if message == viewModel.searchedMessages.last {
                                viewModel.searchInsideThread(offset: viewModel.searchedMessages.count)
                            }
                        }
                }
            }
        }
        .animation(.easeInOut, value: showDatePicker)
        .animation(.easeInOut, value: viewModel.messages)
        .animation(.easeInOut, value: viewModel.messages.count)
        .animation(.easeInOut, value: viewModel.searchedMessages.count)
        .animation(.easeInOut, value: showExportFileURL)
        .animation(.easeInOut, value: viewModel.isInEditMode)
        .animation(.easeInOut, value: viewModel.editMessage)
        .onChange(of: viewModel.isInEditMode) { _ in
            isInEditMode = viewModel.isInEditMode
        }
        .onChange(of: viewModel.editMessage) { _ in
            viewModel.textMessage = viewModel.editMessage?.message ?? ""
        }
        .onReceive((viewModel.exportMessagesVM as! ExportMessagesViewModel).$filePath, perform: { filePath in
            showExportFileURL = filePath != nil
        })
        .onAppear {
            if isPreview {
                viewModel.setupPreview()
            }
            viewModel.getHistory()
        }
        .sheet(isPresented: $showExportFileURL, onDismiss: {
            viewModel.exportMessagesVM.deleteFile()
        }, content: {
            if let exportFileUrl = viewModel.exportMessagesVM.filePath {
                ActivityViewControllerWrapper(activityItems: [exportFileUrl])
            } else {
                EmptyView()
            }
        })
        .sheet(isPresented: $showSelectThreadToForward, onDismiss: nil, content: {
            SelectThreadContentList { selectedThread in
                viewModel.sendForwardMessage(selectedThread)
            }
        })
    }

    @ViewBuilder
    func goToBottomOfThread(scrollView: ScrollViewProxy) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    withAnimation(.easeInOut) {
                        if let index = viewModel.messages.firstIndex(where: { $0.uniqueId == viewModel.messages.last?.uniqueId }) {
                            scrollView.scrollTo(viewModel.messages[index].uniqueId, anchor: .top)
                        }
                    }
                } label: {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .foregroundColor(Color.gray)
                        .aspectRatio(contentMode: .fit)
                }
                .frame(width: 24, height: 24)
                .padding(8)
                .background(Color.white)
                .cornerRadius(36)
                .contentShape(Rectangle())
            }
            .padding(.bottom, 16)
            .padding([.trailing], 8)
        }
    }

    var centerToolbarTitle: some View {
        VStack(alignment: .center) {
            Text(viewModel.thread.title ?? "")
                .fixedSize()
                .font(.headline)

            if let signalMessageText = viewModel.signalMessageText {
                Text(signalMessageText)
                    .foregroundColor(Color(named: "text_color_blue"))
                    .font(.subheadline.bold())
            }

            if let participantsCount = viewModel.thread.participantCount {
                Text("Members \(participantsCount)")
                    .fixedSize()
                    .foregroundColor(Color.gray)
                    .font(.footnote)
            }

            ConnectionStatusToolbar()
        }
    }

    @ViewBuilder
    var trailingToolbar: some View {

        let token = isPreview ? "FAKE_TOKEN" : TokenManager.shared.getSSOTokenFromUserDefaults()?.accessToken
        Avatar(
            url: viewModel.thread.image,
            userName: viewModel.thread.inviter?.username?.uppercased(),
            style: .init(size: 32),
            size: .MEDIUM,
            token: token
        )
        .onTapGesture {
            showThreadDetailButton.toggle()
        }
        .cornerRadius(18)

        Menu {
            Button {
                showDatePicker.toggle()
            } label: {
                Label {
                    Text("Export")
                } icon: {
                    Image(systemName: "square.and.arrow.up")
                        .resizable()
                        .scaledToFit()
                }
            }
        } label: {
            Image(systemName: "ellipsis")
        }
    }

    var background: some View {
        ZStack {
            Image("chat_bg")
                .resizable(resizingMode: .tile)
                .renderingMode(.template)
                .opacity(colorScheme == .dark ? 0.9 : 0.25)
                .colorInvert()
                .colorMultiply(colorScheme == .dark ? Color.white : Color.cyan)
            let darkColors: [Color] = [.gray.opacity(0.5), .white.opacity(0.001)]
            let lightColors: [Color] = [.white.opacity(0.1), .gray.opacity(0.5)]
            LinearGradient(gradient: Gradient(colors: colorScheme == .dark ? darkColors : lightColors),
                           startPoint: .top,
                           endPoint: .bottom)
        }
    }

    var threadMessages: some View {
        ScrollView {
            LazyVStack(spacing: 8) {
                ListLoadingView(isLoading: $viewModel.isLoading)
                ForEach(viewModel.messages, id: \.uniqueId) { message in
                    MessageRow(viewModel: .init(message: message), isInEditMode: $isInEditMode)
                        .environmentObject(viewModel)
                        .onAppear {
                            viewModel.sendSeenMessageIfNeeded(message)
                        }
                }
                ListLoadingView(isLoading: $viewModel.isLoading)
            }
            .background(
                GeometryReader {
                    Color.clear.preference(key: ViewOffsetKey.self, value: -$0.frame(in: .named("scroll")).origin.y)
                }
            )
            .padding(.bottom)
            .padding([.leading, .trailing])
        }
        .simultaneousGesture(
            DragGesture().onChanged { value in
                scrollingUP = value.translation.height > 0
            }
        )
        .coordinateSpace(name: "scroll")
        .onPreferenceChange(ViewOffsetKey.self) { value in
            if value < 64, scrollingUP {
                viewModel.loadMoreMessage()
            }
        }
    }
}

struct SendContainer: View {
    @StateObject var viewModel: ThreadViewModel

    @Binding
    var showAttachmentDialog: Bool

    @Binding
    var showDeleteSelectedMessages: Bool

    @Binding
    var showSelectThreadToForward: Bool

    var body: some View {
        if viewModel.isInEditMode {
            VStack {
                HStack {
                    Image(systemName: "xmark.circle.fill")
                        .font(.system(size: 24))
                        .foregroundColor(Color.blue)
                        .onTapGesture {
                            viewModel.setIsInEditMode(false)
                        }

                    Text("\(viewModel.selectedMessages.count) selected \(viewModel.forwardMessage != nil ? "to forward" : "")")
                        .offset(x: 8)
                    Spacer()
                    Image(systemName: "trash.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color(named: "red_soft"))
                        .padding()
                        .onTapGesture {
                            showDeleteSelectedMessages.toggle()
                        }

                    Image(systemName: "arrowshape.turn.up.right.fill")
                        .font(.system(size: 20))
                        .foregroundColor(Color.blue)
                        .padding()
                        .onTapGesture {
                            showSelectThreadToForward.toggle()
                        }
                }.padding(8)
                Divider()
            }
            .animation(.easeInOut, value: viewModel.selectedMessages.count)
        } else {
            VStack {
                if let replyMessage = viewModel.replyMessage {
                    HStack {
                        Image(systemName: "xmark.circle.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.blue)
                            .onTapGesture {
                                viewModel.setReplyMessage(nil)
                            }
                        Text(replyMessage.message ?? replyMessage.metaData?.name ?? "")
                            .offset(x: 8)
                            .onTapGesture {
                                // TODO: Go to reply message location
                            }
                        Spacer()
                        Image(systemName: "arrowshape.turn.up.left.fill")
                            .font(.system(size: 24))
                            .foregroundColor(Color.gray)
                    }.padding(8)
                    Divider()
                }

                HStack {
                    Image(systemName: "paperclip")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray)
                        .onTapGesture {
                            showAttachmentDialog.toggle()
                        }
                    MultilineTextField(viewModel.textMessage == "" ? "Type message here ..." : "", text: $viewModel.textMessage, textColor: Color.black)
                        .cornerRadius(16)
                        .onChange(of: viewModel.textMessage) { newValue in
                            viewModel.textChanged(newValue)
                        }

                    AudioRecordingView(viewModel: .init(threadViewModel: viewModel))

                    if viewModel.audioRecoderVM.isRecording == false {
                        Button {
                            viewModel.sendTextMessage(viewModel.textMessage)
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.blue)
                        }
                    }
                }
                .padding(8)
                .opacity(viewModel.thread.type == .channel ? 0.3 : 1.0)
                .disabled(viewModel.thread.type == .channel)
            }
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var previews: some View {
        let vm = ThreadViewModel(thread: MockData.thread)
        ThreadView(viewModel: vm, showAttachmentDialog: false)
            .environmentObject(AppState.shared)
            .onAppear {
//                vm.toggleRecording()
//                vm.setReplyMessage(MockData.message)
//                vm.setForwardMessage(MockData.message)
                vm.setIsInEditMode(false)
            }
    }
}
