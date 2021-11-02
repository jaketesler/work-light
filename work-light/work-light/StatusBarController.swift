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
        
//        statusBarButton.title = "Work Light"
        statusBarButton.action = #selector(togglePopover(sender:))
//        statusBarButton.action = #selector(toggleMenu(sender:))
        statusBarButton.target = self

        statusBarButton.menu = self.menu // Right-click menu
        
        self.popover.contentViewController = PopoverViewController.newInstance()
//        self.popover.animates = false
        
        print("SBC done")
    }
    
    @objc func toggleMenu(sender: AnyObject) {
        
    }
//
    @objc func togglePopover(sender: AnyObject) {
        if(popover.isShown) {
            hidePopover(sender)
        }
        else {
            NSApp.activate(ignoringOtherApps: true)
            showPopover(sender)
        }
    }

    func showPopover(_ sender: AnyObject) {
        if let statusBarButton = statusItem.button {
            popover.show(relativeTo: statusBarButton.bounds, of: statusBarButton, preferredEdge: NSRectEdge.maxY)
        }
    }

    func hidePopover(_ sender: AnyObject) {
        popover.performClose(sender)
    }
    
}

//class TempMenu: NSMenu {
//    init() {
//        super.init(coder: nil)
//        self.addItem(withTitle: "MOO", action: #selector(mooItem(sender:)), keyEquivalent: "")
//    }
//
//    required init(coder: NSCoder) {
//        super.init(coder: coder)
//    }
//
//    @objc func mooItem(sender: AnyObject) {
//
//    }
//}

class StatusBarMenuView: NSMenu {
    @IBOutlet weak var topItem: NSMenuItem!
    
//    var title: String = "MENUE"
//
//    override func popUp(positioning item: NSMenuItem?, at location: NSPoint, in view: NSView?) -> Bool {
//        setup()
//        return true
//    }
    
    func setup() {
//        topItem.title? = "TOP"
        
        self.addItem(withTitle: "MOO", action: #selector(mooItem(sender:)), keyEquivalent: "")
    }
    
    @objc func mooItem(sender: AnyObject) {
        
    }
}
