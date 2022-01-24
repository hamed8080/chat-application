//
//  SheetDialog.swift
//  ChatApplication
//
//  Created by Hamed on 1/24/22.
//

import SwiftUI

struct SheetDialog<Content:View>: View {
    
    @Binding
    var showAttachmentDialog: Bool
    
    @ViewBuilder
    var content:Content
    
    var body: some View{
        GeometryReader{ reader in
            VStack{
                let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first
                Spacer()
                VStack{
                    RoundedRectangle(cornerRadius: 6)
                        .fill(Color.gray.opacity(0.8))
                        .frame(width:96, height:5)
                        .gesture(
                            DragGesture()
                                .onChanged({ value in
                                    
                                })
                                .onEnded({ value in
                                    showAttachmentDialog = false
                                })
                        )
                    content
                }
                .customAnimation(.spring(response: 0.5, dampingFraction: 0.6 , blendDuration: 1).speed(1))
                .transition(.move(edge: .bottom))
                .customAnimation(.easeInOut)
                .frame(width:reader.size.width)
                .padding(.top ,6)
                .padding(.bottom , (window?.safeAreaInsets.bottom ?? 0) + 10)
                .background(Color.white.ignoresSafeArea())
                .cornerRadius(24)
            }
            .background(
                (showAttachmentDialog ? Color.gray.opacity(0.3).ignoresSafeArea() : Color.clear.ignoresSafeArea())
                    .gesture(
                        DragGesture()
                            .onChanged({ value in
                                
                            })
                            .onEnded({ value in
                                showAttachmentDialog = false
                            })
                    )
            )
            .edgesIgnoringSafeArea(.bottom)
        }
        
    }
}

struct SheetDialog_Previews: PreviewProvider {
    static var previews: some View {
        SheetDialog(showAttachmentDialog: .constant(true)){
            Text("Test")
        }
    }
}
