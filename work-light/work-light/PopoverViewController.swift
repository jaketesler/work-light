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
    @IBOutlet weak var changeToGreen: NSButton!
    @IBOutlet weak var changeToAmber: NSButton!
    @IBOutlet weak var changeToRed: NSButton!

    @IBOutlet weak var greenToggle: NSSwitch!
    @IBOutlet weak var amberToggle: NSSwitch!
    @IBOutlet weak var redToggle: NSSwitch!

    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var switchOnOff: NSSwitch!
    @IBOutlet weak var colorDot: NSView!

    @IBOutlet weak var switchBlink: NSSwitch!

    @IBAction func greenButtonPushed(_ sender: Any) { ledController.changeColor(to: .green) }
    @IBAction func amberButtonPushed(_ sender: Any) { ledController.changeColor(to: .amber) }
    @IBAction func redButtonPushed(_ sender: Any)   { ledController.changeColor(to: .red) }

    @IBAction func greenSwitchToggled(_ sender: NSSwitch) { ledController.set(color: .green, to: sender.state == .on) }
    @IBAction func amberSwitchToggled(_ sender: NSSwitch) { ledController.set(color: .amber, to: sender.state == .on) }
    @IBAction func redSwitchToggled(_ sender: NSSwitch)   { ledController.set(color: .red,   to: sender.state == .on) }

    @IBAction func switchOnOffToggled(_ sender: NSSwitch) { ledController.set(power: sender.state == .off ? .off : .on) }
    @IBAction func switchBlinkToggled(_ sender: NSSwitch) { ledController.set(blink: sender.state == .on) }

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
        changeToGreen.showsBorderOnlyWhileMouseInside = true
        changeToAmber.showsBorderOnlyWhileMouseInside = true
        changeToRed.showsBorderOnlyWhileMouseInside = true

        colorDot.wantsLayer = true
        colorDot.layer?.masksToBounds = true
        colorDot.layer?.cornerRadius = 12.0;
        colorDot.layer?.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
    }

    func update() {
        switchOnOff.animator().state = ledController.power == .off ? .off : .on
        switchBlink.animator().state = ledController.isBlinking ? .on : .off

        colorDot.layer?.backgroundColor = ledColorToSystemColor(ledController.color)

        redToggle.animator().state = ledController.color.contains(.red) ? .on : .off
        greenToggle.animator().state = ledController.color.contains(.green) ? .on : .off
        amberToggle.animator().state = ledController.color.contains(.amber) ? .on : .off
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
