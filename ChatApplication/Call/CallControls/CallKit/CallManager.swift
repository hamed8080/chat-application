//
//  CallManager.swift
//  ChatApplication
//
//  Created by Hamed Hosseini on 10/16/21.
//

import Foundation
import CallKit

class CallManager : NSObject, ObservableObject{
    
    var callController = CXCallController()
    
    @Published
    var calls:[CallItem] = []
    
    func addCall(_ call:CallItem){
        calls.append(call)
    }
    
    func removeCall(_ call:CallItem){
        guard let index = calls.firstIndex(where: {$0 === call}) else {return}
        calls.remove(at: index)
    }
    
    func removeAllCall(){
        calls.removeAll()
    }
    
    func startCall(_ handle:String , video:Bool, uuid:UUID){
        print("start call uuid is:\(uuid.uuidString)")
        let handle = CXHandle(type: .phoneNumber, value: handle)
        let startAction = CXStartCallAction(call: uuid , handle: handle)
        startAction.isVideo = video
        let transaction = CXTransaction(action: startAction)
        requestTransaction(transaction)
    }
    
    func endCall(_ uuid:UUID){
        if calls.contains(where: {$0.uuid == uuid}){
            print("end call uuid is:\(uuid.uuidString)")
            let endAction = CXEndCallAction(call: uuid)
            let transaction = CXTransaction(action: endAction)
            requestTransaction(transaction)
        }
    }
    
    func holdStatus(call: CallItem, hold: Bool) {
        let heldAction = CXSetHeldCallAction(call: call.uuid, onHold: hold)
        let transaction = CXTransaction()
        transaction.addAction(heldAction)
        requestTransaction(transaction)
    }
    
    func callWithUUID(uuid: UUID) -> CallItem? {
        guard let index = calls.firstIndex(where: { $0.uuid == uuid }) else { return nil }
        return calls[index]
    }
    
    func callAnsweredFromCusomUI(){
        let uuid = CallState.shared.model.uuid
        let answerAction = CXAnswerCallAction(call: uuid)
        let transaction  = CXTransaction(action: answerAction)
        requestTransaction(transaction)        
    }
    
    private func requestTransaction(_ transaction:CXTransaction){
        callController.request(transaction) { error in
            if let error = error {                
                print("Error requesting transaction:", error.localizedDescription)
            } else {
                print("Requested transaction successfully")
            }
        }
    }
}
