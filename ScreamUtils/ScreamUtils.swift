//
//  ScreamUtils.swift
//  ScreamShot
//
//  Created by Maxime GUERREIRO on 12/05/15.
//
//

import Foundation
import Cocoa


public func displayNotification(title: String, informativeText: String) {
    let notification = NSUserNotification();
    notification.title = title;
    notification.informativeText = informativeText;
    notification.soundName = NSUserNotificationDefaultSoundName;
    NSUserNotificationCenter.defaultUserNotificationCenter().scheduleNotification(notification);
}


public func copyToClipboard(string: String) {
    let pasteBoard = NSPasteboard.generalPasteboard();
    pasteBoard.clearContents();
    pasteBoard.setString(string, forType: NSStringPboardType);
}


public func deleteFile(filePath: String) {
    var error: NSError?;
    do {
        try NSFileManager.defaultManager().removeItemAtPath(filePath)
    } catch let error1 as NSError {
        error = error1
    };
    if error != nil {
        NSLog(error!.localizedDescription);
    }
}


public func openURL(url: String) {
    NSWorkspace.sharedWorkspace().openURL(NSURL(string: url)!);
}


public func getMimetype(filePath: NSURL) -> String{
    let UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, (filePath.pathExtension as NSString?)!, nil)!.takeUnretainedValue();
    let str = UTTypeCopyPreferredTagWithClass(UTI, kUTTagClassMIMEType);
    if (str == nil) {
        return "application/octet-stream";
    } else {
        return str!.takeUnretainedValue() as String;
    }
}


public func getDisplayID(screen: NSScreen) -> UInt32 {
    let screenDetails: NSDictionary = screen.deviceDescription
    let screenID: AnyObject? = screenDetails.objectForKey("NSScreenNumber")
    let screenIDInt: Int = screenID as! Int
    return UInt32(screenIDInt)
}