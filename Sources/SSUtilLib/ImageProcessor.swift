//
// This source file is part of the ssutil open-source project
//
// SPDX-FileCopyrightText: 2025 Lukas Kollmer
//
// SPDX-License-Identifier: MIT
//


import Algorithms
public import AppKit
import CoreGraphics
import Foundation


/// Creates a new image by placing `input` in a suitable bezel.
public func process(
    _ input: Input,
    bezelsDir: URL,
    defaultDevice: Device?,
    color: String?,
    destination: Destination
) async throws {
    let image = try await makeImage(input, bezelsDir: bezelsDir, defaultDevice: defaultDevice, color: color)
    let dstUrl = switch destination {
    case .inPlace:
        input.srcUrl
    case .directory(let outputDir):
        outputDir.appendingPathComponent(input.srcUrl.deletingPathExtension().lastPathComponent, conformingTo: .png)
    case .file(let fileUrl):
        fileUrl
    }
    print("writing output to \(dstUrl.absoluteURL.path)")
    try image.writePNG(to: dstUrl)
}


/// Creates a new image by placing `input` in a suitable bezel.
public func makeImage(_ input: Input, bezelsDir: URL, defaultDevice: Device?, color: String?) async throws -> NSImage {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        throw CommandError("Unable to create CGColorSpace")
    }
    
    guard let device = input.device ?? defaultDevice else {
        throw CommandError("Unable to determine device type for input '\(input.srcUrl.lastPathComponent)'")
    }
    
    let bezelTemplate = try await BezelTemplate.for(
        deviceInfo: .init(device: device, color: color ?? device.defaultColor, orientation: input.orientation),
        bezelsDir: bezelsDir
    )
    
    let overallFrame = CGRect(
        origin: .zero,
        // using the CGImage here since that takes the scale into account.
        size: .init(width: bezelTemplate.cgImage.width, height: bezelTemplate.cgImage.height)
    )
    
    guard let context = CGContext(
        data: nil,
        width: Int(overallFrame.width),
        height: Int(overallFrame.height),
        bitsPerComponent: 8,
        bytesPerRow: 0,
        space: colorSpace,
        bitmapInfo: CGImageAlphaInfo.premultipliedLast.rawValue
    ) else {
        throw CommandError("Unable to create CGContext")
    }
    
    context.draw(
        try input.cgImage.masking(bezelTemplate.maskImage).expect("unable to mask screenshot"),
        in: bezelTemplate.bezelFrame.innerFrame
    )
    context.draw(bezelTemplate.cgImage, in: overallFrame)
    
    guard let resultCGImage = context.makeImage() else {
        throw CommandError("Unable to make result CGImage")
    }
    let resultImage = NSImage(cgImage: resultCGImage, size: overallFrame.size)
    return resultImage
}
