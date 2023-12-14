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
        } else if viewModel.attachments.count > 1 {
            ListAttachmentFile(attachments: viewModel.attachments)
        } else {
            Rectangle()
                .frame(width: 0, height: 0)
                .hidden()
        }
    }
}

struct SingleAttachmentFile: View {
    @EnvironmentObject var viewModel: AttachmentsViewModel
    let attachment: AttachmentFile

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            let imageItem = attachment.request as? ImageItem
            let isVideo = imageItem?.isVideo == true
            let icon = attachment.icon
            if icon != nil || isVideo {
                HStack {
                    Image(systemName: isVideo ? "film.fill" : icon ?? "")
                        .resizable()
                        .scaledToFit()
                        .padding(8)
                }
                .frame(width: 32, height: 32)
                .padding(isVideo || icon != nil ? 6 : 0)
                .background(Color.App.bgInput)
                .clipShape(RoundedRectangle(cornerRadius:(6)))
            } else if !isVideo, let cgImage = imageItem?.data.imageScale(width: 48)?.image {
                Image(cgImage: cgImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 42, height: 42)
                    .clipShape(RoundedRectangle(cornerRadius:(6)))
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
            .padding(EdgeInsets(top: 6, leading: 6 + 12, bottom: 6, trailing: 6))

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
        .padding(EdgeInsets(top: 8, leading: 16, bottom: 8, trailing: 16))
        .onTapGesture {} // To prevent clicking on messages behind the item, especially images.
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
            Button {
                withAnimation(.spring(response: 0.4, dampingFraction: 0.7, blendDuration: 0.2)) {
                    viewModel.clear()
                }
            } label: {
                Text("General.cancel")
                    .foregroundStyle(Color.App.red)
                    .font(.iransansCaption)
            }
            Image(systemName: viewModel.isExpanded ? "chevron.down" : "chevron.up")
                .resizable()
                .scaledToFit()
                .frame(width: 12, height: 12)
                .foregroundStyle(Color.App.hint)
                .frame(width: 36, height: 36)
                .padding(.horizontal, 4)
                .contentShape(Rectangle())
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
