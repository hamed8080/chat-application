//
//  DateSelectionView.swift
//  ChatApplication
//
//  Created by hamed on 4/17/22.
//

import Foundation
import SwiftUI

struct DateSelectionView:View{
    
    @State
    var startDate:Date = Date()

    @State
    var endDate:Date = Date()
    
    @State
    var showEndDate = false
    
    var completion:(Date,Date)->()
    
    var body: some View{
        HStack{
            Spacer()
            VStack{
                Spacer()
                if !showEndDate {
                    VStack{
                        Text("Start Date")
                            .foregroundColor(Color("text_color_blue"))
                            .font(.title.bold())
                        DatePicker("", selection: $startDate)
                            .labelsHidden()
                            .padding(16)
                        Button {
                            showEndDate.toggle()
                        } label: {
                                Text("Next")
                        }
                        .buttonStyle(PrimaryButtonStyle(bgColor:Color(named: "icon_color")))
                    }
                    .padding()
                    .background(Color(named: "background"))
                    .cornerRadius(12)
                }else{
                    VStack{
                        
                        Text("End Date")
                            .foregroundColor(Color("text_color_blue"))
                            .font(.title.bold())
                        
                        DatePicker("", selection: $endDate)
                            .labelsHidden()
                            .padding(16)
                        
                        HStack{
                            Button {
                                showEndDate.toggle()
                            } label: {
                                Text("Back")
                            }
                            .buttonStyle(PrimaryButtonStyle(bgColor:Color(named: "icon_color")))
                            
                            Button {
                                showEndDate.toggle()
                                completion(startDate,endDate)
                            } label: {
                                Text("Export")
                            }
                            .buttonStyle(PrimaryButtonStyle(bgColor:Color(named: "icon_color")))
                        }
                    }
                    .padding()
                    .background(Color(named: "background"))
                    .cornerRadius(12)
                }
                Spacer()
            }
            .padding(16)
            Spacer()
        }
        .background(.ultraThinMaterial)
        
    }
}


struct DateSelectionView_Previews: PreviewProvider {
    
    static var previews: some View {
        DateSelectionView(){ startDate, endDate in
            
        }
        .preferredColorScheme(.dark)
        .environmentObject(AppState.shared)
        .onAppear(){
        }
    }
}
