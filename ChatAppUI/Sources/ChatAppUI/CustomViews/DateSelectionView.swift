//
//  DateSelectionView.swift
//  ChatApplication
//
//  Created by hamed on 4/17/22.
//

import Foundation
import SwiftUI
import ChatAppViewModels

public struct DateSelectionView: View {
    @State var startDate: Date = .init()
    @State var endDate: Date = .init()
    @State var showEndDate: Bool = false
    @Binding var showDialog: Bool
    var completion: (Date, Date) -> Void

    public init(showDialog: Binding<Bool>, completion: @escaping (Date, Date) -> Void) {
        self.completion = completion
        self._showDialog = showDialog
    }

    public var body: some View {
        ZStack {
            if !showEndDate {
                VStack {
                    Text("Start Date")
                        .foregroundColor(.textBlueColor)
                        .font(.iransansBoldTitle)

                    DatePicker("", selection: $startDate)
                        .datePickerStyle(.graphical)

                    Button {
                        showEndDate.toggle()
                    } label: {
                        Label("Next".uppercased(), systemImage: "arrow.forward")
                            .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
                    }
                    .font(.iransansSubheadline)
                    .buttonStyle(.bordered)
                    .frame(maxWidth: 428)
                }
            } else {
                VStack {
                    Text("End Date")
                        .foregroundColor(.textBlueColor)
                        .font(.iransansBoldTitle)
                    DatePicker("", selection: $endDate)
                        .datePickerStyle(.graphical)
                    HStack {
                        Button {
                            showEndDate.toggle()
                        } label: {
                            Label("Back".uppercased(), systemImage: "arrow.backward")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
                        }
                        .font(.iransansSubheadline)
                        .buttonStyle(.bordered)

                        Button {
                            showEndDate.toggle()
                            completion(startDate, endDate)
                        } label: {
                            Label("Export".uppercased(), systemImage: "tray.and.arrow.down")
                                .frame(minWidth: 0, maxWidth: .infinity, minHeight: 36)
                        }
                        .font(.iransansSubheadline)
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: 428)
                }
            }
        }
        .animation(.easeInOut, value: showEndDate)
        .animation(.easeInOut, value: showDialog)
    }
}

struct DateSelectionView_Previews: PreviewProvider {
    static var previews: some View {
        DateSelectionView(showDialog: .constant(true)) { _, _ in
        }
        .preferredColorScheme(.dark)
        .environmentObject(AppState.shared)
        .onAppear {}
    }
}
