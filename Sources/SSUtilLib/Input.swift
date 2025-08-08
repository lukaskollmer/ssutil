//
// This source file is part of the ssutil open-source project
//
// SPDX-FileCopyrightText: 2025 Lukas Kollmer
//
// SPDX-License-Identifier: MIT
//

import AppKit
import CoreGraphics
import Foundation


public struct Input {
    enum Orientation: String {
        case portrait = "Portrait"
        case landscape = "Landscape"
    }
    
    let srcUrl: URL
    let nsImage: NSImage
    let cgImage: CGImage
//    let bezelFrame: BezelFrame
    let device: Device
    
    var orientation: Orientation {
        cgImage.width < cgImage.height ? .portrait : .landscape
    }
    
    public init(srcUrl: URL) throws {
        self.srcUrl = srcUrl
        self.nsImage = try NSImage(contentsOf: srcUrl).expect("Unable to read NSImage")
        self.cgImage = try nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil).expect("Unable to create CGImage")
        self.device = try Self.extractDevice(from: srcUrl).expect("Unable to parse device type from input filename")
    }
    
    private static func extractDevice(from url: URL) -> Device? {
        let filename = url.lastPathComponent
        let filenameComponents = filename.split(separator: " - ")
        return Device(rawValue: String(filenameComponents[1]))
    }
}



public enum Destination {
    /// The input file should be overwritten in-place
    case inPlace
    /// The output file should be written to the specified directory.
    case directory(URL)
    /// The output file should be written to the specified file url.
    case file(URL)
}
