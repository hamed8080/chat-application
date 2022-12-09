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
                                .foregroundColor(Color("text_color_blue"))
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
                        .buttonStyle(PrimaryButtonStyle(bgColor: Color(named: "icon_color")))
                    }
                    .frame(maxWidth: isIpad ? 420 : .infinity)
                    .padding()
                    .background(Color(named: "background"))
                    .cornerRadius(12)
                } else {
                    VStack {
                        HStack {
                            Text("End Date")
                                .foregroundColor(Color("text_color_blue"))
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
                            .buttonStyle(PrimaryButtonStyle(bgColor: Color(named: "icon_color")))

                            Button {
                                showEndDate.toggle()
                                completion(startDate, endDate)
                            } label: {
                                Text("Export")
                            }
                            .buttonStyle(PrimaryButtonStyle(bgColor: Color(named: "icon_color")))
                        }
                    }
                    .frame(maxWidth: isIpad ? 420 : .infinity)
                    .padding()
                    .background(Color(named: "background"))
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
