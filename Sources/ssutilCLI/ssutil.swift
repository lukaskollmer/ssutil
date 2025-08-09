//
// This source file is part of the ssutil open-source project
//
// SPDX-FileCopyrightText: 2025 Lukas Kollmer
//
// SPDX-License-Identifier: MIT
//

public import ArgumentParser
import Foundation
import SSUtilLib


@main
struct ssutil: AsyncParsableCommand, Sendable { // swiftlint:disable:this type_name
    @Option(name: .customLong("bezels"), help: "bezel templates downloaded from apple")
    var bezelsPath: String
    
    @Option(help: "fallback device type")
    var device: Device?
    
    @Option(help: "device color")
    var color: String?
    
    @Flag(help: "override input files in-place")
    var inPlace = false
    
    @Flag(name: .short, help: "enables debug logging")
    var verbose = false
    
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
    
    func run() async throws {
        if verbose {
            print("invocation: \(self)")
        }
        await withDiscardingTaskGroup { taskGroup in
            for file in files {
                taskGroup.addTask {
                    await handle(file: file)
                }
            }
        }
    }
    
    
    private func handle(file: String) async {
        if verbose {
            print("processing input file: \(file)")
        }
        let url = URL(filePath: file, relativeTo: .currentDirectory())
        let destination: Destination = if inPlace {
            .inPlace
        } else if let outputDir {
            .directory(outputDir)
        } else {
            .file(
                url
                    .deletingLastPathComponent()
                    .appendingPathComponent("\(url.deletingPathExtension().lastPathComponent)+bezel", conformingTo: .png)
            )
        }
        do {
            let input = try Input(srcUrl: url)
            try await SSUtilLib.process(input, bezelsDir: bezelsDir, defaultDevice: device, color: color, destination: destination)
        } catch {
            print("Failed to process '\(file)': \(error)")
        }
    }
}


extension Device: ExpressibleByArgument {}
