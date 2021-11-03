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
    @objc dynamic var portManager = ORSSerialPortManager.shared()
    private var observation: NSKeyValueObservation?
    
    private var port: ORSSerialPort? {
        didSet {
            if port == nil {
                _ledPower = .off
                print("Serial disconnected")
            }
            updateDelegates()
        }
    }
    
    //MARK: - Delegates
    private var delegates: [SerialControllerDelegate] = []
    
    // MARK: - State Tracking
    private var _ledState : LEDState = .off { didSet { updateDelegates() } }
    private var ledState: LEDState {
        get { return _ledState }
        set {
            _ledState = newValue
            if ledPower == .on {
                sendData(Data([ledColor.rawValue | ledState.rawValue] as [UInt8]))
            }
            updateDelegates()
        }
    }
    
    private var _ledColor: LEDColor = .green { didSet { updateDelegates() } }
    private var ledColor: LEDColor {
        get { return _ledColor }
        set {
            _ledColor = newValue
            turnOff()
            if ledPower == .on {
                sendData(Data([newValue.rawValue | ledState.rawValue] as [UInt8]))
            }
            updateDelegates() // does this need newValue?
        }
    }
    
    private var _ledPower: LEDPower = .off { didSet { updateDelegates() } }
    private var ledPower: LEDPower {
        get { return _ledPower }
        set {
            _ledPower = newValue
            if newValue == .off {
                 turnOff()
            } else {
                sendData(Data([ledColor.rawValue | ledState.rawValue] as [UInt8]))
            }
            updateDelegates() // does this need newValue?
        }
    }
    
    //MARK: - Initialization
    
    override init() {
        super.init()
        
        connect()
        status()

        observation = observe(\.portManager.availablePorts, options: [.new], changeHandler: serialPortsChanged)
    }
    
    //MARK: - Public Functions
    
    public func changeColor(_ color: LEDColor) {
        self.ledColor = color
    }
    
    public func setOnOffState(_ state: LEDPower) {
        if self.ledState == .off { self.ledState = .on } // coundn't be blinking(True) in this state
        
        self.ledPower = state
    }
    
    public func setBlink(shouldBlink blink: Bool) {
        if blink {
            ledState = .blink
        } else {
            ledState = ledPower == .off ? .off : .on
        }
    }
    
    // MARK: - Private functions
    private func status() {
        let stream: UInt8 = 0x30
        
        sendData(Data([stream] as [UInt8]))
    }
    
    // KVO
    private func serialPortsChanged(_ obj: _KeyValueCodingAndObserving, _ value: NSKeyValueObservedChange<[ORSSerialPort]>) -> Void {
        connect()
    }
    
    private func updateDelegates() {
        for delegate in delegates {
            delegate.serialControllerDelegate(statusDidChange: ledPower, ledColor: ledColor)
        }
    }
    
    private func turnOff() {
        var rawData: [UInt8] = []
        for color in LEDColor.allCases {
            let bit = (color.rawValue | LEDState.off.rawValue)
            rawData.append(bit)
        }
        sendData(Data(rawData))
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
        self.port = nil
    }
    
    private func sendData(_ data: Data) {
        guard let serialport = self.port else { return }
        if !serialport.isOpen { serialport.open() }
        serialport.send(data)
        print("Data sent!")
//        serialport.close()
    }
}

extension SerialController: ORSSerialPortDelegate {
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("Serial removed: \(serialPort)")
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        let string = String(data: data, encoding: .utf8)
//        print("Got \(string) from the serial port!")
        
        for element in (string ?? "").unicodeScalars {
            if let value = element.value as? UInt32 {
                updateDriverState(rawData: value)
            }
        }
    }
    
    func updateDriverState(rawData: UInt32) {
        print("Status update received")
        switch rawData {
        case 0x03, 0x00:
            _ledPower = .off
            _ledState = .off
        
        case 0x01:
            _ledPower = .on
            _ledState = .on
            _ledColor = .red
        case 0x10, 0x11:
            _ledPower = .on
            _ledState = .blink
            _ledColor = .red
        
        case 0x02:
            _ledPower = .on
            _ledState = .on
            _ledColor = .amber
        case 0x20, 0x22:
            _ledPower = .on
            _ledState = .blink
            _ledColor = .amber
        
        case 0x04:
            _ledPower = .on
            _ledState = .on
            _ledColor = .green
        case 0x40, 0x44:
            _ledPower = .on
            _ledState = .blink
            _ledColor = .green
        
        default:
            print(String(rawData))
            print("boooo unknown response :(")
        }
    }
}

// MARK: - Public interface
extension SerialController {
    public static var shared: SerialController = SerialController()
    
    public var power: LEDPower { get { return self.ledPower } }
    public var color: LEDColor { get { return self.ledColor } }
    public var isBlinking: Bool { get { return self.ledState == .blink } }
    public var deviceConnected: Bool { get { return self.port != nil } }
    
    public func addDelegate(_ delegate: SerialControllerDelegate) {
        self.delegates.append(delegate)
    }
}

// MARK: - SerialControllerDelegate
protocol SerialControllerDelegate {
    func serialControllerDelegate(statusDidChange state: LEDPower, ledColor: LEDColor)
}
