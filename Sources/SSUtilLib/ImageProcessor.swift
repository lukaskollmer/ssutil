//
// This source file is part of the ssutil open-source project
//
// SPDX-FileCopyrightText: 2025 Lukas Kollmer
//
// SPDX-License-Identifier: MIT
//


import Algorithms
import AppKit
import CoreGraphics
import Foundation


struct BezelFrame {
    let canvasSize: CGSize
    let top: ClosedRange<Int>
    let bottom: ClosedRange<Int>
    let left: ClosedRange<Int>
    let right: ClosedRange<Int>
    
    /// The frame representing the device image's transparent inner region
    var innerFrame: CGRect {
        return CGRect(
            x: left.upperBound + 1,
            y: top.upperBound + 1,
            width: right.lowerBound - left.upperBound - 1,
            height: bottom.lowerBound - top.upperBound - 1
        )
    }
    
    init(canvasSize: CGSize, top: ClosedRange<Int>, bottom: ClosedRange<Int>, left: ClosedRange<Int>, right: ClosedRange<Int>) {
        self.canvasSize = canvasSize
        self.top = top
        self.bottom = bottom
        self.left = left
        self.right = right
    }
}



public func process(_ input: Input, bezelsDir: URL, color: String?, destination: Destination) throws {
    let image = try makeImage(input, bezelsDir: bezelsDir, color: color)
    let dstUrl = switch destination {
    case .inPlace:
        input.srcUrl
    case .directory(let outputDir):
        outputDir.appendingPathComponent(input.srcUrl.deletingPathExtension().lastPathComponent, conformingTo: .png)
    case .file(let fileUrl):
        fileUrl
    }
    try image.writePNG(to: dstUrl)
}


private func makeImage(_ input: Input, bezelsDir: URL, color: String?) throws -> NSImage {
    guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
        throw CommandError("Unable to create CGColorSpace")
    }
    
    let bezelImageUrl = bezelsDir
        .appendingPathComponent(input.device.rawValue, isDirectory: true)
        .appendingPathComponent("\(input.device.rawValue) - \(color ?? input.device.defaultColor) - \(input.orientation.rawValue)", conformingTo: .png)
    precondition(FileManager.default.fileExists(atPath: bezelImageUrl.absoluteURL.path))
      
    guard let bezelImage = NSImage(contentsOf: bezelImageUrl),
          let bezelCGImage = bezelImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
        throw CommandError("Unable to open device bezel file")
    }
    
    let overallFrame = CGRect(
        origin: .zero,
        // using the CGImage here since that takes the scale into account.
        size: .init(width: bezelCGImage.width, height: bezelCGImage.height)
    )
    
    let bezelFrame = try locateBezelFrame(in: bezelImage)
    
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
    
    let screenshotMask = try makeMask(for: input.cgImage, from: bezelCGImage, bezelFrame: bezelFrame)
    context.draw(input.cgImage.masking(screenshotMask)!, in: bezelFrame.innerFrame)
    context.draw(bezelCGImage, in: overallFrame)
    
    guard let resultCGImage = context.makeImage() else {
        throw CommandError("Unable to make result CGImage")
    }
    let resultImage = NSImage(cgImage: resultCGImage, size: overallFrame.size)
    return resultImage
}


