//
//  PopoverViewController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI

class PopoverViewController: NSViewController {
    
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
