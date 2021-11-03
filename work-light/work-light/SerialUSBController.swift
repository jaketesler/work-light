//
//  SerialUSBController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation

import IOKit
import IOKit.usb
import IOKit.usb.IOUSBLib
import IOKit.serial

import ORSSerial

//import UserNotifications

class SerialController: NSObject {
    var port: ORSSerialPort
    
    static var controller: SerialController = SerialController()
    
    override init() {
        print("init")
        
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
//        port.numberOfDataBits = 8
//        port.parity = .none
//        port.numberOfStopBits = 1
//        port.usesRTSCTSFlowControl = false
        self.port.delegate = self
        port.open()
        
        
//        nc_config()
    }
    
    func changeColor(_ color: LEDColor) {
        print("changeColor")
        
//        RunLoop.current.run() // Required to receive data from ORSSerialPort and to process user input
        
        let colorHex: UInt8?
        switch color {
        case .red:
            colorHex = 0x11
        case .amber:
            colorHex = 0x12
        case .green:
            colorHex = 0x14
        }
        
//        print(color.rawValue.description)
        
        if let color = colorHex {
            turnOff()
            sendData(Data([color] as [UInt8]))
        } else {
            print("no color hex :(")
        }
    }
    
    func turnOff() {
        let offData = Data([0x21, 0x22, 0x24] as [UInt8])
        sendData(offData)
    }
    
    private func sendData(_ data: Data) {
        if !port.isOpen { port.open() }
        port.send(data)
        print("Data sent!")
//        port.close()
    }
    
    enum LEDColor: UInt8 {
        case red
        case amber
        case green
    }
}

extension SerialController: ORSSerialPortDelegate {
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("Serial removed: \(serialPort)")
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        let string = String(data: data, encoding: .utf8)
        print("Got \(string) from the serial port!")
    }

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
}

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


extension String {
    
    /// Create `Data` from hexadecimal string representation
    ///
    /// This creates a `Data` object from hex string. Note, if the string has any spaces or non-hex characters (e.g. starts with '<' and with a '>'), those are ignored and only hex characters are processed.
    ///
    /// - returns: Data represented by this hexadecimal string.
    
    var hexadecimal: Data? {
        var data = Data(capacity: count / 2)
        
        let regex = try! NSRegularExpression(pattern: "[0-9a-f]{1,2}", options: .caseInsensitive)
        regex.enumerateMatches(in: self, range: NSRange(startIndex..., in: self)) { match, _, _ in
            let byteString = (self as NSString).substring(with: match!.range)
            let num = UInt8(byteString, radix: 16)!
            data.append(num)
        }
        
        guard data.count > 0 else { return nil }
        
        return data
    }
    
}
