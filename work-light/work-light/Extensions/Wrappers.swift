//
//  Wrappers.swift
//  work-light
//
//  Created by Jake Tesler on 12/1/21.
//

import Foundation

@propertyWrapper
struct Sorted<T: Comparable> {
    private var value: [T]
    var wrappedValue: [T] {
        get { value }
        set { value = newValue.sorted() }
    }

    init(wrappedValue: [T] = []) {
        value = wrappedValue.sorted()
    }
}
