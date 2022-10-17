//
//  ContentView.swift
//  SwiftUI GameKit
//
//  Created by Daffa Yagrariksa on 13/10/22.
//

import SwiftUI
import SocketIO

final class Service: ObservableObject {
    let local = "ws://localhost:49999"
    let deploy = "https://tictac.yagrariksa.site:49999"
    //    let manager = SocketManager(socketURL: URL(string: "https://tictac.yagrariksa.site:443")!, config: [.log(true), .compress])
    let manager = SocketManager(socketURL: URL(string: "ws://localhost:3000")!, config: [.log(true), .compress])
    let socket: SocketIOClient
    
    @Published var message = String()
    @Published var connected = false
    
    
    public func joinGame(data: String){
        
        self.socket.on(Port.join_response) {data, ack in
            DispatchQueue.main.async {
                self.message = "Success Join Room"
                self.socket.off(Port.join_response)
                self.socket.off(Port.join_error)
            }
        }
        
        self.socket.on(Port.join_error) {data, ack in
            guard let cur = data[0] as? [String: String],
                  let raw = cur["error"] else { return }
            
            DispatchQueue.main.async {
                self.message = raw
                self.socket.off(Port.join_response)
                self.socket.off(Port.join_error)
            }
        }
        
        self.socket.emit(Port.join, ["roomId": data])
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 5.0) {
            self.socket.off(Port.join_response)
        }
    }
    
    public func reconnect(){
        disconnect()
        connect()
    }
    
    public func connect(){
        socket.connect()
    }
    
    public func disconnect(){
        socket.disconnect()
    }
    
    
    init() {
        socket = manager.defaultSocket
        socket.on(clientEvent: .connect) {data, ack in
            self.connected = true
        }
        
        socket.on(clientEvent: .disconnect, callback: {data, ack in
            self.connected = false
        })
        
        //        socket.off("iosport")
        
        
        
    }
}

struct ContentView: View {
    
    @EnvironmentObject var socketService: SocketService
    @ObservedObject var gameService = GameService()
    
    @State var showAlert: Bool = false
    
    func joinGame(){
        guard name != "" else {return}
        
        let socket = socketService.socket
        gameService.joinGameRoom(socket: socket, roomId: name)
    }
    
    func resetConnection(){
        gameService.joined = false
        gameService.msg = ""
    }
    
    func selectMatrix(_ i: Int, _ j: Int) {
        gameService.matrix[i][j] = gameService.playerColor
        gameService.updateMatrix(
            socket: socketService.socket,
            roomId: name
        )
        gameService.checkWinner(socket: socketService.socket, roomId: name)
        
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.0){
            if gameService.winner != nil {
                showAlert = true
            }else{
                showAlert = false
            }
        }
    }
    
    @State var name = ""
    
    var body: some View {
        if gameService.joined {
            GeometryReader{ geometry in
                VStack {
                    Text(gameService.play ? "Let's Play" : "Wait other Player")
                    Text("Room : \(name)")
                    if gameService.play {
                        Text("You are \(gameService.playerColor?.uppercased() ?? "")")
                            .padding()
                            .foregroundColor(gameService.playerColor == "red" ? .red : .blue)
                        Text(gameService.turn ? "YOUR TURN" : "WAIT...")
                            .foregroundColor(gameService.turn ? .green : .yellow)
                        VStack{
                            let matrix = gameService.matrix
                            ForEach(0..<matrix.count){ i in
                                HStack {
                                    ForEach(0..<matrix[i].count) { j in
                                        let val: String? = matrix[i][j]
                                        Rectangle()
                                            .fill( (val == nil) ? .gray : (val == "red" ? .red : .blue))
                                            .frame(
                                                width: geometry.size.width/4,
                                                height: geometry.size.width/4
                                            )
                                            .onTapGesture {
                                                if(matrix[i][j] == nil && gameService.turn){
                                                    selectMatrix(i, j)
                                                }
                                            }
                                    }
                                }
                            }
                        }
                        .onAppear{
                            gameService.listenGameRoom(socket: socketService.socket)
                            gameService.listenTheWinner(socket: socketService.socket)
                        }
                    }else{
                        Button(action: {
                            gameService.leaveGameRoom(socket: socketService.socket, roomId: name)
                        }, label: {
                            Text("Leave")
                        })
                        .buttonStyle(.bordered)
                        .foregroundColor(.red)
                    }
                    
                }
                .frame(width: geometry.size.width, height: geometry.size.height)
                .alert(isPresented: $showAlert ){
                    Alert(
                        title: Text("Game Result"),
                        message: Text(gameService.winner == true ? "You Win" : "You Lose"),
                        dismissButton: .default(Text("Good Game")){
                            print("BACK TO LOBBY")
                        }
                    )
                }
            }
        }else{
            VStack {
                Text("Join Tic-Tac-Toe Game")
                    .padding()
                
                TextField("ROOM ID", text: $name)
                    .textFieldStyle(.roundedBorder)
                    .padding()
                
                Button(action: {
                    joinGame()
                }, label: {
                    Text(gameService.joined ? "Success Join" : "Join Room!")
                })
                .buttonStyle(.bordered)
                .disabled(name == "" || !socketService.connected || gameService.joined)
                .padding()
                
                if gameService.msg != "" {
                    Text(gameService.msg)
                        .foregroundColor(.red)
                        .padding()
                }
                
                Text(socketService.connected ? "Connected" : "Disconnected")
                    .padding()
                
                HStack {
                    Button(action: {
                        socketService.reconnect()
                        resetConnection()
                    }, label: {
                        Text("Reconnect!")
                    })
                    .buttonStyle(.borderedProminent)
                    .disabled(!socketService.connected)
                    Button(action: socketService.connect, label: {
                        Text("Connect!")
                    })
                    .buttonStyle(.borderedProminent)
                    .disabled(socketService.connected)
                    Button(action: {
                        socketService.disconnect()
                        resetConnection()
                    }, label: {
                        Text("Disconnect!")
                    })
                    .buttonStyle(.borderedProminent)
                    .disabled(!socketService.connected)
                }
            }
            .onAppear{
                socketService.connect()
            }
        }
        
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
    }
}
