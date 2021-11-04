//
//  StatusBarView.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI

class StatusBarController {
    private var statusBar: NSStatusBar
    private var statusItem: NSStatusItem
    private var popover: NSPopover
    private var menu: StatusBarMenuView

    init(_ popover: NSPopover) {
        self.popover = popover
        self.popover.behavior = .transient

        self.menu = StatusBarMenuView()
        self.menu.setup()

        self.statusBar = NSStatusBar.system
        self.statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)

        guard let statusBarButton = self.statusItem.button else {
            fatalError("Unable to acquire Status Bar Button")
        }

        statusBarButton.image = NSImage(named: NSImage.Name("sun"))
        statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)

        statusBarButton.action = #selector(togglePopover(sender:))
        statusBarButton.target = self

        statusBarButton.menu = self.menu // Right-click menu

        self.popover.contentViewController = PopoverViewController.newInstance()
        // self.popover.animates = false
    }

    @objc func togglePopover(sender: AnyObject) {
        if(popover.isShown) {
            hidePopover(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true) // needed for auto-hide
            showPopover(sender)
        }
    }

    func showPopover(_ sender: AnyObject) {
        guard let statusBarButton = statusItem.button else { return }
        popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: NSRectEdge.maxY)
    }

    func hidePopover(_ sender: AnyObject) {
        popover.performClose(sender)
    }
}

class StatusBarMenuView: NSMenu {
    @IBOutlet weak var topItem: NSMenuItem!

    private let deviceDefaultText = "No Device Found"
    lazy var deviceInfo = deviceDefaultText {
        didSet { deviceItem.title = "Device: " + deviceInfo }
    }

    lazy var deviceItem: NSMenuItem = { return NSMenuItem(title: deviceInfo, action: nil, keyEquivalent: "") }()

    func setup() {
        SerialController.shared.addDelegate(self)

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
