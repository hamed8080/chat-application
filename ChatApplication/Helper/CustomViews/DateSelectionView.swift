//
//  DateSelectionView.swift
//  ChatApplication
//
//  Created by hamed on 4/17/22.
//

import Foundation
import SwiftUI

struct DateSelectionView: View {
    @State var startDate: Date = .init()
    @State var endDate: Date = .init()
    @State var showEndDate = false
    @Binding var showDialog: Bool

    var completion: (Date, Date) -> Void

    var body: some View {
        HStack {
            Spacer()
            VStack {
                Spacer()
                if !showEndDate {
                    VStack {
                        HStack {
                            Text("Start Date")
                                .foregroundColor(.textBlueColor)
                                .font(.title.bold())
                            Spacer()
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.gray.opacity(0.5))
                                .onTapGesture {
                                    showDialog = false
                                }
                        }

                        DatePicker("", selection: $startDate)
                            .labelsHidden()
                            .padding(16)
                        Button {
                            showEndDate.toggle()
                        } label: {
                            Text("Next")
                        }
                        .buttonStyle(.bordered)
                    }
                    .frame(maxWidth: isIpad ? 420 : .infinity)
                    .padding()
                    .background(Color.bgColor)
                    .cornerRadius(12)
                } else {
                    VStack {
                        HStack {
                            Text("End Date")
                                .foregroundColor(.textBlueColor)
                                .font(.title.bold())
                            Spacer()
                            Image(systemName: "xmark.circle.fill")
                                .resizable()
                                .scaledToFit()
                                .frame(width: 36, height: 36)
                                .foregroundColor(.gray.opacity(0.5))
                                .onTapGesture {
                                    showDialog = false
                                }
                        }

                        DatePicker("", selection: $endDate)
                            .labelsHidden()
                            .padding(16)

                        HStack {
                            Button {
                                showEndDate.toggle()
                            } label: {
                                Text("Back")
                            }
                            .buttonStyle(.bordered)

                            Button {
                                showEndDate.toggle()
                                completion(startDate, endDate)
                            } label: {
                                Text("Export")
                            }
                            .buttonStyle(.bordered)
                        }
                    }
                    .frame(maxWidth: 420)
                    .padding()
                    .background(Color.bgColor)
                    .cornerRadius(12)
                }
                Spacer()
            }
            .padding(16)
            Spacer()
        }
        .animation(.easeInOut, value: showDialog)
        .animation(.spring(), value: showEndDate)
        .background(.ultraThinMaterial)
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
