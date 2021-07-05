//
//  ResultViewController.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 7/3/21.
//


import Foundation
import UIKit
import FanapPodChatSDK
import SwiftUI

struct ResultView:UIViewControllerRepresentable {
    
    func makeUIViewController(context: Context)-> ResultViewController {
        let resultVC = UIStoryboard(name: "Result", bundle: nil).instantiateInitialViewController() as! ResultViewController
        return resultVC
    }
    
    func updateUIViewController(_ uiViewController: UIViewControllerType, context: Context) {
        
    }
}

class ResultViewController: UIViewController , UITableViewDelegate , UITableViewDataSource{
   
    @IBOutlet weak var tblLogs: UITableView!
    
    private static var logs:[LogResult] = []
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tblLogs.tableFooterView = UIView()
        tblLogs.reloadData()
    }
    
    public class func addToLog(logResult:LogResult){
        ResultViewController.logs.insert(logResult, at: 0)
        if let resultVC = getResultViewController(){
            resultVC.tblLogs.insertRows(at: [IndexPath(row: 0, section: 0)], with: .right)
        }
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return ResultViewController.logs.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard let logCell = tableView.dequeueReusableCell(withIdentifier: "LogCell") as? LogCell else {return UITableViewCell()}
        logCell.logResult = ResultViewController.logs[indexPath.row]
        return logCell
    }
    
    @IBAction func btnClearLogsTaped(_ sender: UIButton) {
        ResultViewController.logs.removeAll()
        tblLogs.reloadData()
    }
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {

        return UITableView.automaticDimension
    }
    
    class func getResultViewController()->ResultViewController?{
        guard let window = (UIApplication.shared.connectedScenes.first as? UIWindowScene)?.windows.first else {return nil}
        if let resultVC = window.rootViewController?.presentedViewController as? ResultViewController{
            return resultVC
        }else if let resultVC = window.rootViewController?.presentedViewController?.presentedViewController as? ResultViewController{
            return resultVC
        }else{
            return nil
        }
    }
}
