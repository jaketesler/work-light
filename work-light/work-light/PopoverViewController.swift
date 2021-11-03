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
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var switchOnOff: NSSwitch!
    @IBOutlet weak var colorDot: NSView!
    
    @IBOutlet weak var switchBlink: NSSwitch!
    
    var ledController = SerialController.controller
    
    
    @IBAction func greenButtonPushed(_ sender: Any) { ledController.changeColor(.green) }
    @IBAction func amberButtonPushed(_ sender: Any) { ledController.changeColor(.amber) }
    @IBAction func redButtonPushed(_ sender: Any) { ledController.changeColor(.red) }
    
    @IBAction func switchOnOffToggled(_ sender: NSSwitch) {
        ledController.setOnOffState(sender.state == .off ? .off : .on)
    }
    
    @IBAction func switchBlinkToggled(_ sender: NSSwitch) {
        ledController.setBlink(shouldBlink: sender.state == .on)
    }
    
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
        colorDot.layer?.backgroundColor = .init(red: 0, green: 1, blue: 0, alpha: 0)
    }
    
    func update() {
        print("Updating")
        switchOnOff.state = ledController.power == .off ? .off : .on
        switchBlink.state = ledController.isBlinking ? .on : .off
        colorDot.layer?.backgroundColor = ledColorToSystemColor(ledController.color)
    }
    
    func ledColorToSystemColor(_ ledColor: LEDColor) -> CGColor {
        switch ledColor {
        case .red:
            return NSColor.systemRed.cgColor
        case .amber:
            return NSColor.systemOrange.cgColor
        case .green:
            return NSColor.systemGreen.cgColor
        }
    }
}

extension PopoverViewController: SerialControllerDelegate {
    func serialControllerDelegate(statusDidChange state: LEDPower, ledColor: LEDColor) {
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
