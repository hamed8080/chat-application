//
//  AttachmentButtons.swift
//  Talk
//
//  Created by Hamed Hosseini on 11/23/21.
//

import AdditiveUI
import SwiftUI
import TalkModels
import TalkUI
import TalkViewModels

struct AttachmentButtons: View {
    let viewModel: AttachmentsViewModel

    var body: some View {
        MutableAttachmentDialog()
            .environmentObject(viewModel)
            .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .move(edge: .bottom)))
    }
}

struct MutableAttachmentDialog: View {
    @EnvironmentObject var viewModel: SendContainerViewModel
    @EnvironmentObject var threadVM: ThreadViewModel

    var body: some View {
        HStack(spacing: 8) {
            Spacer()

            AttchmentButtonItem(title: "General.gallery", image: "photo.fill") {
                threadVM.sheetType = .galleryPicker
                viewModel.showActionButtons.toggle()
                threadVM.animateObjectWillChange()
            }

            Spacer()

            AttchmentButtonItem(title: "General.file", image: "doc.fill") {
                threadVM.sheetType = .filePicker
                viewModel.showActionButtons.toggle()
                threadVM.animateObjectWillChange()
            }

            Spacer()

            AttchmentButtonItem(title: "General.location", image: "location.fill") {
                threadVM.sheetType = .locationPicker
                viewModel.showActionButtons.toggle()
                threadVM.animateObjectWillChange()
            }

            Spacer()

            if EnvironmentValues.isTalkTest {
                AttchmentButtonItem(title: "General.contact", image: "person.2.crop.square.stack.fill") {
                    threadVM.sheetType = .contactPicker
                    viewModel.showActionButtons.toggle()
                    threadVM.animateObjectWillChange()
                }
                .disabled(!EnvironmentValues.isTalkTest)
                .opacity(EnvironmentValues.isTalkTest ? 1.0 : 0.2)
                Spacer()
            }
        }
        .font(.iransansBody)
        .padding(.top, viewModel.showActionButtons ? 8 : 0)
        .frame(height: viewModel.showActionButtons ? nil : 0)
        .clipped()
        .animation(.easeInOut, value: viewModel.showActionButtons)
        .transition(.asymmetric(insertion: .move(edge: .bottom), removal: .push(from: .top).animation(.easeOut(duration: 0.2))))
    }
}

fileprivate struct AttchmentButtonItem: View {
    let title: String
    let image: String
    let action: () -> Void
    @Environment(\.colorScheme) var colorScheme
    @State var isPressing = false
    @EnvironmentObject var viewModel: SendContainerViewModel

    var body: some View {
        VStack {
            if viewModel.showActionButtons {
                buttonContainer
            }
        }
        .frame(height: viewModel.showActionButtons ? nil : 0)
        .contentShape(Rectangle())
        .onTapGesture {
            action()
        }
        .simultaneousGesture(dragGesture)
        .animation(.easeInOut, value: isPressing)
    }

    @ViewBuilder
    private var buttonContainer: some View {
        ZStack {
            Image(systemName: image)
                .interpolation(.none)
                .resizable()
                .scaledToFit()
                .frame(width: 24, height: 24)
                .foregroundColor(colorScheme == .dark ? Color.App.white : Color.App.accent)
        }
        .frame(width: isPressing ? 22 : 34, height: isPressing ? 22 : 34)
        .padding()
        .background(
            RoundedRectangle(cornerRadius: 26)
                .strokeBorder(Color.App.textSecondary.opacity(0.5), lineWidth: 1, antialiased: true)
        )
        .overlay(alignment: .center) {
            if isPressing {
                RoundedRectangle(cornerRadius: 26)
                    .stroke(Color.clear)
                    .background(Color.App.white.opacity(0.3))
                    .clipShape(RoundedRectangle(cornerRadius:(26)))
            }
        }
        Text(title)
            .font(.iransansCaption3)
            .foregroundStyle(Color.App.textSecondary)
            .multilineTextAlignment(.center)
    }

    private var dragGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { newValue in
                isPressing = true
            }
            .onEnded { newValue in
                isPressing = false
            }
    }
}

struct AttachmentDialog_Previews: PreviewProvider {
    static var previews: some View {
        AttachmentButtons(viewModel: .init())
        //            AttchmentButtonItem(title: "Contacts", image: "person.fill") {
        //
        //            }

        //        AttachmentDialog(viewModel: viewModel)
    }
}
