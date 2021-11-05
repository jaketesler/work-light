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

    func applicationWillResignActive(_ notification: Notification) { // Called on navigate away
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBar = StatusBarController()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        SerialController.shared.disconnect()
    }
}