private func locateBezelFrame(in bezelImage: NSImage) throws -> BezelFrame {
    guard let tiff = bezelImage.tiffRepresentation,
          let bitmap = NSBitmapImageRep(data: tiff) else {
        throw CommandError("Unable to get bezel bitmap")
    }
    guard let pixelData = bitmap.bitmapData else {
        throw CommandError("Unable to get bezel bitmap data")
    }
    let width = bitmap.pixelsWide
    let height = bitmap.pixelsHigh
    let bytesPerRow = bitmap.bytesPerRow
    let samplesPerPixel = bitmap.samplesPerPixel
    
    func offset(forX x: Int, y: Int) -> Int {
        y * bytesPerRow + x * samplesPerPixel
    }
    
    /// The alpha value at the specifed location, with `0` being fully transparent and `255` fully opaque
    func alpha(atX x: Int, y: Int) -> UInt8 {
        let offset = offset(forX: x, y: y)
        let alpha = pixelData[offset + samplesPerPixel - 1]
        return alpha
    }
    
    let middleX = width / 2
    let middleY = height / 2
    
    let topStart = (0..<height).adjacentPairs().first { y0, y1 in
        alpha(atX: middleX, y: y0) == 0 && alpha(atX: middleX, y: y1) != 0
    }?.1
    let topEnd = (0..<height).adjacentPairs().first { y0, y1 in
        alpha(atX: middleX, y: y0) != 0 && alpha(atX: middleX, y: y1) == 0
    }?.0
    let bottomStart = (0..<height).adjacentPairs().last { y0, y1 in
        alpha(atX: middleX, y: y0) == 0 && alpha(atX: middleX, y: y1) != 0
    }?.1
    let bottomEnd = (0..<height).adjacentPairs().last { y0, y1 in
        alpha(atX: middleX, y: y0) != 0 && alpha(atX: middleX, y: y1) == 0
    }?.0
    let leftStart = (0..<width).adjacentPairs().first { x0, x1 in
        alpha(atX: x0, y: middleY) == 0 && alpha(atX: x1, y: middleY) != 0
    }?.1
    let leftEnd = (0..<width).adjacentPairs().first { x0, x1 in
        alpha(atX: x0, y: middleY) != 0 && alpha(atX: x1, y: middleY) == 0
    }?.0
    let rightStart = (0..<width).adjacentPairs().last { x0, x1 in
        alpha(atX: x0, y: middleY) == 0 && alpha(atX: x1, y: middleY) != 0
    }?.1
    let rightEnd = (0..<width).adjacentPairs().last { x0, x1 in
        alpha(atX: x0, y: middleY) != 0 && alpha(atX: x1, y: middleY) == 0
    }?.0
    
    guard let topStart, let topEnd, let bottomStart, let bottomEnd, let leftStart, let leftEnd, let rightStart, let rightEnd else {
        throw CommandError("Unable to determine bezel rect")
    }
    
    
    return .init(
        canvasSize: CGSize(width: width, height: height),
        top: topStart...topEnd,
        bottom: bottomStart...bottomEnd,
        left: leftStart...leftEnd,
        right: rightStart...rightEnd
    )
}


private func makeMask(for screenshotImage: CGImage, from deviceImage: CGImage, bezelFrame: BezelFrame) throws -> CGImage {
    let screenFrame = bezelFrame.innerFrame
    let deviceImageBitmap = NSBitmapImageRep(cgImage: deviceImage)
    
    let setPixelBlack = { (x: Int, y: Int) in
        var blackPixel = [0, 0, 0, 255]
        deviceImageBitmap.setPixel(&blackPixel, atX: x, y: y)
    }
    let isTransparent = { (x: Int, y: Int) -> Bool in
        let pixel = UnsafeMutablePointer<Int>.allocate(capacity: 3)
        defer { pixel.deallocate() }
        deviceImageBitmap.getPixel(pixel, atX: x, y: y)
        precondition((pixel[3] == 0) == (deviceImageBitmap.colorAt(x: x, y: y)!.alphaComponent == 0))
        return pixel[3] == 0
    }
    let isOpaque = { (x: Int, y: Int) -> Bool in
        let pixel = UnsafeMutablePointer<Int>.allocate(capacity: 3)
        defer { pixel.deallocate() }
        deviceImageBitmap.getPixel(pixel, atX: x, y: y)
        precondition((pixel[3] == 255) == (deviceImageBitmap.colorAt(x: x, y: y)!.alphaComponent == 1))
        return pixel[3] == 255
    }
    
    for y in 0..<deviceImageBitmap.pixelsHigh {
        let firstNonTransparentX = (0..<deviceImageBitmap.pixelsWide).first { isOpaque($0, y) }
        for x in 0..<(firstNonTransparentX ?? deviceImageBitmap.pixelsWide) {
            setPixelBlack(x, y)
        }
        if firstNonTransparentX != nil {
            // at least one non-fully-transparent pixel in the row...
            let lastNonTransparentX = (0..<deviceImageBitmap.pixelsWide).last { isOpaque($0, y) }!
            for x in lastNonTransparentX..<deviceImageBitmap.pixelsWide {
                setPixelBlack(x, y)
            }
        }
        // get rid of the notch
        if let firstTransparentX = (0..<deviceImageBitmap.pixelsWide).first(where: { isTransparent($0, y) }),
           let lastTransparentX = (0..<deviceImageBitmap.pixelsWide).last(where: { isTransparent($0, y) }) {
            for x in firstTransparentX..<lastTransparentX {
                var pixel = [0, 0, 0, 0]
                deviceImageBitmap.setPixel(&pixel, atX: x, y: y)
            }
        }
    }
    return deviceImageBitmap.cgImage!.cropping(to: screenFrame)!.createMask()!
}
