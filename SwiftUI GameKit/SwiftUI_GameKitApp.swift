//
//  SwiftUI_GameKitApp.swift
//  SwiftUI GameKit
//
//  Created by Daffa Yagrariksa on 13/10/22.
//

import SwiftUI

@main
struct SwiftUI_GameKitApp: App {
    @ObservedObject var socketService = SocketService(url: Port.url)
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(socketService)
        }
    }
}
