//
//  SerialControllerManager.swift
//  work-light
//
//  Created by Jake Tesler on 11/9/21.
//

import Foundation

// MARK: - SerialControllerManager (Public)
class SerialControllerManager {
    // MARK: - Private Variables
    private var controllers: [SerialController] = []

    // MARK: - Public Variables
    public static var shared = SerialControllerManager()

    // MARK: Public Functions
    public func disconnectAll() {
        controllers.forEach { $0.disconnect() }
    }
}

// MARK: - SerialControllerManaged
// Protocol for SerialController object conformance
protocol SerialControllerManaged {
    func disconnect()
}
