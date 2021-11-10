//
//  Bool-Extension.swift
//  work-light
//
//  Created by Jake Tesler on 11/10/21.
//

import Foundation

extension Bool {
    init(_ value: UInt32) {
        self = Bool(value != 0)
    }
}
