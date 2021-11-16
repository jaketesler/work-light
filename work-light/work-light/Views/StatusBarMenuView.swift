//
//  StatusbarMenuView.swift
//  work-light
//
//  Created by Jake Tesler on 11/4/21.
//

import Foundation
import SwiftUI

class StatusBarMenuView: NSMenu {
    // MARK: - UI Elements
    @IBOutlet private weak var topItem: NSMenuItem!

    lazy var deviceItem = NSMenuItem(title: self.deviceInfo, action: nil, keyEquivalent: "")

    // MARK: - Variables
    private let deviceDefaultText = "No Device Found"
    lazy var deviceInfo = self.deviceDefaultText {
        didSet { self.deviceItem.title = "Device: \(self.deviceInfo)" }
    }

    // MARK: - Initialization
    override init(title: String) {
        super.init(title: title)

        setupView()

        LEDController.shared.register(serialDeviceDelegate: self)
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)
    }

    // MARK: - UI Helpers
    private func setupView() {
        self.addItem(withTitle: "LED Light Pole Menu Bar Controller", action: nil, keyEquivalent: "")
        self.addItem(withTitle: "Created by Jake Tesler", action: nil, keyEquivalent: "")
        self.addItem(NSMenuItem.separator())

        self.addItem(deviceItem)
        self.addItem(NSMenuItem.separator())

        let quitItem = NSMenuItem(title: "Quit", action: #selector(quit), keyEquivalent: "Q")
        quitItem.isEnabled = true
        quitItem.target = self
        self.addItem(quitItem)
    }

    func setDevice(_ device: String?) {
        deviceInfo = device ?? deviceDefaultText
    }

    // MARK: - Utilities
    @objc
    func quit() { exit(0) }
}

// MARK: - Extensions
// MARK: StatusBarMenuView: SerialDeviceDelegate
extension StatusBarMenuView: SerialDeviceDelegate {
    func serialDeviceDelegate(deviceDidChange device: String?) {
        setDevice(device)
    }
}
