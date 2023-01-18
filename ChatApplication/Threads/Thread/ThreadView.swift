//
//  ThreadView.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 6/5/21.
//

import Combine
import FanapPodChatSDK
import SwiftUI

struct ThreadView: View {
    let thread: Conversation
    @StateObject var viewModel = ThreadViewModel()
    @EnvironmentObject var threadsVM: ThreadsViewModel
    @State var showAttachmentDialog: Bool = false
    @State var isInEditMode: Bool = false
    @State var deleteDialaog: Bool = false
    @State var showSelectThreadToForward: Bool = false
    @Environment(\.isPreview) var isPreview
    @State var showMoreButton = false
    @State var showDatePicker = false
    @State var showExportFileURL = false
    @State var searchMessageText: String = ""
    @StateObject var imageLoader = ImageLoader()

    var body: some View {
        ZStack {
            VStack {
                ThreadPinMessage(message: viewModel.messages.filter { $0.pinned == true }.first)
                ZStack {
                    ThreadMessagesList(isInEditMode: $isInEditMode)
                        .environmentObject(viewModel)
                    ThreadSearchList(searchMessageText: $searchMessageText)
                        .environmentObject(viewModel)
                        .zIndex(1)
                }
                .animation(.easeInOut, value: searchMessageText.count)
                .animation(.easeInOut, value: viewModel.searchedMessages.count)
                SendContainer(showAttachmentDialog: $showAttachmentDialog,
                              deleteMessagesDialog: $deleteDialaog,
                              showSelectThreadToForward: $showSelectThreadToForward)
                    .environmentObject(viewModel)
            }
            .background(Color.gray.opacity(0.15).edgesIgnoringSafeArea(.bottom))
            .dialog("Delete selected messages", "Are you sure you want to delete all selected messages?", "trash.fill", $deleteDialaog) { _ in
                viewModel.deleteMessages(viewModel.selectedMessages)
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
        .onChange(of: searchMessageText) { value in
            viewModel.searchInsideThread(text: value)
        }
        .searchable(text: $searchMessageText, placement: .toolbar, prompt: "Search inside this chat")
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
        .onReceive((viewModel.exportMessagesVM as! ExportMessagesViewModel).$filePath) { filePath in
            showExportFileURL = filePath != nil
        }
        .onAppear {
            viewModel.setup(thread: thread, readOnly: false, threadsViewModel: threadsVM)
            viewModel.getHistory()
            imageLoader.fetch(url: viewModel.thread?.computedImageURL, userName: viewModel.thread?.title)
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
        .sheet(isPresented: $showSelectThreadToForward, onDismiss: nil) {
            SelectThreadContentList { selectedThread in
                viewModel.sendForwardMessage(selectedThread)
            }
        }
    }

    var centerToolbarTitle: some View {
        VStack(alignment: .center) {
            Text(viewModel.thread?.title ?? "")
                .fixedSize()
                .font(.headline)

            if let signalMessageText = viewModel.signalMessageText {
                Text(signalMessageText)
                    .foregroundColor(Color(named: "text_color_blue"))
                    .font(.subheadline.bold())
            }

            if let participantsCount = viewModel.thread?.participantCount {
                Text("Members \(participantsCount)")
                    .fixedSize()
                    .foregroundColor(Color.gray)
                    .font(.footnote)
            }

            ConnectionStatusToolbar()
        }
    }

    @ViewBuilder var trailingToolbar: some View {
        NavigationLink {
            DetailView(viewModel: DetailViewModel(thread: viewModel.thread))
        } label: {
            imageLoader.imageView
                .font(.system(size: 16).weight(.heavy))
                .foregroundColor(.white)
                .frame(width: 32, height: 32)
                .background(Color.blue.opacity(0.4))
                .cornerRadius(16)
                .cornerRadius(18)
        }

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
}

struct ThreadMessagesList: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    var isInEditMode: Binding<Bool>
    @State var scrollingUP = false
    @Environment(\.colorScheme) var colorScheme
    @State private var scrollViewHeight = CGFloat.infinity
    @Namespace var scrollViewNameSpace

    var body: some View {
        ScrollViewReader { scrollView in
            ZStack {
                ScrollView {
                    LazyVStack(spacing: 8) {
                        ListLoadingView(isLoading: $viewModel.isLoading)
                        ForEach(viewModel.messages) { message in
                            MessageRow(message: message, isInEditMode: isInEditMode)
                                .id(message.uniqueId)
                                .environmentObject(viewModel)
                                .onAppear {
                                    viewModel.sendSeenMessageIfNeeded(message)
                                    viewModel.setIfNeededToScrollToTheLastPosition(scrollingUP, message)
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
                .onPreferenceChange(ViewOffsetKey.self) { originY in
                    if originY < 64, scrollingUP {
                        viewModel.loadMoreMessage()
                    }
                }
                .onReceive(viewModel.$scrollToUniqueId) { uniqueId in
                    guard let uniqueId = uniqueId else { return }
                    withAnimation {
                        scrollView.scrollTo(uniqueId, anchor: .bottom)
                    }
                }
                .background(
                    background
                )
                goToBottomOfThread(scrollView: scrollView)
            }
        }
        .onTapGesture {
            UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder), to: nil, from: nil, for: nil)
        }
    }

    @ViewBuilder
    func goToBottomOfThread(scrollView _: ScrollViewProxy) -> some View {
        VStack {
            Spacer()
            HStack {
                Spacer()
                Button {
                    viewModel.scrollToBottom()
                } label: {
                    Image(systemName: "chevron.down")
                        .resizable()
                        .scaledToFit()
                        .frame(width: 16, height: 16)
                        .padding()
                        .foregroundColor(Color.gray)
                        .aspectRatio(contentMode: .fit)
                        .contentShape(Rectangle())
                }
                .frame(width: 36, height: 36)
                .background(Color.white)
                .cornerRadius(36)
            }
            .padding(.bottom, 16)
            .padding([.trailing], 8)
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
}

struct ThreadSearchList: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var searchMessageText: String

    var body: some View {
        if searchMessageText.count > 0, viewModel.searchedMessages.count > 0 {
            ScrollView {
                LazyVStack {
                    ForEach(viewModel.searchedMessages) { message in
                        SearchMessageRow(message: message)
                            .onAppear {
                                if message == viewModel.searchedMessages.last {
                                    viewModel.searchInsideThread(text: searchMessageText, offset: viewModel.searchedMessages.count)
                                }
                            }
                    }
                }
            }
            .padding()
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
            .background(.ultraThickMaterial)
        } else if searchMessageText.count > 0 {
            ZStack {
                Text("Nothing found.")
                    .font(.title2.bold())
            }
            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 0, maxHeight: .infinity)
            .background(.ultraThickMaterial)
        }
    }
}

struct ThreadPinMessage: View {
    let message: Message?

    var body: some View {
        if let message = message {
            HStack {
                Text(message.messageTitle)
                Spacer()
                Image(systemName: "pin")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 24, height: 24)
                    .foregroundColor(.orange)
            }
            .frame(height: 64)
        } else {
            EmptyView()
        }
    }
}

struct SendContainer: View {
    @EnvironmentObject var viewModel: ThreadViewModel
    @Binding var showAttachmentDialog: Bool
    @Binding var deleteMessagesDialog: Bool
    @Binding var showSelectThreadToForward: Bool
    @State var text: String = ""

    var body: some View {
        if viewModel.isInEditMode {
            VStack {
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
                        .foregroundColor(Color(named: "red_soft"))
                        .padding()
                        .onTapGesture {
                            deleteMessagesDialog.toggle()
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
                                viewModel.replyMessage = nil
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
                    }
                    .animation(.easeInOut, value: viewModel.replyMessage)
                    .transition(.asymmetric(insertion: .move(edge: .top), removal: .move(edge: .bottom)))
                    .padding(8)
                    Divider()
                }

                MentionList(text: $text)

                HStack {
                    Image(systemName: "paperclip")
                        .font(.system(size: 24))
                        .foregroundColor(Color.gray)
                        .onTapGesture {
                            showAttachmentDialog.toggle()
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
                        } label: {
                            Image(systemName: "arrow.up.circle.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Color.blue)
                        }
                    }
                }
                .padding(8)
                .opacity(viewModel.thread?.type == .channel ? 0.3 : 1.0)
                .disabled(viewModel.thread?.type == .channel)
            }
            .animation(.easeInOut, value: viewModel.mentionList.count)
            .onReceive(viewModel.$editMessage) { editMessage in
                if let editMessage = editMessage {
                    text = editMessage.message ?? ""
                }
            }
            .onChange(of: text) { newValue in
                viewModel.searchForMention(newValue)
                viewModel.textMessage = newValue
            }
        }
    }
}

struct MentionList: View {
    @Binding var text: String
    @EnvironmentObject var viewModel: ThreadViewModel

    var body: some View {
        if viewModel.mentionList.count > 0 {
            List(viewModel.mentionList) { participant in
                ParticipantRow(participant: participant)
                    .onTapGesture {
                        if let lastMatch = text.matches(char: "@")?.last {
                            let removeRange = text.last == "@" ? NSRange(text.index(text.endIndex, offsetBy: -1)..., in: text) : lastMatch.range
                            let removedText = text.remove(in: removeRange) ?? ""
                            text = removedText + "@" + (participant.username ?? "")
                        }
                    }
            }
            .listStyle(.plain)
            .background(.ultraThickMaterial)
            .transition(.asymmetric(insertion: .opacity, removal: .move(edge: .bottom)))
        } else {
            EmptyView()
        }
    }
}

struct ThreadView_Previews: PreviewProvider {
    static var searchMessageText: Binding<String> {
        Binding(get: { "Hello" }, set: { _ in })
    }

    static var vm: ThreadViewModel {
        let vm = ThreadViewModel()
        vm.searchedMessages = MockData.generateMessages(count: 15)
        vm.objectWillChange.send()
        return vm
    }

    static var previews: some View {
        ThreadView(thread: MockData.thread, showAttachmentDialog: false, searchMessageText: "s")
            .environmentObject(AppState.shared)
            .onAppear {
                vm.setup(thread: MockData.thread)
                //                vm.toggleRecording()
                //                vm.setReplyMessage(MockData.message)
                //                vm.setForwardMessage(MockData.message)
                vm.isInEditMode = false
            }

        ThreadSearchList(searchMessageText: searchMessageText)
            .previewDisplayName("ThreadSearchList")
            .environmentObject(vm)
    }
}
