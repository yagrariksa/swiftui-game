//
//  Port.swift
//  SwiftUI GameKit
//
//  Created by Daffa Yagrariksa on 15/10/22.
//

import Foundation

struct Port {
    static let url_local = "ws://localhost:3000"
    static let url = "https://tictac.yagrariksa.site:443"
    
    static let join = "join_game"
    static let join_response = "join_game_response"
    static let join_error = "join_game_error"
    
    static let leave = "leave_game"
    static let leave_response = "leave_game_response"
    
    static let game_start = "game_start"
    static let game_disconnected = "game_player_disconnected"
    static let game_matrix_update = "game_matrix_send"
    static let game_matrix_response = "game_matrix_recieve"
    
    static let game_winner = "game_winner"
    static let game_looser = "game_looser"
}
