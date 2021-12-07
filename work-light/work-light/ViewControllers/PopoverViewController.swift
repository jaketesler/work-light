//
//  PopoverViewController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI

// swiftlint:disable comma

// swiftlint:disable vertical_whitespace_closing_braces vertical_whitespace

class PopoverViewController: NSViewController {
    // MARK: - UI Elements
    @IBOutlet private weak var onOffToggle: NSSwitch!
    @IBOutlet private weak var blinkToggle: NSSwitch!
    @IBOutlet private weak var buzzerToggle: NSSwitch!

    @IBOutlet private weak var greenOnly: NSButton!
    @IBOutlet private weak var amberOnly: NSButton!
    @IBOutlet private weak var redOnly: NSButton!

    @IBOutlet private weak var greenBlinkSelector: NSSegmentedControl!
    @IBOutlet private weak var amberBlinkSelector: NSSegmentedControl!
    @IBOutlet private weak var redBlinkSelector: NSSegmentedControl!

    @IBOutlet private weak var greenToggle: NSSwitch!
    @IBOutlet private weak var amberToggle: NSSwitch!
    @IBOutlet private weak var redToggle: NSSwitch!

    private lazy var allButtons: [NSButton] = [greenOnly, amberOnly, redOnly]
    private lazy var allSelectors: [NSSegmentedControl] = [greenBlinkSelector, amberBlinkSelector, redBlinkSelector]
    private lazy var allToggles: [NSSwitch] = [onOffToggle, blinkToggle, buzzerToggle,
                                               greenToggle, amberToggle, redToggle]

    @IBOutlet private weak var statusLabel: NSTextField!
    @IBOutlet private weak var disconnectedLabel: NSTextField!

    @IBOutlet private weak var colorDot: NSView!
    private lazy var colorDotLeftLayer = getLeftHalf()
    private lazy var colorDotRightLayer = getRightHalf()
    private lazy var centerLine = getCenterLine()
    private lazy var borderLayer = getBorderLayer()

    // MARK: - UI Actions
    // swiftlint:disable line_length
    @IBAction func switchOnOffToggled(_ sender: NSSwitch)  { ledController.set(power: sender.state == .off ? .off : .on) }
    @IBAction func switchBlinkToggled(_ sender: NSSwitch)  { ledController.set(blink: sender.state == .on) }
    @IBAction func switchBuzzerToggled(_ sender: NSSwitch) { ledController.set(color: .buzzer, to: sender.state == .on) }

    @IBAction func greenOnlyPushed(_ sender: Any) { ledController.changeColor(to: .green) }
    @IBAction func amberOnlyPushed(_ sender: Any) { ledController.changeColor(to: .amber) }
    @IBAction func redOnlyPushed(_ sender: Any)   { ledController.changeColor(to: .red) }

    @IBAction func greenBlinkSelected(_ sender: NSSegmentedControl) {
        ledController.set(color: .green, blink: sender.selectedSegment != 0, secondary: sender.selectedSegment == 2)
    }

    @IBAction func amberBlinkSelected(_ sender: NSSegmentedControl) {
        ledController.set(color: .amber, blink: sender.selectedSegment != 0, secondary: sender.selectedSegment == 2)
    }

    @IBAction func redBlinkSelected(_ sender: NSSegmentedControl) {
        ledController.set(color: .red, blink: sender.selectedSegment != 0, secondary: sender.selectedSegment == 2)
    }

    @IBAction func greenSwitchToggled(_ sender: NSSwitch) { ledController.set(color: .green, to: sender.state == .on) }
    @IBAction func amberSwitchToggled(_ sender: NSSwitch) { ledController.set(color: .amber, to: sender.state == .on) }
    @IBAction func redSwitchToggled(_ sender: NSSwitch)   { ledController.set(color: .red,   to: sender.state == .on) }
    // swiftlint:enable line_length

    // MARK: - Variables
    private var ledController = LEDController.shared
//    private var uiEnabled = false {
//        didSet {
//            if uiEnabled != oldValue {
//                uiEnabled ? enableUI() : disableUI()
//            }
//        }
//    }
    private var colorLeft: NSColor = .clear
    private var colorRight: NSColor?
    private var colorUpdating = false
//    private var waitForUpdateLock = false

    // MARK: - ViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        ledController.register(ledControllerDelegate: self)

        update()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        _ = ledController.updateStatus()
        update()
    }

    // MARK: - UI Helpers
    private func setupView() {
        allButtons.forEach { $0.showsBorderOnlyWhileMouseInside = true }

        colorDot.wantsLayer = true
        colorDot.layer?.masksToBounds = true
        colorDot.layer?.cornerRadius = 12.0
        colorDot.layer?.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0)

