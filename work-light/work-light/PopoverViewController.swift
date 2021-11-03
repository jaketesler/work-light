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
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        changeToGreen.showsBorderOnlyWhileMouseInside = true
        changeToAmber.showsBorderOnlyWhileMouseInside = true
        changeToRed.showsBorderOnlyWhileMouseInside = true
    }
    
    
    @IBAction func greenButtonPushed(_ sender: Any) { SerialController.controller.changeColor(.green) }
    @IBAction func amberButtonPushed(_ sender: Any) { SerialController.controller.changeColor(.amber) }
    @IBAction func redButtonPushed(_ sender: Any) { SerialController.controller.changeColor(.red) }
    
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
