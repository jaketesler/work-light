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
    var port: ORSSerialPort? {
        didSet {
            if port == nil { print("Serial disconnected") }
            for delegate in delegates { delegate.serialControllerDelegate(statusDidChange: ledPower, ledColor: ledColor) }
        }
    }
    
    @objc dynamic var portManager = ORSSerialPortManager.shared()
    
    static var controller: SerialController = SerialController()
    private var delegates: [SerialControllerDelegate] = []
    
    var deviceConnected: Bool {
        get { return self.port != nil }
    }
    
    private var ledState: LEDState = .off {
        didSet {
            if ledPower == .on {
                sendData(Data([ledColor.rawValue | ledState.rawValue] as [UInt8]))
            }
            for delegate in delegates { delegate.serialControllerDelegate(statusDidChange: ledPower, ledColor: ledColor) }
        }
    }
    
    private var ledColor: LEDColor = .green {
        didSet {
            turnOff()
            if ledPower == .on {
                sendData(Data([ledColor.rawValue | ledState.rawValue] as [UInt8]))
            }
            for delegate in delegates { delegate.serialControllerDelegate(statusDidChange: ledPower, ledColor: ledColor) }
        }
    }
    
    private var ledPower: LEDPower = .off {
        didSet {
            if ledPower == .off {
                 turnOff()
            } else {
                sendData(Data([ledColor.rawValue | ledState.rawValue] as [UInt8]))
            }
            for delegate in delegates { delegate.serialControllerDelegate(statusDidChange: ledPower, ledColor: ledColor) }
        }
    }
    
    
    var observation: NSKeyValueObservation?
    
    override init() {
        
        super.init()
        
        connect()
        
        observation = observe(\.portManager.availablePorts, options: [.new], changeHandler: serialPortsChanged)
        
//        nc_config()
    }
    
    func changeColor(_ color: LEDColor) {
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
    
    private func status() {
        let stream: UInt8 = 0x30
        
        sendData(Data([stream] as [UInt8]))
    }
    
    private func serialPortsChanged(_ obj: _KeyValueCodingAndObserving, _ value: NSKeyValueObservedChange<[ORSSerialPort]>) -> Void {
        connect()
    }
    
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
    
    private func turnOff() {
        var rawData: [UInt8] = []
        for color in LEDColor.allCases {
            let bit = (color.rawValue | LEDState.off.rawValue)
            rawData.append(bit)
        }

        sendData(Data(rawData))
    }
    
    private func sendData(_ data: Data) {
        guard let serialport = self.port else { return }
        if !serialport.isOpen { serialport.open() }
        serialport.send(data)
        print("Data sent!")
//        serialport.close()
    }
}

enum LEDColor: UInt8, CaseIterable {
    case red = 0x01
    case amber = 0x02
    case green = 0x04
}

private enum LEDState: UInt8, CaseIterable {
    case on = 0x10
    case off = 0x20
    case blink = 0x40
}

enum LEDPower: CaseIterable {
    case on
    case off
}

extension SerialController {
    public var power: LEDPower {
        get { return self.ledPower }
    }
    
    public var color: LEDColor {
        get { return self.ledColor }
    }
    
    public var isBlinking: Bool {
        get { return self.ledState == .blink }
    }
    
    public func addDelegate(_ delegate: SerialControllerDelegate) {
        self.delegates.append(delegate)
    }
}

protocol SerialControllerDelegate {
    func serialControllerDelegate(statusDidChange state: LEDPower, ledColor: LEDColor)
}


extension SerialController: ORSSerialPortDelegate {
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("Serial removed: \(serialPort)")
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        let string = String(data: data, encoding: .utf8)
        print("Got \(string) from the serial port!")
    }
}
