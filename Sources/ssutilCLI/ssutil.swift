//
//  main.swift
//  ssutil
//
//  Created by Lukas Kollmer on 2025-08-07.
//  Copyright © 2025 Lukas Kollmer. All rights reserved.
//

import ArgumentParser
import Foundation
import OSLog
import SSUtilLib


let logger = Logger(subsystem: "de.lukaskollmer.ssutil", category: "main")


extension Device: ExpressibleByArgument {}


@main
struct ssutil: ParsableCommand {
    @Option(name: .customLong("bezels"), help: "bezel files downloaded from apple")
    var bezelsPath: String
    
    @Option(help: "device color")
    var color: String?
    
    @Flag(help: "override input files in-place")
    var inPlace = false
    
    @Option(name: .customLong("output"), help: "output directory")
    var outputPath: String?
    
    @Argument(help: "input files")
    var files: [String] = []
    
    var bezelsDir: URL {
        URL(filePath: bezelsPath, relativeTo: .currentDirectory())
    }
    
    var outputDir: URL? {
        outputPath.map { URL(filePath: $0, relativeTo: .currentDirectory()) }
    }
    
    func run() throws {
        for file in files {
            let url = URL(filePath: file, relativeTo: .currentDirectory())
            let destination: Destination = if inPlace {
                .inPlace
            } else if let outputDir {
                .directory(outputDir)
            } else {
                .file(url
                    .deletingLastPathComponent()
                    .appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)+bezel", conformingTo: .png)
                )
            }
            do {
                let input = try Input(srcUrl: url)
                try SSUtilLib.process(input, bezelsDir: bezelsDir, color: color, destination: destination)
            } catch {
                logger.error("Failed to process '\(file)'")
            }
        }
    }
}
