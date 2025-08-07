//
//  ImageProcessor.swift
//  ssutil
//
//  Created by Lukas Kollmer on 2025-08-07.
//  Copyright © 2025 Lukas Kollmer. All rights reserved.
//


import Algorithms
import AppKit
import CoreGraphics
import Foundation


private struct BezelFrame {
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


extension ssutil {
    func process(_ fileUrl: URL) throws {
        print(fileUrl.resolvingSymlinksInPath().absoluteURL.resolvingSymlinksInPath().path)
        let deviceImageUrl = URL(filePath: "/Users/lukas/temp/bezels/PNG/iPhone 16 Pro Max/iPhone 16 Pro Max - Black Titanium - Portrait.png")
        
        guard let deviceImage = NSImage(contentsOf: deviceImageUrl),
              let deviceCGImage = deviceImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CommandError("Unable to open device bezel file")
        }
        
        let overallFrame = CGRect(
            origin: .zero,
            // using the CGImage here since that takes the scale into account.
            size: .init(width: deviceCGImage.width, height: deviceCGImage.height)
        )
        
        let bezelFrame = try Self.locateBezelFrame(in: deviceImage)
        
        guard let screenshotImage = NSImage(contentsOf: fileUrl),
              let screenshotCGImage = screenshotImage.cgImage(forProposedRect: nil, context: nil, hints: nil) else {
            throw CommandError("Unable to open screenshot image file")
        }
        
        guard let colorSpace = CGColorSpace(name: CGColorSpace.sRGB) else {
            throw CommandError("Unable to create CGColorSpace")
        }
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
        
        let screenshotMask = try Self.makeMask(for: screenshotCGImage, from: deviceCGImage, bezelFrame: bezelFrame)
        context.draw(screenshotCGImage.masking(screenshotMask)!, in: bezelFrame.innerFrame)
        context.draw(deviceCGImage, in: overallFrame)
        
        guard let resultCGImage = context.makeImage() else {
            throw CommandError("Unable to make result CGImage")
        }
        let resultImage = NSImage(cgImage: resultCGImage, size: overallFrame.size)
        let dstUrl = fileUrl.deletingLastPathComponent().appendingPathComponent(
            fileUrl.deletingPathExtension().lastPathComponent + "+bezel",
            conformingTo: .png
        )
        try resultImage.writePNG(to: dstUrl)
    }
    
    
    private static func locateBezelFrame(in bezelImage: NSImage) throws -> BezelFrame {
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
        
        print(width, height)
        return .init(
            canvasSize: CGSize(width: width, height: height),
            top: topStart...topEnd,
            bottom: bottomStart...bottomEnd,
            left: leftStart...leftEnd,
            right: rightStart...rightEnd
        )
    }
    
    
    private static func makeMask(for screenshotImage: CGImage, from deviceImage: CGImage, bezelFrame: BezelFrame) throws -> CGImage {
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
}


extension NSImage {
    func writePNG(to dstUrl: URL) throws {
        guard let tiff = self.tiffRepresentation,
              let bitmap = NSBitmapImageRep(data: tiff),
              let png = bitmap.representation(using: .png, properties: [:]) else {
            throw CommandError("Unable to get PNG representation")
        }
        try png.write(to: dstUrl)
    }
}


extension CGImage {
    func writePNG(to dstUrl: URL) throws {
        try NSImage(
            cgImage: self,
            size: .init(width: self.width, height: self.height)
        ).writePNG(to: dstUrl)
    }
    
    
    func createMask() -> CGImage? {
        let rect = CGRect(x: 0, y: 0, width: width, height: height)
        guard let colorSpace = CGColorSpace(name: CGColorSpace.genericGrayGamma2_2) else {
            return nil
        }
        guard let context = CGContext(
            data: nil,
            width: width,
            height: height,
            bitsPerComponent: 8,
            bytesPerRow: 0,
            space: colorSpace,
            bitmapInfo: CGImageAlphaInfo.none.rawValue
        ) else {
            return nil
        }
        context.setFillColor(gray: 1.0, alpha: 1.0)
        context.fill(rect)
        context.clip(to: rect, mask: self)
        context.setFillColor(gray: 0.0, alpha: 1.0)
        context.fill(rect)
        return context.makeImage()
    }
}