//        colorDotLeftLayer.anchorPoint = .zero
//        colorDotRightLayer.anchorPoint = .zero

//        let layerBounds = CGRect(x: 0.0, y: 0.0, width: colorDot.bounds.width/2, height: colorDot.bounds.height)
//        colorDotLeftLayer.bounds = layerBounds
//        colorDotRightLayer.bounds = layerBounds
//
//        colorDotLeftLayer.position = .init(x: 0.0, y: 0.0)
//        colorDotRightLayer.position = .init(x: colorDot.bounds.width/2, y: 0.0)

//        colorDotLeftLayer.masksToBounds = true
//        colorDotRightLayer.masksToBounds = true
//        colorDotLeftLayer.cornerRadius = 12.0
//        colorDotRightLayer.cornerRadius = 12.0


        colorDot.layer?.addSublayer(colorDotLeftLayer)
        colorDot.layer?.addSublayer(colorDotRightLayer)
        colorDot.layer?.addSublayer(centerLine)
        colorDot.layer?.addSublayer(borderLayer)

        greenBlinkSelector.selectedSegmentBezelColor = greenOnly.bezelColor
        amberBlinkSelector.selectedSegmentBezelColor = greenOnly.bezelColor
        redBlinkSelector.selectedSegmentBezelColor = greenOnly.bezelColor

