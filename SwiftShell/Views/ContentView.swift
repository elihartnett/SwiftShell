//
//  ContentView.swift
//  SwiftShell
//
//  Created by Eli Hartnett on 3/24/23.
//

import SwiftUI

struct ContentView: View {
    
    @EnvironmentObject var model: ShellModel
    
    var body: some View {
        VStack {
            Spacer()
            
            ScrollViewReader { proxy in
                ScrollView {
                    ForEach(model.shellOutput) { output in
                        Text(output.output)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .id(output.id)
                    }
                }
                .onChange(of: model.shellOutput.count) { _ in
                    proxy.scrollTo(model.shellOutput.last?.id)
                }
            }
            
            HStack {
                TextField("Input", text: $model.shellInput)
                    .onSubmit {
                        submitInput()
                    }
                
                Button {
                    submitInput()
                } label: {
                    Text("Send")
                }
            }
        }
        .padding()
    }
    
    func submitInput() {
        DispatchQueue.global().async {
            do {
                if model.asyncShellIsRunning {
                    try  model.shellInputPipe.fileHandleForWriting.write(contentsOf: model.shellInput.data(using: .utf8)!)
                }
                else {
                    DispatchQueue.main.async {
                        model.shellOutput.append(ShellOutput(index: model.shellOutput.count, output: "~ \(model.shellInput)"))
                    }
                    try? model.safeAsyncShell(model.shellInput)
                }
            }
            catch {
                model.handleError(error: error)
            }
        }
    }
}

struct ContentView_Previews: PreviewProvider {
    static var previews: some View {
        ContentView()
            .environmentObject(ShellModel())
    }
}
