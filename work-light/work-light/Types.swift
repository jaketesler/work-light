//
//  Types.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation

enum LEDColor: UInt8, CaseIterable, Comparable {
    static func < (lhs: LEDColor, rhs: LEDColor) -> Bool { return lhs.rawValue < rhs.rawValue }

    case red = 0x01
    case amber = 0x02
    case green = 0x04
}

enum LEDState: UInt8, CaseIterable {
    case on = 0x10
    case off = 0x20
    case blink = 0x40
}

enum LEDPower: CaseIterable {
    case on
    case off
}