//        colorDot.layer?.addSublayer(getInnerGrayCircle())
    }

    func update() {
         onOffToggle.animator().state  = ledController.power == .off ? .off : .on
         blinkToggle.animator().state  = ledController.blinkEnabled ? .on : .off
         buzzerToggle.animator().state = ledController.isBuzzerOn ? .on : .off

        if ledController.blinkEnabled {
            greenToggle.isHidden = true
            amberToggle.isHidden = true
            redToggle.isHidden = true

            allSelectors.forEach { $0.isHidden = false }
        } else {
            greenToggle.isHidden = false
            amberToggle.isHidden = false
            redToggle.isHidden = false

            allSelectors.forEach { $0.isHidden = true }
        }

//        enableColorDot() // called in enableUI()

         greenToggle.animator().state = ledController.color.contains(.green) ? .on : .off
         amberToggle.animator().state = ledController.color.contains(.amber) ? .on : .off
         redToggle.animator().state   = ledController.color.contains(.red)   ? .on : .off

         greenBlinkSelector.animator().selectedSegment = ledController.blinkingColors.colorsA.contains(.green)
            ? 1 : (ledController.blinkingColors.colorsB.contains(.green) ? 2 : 0)

         amberBlinkSelector.animator().selectedSegment = ledController.blinkingColors.colorsA.contains(.amber)
            ? 1 : (ledController.blinkingColors.colorsB.contains(.amber) ? 2 : 0)

         redBlinkSelector.animator().selectedSegment = ledController.blinkingColors.colorsA.contains(.red)
            ? 1 : (ledController.blinkingColors.colorsB.contains(.red) ? 2 : 0)

        if ledController.deviceConnected {
            // device is connected
            disconnectedLabel.isHidden = true
//            uiEnabled = true
            enableUI()
        } else {
            // device is not connected
            disconnectedLabel.isHidden = false
//            uiEnabled = false
            disableUI()
        }
    }

    // swiftlint:disable force_cast
    func enableUI() {
        allToggles.forEach { $0.isEnabled = true }

        allButtons.forEach { button in
            button.isEnabled = true
            button.showsBorderOnlyWhileMouseInside = true
            button.bezelColor = .systemBlue
        }

        allSelectors.forEach { $0.isEnabled = true }

        enableColorDot()

        (self.view as! NSViewInteractive).isUserInteractionEnabled = true
    }

    func disableUI() {
        allToggles.forEach { $0.isEnabled = false }

        allSelectors.forEach { $0.isEnabled = false }

        allButtons.forEach { button in
            button.isEnabled = false
            button.showsBorderOnlyWhileMouseInside = false
            button.bezelColor = nil
        }

        setColorDot(.clear)
        // setLayer(colorDot.layer, backgroundColor: .clear)

        (self.view as! NSViewInteractive).isUserInteractionEnabled = false
    }

    private func setColorDot(left: NSColor, right rightColor: NSColor?) {
        CATransaction.begin()
//        CATransaction.setAnimationDuration(2.0)
//        CATransaction.setDisableActions(true)

        if !ledController.blinkEnabled {
            if left == .clear {
                borderLayer.strokeColor = NSColor.black.cgColor
                borderLayer.lineWidth = 1.0
            } else {
                borderLayer.strokeColor = .clear
                borderLayer.lineWidth = 0.0
            }

            centerLine.fillColor = NSColor.clear.cgColor

            [colorDotLeftLayer, colorDotRightLayer].forEach { layer in
//                setLayer(layer, backgroundColor: left)
                layer.strokeColor = .clear
                layer.lineWidth = 0.0
                layer.fillColor = left.cgColor
            }

            CATransaction.commit()
            return
        }

        if let right = rightColor { // two-color mode
            if left == .clear && right == .clear { // if both sides are empty
                // colorDot.layer?.backgroundColor = .clear

//                centerLine.isHidden = false

//                borderLayer.isHidden = false
                borderLayer.strokeColor = NSColor.black.cgColor
                borderLayer.lineWidth = 1.0

                [colorDotLeftLayer, colorDotRightLayer].forEach { layer in
                    layer.strokeColor = .clear
                    layer.lineWidth = 0.0
                    layer.fillColor = .clear
                }

                centerLine.fillColor = NSColor.black.cgColor

            } else { // one or both sides are colored
                if left == .clear { // push left to back
                    colorDot.layer?.insertSublayer(colorDotRightLayer, above: colorDotLeftLayer)
                    centerLine.fillColor = NSColor.black.cgColor
                } else if right == .clear { // push right to back
                    colorDot.layer?.insertSublayer(colorDotLeftLayer, above: colorDotRightLayer)
                    centerLine.fillColor = NSColor.black.cgColor
                } else {
                    centerLine.fillColor = NSColor.clear.cgColor
                }

                borderLayer.strokeColor = .clear
                borderLayer.lineWidth = 0.0

                setLayer(colorDotLeftLayer, backgroundColor: left)
                setLayer(colorDotRightLayer, backgroundColor: right)
            }
        } else { // single-color mode
            /*
            [colorDotLeftLayer, colorDotRightLayer].forEach { layer in
                layer.isHidden = true
//                setLayer(layer, backgroundColor: .clear) // is this needed??
            }

            centerLine.isHidden = true

//            setLayer(colorDot.layer, backgroundColor: left)
            borderLayer.isHidden = left != .clear
            colorDot.layer?.backgroundColor = left.cgColor
            */

            if left == .clear {
                borderLayer.strokeColor = NSColor.black.cgColor
                borderLayer.lineWidth = 1.0
            } else {
                borderLayer.strokeColor = .clear
                borderLayer.lineWidth = 0.0
            }

            centerLine.fillColor = NSColor.clear.cgColor

            [colorDotLeftLayer, colorDotRightLayer].forEach { layer in
                setLayer(layer, backgroundColor: left)
            }

        }

        CATransaction.commit()
    }
    private func setColorDot(_ color: NSColor) { setColorDot(left: color, right: nil) }

    private func enableColorDot() {
        if ledController.blinkEnabled {
            let leftColor = ledController.blinkingColors.colorsA.isEmpty
                ? .clear
                : ledColorToSystemColor(ledController.blinkingColors.colorsA)
            let rightColor = ledController.blinkingColors.colorsB.isEmpty
                ? .clear
                : ledColorToSystemColor(ledController.blinkingColors.colorsB)

            setColorDot(left: leftColor, right: rightColor)
        } else {
            setColorDot(ledColorToSystemColor(ledController.color))
        }
    }

    private func setLayer(_ caLayer: CALayer?, backgroundColor color: NSColor) {
        if let layer = caLayer as? CAShapeLayer { // left/right sides
            if color == .clear {
                layer.strokeColor = .black
//                layer.lineWidth = 1.0
            } else {
                layer.strokeColor = color.cgColor
//                layer.lineWidth = 0.0
            }
            layer.lineWidth = 1.0
            layer.fillColor = color.cgColor

        } /* else if let layer = caLayer { // whole colorDot
            if color == .clear {
                borderLayer.isHidden = false
//                layer.borderColor = .black
//                layer.borderWidth = 0.5
            } else {
                borderLayer.isHidden = true
//                layer.borderColor = .clear
//                layer.borderWidth = 0.5
            }
            layer.backgroundColor = color.cgColor
        }*/
    }

    func getLeftHalf() -> CAShapeLayer {
        let center = CGPoint(x: colorDot.bounds.width / 2, y: colorDot.bounds.height / 2)
        let bezierPath = NSBezierPath()
        bezierPath.move(to: center)
        bezierPath.addArc(withCenter: center,
                          radius: colorDot.bounds.width / 2,
                          startAngle: 0.5 * .pi,
                          endAngle: 1.5 * .pi,
                          clockwise: true)
        bezierPath.close()
        let innerGrayCircle = CAShapeLayer()
        innerGrayCircle.path = bezierPath.cgPath
        innerGrayCircle.fillColor = NSColor.clear.cgColor

        return innerGrayCircle
    }

    func getRightHalf() -> CAShapeLayer {
        let center = CGPoint(x: colorDot.bounds.width / 2, y: colorDot.bounds.height / 2)
        let bezierPath = NSBezierPath()
        bezierPath.move(to: center)
        bezierPath.addArc(withCenter: center,
                          radius: colorDot.bounds.width / 2,
                          startAngle: 0.5 * .pi,
                          endAngle: 1.5 * .pi,
                          clockwise: false)
        bezierPath.close()
        let innerGrayCircle = CAShapeLayer()
        innerGrayCircle.path = bezierPath.cgPath
        innerGrayCircle.fillColor = NSColor.clear.cgColor
        return innerGrayCircle
    }

    func getBorderLayer() -> CAShapeLayer {
        let bezierPath = NSBezierPath()
        bezierPath.appendOval(in: NSRect(x: 0, y: 0, width: colorDot.bounds.width, height: colorDot.bounds.height))
        bezierPath.close()

        let innerGrayCircle = CAShapeLayer()
        innerGrayCircle.path = bezierPath.cgPath
        innerGrayCircle.fillColor = NSColor.clear.cgColor
        innerGrayCircle.backgroundColor = NSColor.clear.cgColor

        innerGrayCircle.lineWidth = 1.0
//        innerGrayCircle.strokeColor = .black
        innerGrayCircle.strokeColor = NSColor.blue.cgColor

        return innerGrayCircle
    }

    func getCenterLine() -> CAShapeLayer {
        let center = CGPoint(x: colorDot.bounds.width / 2 - 0.25, y: colorDot.bounds.height)
        let bezierPath = NSBezierPath()
        bezierPath.move(to: center)
        bezierPath.addLine(to: CGPoint(x: colorDot.bounds.width / 2 - 0.25, y: 0))
        bezierPath.addLine(to: CGPoint(x: colorDot.bounds.width / 2 + 0.25, y: 0))
        bezierPath.addLine(to: CGPoint(x: colorDot.bounds.width / 2 + 0.25, y: colorDot.bounds.height))
        bezierPath.close()
        let innerGrayCircle = CAShapeLayer()
        innerGrayCircle.path = bezierPath.cgPath
        innerGrayCircle.fillColor = NSColor.black.cgColor
        return innerGrayCircle
    }


    // swiftlint:enable force_cast

    // MARK: - Utilities
    func ledColorToSystemColor(_ ledColor: [LEDColor]) -> NSColor {
        let color = ledColor.filter { $0 != .buzzer }
        switch color {
            case [.red]:   return NSColor.systemRed
            case [.amber]: return NSColor.systemOrange
            case [.green]: return NSColor.systemGreen

            case [.red, .amber]:   return colorBlend(.systemRed,   .systemOrange)
            case [.red, .green]:   return colorBlend(.systemGreen, .systemYellow, weightA: 0.4)
            case [.amber, .green]: return colorBlend(.systemGreen, .systemOrange, weightA: 0.6)

            case [.red, .amber, .green]: return NSColor.systemYellow

            default: return NSColor.clear
        }
    }

    // MARK: Utilities (Private)
    private func colorBlend(_ colorA: NSColor, _ colorB: NSColor, weightA: CGFloat = 0.5) -> NSColor {
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
}

