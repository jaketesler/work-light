//
//  WorkLightApp.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import SwiftUI
import ORSSerial

class AppDelegate: NSObject, NSApplicationDelegate {
    var statusBar: StatusBarController!
    var popover = NSPopover.init()

    func applicationWillResignActive(_ notification: Notification) { // Called on navigate away
        //print("resign active")
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        print("applicationDidFinishLaunching")

//        let contentView = ContentView()
//        popover.contentSize = NSSize(width: 360, height: 360)
//        popover.contentViewController = NSHostingController(rootView: contentView)

        statusBar = StatusBarController.init(popover)
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        SerialController.shared.disconnect()
    }
}

//class MainViewController: NSViewController {
//    var statusBarController: StatusBarController?
//    lazy private var popover = NSPopover.init()
//
//    override func viewDidLoad() {
//        super.viewDidLoad()
//        self.view.isHidden = true
//
//        statusBarController = StatusBarController(popover)
//    }
//}
