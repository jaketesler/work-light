//
//  StatusbarMenuView.swift
//  work-light
//
//  Created by Jake Tesler on 11/4/21.
//

import Foundation
import SwiftUI

class StatusBarMenuView: NSMenu {
    @IBOutlet weak var topItem: NSMenuItem!

    private let deviceDefaultText = "No Device Found"
    lazy var deviceInfo = self.deviceDefaultText {
        didSet { self.deviceItem.title = "Device: \(self.deviceInfo)" }
    }

    lazy var deviceItem = NSMenuItem(title: self.deviceInfo, action: nil, keyEquivalent: "")

    override init(title: String) {
        super.init(title: title)

        addItems()
        SerialController.shared.addDelegate(self)
    }

    required init(coder: NSCoder) {
        super.init(coder: coder)

        addItems()
        SerialController.shared.addDelegate(self)
    }

    private func addItems() {
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
        self.deviceInfo = device ?? deviceDefaultText
    }

    @objc func quit() { exit(0) }
}

extension StatusBarMenuView: SerialDeviceDelegate {
    func serialDeviceDelegate(deviceDidChange device: String?) {
        setDevice(device)
    }
}
