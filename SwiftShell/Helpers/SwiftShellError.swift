//
//  SwiftShellError.swift
//  SwiftShell
//
//  Created by Eli Hartnett on 3/24/23.
//

import Foundation

enum SwiftShellError: Error {
    case exitFailureError(command: String)
    case decodeError(data: Data)
}
