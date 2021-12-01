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
                ledState = .off
                ledColor = []
                print("Serial disconnected")
            }
            updateLEDControllerDelegates()
        }
    }

    // MARK: LED State Tracking
    private var ledState : LEDState = .off {
        didSet { updateLEDControllerDelegates() }
    }
    private var _prevLEDBlinkState = false

    private var ledColor: [LEDColor] {
        get { _ledColorSorted.sorted() }
        set {
            _ledColorSorted = newValue.sorted()
            updateLEDControllerDelegates()
        }
    }
    private var _ledColorSorted: [LEDColor] = [] // To ensure sorting
    private var _prevLEDColorState: [LEDColor] = [.green]

    private var ledPower: LEDPower = .off {
        didSet { updateLEDControllerDelegates() }
    }

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
        if ledState == .off { ledState = .on }

        ledColor = isBuzzerOn ? [color, .buzzer] : [color]
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
            if ledState == .off { ledState = .on }

            if !ledColor.contains(color) {
                ledColor.append(color)
                pushSystemState()
            }
        }
    }

    public func set(color: LEDColor, to state: Bool) {
        set(color: color, to: state ? .on : .off)
    }

    public func set(power state: LEDPower) {
        if state == .off { // -> OFF
           // store color then clear
            if !ledColor.isEmpty { _prevLEDColorState = ledColor }
            ledColor = []

            // store blink then clear
            _prevLEDBlinkState = ledState == .blink
            ledState = .off

            // ledPowerChanged
            ledPower = state
            turnOff() // this seems to be needed, otherwise blink can't be set while power is off

        } else { // -> ON
            ledPower = state
            if ledColor.isEmpty { ledColor = _prevLEDColorState }
            if ledState == .off { // coundn't be blinking(True) in this state
                ledState = _prevLEDBlinkState ? .blink : .on // Restore state
            }
        }

        pushSystemState()
    }

    public func set(blink: Bool) {
        if blink {
            ledState = .blink
        } else {
            ledState = (ledPower == .off) ? .off : .on
        }

        pushSystemState()
    }

    // MARK: - Private Functions
    private func pushSystemState() {
        // NOTE: This function cannot be used to turn the system off, because settings (e.g. blink) are cleared during data refresh,
        //       and will not be retained in UI since actual received system state would be 'off' (rather than what config is)

        if ledPower == .on {
            // This may result in new modes! (alternating blink?)
//             let rawData: [UInt8] = LEDColor.allCases.map { color in
//                 (color.rawValue | (ledColor.contains(color) ?  ledState.rawValue : LEDState.off.rawValue))
//             }
//             _ = serialController.send(serialData: Data(rawData))

            turnOff() // seems necessary when using bad code
            let data = Data([bitwise_or(ledColor) | ledState.rawValue] as [UInt8]) // TODO: bad code
            _ = serialController.send(serialData: data)
        }
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
        let ledPowerIn: LEDPower,
            ledStateIn: LEDState,
            ledColorIn: [LEDColor]
        (ledPowerIn, ledStateIn, ledColorIn) = LEDCommands.Data.rawDataToState(rawData)

        if ledPower != ledPowerIn { ledPower = ledPowerIn }
        if ledState != ledStateIn { ledState = ledStateIn }
        if ledColor != ledColorIn { ledColor = ledColorIn }
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
    public var isBlinking: Bool  { self.ledState == .blink }
    public var isBuzzerOn: Bool  { self.ledColor.contains(.buzzer) }
    public var deviceConnected: Bool { self.serialController.deviceConnected }

    // MARK: - Public Functions
    public func register(ledControllerDelegate delegate: LEDControllerDelegate) { addDelegate(ledControllerDelegate: delegate) }
    public func register(serialDeviceDelegate delegate: SerialDeviceDelegate) { addDelegate(serialDeviceDelegate: delegate) }
}

// MARK: - Protocols
protocol LEDControllerDelegate: AnyObject {
    func ledControllerDelegate(statusDidChange state: LEDPower, ledColor: [LEDColor])
}
