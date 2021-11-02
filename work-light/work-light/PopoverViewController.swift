//
//  PopoverViewController.swift
//  work-light
//
//  Created by Jake Tesler on 11/2/21.
//

import Foundation
import SwiftUI

class PopoverViewController: NSViewController {
    
    @IBOutlet weak var pushButton: NSButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        pushButton.showsBorderOnlyWhileMouseInside = true
    }
    
    
    @IBAction func pushButtonPushed(_ sender: Any) {
        
    }
}



//extension PopoverViewController {
//    func setupMenu() -> NSMenu {
//        let menu = NSMenu()
//
//        menu.addItem(withTitle: "HIE", action: #selector(moo(sender:)), keyEquivalent: "")
//
//        return menu
//    }
//
//    @objc func moo(sender: AnyObject?) {
//
//    }
//}


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
