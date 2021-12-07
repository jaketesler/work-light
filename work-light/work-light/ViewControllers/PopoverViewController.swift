//
//  PopoverViewController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI

// swiftlint:disable comma discouraged_optional_boolean multiline_parameters

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
    private lazy var colorDotLeftLayer  = buildHalf(bounds: colorDot.bounds, clockwise: true)
    private lazy var colorDotRightLayer = buildHalf(bounds: colorDot.bounds, clockwise: false)
    private lazy var colorDotCenterLine  = getCenterLine(bounds: colorDot.bounds)
    private lazy var colorDotBorderLayer = getBorderLayer(bounds: colorDot.bounds)

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

        colorDot.layer?.addSublayer(colorDotLeftLayer)
        colorDot.layer?.addSublayer(colorDotRightLayer)
        colorDot.layer?.addSublayer(colorDotCenterLine)
        colorDot.layer?.addSublayer(colorDotBorderLayer)

        greenBlinkSelector.selectedSegmentBezelColor = greenOnly.bezelColor
        amberBlinkSelector.selectedSegmentBezelColor = greenOnly.bezelColor
        redBlinkSelector.selectedSegmentBezelColor = greenOnly.bezelColor
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

        // enableColorDot() // called in enableUI()

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
            enableUI()
        } else {
            // device is not connected
            disconnectedLabel.isHidden = false
            disableUI()
        }
    }

    // swiftlint:disable force_cast
    func enableUI() {
        allToggles.forEach { $0.isEnabled = true }

        allSelectors.forEach { $0.isEnabled = true }

        allButtons.forEach { button in
            button.isEnabled = true
            button.showsBorderOnlyWhileMouseInside = true
            button.bezelColor = .systemBlue
        }

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

        (self.view as! NSViewInteractive).isUserInteractionEnabled = false
    }

    private func setColorDot(left: NSColor, right rightColor: NSColor?) {
        CATransaction.begin()

        if let right = rightColor {
            // Two-color mode
            if left == .clear && right == .clear { // if both sides are empty
                setLayer(colorDotLeftLayer,  color: .clear, borderColor: .clear, borderWidth: 0.0)
                setLayer(colorDotRightLayer, color: .clear, borderColor: .clear, borderWidth: 0.0)

                updateDotView(showBorder: true, showCenterLine: true)
            } else {
                // One or both sides are colored
                var showCenter = false
                if left == .clear { // push left to back
                    colorDot.layer?.insertSublayer(colorDotRightLayer, above: colorDotLeftLayer)
                    showCenter = true
                } else if right == .clear { // push right to back
                    colorDot.layer?.insertSublayer(colorDotLeftLayer, above: colorDotRightLayer)
                    showCenter = true
                }

                updateDotView(leftColor: left, rightColor: right, showBorder: false, showCenterLine: showCenter)
            }
        } else {
            // Single-color mode -> color = left
            colorDot.layer?.insertSublayer(colorDotRightLayer, above: colorDotLeftLayer) // default (right above left)

            updateDotView(leftColor: left, rightColor: left, showBorder: left == .clear, showCenterLine: false)
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

    private func updateDotView(leftColor: NSColor? = nil, rightColor: NSColor? = nil,
                               showBorder: Bool? = nil, showCenterLine: Bool? = nil) {
        if let left  = leftColor  { setLayer(colorDotLeftLayer,  color: left) }
        if let right = rightColor { setLayer(colorDotRightLayer, color: right) }

        if let border = showBorder {
            if border {
                colorDotBorderLayer.strokeColor = NSColor.black.cgColor
                colorDotBorderLayer.lineWidth = 1.0
            } else {
                colorDotBorderLayer.strokeColor = .clear
                colorDotBorderLayer.lineWidth = 0.0
            }
        }

        if let center = showCenterLine {
            if center {
                colorDotCenterLine.fillColor = NSColor.black.cgColor
            } else {
                colorDotCenterLine.fillColor = NSColor.clear.cgColor
            }
        }
    }

    private func setLayer(_ layer: CAShapeLayer, color: NSColor,
                          borderColor: NSColor? = nil, borderWidth: CGFloat = 1.0) {
        layer.fillColor = color.cgColor
        layer.lineWidth = borderWidth

        if let border = borderColor {
            layer.strokeColor = border.cgColor
        } else {
            layer.strokeColor = (color != .clear) ? color.cgColor : .black
        }
    }

    // swiftlint:enable force_cast

    // MARK: - Utilities
    func ledColorToSystemColor(_ ledColor: [LEDColor]) -> NSColor {
        let color = ledColor.filter { $0 != .buzzer }.sorted()
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
