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


let logger = Logger(subsystem: "de.lukaskollmer.ssutil", category: "main")


struct CommandError: Swift.Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}


enum Device: String, RawRepresentable, CaseIterable, ExpressibleByArgument {
    case iPhone16 = "iPhone 16"
    case iPhone16Plus = "iPhone 16 Plus"
    case iPhone16Pro = "iPhone 16 Pro"
    case iPhone16ProMax = "iPhone 16 Pro Max"
    
    init?(rawValue: String) {
        switch rawValue {
        case "iPhone16", "iPhone 16":
            self = .iPhone16
        case "iPhone16Plus", "iPhone 16 Plus":
            self = .iPhone16Plus
        case "iPhone16Pro", "iPhone 16 Pro":
            self = .iPhone16Pro
        case "iPhone16ProMax", "iPhone 16 Pro Max":
            self = .iPhone16ProMax
        default:
            return nil
        }
    }
    
    var defaultColor: String {
        switch self {
        case .iPhone16, .iPhone16Plus:
            "Black"
        case .iPhone16Pro, .iPhone16ProMax:
            "Black Titanium"
        }
    }
}


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
            do {
                let input = try Input(srcUrl: url)
                try process(input)
            } catch {
                logger.error("Failed to process '\(file)'")
            }
        }
    }
}
