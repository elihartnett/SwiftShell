//
//  ShellOutput.swift
//  SwiftShell
//
//  Created by Eli Hartnett on 3/25/23.
//

import Foundation

struct ShellOutput: Identifiable {
    let id = UUID()
    
    let index: Int
    var output: String
}
