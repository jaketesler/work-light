//
//  StatusBarView.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI

class StatusBarView {
    // MARK: - UI Elements
    private var statusItem: NSStatusItem
    private var menu: StatusBarMenuView
    private var popover = NSPopover()

    private var statusBarButton: NSStatusBarButton {
        guard let button = self.statusItem.button else { fatalError("Unable to acquire Status Bar Button") }
        return button
    }

    // MARK: - Initialization
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

    // MARK: - UI Controls (Popover)
    @objc
    func togglePopover(sender: AnyObject) {
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
