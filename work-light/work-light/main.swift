//
//  main.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import AppKit


let app = NSApplication.shared
let delegate = AppDelegate()
app.delegate = delegate

_ = NSApplicationMain(CommandLine.argc, CommandLine.unsafeArgv)
