//
//  Types.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation

// swiftlint:disable identifier_name large_tuple

enum LEDColor: UInt8, CaseIterable, Comparable {
    case red    = 0x01
    case amber  = 0x02
    case green  = 0x04
    case buzzer = 0x08

    static func < (lhs: LEDColor, rhs: LEDColor) -> Bool { lhs.rawValue < rhs.rawValue }
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

    private class ControlBits {
        static let red:    UInt32 = 0x01
        static let amber:  UInt32 = 0x02
        static let green:  UInt32 = 0x04
        static let buzzer: UInt32 = 0x08
    }

    class Data {
        static func rawDataToState(_ rawData: UInt32) -> DataSet {
            let redBit      = Bool(rawData & ControlBits.red)
            let amberBit    = Bool(rawData & ControlBits.amber)
            let greenBit    = Bool(rawData & ControlBits.green)
            let buzzerBit   = Bool(rawData & ControlBits.buzzer)
            print(
                (redBit ? "RED " : "noRed ") +
                (amberBit ? "AMBER " : "noAmber ") +
                (greenBit ? "GREEN " : "noGreen ") +
                (buzzerBit ? "BUZZ " : "noBuzz ")
            )

            let redBlink    = Bool(rawData & (ControlBits.red    << 4))
            let amberBlink  = Bool(rawData & (ControlBits.amber  << 4))
            let greenBlink  = Bool(rawData & (ControlBits.green  << 4))
            let buzzerBlink = Bool(rawData & (ControlBits.buzzer << 4))
            print(
                (redBlink ? "RED_bl " : "noRed_bl ") +
                (amberBlink ? "AMBER_bl " : "noAmber_bl ") +
                (greenBlink ? "GREEN_bl " : "noGreen_bl ") +
                (buzzerBlink ? "BUZZ_bl " : "noBuzz_bl ")
            )

            let powerOnOff  = Bool(rawData & 0xFF)
            let blinkActive = Bool(rawData & 0xF0)

            if buzzerBlink { print("BuzzerBlink") }
            if buzzerBit { print("BuzzerBit") }

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

            var colorBlinkSetA: [LEDColor] = []
            if Bool(!redBit    && redBlink)    { colorBlinkSetA.append(.red) }
            if Bool(!amberBit  && amberBlink)  { colorBlinkSetA.append(.amber) }
            if Bool(!greenBit  && greenBlink)  { colorBlinkSetA.append(.green) }
            if Bool(!buzzerBit && buzzerBlink) { colorBlinkSetA.append(.buzzer) }

            var colorBlinkSetB: [LEDColor] = []
            if Bool(redBit    && redBlink)    { colorBlinkSetB.append(.red) }
            if Bool(amberBit  && amberBlink)  { colorBlinkSetB.append(.amber) }
            if Bool(greenBit  && greenBlink)  { colorBlinkSetB.append(.green) }
            if Bool(buzzerBit && buzzerBlink) { colorBlinkSetB.append(.buzzer) }

//            print(colorBlinkSetA)
//            print(colorBlinkSetB)

            return DataSet(power: power, state: state, color: color, blinkA: colorBlinkSetA, blinkB: colorBlinkSetB)
        }
    }

    struct DataSet {
        var power: LEDPower
        var state: LEDState
        var color: [LEDColor]

        var blinkA: [LEDColor]
        var blinkB: [LEDColor]
    }
}
