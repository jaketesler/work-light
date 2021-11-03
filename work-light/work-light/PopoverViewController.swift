//
//  PopoverViewController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI

class PopoverViewController: NSViewController {

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

    var ledController = SerialController.shared

    @IBAction func greenButtonPushed(_ sender: Any) { ledController.changeColorTo(.green) }
    @IBAction func amberButtonPushed(_ sender: Any) { ledController.changeColorTo(.amber) }
    @IBAction func redButtonPushed(_ sender: Any)   { ledController.changeColorTo(.red) }

    @IBAction func greenSwitchToggled(_ sender: NSSwitch) { ledController.setColor(.green, state: sender.state == .on) }
    @IBAction func amberSwitchToggled(_ sender: NSSwitch) { ledController.setColor(.amber, state: sender.state == .on) }
    @IBAction func redSwitchToggled(_ sender: NSSwitch)   { ledController.setColor(.red,   state: sender.state == .on) }

    @IBAction func switchOnOffToggled(_ sender: NSSwitch) { ledController.setOnOffState(sender.state == .off ? .off : .on) }
    @IBAction func switchBlinkToggled(_ sender: NSSwitch) { ledController.setBlink(sender.state == .on) }

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

    func setupView() {
        changeToGreen.showsBorderOnlyWhileMouseInside = true
        changeToAmber.showsBorderOnlyWhileMouseInside = true
        changeToRed.showsBorderOnlyWhileMouseInside = true

        colorDot.wantsLayer = true
        colorDot.layer?.masksToBounds = true
        colorDot.layer?.cornerRadius = 12.0;
        colorDot.layer?.backgroundColor = .init(red: 0, green: 0, blue: 0, alpha: 0)
    }

    func update() {
        print("Updating")
        switchOnOff.animator().state = ledController.power == .off ? .off : .on
        switchBlink.animator().state = ledController.isBlinking ? .on : .off
        colorDot.layer?.backgroundColor = ledColorToSystemColor(ledController.color)

        redToggle.animator().state = ledController.color.contains(.red) ? .on : .off
        greenToggle.animator().state = ledController.color.contains(.green) ? .on : .off
        amberToggle.animator().state = ledController.color.contains(.amber) ? .on : .off
    }

    func ledColorToSystemColor(_ ledColor: [LEDColor]) -> CGColor {
        print(ledColor)
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

        let cAr = colA.redComponent
        let cAg = colA.greenComponent
        let cAb = colA.blueComponent

        let cBr = colB.redComponent
        let cBg = colB.greenComponent
        let cBb = colB.blueComponent

        let cOr = weightA * cAr + (1.0 - weightA) * cBr
        let cOg = weightA * cAg + (1.0 - weightA) * cBg
        let cOb = weightA * cAb + (1.0 - weightA) * cBb

        return NSColor(red: cOr, green: cOg, blue: cOb, alpha: 1.0)
    }
}

extension PopoverViewController: SerialControllerDelegate {
    func serialControllerDelegate(statusDidChange state: LEDPower, ledColor: [LEDColor]) {
        update()
    }
}

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
