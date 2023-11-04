//
//  AttachmentFiles.swift
//  Talk
//
//  Created by hamed on 10/31/23.
//

import SwiftUI
import TalkUI
import TalkViewModels
import TalkModels
import Additive

struct AttachmentFiles: View {
    @EnvironmentObject var viewModel: AttachmentsViewModel

    var body: some View {
        if viewModel.attachments.count == 1, let attachmentFile = viewModel.attachments.first {
            SingleAttachmentFile(attachment: attachmentFile)
                .background(MixMaterialBackground())
                .onAppear {
                    NotificationCenter.default.post(name: .senderSize, object: CGSize(width: 0, height: 86))
                }
        } else if viewModel.attachments.count > 1 {
            ListAttachmentFile(attachments: viewModel.attachments)
        } else {
            Rectangle()
                .frame(width: 0, height: 0)
                .hidden()
                .onAppear {
                    NotificationCenter.default.post(name: .senderSize, object: CGSize(width: 0, height: 52))
                }
        }
    }
}

struct SingleAttachmentFile: View {
    @EnvironmentObject var viewModel: AttachmentsViewModel
    let attachment: AttachmentFile

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            if let icon = attachment.icon {
                HStack {
                    Image(systemName: icon)
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                }
                .frame(width: 32, height: 32)
                .padding(attachment.request is ImageItem ? 0 : 6)
                .background(Color.App.bgInput)
                .cornerRadius(6)
            } else if let cgImage = (attachment.request as? ImageItem)?.imageData.imageScale(width: 48)?.image {
                Image(cgImage: cgImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .cornerRadius(6)
            }

            VStack(alignment: .leading, spacing: 4) {
                if let title = attachment.title {
                    Text(verbatim: title)
                        .font(.iransansBoldBody)
                        .foregroundStyle(Color.App.text)
                }

                if let subtitle = attachment.subtitle {
                    Text(verbatim: subtitle)
                        .font(.iransansCaption2)
                        .foregroundStyle(Color.App.hint)
                }
            }
            .padding(6)
            .padding(.leading, 12)

            Spacer()
            Button {
                viewModel.remove(attachment)
            } label: {
                Image(systemName: "xmark")
                    .resizable()
                    .scaledToFit()
                    .frame(width: 12, height: 12)
                    .padding()
                    .contentShape(Rectangle())
                    .foregroundStyle(Color.App.hint)
            }
            .frame(width: 36, height: 36)
        }
        .frame(height: 46)
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
    }
}

struct ListAttachmentFile: View {
    @EnvironmentObject var viewModel: AttachmentsViewModel
    let attachments: [AttachmentFile]

    var body: some View {
        VStack(alignment: .center, spacing: 0) {
            ExpandHeader()
            if viewModel.isExpanded {
                ScrollView(.vertical) {
                    VStack(spacing: 0) {
                        ForEach(attachments) { attachment in
                            SingleAttachmentFile(attachment: attachment)
                        }
                    }
                }
                .offset(y: viewModel.isExpanded ? 0 : 500)
            }
            Spacer()
        }
        .frame(maxHeight: maxHeight)
        .animation(.easeInOut, value: attachments.count)
        .animation(.spring(response: 0.4, dampingFraction: 0.5, blendDuration: 0.2), value: viewModel.isExpanded)
        .background(MixMaterialBackground())
        .onChange(of: maxHeight) { newValue in
            NotificationCenter.default.post(name: .senderSize, object: CGSize(width: 0, height: newValue + 36))
        }
        .onAppear {
            NotificationCenter.default.post(name: .senderSize, object: CGSize(width: 0, height: 82))
        }
    }

    var maxHeight: CGFloat {
        if !viewModel.isExpanded {
            return 48
        } else if viewModel.attachments.count > 4 {
            return UIScreen.main.bounds.height / 3
        } else {
            return (CGFloat(viewModel.attachments.count) * 64) + 64
        }
    }
}

struct ExpandHeader: View {
    @EnvironmentObject var viewModel: AttachmentsViewModel

    var body: some View {
        HStack {
            let localized = String(localized: .init("Thread.sendAttachments"))
            let value = viewModel.attachments.count.formatted(.number)
            Text(String(format: localized, "\(value)"))
                .font(.iransansBoldBody)
                .padding(.leading, 8)
            Spacer()
            Image(systemName: viewModel.isExpanded ? "chevron.down" : "chevron.up")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .padding()
                .contentShape(Rectangle())
                .foregroundStyle(Color.App.hint)
                .frame(width: 36, height: 36)
        }
        .frame(height: 36)
        .padding(8)
        .background(MixMaterialBackground(color: Color.App.bgNavigation))
        .contentShape(Rectangle())
        .animation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2), value: viewModel.isExpanded)
        .onTapGesture {
            viewModel.isExpanded.toggle()
        }
    }
}

struct AttachmentFiles_Previews: PreviewProvider {
    struct Preview: View {
        @StateObject var viewModel = AttachmentsViewModel()

        var body: some View {
            VStack {
                Spacer()
                AttachmentFiles()
                    .environmentObject(viewModel)
                    .task {
                        let attachments: [AttachmentFile] = [.init(url: .init(string: "http://www.google.com/friends")!),
                                                             .init(url: .init(string: "http://www.google.com/report")!),
                                                             .init(url: .init(string: "http://www.google.com/music")!)]
                        viewModel.append(attachments: attachments)
                    }
            }
        }
    }

    static var previews: some View {
        Preview()
            .previewDisplayName("List")
    }
}
