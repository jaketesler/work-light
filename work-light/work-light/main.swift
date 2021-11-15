//
//  main.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import AppKit
import Foundation

// swiftlint:disable all

let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
