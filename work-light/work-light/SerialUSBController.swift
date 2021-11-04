//
//  SerialUSBController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
//import UserNotifications

import ORSSerial

class SerialController: NSObject {
    //MARK: - ORSSerialPortManager
    @objc dynamic private var portManager = ORSSerialPortManager.shared()
    private var observation: NSKeyValueObservation?

    private var port: ORSSerialPort? {
        didSet {
            if port == nil {
                _ledPower = .off
                _ledState = .off
                _ledColor = []
                print("Serial disconnected")
            }
            updateDelegates()
        }
    }

    //MARK: - Delegates
    private var delegates: [SerialControllerDelegate] = []
    private var serialDeviceDelegates: [SerialDeviceDelegate] = []

    // MARK: - State Tracking
    private var _ledState : LEDState = .off { didSet { updateDelegates() } }
    fileprivate var ledState: LEDState {
        get { return _ledState }
        set {
            _ledState = newValue
            if ledPower == .on { sendData(Data([bitwise_or(ledColor) | ledState.rawValue] as [UInt8])) }
            updateDelegates()
        }
    }
    private var _prevLEDBlinkState: Bool = false

    private var _ledColor: [LEDColor] = [] { didSet { updateDelegates() } }
    fileprivate var ledColor: [LEDColor] {
        get { return _ledColor.sorted() }
        set {
            _ledColor = newValue.sorted()
            turnOff()
            if ledPower == .on { sendData(Data([bitwise_or(newValue) | ledState.rawValue] as [UInt8])) }
            updateDelegates()
        }
    }
    private var _prevLEDColorState: [LEDColor] = [.green]

    private var _ledPower: LEDPower = .off { didSet { updateDelegates() } }
    fileprivate var ledPower: LEDPower {
        get { return _ledPower }
        set {
            _ledPower = newValue
            if newValue == .off {
                 turnOff()
            } else {
                if ledColor == [] { _ledColor = _prevLEDColorState }
                if _prevLEDBlinkState { _ledState = .blink }
                sendData(Data([bitwise_or(ledColor) | ledState.rawValue] as [UInt8]))
            }
            updateDelegates()
        }
    }

    //MARK: - Initialization

    fileprivate override init() {
        super.init()

        connect()
        updateStatus()

        // Set up serial port change KVO
        observation = observe(\.portManager.availablePorts, options: [.new], changeHandler: serialPortsChanged)
    }

    //MARK: - Public Functions

    public func changeColor(to color: LEDColor) {
        if _ledPower == .off { // if power is off and we want to turn on a color, switch system on
            _ledPower = .on
            _ledState = .on
        }

        self.ledColor = [color]
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

    // MARK: - Private functions
    private func updateStatus() {
        let status_byte: UInt8 = 0x30
        sendData(Data([status_byte] as [UInt8]))
    }

    // KVO
    private func serialPortsChanged(_ obj: _KeyValueCodingAndObserving, _ value: NSKeyValueObservedChange<[ORSSerialPort]>) -> Void {
        connect()
    }

    private func updateDelegates() {
        delegates.forEach({ $0.serialControllerDelegate(statusDidChange: ledPower, ledColor: ledColor) })

        serialDeviceDelegates.forEach({ $0.serialDeviceDelegate(deviceDidChange: self.port?.path) })
    }

    private func turnOff() {
        let rawData: [UInt8] = LEDColor.allCases.map({ color in (color.rawValue | LEDState.off.rawValue) })
        sendData(Data(rawData))
    }

    // MARK: - Utilities
    func bitwise_or(_ arr: [UInt8]) -> UInt8 {
        var result: UInt8 = 0x0
        arr.forEach { val in (result |= val) }
        return result
    }

    func bitwise_or(_ arr: [LEDColor]) -> UInt8 {
        return bitwise_or(arr.map { $0.rawValue })
    }

    // MARK: - Serial comms
    func connect() {
        if let curPort = self.port {
            if curPort.isOpen { curPort.close() }
            self.port = nil
        }

        for port in portManager.availablePorts {
            guard
                let vID = port.vendorID,
                let pID = port.productID
                else { continue }
            if vID == 0x1a86 && pID == 0x7523 {
                self.port = port
                print("New Serial Device: \(port.path)")
                break
            }
        }

        guard let serialport = self.port else { return }

        serialport.baudRate = 9600
        print("Baud rate set to \(serialport.baudRate)")

        serialport.delegate = self
        serialport.open()
    }

    public func disconnect() {
        guard let serialport = self.port else { return }
        if serialport.isOpen { serialport.close() }
        self.port = nil
    }

    private func sendData(_ data: Data) {
        guard let serialport = self.port else { return }
        if !serialport.isOpen { serialport.open() }
        serialport.send(data)
    }
}

extension SerialController: ORSSerialPortDelegate {
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("Serial removed: \(serialPort)")
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        guard let string = String(data: data, encoding: .utf8) else { return }
        string.unicodeScalars.forEach({ element in
            updateDriverState(rawData: element.value as UInt32)
        })
    }

