//
//  LEDController.swift
//  work-light
//
//  Created by Jake Tesler on 11/4/21.
//

import Foundation

class LEDController: NSObject {
    // MARK: - Private Variables
    // MARK: Management
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

    // MARK: State Tracking
    private var _ledState : LEDState = .off { didSet { updateLEDControllerDelegates() } }
    fileprivate var ledState: LEDState {
        get { return _ledState }
        set {
            _ledState = newValue
            if ledPower == .on { serialController.sendData(Data([bitwise_or(ledColor) | ledState.rawValue] as [UInt8])) }
            updateLEDControllerDelegates()
        }
    }
    private var _prevLEDBlinkState: Bool = false

    private var _ledColor: [LEDColor] = [] { didSet { updateLEDControllerDelegates() } }
    fileprivate var ledColor: [LEDColor] {
        get { return _ledColor.sorted() }
        set {
            _ledColor = newValue.sorted()
            turnOff()
            if ledPower == .on { serialController.sendData(Data([bitwise_or(newValue) | ledState.rawValue] as [UInt8])) }
            updateLEDControllerDelegates()
        }
    }
    private var _prevLEDColorState: [LEDColor] = [.green]

    private var _ledPower: LEDPower = .off { didSet { updateLEDControllerDelegates() } }
    fileprivate var ledPower: LEDPower {
        get { return _ledPower }
        set {
            _ledPower = newValue
            if newValue == .off {
                 turnOff()
            } else {
                if ledColor == [] { _ledColor = _prevLEDColorState }
                if _prevLEDBlinkState { _ledState = .blink }
                serialController.sendData(Data([bitwise_or(ledColor) | ledState.rawValue] as [UInt8]))
            }
            updateLEDControllerDelegates()
        }
    }

    // MARK: - Public Variables
    public var power: LEDPower   { get { return self.ledPower } }
    public var color: [LEDColor] { get { return self.ledColor } }
    public var isBlinking: Bool  { get { return self.ledState == .blink } }
    public var isBuzzerOn: Bool  { get { return self.ledColor.contains(.buzzer) } }

    // MARK: - Initialization
    override init() {
        super.init()

        serialController.addDelegate(serialDeviceDelegate: self)
        serialController.addDelegate(serialPortDelegate: self)

        updateStatus()
    }

    //MARK: - Public Functions
    public func updateStatus() {
        serialController.sendData(Data([LEDCommands.Commands.status] as [UInt8]))
    }

    public func changeColor(to color: LEDColor) {
        if color == .buzzer { return }

        if _ledPower == .off { // if power is off and we want to turn on a color, switch system on
            _ledPower = .on
            _ledState = .on
        }

        self.ledColor = isBuzzerOn ? [color, .buzzer] : [color]
    }

    public func set(color: LEDColor, to state: LEDPower) {
        if _ledPower == .off && state != .off { // if power is off and we want to turn on a color, switch system on
            _ledPower = .on
            _ledState = .on
        }

        if state != .off {
            if ledColor.contains(color) { return }
            ledColor.append(color)
        } else {
            if !ledColor.contains(color) { return }
            ledColor = ledColor.filter({ $0 != color })
        }
    }

    public func set(color: LEDColor, to state: Bool) {
        set(color: color, to: state ? .on : .off)
    }

    public func set(power state: LEDPower) {
        if state == .off {
            if ledColor != [] { _prevLEDColorState = _ledColor } // store color
            _prevLEDBlinkState = _ledState == .blink
        } else {
            if ledState == .off { // coundn't be blinking(True) in this state
                ledState = .on // refresh ledState to ON
            }
        }

        self.ledPower = state
    }

    public func set(blink: Bool) {
        if blink {
            ledState = .blink
        } else {
            ledState = (ledPower == .off) ? .off : .on
        }
    }

    // MARK: - Private
    private func updateLEDControllerDelegates() {
        delegates.forEach({ $0.ledControllerDelegate(statusDidChange: ledPower, ledColor: ledColor) })
    }

    private func turnOff() {
        let rawData: [UInt8] = LEDColor.allCases.map({ color in (color.rawValue | LEDState.off.rawValue) })
        serialController.sendData(Data(rawData))
    }

    private func updateDriverState(rawData: UInt32) {
        (_ledPower, _ledState, _ledColor) = LEDCommands.Data.rawDataToState(rawData)
    }

    // MARK: - Utilities
    private func bitwise_or(_ arr: [UInt8]) -> UInt8 {
        var result: UInt8 = 0x0
        arr.forEach { val in (result |= val) }
        return result
    }

    private func bitwise_or(_ arr: [LEDColor]) -> UInt8 {
        return bitwise_or(arr.map { $0.rawValue })
    }
}

// MARK: - Extension: SerialDeviceDelegate
extension LEDController: SerialDeviceDelegate {
    func serialDeviceDelegate(deviceDidChange device: String?) {
        portPath = device
    }
}

// MARK: Extension: SerialPortDelegate
extension LEDController: SerialPortDelegate {
    func serialPortDelegate(_ port: String?, didReceive data: Data) {
        guard let dataString = String(data: data, encoding: .utf8) else { return }
        dataString.unicodeScalars.forEach({ element in
            updateDriverState(rawData: element.value as UInt32)
        })
    }
}

// MARK: - Public Interface
extension LEDController {
    public static var shared = LEDController()

    public var deviceConnected: Bool { get { return serialController.deviceConnected } }

    public func addDelegate(ledControllerDelegate delegate: LEDControllerDelegate) {
        self.delegates.append(delegate)
    }

    public func addDelegate(serialDeviceDelegate delegate: SerialDeviceDelegate) {
        self.serialController.addDelegate(serialDeviceDelegate: delegate)
    }
}

// MARK: - LEDControllerDelegate
protocol LEDControllerDelegate {
    func ledControllerDelegate(statusDidChange state: LEDPower, ledColor: [LEDColor])
}
