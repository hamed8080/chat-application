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
        DispatchQueue.main.async {
            ResultViewController.logs.insert(logResult, at: 0)
            if let resultVC = getResultViewController(){
                resultVC.tblLogs.insertRows(at: [IndexPath(row: 0, section: 0)], with: .right)
            }
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
    
    class func printCallLogsFile(){
        if let appSupportDir = try? FileManager.default.url(for: .documentDirectory, in: .userDomainMask, appropriateFor: nil, create: false){
            let logFileDir = "WEBRTC-LOG"
            let url = appSupportDir.appendingPathComponent(logFileDir)
            let contentsOfDir = try? FileManager.default.contentsOfDirectory(atPath: url.path)
            
            DispatchQueue.global(qos: .background).async {
                let df = DateFormatter()
                df.dateFormat = "yyyy-MM-dd-HH-mm-ss"
                let dateString = df.string(from: Date())
                FileManager.default.zipFile(urlPathToZip: url, zipName: "WEBRTC-Logs-\(dateString)") { zipFile in
                    if let zipFile = zipFile{
                        AppState.shared.callLogs = [zipFile]
                    }
                }
            }
            
            contentsOfDir?.forEach({ file in
                DispatchQueue.global(qos: .background).async {
                    if let data = try? Data(contentsOf: url.appendingPathComponent(file)) , let string = String(data: data, encoding: .utf8){
                        print("data of log file '\(file)' is:\n")
                        print(string)
                        let log = LogResult(json: string, receive: false)
                        ResultViewController.addToLog(logResult: log)
                    }
                }
            })
        }
    }
}
