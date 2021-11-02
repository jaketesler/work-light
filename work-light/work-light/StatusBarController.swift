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
    
    init(_ popover: NSPopover) {
        self.popover = popover
        self.popover.behavior = .transient
        
        
//        statusBar = NSStatusBar.init()
        statusBar = NSStatusBar.system
        statusItem = statusBar.statusItem(withLength: 28.0)
        
        if let statusBarButton = statusItem.button {
            statusBarButton.image = NSImage(named: NSImage.Name("sun"))
            statusBarButton.image?.size = NSSize(width: 18.0, height: 18.0)
//            statusBarButton.image?.isTemplate = true
            
//            statusBarButton.title = "Work Light"
            statusBarButton.action = #selector(togglePopover(sender:))
            statusBarButton.target = self
//            statusBarBut
        } else {
            print("error")
        }
        
        self.popover.contentViewController = PopoverViewController.newInstance()
//        self.popover.animates = false
        
//        self.statusBar.addObserver(self.popover, forKeyPath: "NSWindowDidResignKeyNotification")
        print("SBC done")
    }
    
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
