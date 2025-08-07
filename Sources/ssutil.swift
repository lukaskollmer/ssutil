//
//  main.swift
//  ssutil
//
//  Created by Lukas Kollmer on 2025-08-07.
//  Copyright © 2025 Lukas Kollmer. All rights reserved.
//

import ArgumentParser
import Foundation


struct CommandError: Swift.Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}

@main
struct ssutil: ParsableCommand {
    @Option(help: "The device type to use")
    var device: String = "iPhone 16 Pro"
    
    @Flag(help: "override input files in-place")
    var inPlace = false
    
//    @Option(help: "output directory")
//    var outputDirectory: String
    
    @Argument(help: "input files")
    var files: [String] = []
    
    func run() throws {
        print("AYOOOOO", self)
        for file in files {
            let url = URL(filePath: file, relativeTo: .currentDirectory())
            try process(url)
        }
    }
}
