//
//  SerialUSBController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import ORSSerial

// MARK: - SerialController (Public)
class SerialController: NSObject, SerialControllerManaged {
    // MARK: - Private Variables
    // MARK: Configuration
    private var productID: NSNumber = 0x7523
    private var vendorID:  NSNumber = 0x1a86

    // MARK: Delegates
    private var deviceDelegates: [SerialDeviceDelegate] = []
    private var portDelegates: [SerialPortDelegate] = []

    // MARK: ORSSerial
    @objc private dynamic var portManager = ORSSerialPortManager.shared()
    private var observation: NSKeyValueObservation?

    private var port: ORSSerialPort? {
        didSet {
            if self.port == nil { print("Serial disconnected") }
            self.deviceDelegates.forEach { $0.serialDeviceDelegate(deviceDidChange: self.port?.path) }
        }
    }

    // MARK: - Initialization
    override private init() {
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

        observation = observe(\.portManager.availablePorts,
                              options: [.new],
                              changeHandler: serialPortsChanged)
    }

    // MARK: - Private Functions
    // MARK: Serial Communication
    private func connect() {
        disconnect()

        for port in portManager.availablePorts {
            guard
                let vID = port.vendorID,
                let pID = port.productID
                else { continue }
            if  vID == self.vendorID &&
                pID == self.productID {
                self.port = port
                print("New Serial Device: \(port.path)")
                break
            }
        }

        guard let serialPort = self.port
              else { return }

        serialPort.baudRate = 9600
        print("Baud rate set to \(serialPort.baudRate)")

        serialPort.delegate = self
        serialPort.open()
    }

    private func disconnect() {
        guard let serialPort = port
              else { return }

        if serialPort.isOpen { serialPort.close() }
        port = nil
    }

    private func send(data: Data) -> Bool {
        guard let serialPort = port
              else { return false }

        if !serialPort.isOpen { serialPort.open() }
        return serialPort.send(data)
    }

    // MARK: KVO
    private func serialPortsChanged(_ obj: _KeyValueCodingAndObserving,
                                    _ value: NSKeyValueObservedChange<[ORSSerialPort]>) {
        connectSerial()
    }

    // MARK: Delegates
    private func addDelegate(serialDeviceDelegate delegate: SerialDeviceDelegate) {
        deviceDelegates.append(delegate)

        delegate.serialDeviceDelegate(deviceDidChange: port?.path)
    }

    private func addDelegate(serialPortDelegate delegate: SerialPortDelegate) {
        portDelegates.append(delegate)
    }
}

// swiftlint:disable line_length
// MARK: - Public Interface
extension SerialController {
    // MARK: - Public Variables
    public var deviceConnected: Bool { self.port != nil }

    // MARK: - Public Functions
    // MARK: Delegates
    public func register(serialDeviceDelegate delegate: SerialDeviceDelegate) { addDelegate(serialDeviceDelegate: delegate) }
    public func register(serialPortDelegate delegate: SerialPortDelegate) { addDelegate(serialPortDelegate: delegate) }

    // MARK: Serial Communication
    public func connectSerial() { connect() }
    public func disconnectSerial() { disconnect() }
    public func send(serialData data: Data) -> Bool { send(data: data) }
}

// MARK: - Extensions
// MARK: SerialController: ORSSerialPortDelegate
extension SerialController: ORSSerialPortDelegate {
    func serialPortWasRemovedFromSystem(_ serialPort: ORSSerialPort) {
        print("Serial removed: \(serialPort)")
    }

    func serialPort(_ serialPort: ORSSerialPort, didReceive data: Data) {
        portDelegates.forEach { $0.serialPortDelegate(serialPort.path, didReceive: data) }
    }
}

// MARK: - Delegate Protocols
// MARK: SerialDeviceDelegate
protocol SerialDeviceDelegate: AnyObject {
    func serialDeviceDelegate(deviceDidChange device: String?)
}

// MARK: SerialPortDelegate
protocol SerialPortDelegate: AnyObject {
    func serialPortDelegate(_ port: String?, didReceive data: Data)
}
