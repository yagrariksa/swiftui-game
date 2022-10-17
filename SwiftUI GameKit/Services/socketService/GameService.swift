//
//  GameService.swift
//  SwiftUI GameKit
//
//  Created by Daffa Yagrariksa on 15/10/22.
//

import Foundation
import SocketIO

class GameService: ObservableObject {
    @Published var joined: Bool = false
    @Published var msg: String = ""
    @Published var play: Bool = false
    @Published var playerColor: String? = nil
    @Published var turn: Bool = false
    @Published var winner: Bool? = nil
    
    @Published var matrix: [[String?]] = [
        [nil, nil, nil],
        [nil, nil, nil],
        [nil, nil, nil],
    ]
    
    public func joinGameRoom(socket: SocketIOClient, roomId: String) {
        self.msg = ""
        socket.emit(Port.join, [
            "roomId": roomId
        ])
        socket.on(Port.join_response){_,_ in
            socket.off(Port.join_response)
            socket.off(Port.join_error)
            self.joined = true
        }
        socket.on(Port.join_error){data, ack in
            if let data = data[0] as? [String: String],
               let error = data["error"] {
                self.msg = error
            }
            socket.off(Port.join_response)
            socket.off(Port.join_error)
            self.joined = false
        }
        
        lobbyGameRoom(socket: socket)
    }
    
    public func leaveGameRoom(socket: SocketIOClient, roomId: String) {
        socket.emit(Port.leave, [
            "roomId": roomId
        ])
        socket.on(Port.leave_response) {_,_ in
            socket.off(Port.leave_response)
            self.joined = false
            self.msg = ""
        }
    }
    
    public func lobbyGameRoom(socket: SocketIOClient) {
        socket.on(Port.game_start){data,_ in
            guard let data = data[0] as? [String: String],
                  let color = data["color"],
                  let turn = data["turn"] else {return}
            
            socket.off(Port.game_start)
            self.play = true
            self.updatePlayerColor(color: color)
            self.turn = (turn == "true") ? true : false
            
            if !self.turn {
                self.listenMatrixUpdate(socket: socket)
            }
        }
    }
    
    public func listenGameRoom(socket: SocketIOClient) {
        socket.on(Port.game_disconnected) {_,_ in
            socket.off(Port.game_disconnected)
            socket.off(Port.game_looser)
            self.play = false
            
            self.lobbyGameRoom(socket: socket)
            self.matrix = [
                [nil, nil, nil],
                [nil, nil, nil],
                [nil, nil, nil],
            ]
        }
    }
    
    func updatePlayerColor(color: String){
        playerColor = color
    }
    
    func updateMatrix(socket: SocketIOClient, roomId: String){
        
        socket.emit(Port.game_matrix_update, [
            "matrix": matrix,
            "roomId": roomId
        ])
        
        turn = false
        listenMatrixUpdate(socket: socket)
    }
    
    func listenMatrixUpdate(socket: SocketIOClient){
        socket.on(Port.game_matrix_response) {data, ack in
            guard let data = data[0] as? [String: Any],
                  let m = data["matrix"] as? [[String?]] else {return}
            self.matrix = m
            self.turn = true
            socket.off(Port.game_matrix_response)
        }
    }
    
    func checkWinner(socket: SocketIOClient, roomId: String){
        for i in 0..<matrix.count {
            var array = [String?]()
            var column = [String?]()
            for j in 0..<matrix.count {
                array.append(matrix[i][j])
                column.append(matrix[j][i])
            }
            
            if array.dropFirst().allSatisfy({ $0 == array.first })
                && array.first == playerColor {
                showTheWinner(socket: socket, roomId: roomId)
            }
            
            if column.dropFirst().allSatisfy({ $0 == column.first })
                && column.first == playerColor {
                showTheWinner(socket: socket, roomId: roomId)
            }
        }
        
        if matrix[0][0] == matrix[1][1]
            && matrix[2][2] == matrix[1][1]
            && matrix[0][0] == playerColor {
            showTheWinner(socket: socket, roomId: roomId)
        }
        
        if matrix[0][2] == matrix[1][1]
            && matrix[2][0] == matrix[1][1]
            && matrix[0][2] == playerColor {
            showTheWinner(socket: socket, roomId: roomId)
        }
    }
    
    func listenTheWinner(socket: SocketIOClient) {
        socket.on(Port.game_looser) {_,_ in
            print("GAME LOOSER")
            socket.off(Port.game_looser)
            self.winner = false
        }
    }
    
    func showTheWinner(socket: SocketIOClient, roomId: String) {
        winner = true
        socket.emit(Port.game_winner, [
            "roomId": roomId
        ])
    }
}
