//
//  LoadingSpinner.swift
//  SwiftShell
//
//  Created by Eli Hartnett on 4/3/23.
//

import Foundation

func load() {
    let chars = ["-", #"\"#, #"|"#, #"/"#]
    Task {
        var count = 0
        while true {
            let index = count % chars.count
            print("\u{1B}[1A\u{1B}[K\(chars[index])")
            count += 1
            try await delay(seconds: 0.1)
        }
    }
}

func delay(seconds: Double) async throws {
    try await Task.sleep(nanoseconds: UInt64(seconds * Double(NSEC_PER_SEC)))
}

load()
RunLoop.main.run()
