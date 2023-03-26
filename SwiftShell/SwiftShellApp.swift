//
//  SwiftShellApp.swift
//  SwiftShell
//
//  Created by Eli Hartnett on 3/24/23.
//

import SwiftUI

@main
struct SwiftShellApp: App {
    
    @StateObject var model = ShellModel()
    
    var body: some Scene {
        
        WindowGroup {
            ContentView()
                .environmentObject(model)
        }
    }
}
