//
//  StatusBarView.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI
import AppKit

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

//        statusBar = NSStatusBar.init()
        statusBar = NSStatusBar.system
//        statusItem = statusBar.statusItem(withLength: 28.0)
        statusItem = statusBar.statusItem(withLength: NSStatusItem.squareLength)

        guard let statusBarButton = statusItem.button else {
            print("error")
            exit(1)
        }

        statusBarButton.image = NSImage(named: NSImage.Name("sun"))
        statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
//        statusBarButton.image?.isTemplate = true

        statusBarButton.action = #selector(togglePopover(sender:))
        statusBarButton.target = self

        statusBarButton.menu = self.menu // Right-click menu

        self.popover.contentViewController = PopoverViewController.newInstance()
//        self.popover.animates = false
    }

    @objc func togglePopover(sender: AnyObject) {
        if(popover.isShown) {
            hidePopover(sender)
        } else {
            NSApp.activate(ignoringOtherApps: true)
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

    func setup() {
        self.addItem(withTitle: "El Menu", action: #selector(elMenuItem(sender:)), keyEquivalent: "")
    }

    @objc func elMenuItem(sender: AnyObject) {
    }
}
