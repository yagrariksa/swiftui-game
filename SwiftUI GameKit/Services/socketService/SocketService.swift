//
//  SocketService.swift
//  SwiftUI GameKit
//
//  Created by Daffa Yagrariksa on 15/10/22.
//

import Foundation
import SocketIO

class SocketService: ObservableObject {
    
    let manager: SocketManager
    
    @Published var socket: SocketIOClient
    @Published var connected: Bool = false
    
    init(url: String) {
        self.manager = SocketManager(socketURL: URL(string: url)!, config: [.log(true), .compress])
        self.socket = manager.defaultSocket
        
        setSocketConnection()
    }
    
    public func setSocketConnection() {
        self.socket.on(clientEvent: .connect) {data, ack in
            self.connected = true
        }
        
        self.socket.on(clientEvent: .disconnect, callback: {data, ack in
            self.connected = false
        })
    }
    
    public func reconnect(){
        disconnect()
        connect()
    }
    
    public func connect(){
        self.socket.connect()
    }
    
    public func disconnect(){
        self.socket.disconnect()
    }
}
