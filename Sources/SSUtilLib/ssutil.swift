//
//  main.swift
//  ssutil
//
//  Created by Lukas Kollmer on 2025-08-07.
//  Copyright © 2025 Lukas Kollmer. All rights reserved.
//

import Foundation
import OSLog


let logger = Logger(subsystem: "de.lukaskollmer.ssutil", category: "main")


struct CommandError: Swift.Error {
    let message: String
    
    init(_ message: String) {
        self.message = message
    }
}


public enum Device: String, RawRepresentable, CaseIterable {
    case iPhone16 = "iPhone 16"
    case iPhone16Plus = "iPhone 16 Plus"
    case iPhone16Pro = "iPhone 16 Pro"
    case iPhone16ProMax = "iPhone 16 Pro Max"
    
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
    
    var defaultColor: String {
        switch self {
        case .iPhone16, .iPhone16Plus:
            "Black"
        case .iPhone16Pro, .iPhone16ProMax:
            "Black Titanium"
        }
    }
}
