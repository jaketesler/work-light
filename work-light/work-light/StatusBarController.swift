//
//  StatusBarView.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI

class StatusBarController {
    private var statusItem: NSStatusItem
    private var menu: StatusBarMenuView
    private var popover = NSPopover()

    private var statusBarButton: NSStatusBarButton {
        get {
            guard let button = self.statusItem.button else { fatalError("Unable to acquire Status Bar Button") }
            return button
        }
    }

    init() {
        self.statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.squareLength)

        self.menu = StatusBarMenuView()

        self.popover.contentViewController = PopoverViewController.newInstance()
        self.popover.behavior = .transient

        self.statusBarButton.target = self
        self.statusBarButton.action = #selector(togglePopover(sender:))
        self.statusBarButton.menu = self.menu // Right-click menu
        self.statusBarButton.image = NSImage(named: NSImage.Name("sun"))
        self.statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
    }

    // MARK: - Popover controls

    @objc func togglePopover(sender: AnyObject) {
        popover.isShown ? hidePopover(sender) : showPopover(sender)
    }

    func showPopover(_ sender: AnyObject) {
        NSApp.activate(ignoringOtherApps: true) // needed for auto-hide
        popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: NSRectEdge.maxY)
    }

    func hidePopover(_ sender: AnyObject) {
        popover.performClose(sender)
    }
}

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
