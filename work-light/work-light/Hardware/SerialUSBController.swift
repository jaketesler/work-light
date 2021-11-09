//
//  SerialUSBController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
//import UserNotifications

import ORSSerial

class SerialController: NSObject, SerialControllerManaged {
    // MARK: - ORSSerialPortManager
    @objc dynamic private var portManager = ORSSerialPortManager.shared()
    private var observation: NSKeyValueObservation?

    private var port: ORSSerialPort? {
        didSet {
            if port == nil { print("Serial disconnected") }
            deviceDelegates.forEach({ $0.serialDeviceDelegate(deviceDidChange: self.port?.path) })
        }
    }

    // MARK: Configuration
    private var productID: NSNumber = 0x7523
    private var vendorID: NSNumber = 0x1a86


    // MARK: - Delegates
    private var deviceDelegates: [SerialDeviceDelegate] = []
    private var portDelegates: [SerialPortDelegate] = []

    // MARK: - Initialization
    fileprivate override init() {
        super.init()

        setup()
    }

    init(vendorID vID: NSNumber, productID pID: NSNumber) {
        super.init()

        self.vendorID = vID
        self.productID = pID

        setup()
    }

    private func setup() {
        connect()
        observation = observe(\.portManager.availablePorts, options: [.new], changeHandler: serialPortsChanged)
    }

    // MARK: - Private functions
    // KVO
    private func serialPortsChanged(_ obj: _KeyValueCodingAndObserving, _ value: NSKeyValueObservedChange<[ORSSerialPort]>) -> Void {
        connect()
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
            if vID == self.vendorID && pID == self.productID {
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

        deviceDelegates.forEach({ $0.serialDeviceDelegate(deviceDidConnect: serialport.path) })
    }

    func disconnect() {
        guard let serialport = self.port else { return }
        if serialport.isOpen { serialport.close() }
        self.port = nil

        deviceDelegates.forEach({ $0.serialDeviceDelegateDeviceDidDisconnect() })
    }

    func sendData(_ data: Data) {
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
        portDelegates.forEach({ $0.serialPortDelegate(serialPort.path, didReceive: data) })
    }
}



// MARK: - Public interface
extension SerialController {
    public var deviceConnected: Bool { get { return self.port != nil } }

    public func addDelegate(serialDeviceDelegate delegate: SerialDeviceDelegate) {
        self.deviceDelegates.append(delegate)
        delegate.serialDeviceDelegate(deviceDidChange: self.port?.path)
    }

    public func addDelegate(serialPortDelegate delegate: SerialPortDelegate) {
        self.portDelegates.append(delegate)
    }
}

// MARK: - Delegate Protocols
// MARK: SerialDeviceDelegate
protocol SerialDeviceDelegate {
    func serialDeviceDelegate(deviceDidChange device: String?)
    func serialDeviceDelegate(deviceDidConnect device: String)
    func serialDeviceDelegateDeviceDidDisconnect()
}

// MARK: SerialPortDelegate
protocol SerialPortDelegate {
    func serialPortDelegate(_ port: String?, didReceive data: Data)
}
