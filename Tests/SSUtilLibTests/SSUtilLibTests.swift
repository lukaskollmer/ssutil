//
// This source file is part of the ssutil open-source project
//
// SPDX-FileCopyrightText: 2025 Lukas Kollmer
//
// SPDX-License-Identifier: MIT
//

import AppKit
import Foundation
import SnapshotTesting
@testable import SSUtilLib
import Testing

@Suite
struct SSUtilLibTests {
    private var bezelsDir: URL {
        get throws {
            try #require(Bundle.module.url(forResource: "bezels", withExtension: nil))
        }
    }
    
    private func inputFileUrl(named name: String) -> URL? {
        Bundle.module.url(forResource: name, withExtension: "png")
    }
    
    @Test
    func portrait() throws {
        let input = try Input(
            srcUrl: #require(inputFileUrl(named: "Simulator Screenshot - iPhone 16 Pro Max - 2025-08-07 at 11.47.23")),
        )
        let dstUrl = URL.temporaryDirectory.appendingPathComponent(#function, conformingTo: .png)
        try SSUtilLib.process(
            input,
            bezelsDir: try bezelsDir,
            color: nil,
            destination: .file(dstUrl)
        )
        let result = try #require(NSImage(contentsOf: dstUrl))
        assertSnapshot(of: result, as: .image)
    }
}
