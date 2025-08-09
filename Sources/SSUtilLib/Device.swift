//
// This source file is part of the ssutil open-source project
//
// SPDX-FileCopyrightText: 2025 Lukas Kollmer
//
// SPDX-License-Identifier: MIT
//

import Foundation


struct CommandError: Swift.Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}


/// A device for which we can apply a bezel
public enum Device: String, RawRepresentable, CaseIterable, Sendable {
    case iPhone16 = "iPhone 16"
    case iPhone16Plus = "iPhone 16 Plus"
    case iPhone16Pro = "iPhone 16 Pro"
    case iPhone16ProMax = "iPhone 16 Pro Max"
    
    var defaultColor: String {
        switch self {
        case .iPhone16, .iPhone16Plus:
            "Black"
        case .iPhone16Pro, .iPhone16ProMax:
            "Black Titanium"
        }
    }
    
    public init?(rawValue: String) {
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
}
