//
//  Utils.swift
//  ssutil
//
//  Created by Lukas Kollmer on 2025-08-08.
//  Copyright © 2025 Lukas Kollmer. All rights reserved.
//

import AppKit
import CoreGraphics
import Foundation


extension Optional {
    func expect(_ errorMessage: @autoclosure () -> String) throws -> Wrapped {
        switch self {
        case .some(let value):
            return value
        case .none:
            throw CommandError(errorMessage())
        }
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
