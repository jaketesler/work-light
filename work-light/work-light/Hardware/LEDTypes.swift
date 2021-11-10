//
//  Types.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation

enum LEDColor: UInt8, CaseIterable, Comparable {
    case red    = 0x01
    case amber  = 0x02
    case green  = 0x04
    case buzzer = 0x08

    static func < (lhs: LEDColor, rhs: LEDColor) -> Bool { return lhs.rawValue < rhs.rawValue }
}

enum LEDState: UInt8, CaseIterable {
    case on    = 0x10
    case off   = 0x20
    case blink = 0x40
}

enum LEDPower: CaseIterable {
    case on
    case off
}

class LEDCommands {
    class Commands {
        static let status: UInt8 = 0x30
    }

    class Data {
        fileprivate class ControlBits {
            static let red:    UInt32 = 0x01
            static let amber:  UInt32 = 0x02
            static let green:  UInt32 = 0x04
            static let buzzer: UInt32 = 0x08
        }

        static func rawDataToState(_ rawData: UInt32) -> (LEDPower, LEDState, [LEDColor]) {
            let redBit      = Bool(rawData & ControlBits.red)
            let amberBit    = Bool(rawData & ControlBits.amber)
            let greenBit    = Bool(rawData & ControlBits.green)
            let buzzerBit   = Bool(rawData & ControlBits.buzzer)

            let redBlink    = Bool(rawData & (ControlBits.red    << 4))
            let amberBlink  = Bool(rawData & (ControlBits.amber  << 4))
            let greenBlink  = Bool(rawData & (ControlBits.green  << 4))
            let buzzerBlink = Bool(rawData & (ControlBits.buzzer << 4))

            let powerOnOff  = Bool(rawData & 0xFF)
            let blinkActive = Bool(rawData & 0xF0)

            let power: LEDPower = powerOnOff ? .on : .off

            let state: LEDState
            if blinkActive {
                state = .blink
            } else {
                state = powerOnOff ? .on : .off
            }

            var color: [LEDColor] = []
            if Bool(redBit    || redBlink)    { color.append(.red) }
            if Bool(amberBit  || amberBlink)  { color.append(.amber) }
            if Bool(greenBit  || greenBlink)  { color.append(.green) }
            if Bool(buzzerBit || buzzerBlink) { color.append(.buzzer) }

            return (power, state, color)
        }
    }
}