    func updateDriverState(rawData: UInt32) {
        // print("Status update received")
        switch rawData {
            case 0x00:
                _ledPower = .off
                _ledState = .off
                _ledColor = []

            case 0x01:
                _ledPower = .on
                _ledState = .on
                _ledColor = [.red]
            case 0x10, 0x11:
                _ledPower = .on
                _ledState = .blink
                _ledColor = [.red]

            case 0x02:
                _ledPower = .on
                _ledState = .on
                _ledColor = [.amber]
            case 0x20, 0x22:
                _ledPower = .on
                _ledState = .blink
                _ledColor = [.amber]

            case 0x04:
                _ledPower = .on
                _ledState = .on
                _ledColor = [.green]
            case 0x40, 0x44:
                _ledPower = .on
                _ledState = .blink
                _ledColor = [.green]

            case 0x03:
                _ledPower = .on
                _ledState = .on
                _ledColor = [.red, .amber]

            case 0x05:
                _ledPower = .on
                _ledState = .on
                _ledColor = [.red, .green]

            case 0x06:
                _ledPower = .on
                _ledState = .on
                _ledColor = [.amber, .green]

            case 0x07:
                _ledPower = .on
                _ledState = .on
                _ledColor = [.red, .amber, .green]

            case 0x60, 0x66:
                _ledPower = .on
                _ledState = .blink
                _ledColor = [.amber, .green]

            case 0x30, 0x33:
                _ledPower = .on
                _ledState = .blink
                _ledColor = [.red, .amber]

            case 0x50, 0x55:
                _ledPower = .on
                _ledState = .blink
                _ledColor = [.red, .green]

            case 0x70, 0x77:
                _ledPower = .on
                _ledState = .blink
                _ledColor = [.red, .amber, .green]

            default:
                print("boooo unknown status response :( - \(String(rawData))")
        }
    }
}

// MARK: - Public interface
extension SerialController {
    public static var shared: SerialController = SerialController()

    public var power: LEDPower   { get { return self.ledPower } }
    public var color: [LEDColor] { get { return self.ledColor } }
    public var isBlinking: Bool  { get { return self.ledState == .blink } }
    public var deviceConnected: Bool { get { return self.port != nil } }

    public func addDelegate(_ delegate: SerialControllerDelegate) {
        self.delegates.append(delegate)
    }

    public func addDelegate(_ delegate: SerialDeviceDelegate) {
        self.serialDeviceDelegates.append(delegate)
    }
}

// MARK: - SerialControllerDelegate
protocol SerialControllerDelegate {
    func serialControllerDelegate(statusDidChange state: LEDPower, ledColor: [LEDColor])
}

// MARK: - SerialDeviceDelegate
protocol SerialDeviceDelegate {
    func serialDeviceDelegate(deviceDidChange device: String?)
}