// MARK: - Storyboard Initialization
extension PopoverViewController {
    static func newInstance() -> PopoverViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("ButtonPopover"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PopoverViewController")

        guard
            let viewController = storyboard.instantiateController(withIdentifier: identifier) as? PopoverViewController
            else {
                fatalError("Unable to instantiate ViewController in ButtonPopover.storyboard")
        }
        return viewController
    }
}

// MARK: - Extensions
// MARK: PopoverViewController : LEDControllerDelegate
extension PopoverViewController: LEDControllerDelegate {
    func ledControllerDelegate(statusDidChange state: LEDPower, ledColor: [LEDColor]) {
        update()
    }
}

// MARK: - Views
class NSViewInteractive: NSView {
    var isUserInteractionEnabled = true

    override func hitTest(_ point: NSPoint) -> NSView? {
        isUserInteractionEnabled ? super.hitTest(point) : nil
    }
}

// swiftlint:disable all

/*

 Erica Sadun, http://ericasadun.com
 UIKit Compatibility for NSBezierPath

 */

#if canImport(UIKit)
import UIKit
#else
import Cocoa
#endif

#if canImport(Cocoa)
extension NSBezierPath {
    /// Appends a straight line to the receiver’s path.
    open func addLine(to point: CGPoint) {
        self.line(to: point)
    }

