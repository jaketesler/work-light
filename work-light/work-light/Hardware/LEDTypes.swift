//
//  Types.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation

enum LEDColor: UInt8, CaseIterable, Comparable {
    case red   = 0x01
    case amber = 0x02
    case green = 0x04

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
        static func rawDataToState(_ rawData: UInt32) -> (LEDPower, LEDState, [LEDColor])? {
            let power: LEDPower,
                state: LEDState,
                color: [LEDColor]
            switch rawData {
                case 0x00:
                    power = .off
                    state = .off
                    color = []

                case 0x01:
                    power = .on
                    state = .on
                    color = [.red]
                case 0x10, 0x11:
                    power = .on
                    state = .blink
                    color = [.red]

                case 0x02:
                    power = .on
                    state = .on
                    color = [.amber]
                case 0x20, 0x22:
                    power = .on
                    state = .blink
                    color = [.amber]

                case 0x04:
                    power = .on
                    state = .on
                    color = [.green]
                case 0x40, 0x44:
                    power = .on
                    state = .blink
                    color = [.green]

                case 0x03:
                    power = .on
                    state = .on
                    color = [.red, .amber]

                case 0x05:
                    power = .on
                    state = .on
                    color = [.red, .green]

                case 0x06:
                    power = .on
                    state = .on
                    color = [.amber, .green]

                case 0x07:
                    power = .on
                    state = .on
                    color = [.red, .amber, .green]

                case 0x60, 0x66:
                    power = .on
                    state = .blink
                    color = [.amber, .green]

                case 0x30, 0x33:
                    power = .on
                    state = .blink
                    color = [.red, .amber]

                case 0x50, 0x55:
                    power = .on
                    state = .blink
                    color = [.red, .green]

                case 0x70, 0x77:
                    power = .on
                    state = .blink
                    color = [.red, .amber, .green]

                default:
                    return nil
            }

            return (power, state, color)
        }
    }
}
