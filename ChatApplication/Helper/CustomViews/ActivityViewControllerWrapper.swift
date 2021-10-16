//
//  ActivityViewControllerWrapper.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 10/16/21.
//

import SwiftUI

struct ActivityViewControllerWrapper : UIViewControllerRepresentable{
 
    var activityItems:[URL]
    var applicationActivities:[UIActivity]? = nil
    
    func makeUIViewController(context: Context) -> some UIActivityViewController {
        let vc = UIActivityViewController(activityItems: activityItems, applicationActivities: applicationActivities)
        return vc
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