    /// Adds a Bezier cubic curve to the receiver’s path.
    open func addCurve(to point: CGPoint, controlPoint1: CGPoint, controlPoint2: CGPoint) {
        self.curve(to: point, controlPoint1: controlPoint1, controlPoint2: controlPoint2)
    }

    /// Appends a quadratic Bézier curve to the receiver’s path.
    open func addQuadCurve(to point: CGPoint, controlPoint: CGPoint) {
        let (d1x, d1y) = (controlPoint.x - currentPoint.x, controlPoint.y - currentPoint.y)
        let (d2x, d2y) = (point.x - controlPoint.x, point.y - controlPoint.y)
        let cp1 = CGPoint(x: controlPoint.x - d1x / 3.0, y: controlPoint.y - d1y / 3.0)
        let cp2 = CGPoint(x: controlPoint.x + d2x / 3.0, y: controlPoint.y + d2y / 3.0)
        self.curve(to: point, controlPoint1: cp1, controlPoint2: cp2)
    }

    /// Appends an arc to the receiver’s path.
    open func addArc(withCenter center: CGPoint, radius: CGFloat, startAngle: CGFloat, endAngle: CGFloat, clockwise: Bool) {
        let startAngle = startAngle * 180.0 / CGFloat.pi
        let endAngle = endAngle * 180.0 / CGFloat.pi
        appendArc(withCenter: center, radius: radius, startAngle: startAngle, endAngle: endAngle, clockwise: !clockwise)
    }

    /// Creates and returns a new BezierPath object initialized with a rounded rectangular path.
    public convenience init(roundedRect: CGRect, cornerRadius: CGFloat) {
        self.init(roundedRect: roundedRect, xRadius: cornerRadius, yRadius: cornerRadius)
    }

    /// Transforms all points in the path using the specified affine transform matrix.
    open func apply(_ theTransform: CGAffineTransform) {
        let t = AffineTransform(m11: theTransform.a, m12: theTransform.b,
                                m21: theTransform.c, m22: theTransform.d,
                                tX: theTransform.tx, tY: theTransform.ty)
        transform(using: t)
    }
}

extension NSBezierPath {
    /// Creates and returns a new CGPath object initialized with the contents of the Bezier Path
    /// - Note: Implemented to match the UIKit version
    public var cgPath: CGPath {

        // Create a new cgPath to work with
        let path = CGMutablePath()

        // Build an adaptable set of control points for any element type
        var points: [CGPoint] = Array<CGPoint>(repeating: .zero, count: 3)

        // Iterate through the path elements and extend the cgPath
        for idx in 0 ..< self.elementCount {
            let type = self.element(at: idx, associatedPoints: &points)
            switch type {
            case .moveTo:
                path.move(to: points[0])
            case .lineTo:
                path.addLine(to: points[0])
            case .curveTo:
                path.addCurve(to: points[2], control1: points[0], control2: points[1])
            case .closePath:
                path.closeSubpath()
            }
        }

        return path
    }

    /// Creates and returns a new UIBezierPath object initialized with the contents of a Core Graphics path.
    /// - Warning: To match UIKit, this cannot be a failable initializer
    public convenience init(cgPath: CGPath) {

        // Establish self and fetch reference
        self.init(); var selfref = self

        // Apply elements from cgPath argument
        cgPath.apply(info: &selfref, function: {
            (selfPtr, elementPtr: UnsafePointer<CGPathElement>) in

            // Unwrap pointer
            guard let selfPtr = selfPtr else {
                fatalError("init(cgPath: CGPath): Unable to unwrap pointer to self")
            }

            // Bind and fetch path and element
            let pathPtr = selfPtr.bindMemory(to: NSBezierPath.self, capacity: 1)
            let path = pathPtr.pointee
            let element = elementPtr.pointee

            // Update path with element
            switch element.type {
            case .moveToPoint:
                path.move(to: element.points[0])
            case .addLineToPoint:
                path.addLine(to: element.points[0])
            case .addQuadCurveToPoint:
                path.addQuadCurve(to: element.points[1], controlPoint: element.points[0])
            case .addCurveToPoint:
                path.addCurve(to: element.points[2], controlPoint1: element.points[0], controlPoint2: element.points[1])
            case .closeSubpath:
                path.close()
            }
        })
    }
}
#endif
