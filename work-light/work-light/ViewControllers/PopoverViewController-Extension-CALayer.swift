//
//  PopoverViewController-Extension-CALayer.swift
//  work-light
//
//  Created by Jake Tesler on 12/6/21.
//

import Foundation
import SwiftUI

extension PopoverViewController {
    func buildHalf(bounds: CGRect, clockwise: Bool) -> CAShapeLayer {
        let center = CGPoint(x: bounds.width / 2, y: bounds.height / 2)
        let bezierPath = NSBezierPath()
        bezierPath.move(to: center)
        bezierPath.addArc(withCenter: center,
                          radius: bounds.width / 2,
                          startAngle: 0.5 * .pi,
                          endAngle: 1.5 * .pi,
                          clockwise: clockwise)
        bezierPath.close()

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.fillColor = NSColor.clear.cgColor
        return layer
    }

    func getBorderLayer(bounds: CGRect) -> CAShapeLayer {
        let bezierPath = NSBezierPath()
        bezierPath.appendOval(in: NSRect(x: 0, y: 0, width: bounds.width, height: bounds.height))
        bezierPath.close()

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.fillColor = NSColor.clear.cgColor
        layer.backgroundColor = NSColor.clear.cgColor
        layer.lineWidth = 1.0
        layer.strokeColor = NSColor.black.cgColor
        return layer
    }

    func getCenterLine(bounds: CGRect) -> CAShapeLayer {
        let center = CGPoint(x: bounds.width / 2 - 0.25, y: bounds.height)
        let bezierPath = NSBezierPath()
        bezierPath.move(to: center)
        bezierPath.addLine(to: CGPoint(x: bounds.width / 2 - 0.25, y: 0))
        bezierPath.addLine(to: CGPoint(x: bounds.width / 2 + 0.25, y: 0))
        bezierPath.addLine(to: CGPoint(x: bounds.width / 2 + 0.25, y: bounds.height))
        bezierPath.close()

        let layer = CAShapeLayer()
        layer.path = bezierPath.cgPath
        layer.fillColor = NSColor.black.cgColor
        return layer
    }
}
