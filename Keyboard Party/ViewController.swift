//
//  ViewController.swift
//  Keyboard Party
//
//  Created by Sidney San Martín on 12/27/14.
//  Copyright (c) 2014 Coordinated Hackers. All rights reserved.
//

import Cocoa

protocol SettingsWindowDelegate {
    func settingsWindowWillClose(sender: SettingsWindowController)
}

class SettingsWindowController: NSWindowController, NSWindowDelegate {
    
    var delegate: SettingsWindowDelegate?
    
    func windowWillClose(notification: NSNotification) {
        delegate?.settingsWindowWillClose(self)
    }
}

class ViewController: NSViewController {

    override func viewDidLoad() {
        super.viewDidLoad()

        // Do any additional setup after loading the view.
    }

    override var representedObject: AnyObject? {
        didSet {
        // Update the view, if already loaded.
        }
    }
    
    @IBAction func terminate(sender: AnyObject) {
        NSApplication.sharedApplication().terminate(sender)
    }


}

