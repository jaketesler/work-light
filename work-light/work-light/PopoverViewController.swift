//
//  PopoverViewController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI

class PopoverViewController: NSViewController {
    // MARK: - UI Elements
    @IBOutlet weak var onOffToggle: NSSwitch!
    @IBOutlet weak var blinkToggle: NSSwitch!

    @IBOutlet weak var greenButton: NSButton!
    @IBOutlet weak var amberButton: NSButton!
    @IBOutlet weak var redButton: NSButton!

    @IBOutlet weak var greenToggle: NSSwitch!
    @IBOutlet weak var amberToggle: NSSwitch!
    @IBOutlet weak var redToggle: NSSwitch!

    private lazy var allButtons: [NSButton] = [greenButton, amberButton, redButton]
    private lazy var allToggles: [NSSwitch] = [onOffToggle, blinkToggle, greenToggle, amberToggle, redToggle]

    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var disconnectedLabel: NSTextField!

    @IBOutlet weak var colorDot: NSView!

    // MARK: - UI Actions
    @IBAction func switchOnOffToggled(_ sender: NSSwitch) { ledController.set(power: sender.state == .off ? .off : .on) }
    @IBAction func switchBlinkToggled(_ sender: NSSwitch) { ledController.set(blink: sender.state == .on) }

    @IBAction func greenButtonPushed(_ sender: Any) { ledController.changeColor(to: .green) }
    @IBAction func amberButtonPushed(_ sender: Any) { ledController.changeColor(to: .amber) }
    @IBAction func redButtonPushed(_ sender: Any)   { ledController.changeColor(to: .red) }

    @IBAction func greenSwitchToggled(_ sender: NSSwitch) { ledController.set(color: .green, to: sender.state == .on) }
    @IBAction func amberSwitchToggled(_ sender: NSSwitch) { ledController.set(color: .amber, to: sender.state == .on) }
    @IBAction func redSwitchToggled(_ sender: NSSwitch)   { ledController.set(color: .red,   to: sender.state == .on) }

    // MARK: - Variables
    private var ledController = SerialController.shared

    // MARK: - ViewController
    override func viewDidLoad() {
        super.viewDidLoad()

        setupView()

        ledController.addDelegate(self)

        update()
    }

    override func viewWillAppear() {
        super.viewWillAppear()

        update()
    }

    // MARK: - UI Helpers
    private func setupView() {
        allButtons.forEach({ $0.showsBorderOnlyWhileMouseInside = true })

        colorDot.wantsLayer = true
        colorDot.layer?.masksToBounds = true
        colorDot.layer?.cornerRadius = 12.0;
        colorDot.layer?.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
    }

    func update() {
        onOffToggle.animator().state = ledController.power == .off ? .off : .on
        blinkToggle.animator().state = ledController.isBlinking ? .on : .off

        colorDot.layer?.backgroundColor = ledColorToSystemColor(ledController.color)

        redToggle.animator().state = ledController.color.contains(.red) ? .on : .off
        greenToggle.animator().state = ledController.color.contains(.green) ? .on : .off
        amberToggle.animator().state = ledController.color.contains(.amber) ? .on : .off

        if SerialController.shared.deviceConnected {
            // device is connected
            disconnectedLabel.isHidden = true
           enableUI()
        } else {
            // device is not connected
            disconnectedLabel.isHidden = false
            disableUI()
        }
    }

    func enableUI() {
        allToggles.forEach({ $0.isEnabled = true })

        allButtons.forEach({ button in
            button.isEnabled = true
            button.showsBorderOnlyWhileMouseInside = true
            button.bezelColor = .systemBlue
        })

        colorDot.layer?.borderColor = .clear
        colorDot.layer?.borderWidth = 0.0

        (self.view as! NSViewInteractive).isUserInteractionEnabled = true

    }

    func disableUI() {
        allToggles.forEach({ $0.isEnabled = false })

        allButtons.forEach({ button in
            button.isEnabled = false
            button.showsBorderOnlyWhileMouseInside = false
            button.bezelColor = nil
        })

        colorDot.layer?.borderColor = .black
        colorDot.layer?.borderWidth = 0.6
        colorDot.layer?.backgroundColor = .clear

        (self.view as! NSViewInteractive).isUserInteractionEnabled = false
    }

    // MARK: - Utilities
    func ledColorToSystemColor(_ ledColor: [LEDColor]) -> CGColor {
        switch ledColor {
            case [.red]:   return NSColor.systemRed.cgColor
            case [.amber]: return NSColor.systemOrange.cgColor
            case [.green]: return NSColor.systemGreen.cgColor

            case [.red, .amber]:   return colorBlend(.systemRed,   .systemOrange).cgColor
            case [.red, .green]:   return colorBlend(.systemGreen, .systemYellow, weightA: 0.4).cgColor
            case [.amber, .green]: return colorBlend(.systemGreen, .systemOrange, weightA: 0.6).cgColor

            case [.red, .amber, .green]: return NSColor.systemYellow.cgColor

            default: return NSColor.black.cgColor
        }
    }

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

// MARK: - SerialControllerDelegate
extension PopoverViewController: SerialControllerDelegate {
    func serialControllerDelegate(statusDidChange state: LEDPower, ledColor: [LEDColor]) {
        update()
    }
}

class NSViewInteractive: NSView {
    var isUserInteractionEnabled: Bool = true

    override func hitTest(_ point: NSPoint) -> NSView? {
        return isUserInteractionEnabled ? super.hitTest(point) : nil
    }
}

// MARK: - Storyboard
extension PopoverViewController {
    static func newInstance() -> PopoverViewController {
        let storyboard = NSStoryboard(name: NSStoryboard.Name("ButtonPopover"), bundle: nil)
        let identifier = NSStoryboard.SceneIdentifier("PopoverViewController")

        guard let viewcontroller = storyboard.instantiateController(withIdentifier: identifier) as? PopoverViewController else {
            fatalError("Unable to instantiate ViewController in ButtonPopover.storyboard")
        }
        return viewcontroller
    }
}
