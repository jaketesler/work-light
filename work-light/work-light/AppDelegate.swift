//
//  WorkLightApp.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import ORSSerial
import SwiftUI

class AppDelegate: NSObject, NSApplicationDelegate {
    // swiftlint:disable implicitly_unwrapped_optional
    private var statusBar: StatusBarView!
    // swiftlint:enable implicitly_unwrapped_optional

    func applicationWillResignActive(_ notification: Notification) { // Called on navigate away
    }

    func applicationDidFinishLaunching(_ aNotification: Notification) {
        statusBar = StatusBarView()
    }

    func applicationWillTerminate(_ aNotification: Notification) {
        SerialControllerManager.shared.disconnectAll()
    }
}
