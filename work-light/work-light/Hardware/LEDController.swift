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
                _ledPower = .off
                _ledState = .off
                _ledColor = []
                print("Serial disconnected")
            }
            updateLEDControllerDelegates()
        }
    }

    // MARK: LED State Tracking
    private var _ledState : LEDState = .off {
        didSet { updateLEDControllerDelegates() }
    }
    private var ledState: LEDState {
        get { _ledState }
        set {
            _ledState = newValue
            if ledPower == .on {
                let data = Data([bitwise_or(ledColor) | ledState.rawValue] as [UInt8])
                _ = serialController.send(serialData: data)
            }
            updateLEDControllerDelegates()
        }
    }
    private var _prevLEDBlinkState = false

    private var _ledColor: [LEDColor] = [] {
        didSet { updateLEDControllerDelegates() }
    }
    private var ledColor: [LEDColor] {
        get { _ledColor.sorted() }
        set {
            _ledColor = newValue.sorted()
            turnOff()
            if ledPower == .on {
                let data = Data([bitwise_or(newValue) | ledState.rawValue] as [UInt8])
                _ = serialController.send(serialData: data)
            }
            updateLEDControllerDelegates()
        }
    }
    private var _prevLEDColorState: [LEDColor] = [.green]

    private var _ledPower: LEDPower = .off {
        didSet { updateLEDControllerDelegates() }
    }
    private var ledPower: LEDPower {
        get { _ledPower }
        set {
            _ledPower = newValue
            if _ledPower == .off { // -> OFF
                 turnOff()
            } else { // -> ON
                if ledColor.isEmpty { _ledColor = _prevLEDColorState }
                if _prevLEDBlinkState { _ledState = .blink }
                _ = serialController.send(serialData: Data([bitwise_or(ledColor) | ledState.rawValue] as [UInt8]))
            }
            updateLEDControllerDelegates()
        }
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
        if _ledPower == .off { _ledPower = .on }

        // if state is off and we want to turn on a color, switch system on (but if blinking, allow)
        if _ledState == .off { _ledState = .on }

        ledColor = isBuzzerOn ? [color, .buzzer] : [color]
    }

    public func set(color: LEDColor, to state: LEDPower) {
        if state == .off { // -> OFF
            ledColor.removeAll { $0 == color }
        } else { // -> ON
            // if power is off and we want to turn on a color, switch system on
            if _ledPower == .off { _ledPower = .on }

            // if state is off and we want to turn on a color, switch system on (but if blinking, allow)
            if _ledState == .off { _ledState = .on }

            if !ledColor.contains(color) {
                ledColor.append(color)
            }
        }
    }

    public func set(color: LEDColor, to state: Bool) {
        set(color: color, to: state ? .on : .off)
    }

    public func set(power state: LEDPower) {
        if state == .off { // -> OFF
           // store color then clear
            if !ledColor.isEmpty { _prevLEDColorState = _ledColor }
            _ledColor = []

            // store blink then clear
            _prevLEDBlinkState = _ledState == .blink
            _ledState = .off

        } else { // -> ON
            if ledState == .off { // coundn't be blinking(True) in this state
                ledState = _prevLEDBlinkState ? .blink : .on // refresh ledState to ON
            }
        }

        ledPower = state
    }

    public func set(blink: Bool) {
        if blink {
            ledState = .blink
        } else {
            ledState = (ledPower == .off) ? .off : .on
        }
    }

    // MARK: - Private Functions
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

        if _ledPower != ledPowerIn { _ledPower = ledPowerIn }
        if _ledState != ledStateIn { _ledState = ledStateIn }
        if _ledColor != ledColorIn { _ledColor = ledColorIn }
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
