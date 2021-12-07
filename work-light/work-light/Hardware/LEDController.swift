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
                ledColor = []
                print("Serial disconnected")
            }
            updateLEDControllerDelegates()
        }
    }

    // MARK: LED State Tracking
    private var ledPower: LEDPower = .off
//    { didSet { if ledPower != oldValue { updateLEDControllerDelegates() } } }

    @Sorted private var ledColor: [LEDColor] = []
//    { didSet { if ledColor != oldValue { updateLEDControllerDelegates() } } }

    private var _prevLEDColorState: [LEDColor] = [.green] // This is also the initial state

    struct LEDColorsBlinking {
        @Sorted var colorsA: [LEDColor] = [] {
            didSet { print("colorsA: \(colorsA)") }
        }
        @Sorted var colorsB: [LEDColor] = [] {
            didSet { print("colorsB: \(colorsB)") }
        }
    }

    private var ledColorsBlinking = LEDColorsBlinking()
    private var _prevLEDColorBlinkState = LEDColorsBlinking()

    var blinkActive: Bool {
        !ledColorsBlinking.colorsA.isEmpty || !ledColorsBlinking.colorsB.isEmpty
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
            }

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
            } else {
                if ledColor.isEmpty {
                    ledColor = _prevLEDColorState.isEmpty ? [.green] : _prevLEDColorState
                }
                _prevLEDColorState = [] // needed?
            }
        }

        pushSystemState()
    }

    public func set(blink: Bool) {
        if blink == blinkEnabled { return } // do nothing

        if blink { // -> Enable blink
            if ledPower == .off { set(power: .on) }

            ledColorsBlinking.colorsA = ledColor
            ledColor = []
            blinkEnabled = true
        } else {  // -> Disable blink
            blinkEnabled = false
            if blinkActive { // at least one of two color arrays will have something
                ledColor = !ledColorsBlinking.colorsA.isEmpty
                    ? ledColorsBlinking.colorsA
                    : ledColorsBlinking.colorsB

                ledColorsBlinking = LEDColorsBlinking()
            }
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
                print("185 change B")
                ledColorsBlinking.colorsA.append(color)
                print("187 change A")
            } else {
                ledColorsBlinking.colorsA.removeAll { $0 == color }
                print("190 change A")
                ledColorsBlinking.colorsB.append(color)
                print("192 change B")
            }
        } else {
            ledColorsBlinking.colorsA.removeAll { $0 == color }
            print("196 change A")
            ledColorsBlinking.colorsB.removeAll { $0 == color }
            print("198 change B")
        }

        pushSystemState()
    }

    // MARK: - Private Functions
    private func pushSystemState() {
        // NOTE: This function cannot be used to turn the system off, because settings (e.g. blink)
        //       are cleared during data refresh, and will not be retained in UI since actual received system state
        //       would be 'off' (rather than what config is)

        if ledPower == .on {
            let data: Data
            turnOff()

            if blinkEnabled {
                var rawData: [UInt8] = []
                rawData.append(contentsOf: ledColorsBlinking.colorsA.map { $0.rawValue | LEDState.off.rawValue })
                rawData.append(contentsOf: ledColorsBlinking.colorsB.map { $0.rawValue | LEDState.on.rawValue })
                rawData.append(contentsOf: (
                    ledColorsBlinking.colorsA + ledColorsBlinking.colorsB).map { $0.rawValue | LEDState.blink.rawValue }
                )
                data = Data(rawData)
            } else {
                data = Data([bitwise_or(ledColor) | LEDState.on.rawValue] as [UInt8])
            }
            _ = serialController.send(serialData: data)
        }

//        updateLEDControllerDelegates() // This is unnecessary since the data update will call this after device has settled
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
        print(dataSet)

        if ledPower != dataSet.power { ledPower = dataSet.power }

        if !blinkEnabled {
            if ledColor != dataSet.color { ledColor = dataSet.color }
        } else {
            ledColorsBlinking.colorsA = dataSet.blinkA
            ledColorsBlinking.colorsB = dataSet.blinkB
        }
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

//        var scalars: [String.UnicodeScalarView.Element] = []
//        dataString.unicodeScalars.forEach { element in
//            if !scalars.contains(element) { scalars.append(element) }
//        }

//        var scalars: [UInt32] = []
//        dataString.unicodeScalars.forEach { element in
//            if !scalars.contains(element.value) { scalars.append(element.value) }
//        }

//        let scalarsCopy = scalars
//
//        if scalars.reduce(into: 0, { partialResult, scalar in partialResult += scalar.value }) > 0 { // value greater than 0 present
//            scalars.removeAll(where: {$0.value == 0}) // remove all 0-based values
//        }
//        print(scalarsCopy, "->", scalars)

//        scalars.forEach { element in
        dataString.unicodeScalars.forEach { element in
            updateDriverState(rawData: element.value as UInt32)
        }

//        scalars.forEach { value in
//            updateDriverState(rawData: value as UInt32)
//        }

        updateLEDControllerDelegates() // Finished -> Update Delegates
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
