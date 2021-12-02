//
//  LEDController.swift
//  work-light
//
//  Created by Jake Tesler on 11/4/21.
//

import Foundation

class LEDController: NSObject {
    // MARK: - Private Variables
    // MARK: Serial Management
    private var serialController = SerialController(vendorID: 0x1a86, productID: 0x7523)
    private var delegates: [LEDControllerDelegate] = []

    private var portPath: String? {
        didSet {
            if portPath == nil {
                ledPower = .off
//                ledState = .off
                ledColor = []
                print("Serial disconnected")
            }
            updateLEDControllerDelegates()
        }
    }

    // MARK: LED State Tracking
//    private var ledState : LEDState = .off {
//        didSet { updateLEDControllerDelegates() }
//    }
//    private var _prevLEDBlinkState = false

    @Sorted private var ledColor: [LEDColor] = [] {
        didSet { updateLEDControllerDelegates() }
    }
    private var _prevLEDColorState: [LEDColor] = [.green] // This is also the initial state

    private var ledPower: LEDPower = .off {
        didSet { updateLEDControllerDelegates() }
    }

    struct LEDColorsBlinking {
        @Sorted var colorsA: [LEDColor] = []
        @Sorted var colorsB: [LEDColor] = []
    }

    private var ledColorsBlinking = LEDColorsBlinking()

    private var _prevLEDColorBlinkState = LEDColorsBlinking()

    var blinkActive: Bool {
        !(ledColorsBlinking.colorsA.isEmpty || ledColorsBlinking.colorsB.isEmpty)
    }
    public var blinkEnabled = false

    // MARK: - Initialization
    override init() {
        super.init()

        serialController.register(serialDeviceDelegate: self)
        serialController.register(serialPortDelegate: self)

        _ = updateStatus()
    }

    // MARK: - Public Functions
    public func updateStatus() -> Bool {
        serialController.send(serialData: Data([LEDCommands.Commands.status] as [UInt8]))
    }

    public func changeColor(to color: LEDColor) {
        if color == .buzzer { return }

        // if power is off and we want to turn on a color, switch system on
        if ledPower == .off { ledPower = .on }

        // if state is off and we want to turn on a color, switch system on (but if blinking, allow)
//        if ledState == .off { ledState = .on }

        ledColor = isBuzzerOn ? [color, .buzzer] : [color]

        ledColorsBlinking.colorsA = []
        ledColorsBlinking.colorsB = []
        blinkEnabled = false

        pushSystemState()
    }

    public func set(color: LEDColor, to state: LEDPower) {
        if state == .off { // -> OFF
            ledColor.removeAll { $0 == color }
            pushSystemState()
        } else { // -> ON
            // if power is off and we want to turn on a color, switch system on
            if ledPower == .off { ledPower = .on }

            // if state is off and we want to turn on a color, switch system on (but if blinking, allow)
//            if ledState == .off { ledState = .on }

            if blinkEnabled {
                ledColorsBlinking.colorsB.removeAll { $0 == color }
                if !ledColorsBlinking.colorsA.contains(color) {
                    ledColorsBlinking.colorsA.append(color)
                }
                blinkEnabled = false
                pushSystemState()

            } else {
                if !ledColor.contains(color) {
                    ledColor.append(color)
                    pushSystemState()
                }
            }

        }
    }

    public func set(color: LEDColor, to state: Bool) {
        set(color: color, to: state ? .on : .off)
    }

