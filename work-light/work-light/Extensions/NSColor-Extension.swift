//
//  NSColor-Extension.swift
//  work-light
//
//  Created by Jake Tesler on 12/6/21.
//

import Foundation
import SwiftUI

public func colorBlend(_ colorA: NSColor, _ colorB: NSColor, weightA: CGFloat = 0.5) -> NSColor {
    guard let colA = colorA.usingColorSpace(.sRGB),
          let colB = colorB.usingColorSpace(.sRGB)
          else { return .black }

    let cAr = colA.redComponent,
        cAg = colA.greenComponent,
        cAb = colA.blueComponent

    let cBr = colB.redComponent,
        cBg = colB.greenComponent,
        cBb = colB.blueComponent

    let cOr = weightA * cAr + (1.0 - weightA) * cBr,
        cOg = weightA * cAg + (1.0 - weightA) * cBg,
        cOb = weightA * cAb + (1.0 - weightA) * cBb

    return NSColor(red: cOr, green: cOg, blue: cOb, alpha: 1.0)
}
