//
//  ShellModel.swift
//  SwiftShell
//
//  Created by Eli Hartnett on 3/24/23.
//

import Foundation

class ShellModel: ObservableObject {
    
    @Published var shellOutput = [ShellOutput]()
    @Published var shellInput = ""
    
    var asyncShellIsRunning = false
    var shellOutputPipe = Pipe()
    var shellInputPipe = Pipe()
    
    func safeAsyncShell(_ command: String) throws {
        asyncShellIsRunning = true
        
        // Create process
        let task = Process()
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.arguments = ["-c", "script -q /dev/null \(command)"] // Remove buffer

        // Read input and inject to process
        let pipe = Pipe()
        task.standardInput = pipe
        shellInputPipe.fileHandleForReading.readabilityHandler = { handle in
            do {
                if let decodedData = try self.decodeData(data: handle.availableData) {
                    try pipe.fileHandleForWriting.write(contentsOf: (decodedData + "\n").data(using: .utf8) ?? Data())
                }
            }
            catch {
                self.handleError(error: error)
            }
        }
        
        // Read process output and append to shellOutput
        shellOutputPipe = Pipe()
        task.standardOutput = shellOutputPipe
        task.standardError = shellOutputPipe
        shellOutputPipe.fileHandleForReading.readabilityHandler = { handle in
            do {
                if let decodedData = try self.decodeData(data: handle.availableData) {
                    DispatchQueue.main.async {
                        self.shellOutput.append(ShellOutput(index: self.shellOutput.count, output: decodedData))
                        self.resetInput()
                    }
                }
            }
            catch {
                self.handleError(error: error)
            }
        }
        
        // Remove log noise
        var environment = ProcessInfo.processInfo.environment
        if environment.keys.contains("OS_ACTIVITY_DT_MODE") {
            environment["OS_ACTIVITY_DT_MODE"] = nil
            task.environment = environment
        }
        
        // Run process
        try task.run()
        task.waitUntilExit()
        
        if task.terminationStatus == EXIT_SUCCESS {
            try shellOutputPipe.fileHandleForReading.close()
            asyncShellIsRunning = false
            return
        }
        else { throw SwiftShellError.exitFailureError(command: command) }
    }
    
    @discardableResult
    func safeSyncShell(_ command: String) throws -> String {
        let task = Process()
        let pipe = Pipe()
        
        task.standardOutput = pipe
        task.standardError = pipe
        task.arguments = ["-c", command]
        task.executableURL = URL(fileURLWithPath: "/bin/zsh")
        task.standardInput = nil
        
        try task.run()
        
        let data = pipe.fileHandleForReading.readDataToEndOfFile()
        let output = String(data: data, encoding: .utf8)
        
        task.waitUntilExit()
        
        if task.terminationStatus == EXIT_SUCCESS {
            return output ?? "Error decoding data: \(data)"
        }
        else { throw SwiftShellError.exitFailureError(command: command) }
    }
    
    func decodeData(data: Data) throws -> String? {
        if data.count > 0 {
            if let line = String(data: data, encoding: .utf8) {
                return line
            }
            else {
                throw SwiftShellError.decodeError(data: data)
            }
        }
        return nil
    }
    
    func resetInput() {
        DispatchQueue.main.async {
            self.shellInput = ""
        }
    }
    
    func handleError(error: Error) {
        if let error = error as? SwiftShellError {
            switch error {
            case .exitFailureError(let command):
                print("Exit Failure Error: \(error.localizedDescription)")
                print("Command: \(command)")
            case .decodeError(let data):
                print("Decode Error: \(error.localizedDescription)")
                print("Data: \(data)")
            }
        }
    }
}