    public func set(power state: LEDPower) {
        if state == .off { // -> OFF
            if blinkEnabled {
                _prevLEDColorBlinkState = ledColorsBlinking
                ledColorsBlinking = LEDColorsBlinking()

            } else {
                // store color then clear
                if !ledColor.isEmpty { _prevLEDColorState = ledColor }
                ledColor = []

                // store blink then clear
//                _prevLEDBlinkState = ledState == .blink
//                ledState = .off
            }

            // ledPowerChanged
            ledPower = state
            turnOff() // this seems to be needed, otherwise blink can't be set while power is off

        } else { // -> ON
            ledPower = state

            if blinkEnabled {
                if ledColorsBlinking.colorsA.isEmpty && ledColorsBlinking.colorsB.isEmpty {
                    ledColorsBlinking = _prevLEDColorBlinkState
                }

                // Set default, if needed
                if ledColorsBlinking.colorsA.isEmpty && ledColorsBlinking.colorsB.isEmpty {
                    ledColorsBlinking.colorsA.append(.green)
                }

                // Reset
                _prevLEDColorBlinkState = LEDColorsBlinking() // needed?

//                ledState = .blink
            } else {
                if ledColor.isEmpty {
                    ledColor = _prevLEDColorState.isEmpty ? [.green] : _prevLEDColorState
                }
                _prevLEDColorState = [] // needed?

//                if ledState == .off { // coundn't be blinking(True) in this state
//                    ledState = _prevLEDBlinkState ? .blink : .on // Restore state
//                }
            }

        }

        pushSystemState()
    }

    public func set(blink: Bool) {
        if blink == blinkEnabled { return } // do nothing

        if blink { // -> Enable blink
            ledColorsBlinking.colorsA = ledColor
            ledColor = []
//            ledState = .blink
            blinkEnabled = true
        } else {  // -> Disable blink
            blinkEnabled = false
            if blinkActive { // at least one of two color arrays will have something
                ledColor = !ledColorsBlinking.colorsA.isEmpty
                    ? ledColorsBlinking.colorsA
                    : ledColorsBlinking.colorsB

                ledColorsBlinking = LEDColorsBlinking()
            }
//            ledState = (ledPower == .off) ? .off : .on
        }

        pushSystemState()
    }

    public func set(color: LEDColor, blink: Bool, secondary: Bool = false) {
        if !blinkEnabled {
            set(blink: true)
        }

        if blink {
            if ledPower == .off { ledPower = .on } // turn on if not already on

            if !secondary {
                ledColorsBlinking.colorsB.removeAll { $0 == color }
                ledColorsBlinking.colorsA.append(color)
            } else {
                ledColorsBlinking.colorsA.removeAll { $0 == color }
                ledColorsBlinking.colorsB.append(color)
            }
        } else {
            ledColorsBlinking.colorsA.removeAll { $0 == color }
            ledColorsBlinking.colorsB.removeAll { $0 == color }
        }

        pushSystemState()
    }

    // MARK: - Private Functions
    private func pushSystemState() {
        // NOTE: This function cannot be used to turn the system off, because settings (e.g. blink) are cleared during data refresh,
        //       and will not be retained in UI since actual received system state would be 'off' (rather than what config is)

        if ledPower == .on {
            if blinkEnabled {
                turnOff()
                var rawData: [UInt8] = []
                rawData.append(contentsOf: ledColorsBlinking.colorsA.map( { $0.rawValue | LEDState.off.rawValue }))
                rawData.append(contentsOf: ledColorsBlinking.colorsB.map( { $0.rawValue | LEDState.on.rawValue }))
                rawData.append(contentsOf: (ledColorsBlinking.colorsA + ledColorsBlinking.colorsB).map( { $0.rawValue | LEDState.blink.rawValue }))

//                let rawData: [UInt8] = LEDColor.allCases.map { color in
//                    (color.rawValue | (ledColor.contains(color) ?  ledState.rawValue : LEDState.off.rawValue))
//                }
                _ = serialController.send(serialData: Data(rawData))

            } else {
                turnOff() // seems necessary when using bad code
                print(ledColor)
//                let data = Data([bitwise_or(ledColor) | ledState.rawValue] as [UInt8]) // TODO: bad code
                let data = Data([bitwise_or(ledColor) | LEDState.on.rawValue] as [UInt8]) // TODO: bad code
                _ = serialController.send(serialData: data)
            }

        }

        // Okay so how this works is:
        //   Set some colors ON (this is the first half), set some colors OFF (other side). Then set them all to blink.
        //   Order DNM, as long as the 'on'/'off' is before the 'blink' for the respective color.
//        let rawData: [UInt8] = [(LEDColor.green.rawValue | LEDState.off.rawValue),
//                                (LEDColor.green.rawValue | LEDState.blink.rawValue),
//                                (LEDColor.red.rawValue | LEDState.on.rawValue),
//                                (LEDColor.amber.rawValue | LEDState.on.rawValue),
//                                (LEDColor.amber.rawValue | LEDState.blink.rawValue),
//                                (LEDColor.red.rawValue | LEDState.blink.rawValue)]
//        _ = serialController.send(serialData: Data(rawData))

        updateLEDControllerDelegates()
    }

