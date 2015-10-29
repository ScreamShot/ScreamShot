//
//  OverlayWindow.swift
//  Screen Recording Demo
//
//  Created by Miles Dunne on 28/10/2015.
//
//

import Cocoa

class OverlayWindow: NSWindow {
    
    override func awakeFromNib() {
        // We want the window to be transparent
        backgroundColor = NSColor.clearColor()
        opaque = false
        
        // The window should be above all others
        level = Int(CGWindowLevelForKey(CGWindowLevelKey.OverlayWindowLevelKey))
    }
    
    override var canBecomeKeyWindow: Bool {
        return true
    }
    
}