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
    func portrait() async throws {
        let input = try Input(
            srcUrl: #require(inputFileUrl(named: "Simulator Screenshot - iPhone 16 Pro Max - 2025-08-07 at 11.47.23")),
        )
        let result = try await SSUtilLib.makeImage(
            input,
            bezelsDir: try bezelsDir,
            defaultDevice: nil,
            color: nil
        )
        assertSnapshot(of: result, as: .image)
    }
}
