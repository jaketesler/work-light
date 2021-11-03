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
    var port: ORSSerialPort
    
    static var controller: SerialController = SerialController()
    private var delegates: [SerialControllerDelegate] = []
    
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
    
    override init() {
        var ser_device: ORSSerialPort? = nil
        for port in ORSSerialPortManager.shared().availablePorts {
            guard
                let vID = port.vendorID,
                let pID = port.productID
                else { continue }
            if vID == 0x1a86 && pID == 0x7523 {
                ser_device = port
                break
            }
        }
        
        guard let serialport = ser_device else {
            print("no serial")
            exit(1)
        }

        self.port = serialport
        print("Path: \(port.path)")
        
        self.port.baudRate = 9600
        
        super.init()
        
        print("Baud rate set to \(self.port.baudRate)")
        self.port.delegate = self
        port.open()
        
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
        let stream: UInt8 = 0x00
        
        sendData(Data([stream] as [UInt8]))
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
        if !port.isOpen { port.open() }
        port.send(data)
        print("Data sent!")
//        port.close()
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

//extension SerialController {
//    @objc func serialPortsWereConnected(_ notification: Notification) {
//        if let userInfo = notification.userInfo {
//            let connectedPorts = userInfo[ORSConnectedSerialPortsKey] as! [ORSSerialPort]
//            print("Ports were connected: \(connectedPorts)")
//            self.postUserNotificationForConnectedPorts(connectedPorts)
//        }
//    }
//
//    @objc func serialPortsWereDisconnected(_ notification: Notification) {
//        if let userInfo = notification.userInfo {
//            let disconnectedPorts: [ORSSerialPort] = userInfo[ORSDisconnectedSerialPortsKey] as! [ORSSerialPort]
//            print("Ports were disconnected: \(disconnectedPorts)")
//            self.postUserNotificationForDisconnectedPorts(disconnectedPorts)
//        }
//    }
//}

//extension SerialController: UNUserNotificationCenterDelegate {
//    func nc_config() {
//        let nc = UNUserNotificationCenter.current()
//        nc.addObserver(self, forKeyPath: <#T##String#>, options: <#T##NSKeyValueObservingOptions#>, context: <#T##UnsafeMutableRawPointer?#>)
//        nc.addObserver(self, selector: #selector(serialPortsWereConnected(_:)), name: NSNotification.Name.ORSSerialPortsWereConnected, object: nil)
//        nc.addObserver(self, selector: #selector(serialPortsWereDisconnected(_:)), name: NSNotification.Name.ORSSerialPortsWereDisconnected, object: nil)
////        NSUserNotificationCenter.default.delegate = self
//        UNUserNotificationCenter.current().delegate = self
//
////        NotificationCenter.default.
//    }
//
//    func postUserNotificationForConnectedPorts(_ connectedPorts: [ORSSerialPort]) {
//        let unc = UNUserNotificationCenter.current()
//        for port in connectedPorts {
//            print(port)
////            let userNotee = UNNotification()
////            userNotee.
//
////            let userNote = NSUserNotification()
////            userNote.title = NSLocalizedString("Serial Port Connected", comment: "Serial Port Connected")
////        userNote.informativeText = "Serial Port \(port.name) was connected to your Mac."
////            userNote.soundName = nil;
////            unc.deliver(userNote)
//        }
//    }
//
//    func postUserNotificationForDisconnectedPorts(_ disconnectedPorts: [ORSSerialPort]) {
//        let unc = NSUserNotificationCenter.default
//        for port in disconnectedPorts {
//            let userNote = NSUserNotification()
//            userNote.title = NSLocalizedString("Serial Port Disconnected", comment: "Serial Port Disconnected")
//            userNote.informativeText = "Serial Port \(port.name) was disconnected from your Mac."
//            userNote.soundName = nil;
//            unc.deliver(userNote)
//        }
//    }
//}