    private func updateLEDControllerDelegates() {
        delegates.forEach { $0.ledControllerDelegate(statusDidChange: ledPower, ledColor: ledColor) }
    }

    private func addDelegate(ledControllerDelegate delegate: LEDControllerDelegate) {
        delegates.append(delegate)
    }

    private func addDelegate(serialDeviceDelegate delegate: SerialDeviceDelegate) {
        serialController.register(serialDeviceDelegate: delegate)
    }

    private func turnOff() {
        let rawData: [UInt8] = LEDColor.allCases.map { color in (color.rawValue | LEDState.off.rawValue) }
        _ = serialController.send(serialData: Data(rawData))
    }

    private func updateDriverState(rawData: UInt32) {
        let dataSet = LEDCommands.Data.rawDataToState(rawData)

        if ledPower != dataSet.power { ledPower = dataSet.power }
//        if ledState != dataSet.state { ledState = dataSet.state }

        if !blinkEnabled {
            if ledColor != dataSet.color { ledColor = dataSet.color }
        } else {
            ledColorsBlinking.colorsA = dataSet.blinkA
            ledColorsBlinking.colorsB = dataSet.blinkB
        }

        updateLEDControllerDelegates()
    }

    // MARK: Utilities
    private func bitwise_or(_ arr: [UInt8]) -> UInt8 {
        var result: UInt8 = 0x0
        arr.forEach { result |= $0 }
        return result
    }

    private func bitwise_or(_ arr: [LEDColor]) -> UInt8 { bitwise_or(arr.map { $0.rawValue }) }
}

// MARK: - Extensions
// MARK: LEDController: SerialDeviceDelegate
extension LEDController: SerialDeviceDelegate {
    func serialDeviceDelegate(deviceDidChange device: String?) {
        portPath = device
    }
}

// MARK: LEDController: SerialPortDelegate
extension LEDController: SerialPortDelegate {
    func serialPortDelegate(_ port: String?, didReceive data: Data) {
        guard let dataString = String(data: data, encoding: .utf8) else { return }

        dataString.unicodeScalars.forEach { element in
            updateDriverState(rawData: element.value as UInt32)
        }
    }
}

// swiftlint:disable line_length
// MARK: - Public Interface
extension LEDController {
    // MARK: - Public Variables
    // MARK: Shared Instance
    public static var shared = LEDController()

    // MARK: State Variables
    public var power: LEDPower   { self.ledPower }
    public var color: [LEDColor] { self.ledColor }
//    public var isBlinking: Bool  { self.ledState == .blink }
    public var isBuzzerOn: Bool  { self.ledColor.contains(.buzzer) }
    public var deviceConnected: Bool { self.serialController.deviceConnected }
    public var blinkingColors: LEDColorsBlinking { self.ledColorsBlinking }

    // MARK: - Public Functions
    public func register(ledControllerDelegate delegate: LEDControllerDelegate) { addDelegate(ledControllerDelegate: delegate) }
    public func register(serialDeviceDelegate delegate: SerialDeviceDelegate) { addDelegate(serialDeviceDelegate: delegate) }
}

// MARK: - Protocols
protocol LEDControllerDelegate: AnyObject {
    func ledControllerDelegate(statusDidChange state: LEDPower, ledColor: [LEDColor])
}
