//
// This source file is part of the ssutil open-source project
//
// SPDX-FileCopyrightText: 2025 Lukas Kollmer
//
// SPDX-License-Identifier: MIT
//

// swiftlint:disable file_types_order

import AppKit
import CoreGraphics
public import Foundation


enum Orientation: String, Hashable, Sendable, CaseIterable {
    case portrait = "Portrait"
    case landscape = "Landscape"
}


/// Processing Input
public struct Input {
    let srcUrl: URL
    let nsImage: NSImage
    let cgImage: CGImage
//    let bezelFrame: BezelFrame
    let device: Device?
    
    var orientation: Orientation {
        cgImage.width < cgImage.height ? .portrait : .landscape
    }
    
    /// Creates a new `Input` object, for the screenshot at the specified url
    public init(srcUrl: URL) throws {
        self.srcUrl = srcUrl
        self.nsImage = try NSImage(contentsOf: srcUrl).expect("Unable to read NSImage")
        self.cgImage = try nsImage.cgImage(forProposedRect: nil, context: nil, hints: nil).expect("Unable to create CGImage")
        self.device = Self.extractDevice(from: srcUrl)
    }
    
    private static func extractDevice(from url: URL) -> Device? {
        let filename = url.lastPathComponent
        let filenameComponents = filename.split(separator: " - ")
        guard filenameComponents.count >= 2 else {
            return nil
        }
        return Device(rawValue: String(filenameComponents[1]))
    }
}


/// Where the resulting image should be stored.
public enum Destination {
    /// The input file should be overwritten in-place
    case inPlace
    /// The output file should be written to the specified directory.
    case directory(URL)
    /// The output file should be written to the specified file url.
    case file(URL)
}
