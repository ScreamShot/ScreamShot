/* This file is part of mac2imgur.
*
* mac2imgur is free software: you can redistribute it and/or modify
* it under the terms of the GNU General Public License as published by
* the Free Software Foundation, either version 3 of the License, or
* (at your option) any later version.

* mac2imgur is distributed in the hope that it will be useful,
* but WITHOUT ANY WARRANTY; without even the implied warranty of
* MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
* GNU General Public License for more details.

* You should have received a copy of the GNU General Public License
* along with mac2imgur.  If not, see <http://www.gnu.org/licenses/>.
*/

import Cocoa
import Foundation

extension NSMenuItem {
    var data: AnyObject { return self }
}

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate, ScreenshotMonitorDelegate, UploadControllerDelegate {
    
    @IBOutlet weak var menu: NSMenu!
    @IBOutlet weak var deleteAfterUploadOption: NSMenuItem!
    @IBOutlet weak var launchAtStartup: NSMenuItem!
    @IBOutlet weak var disableDetectionOption: NSMenuItem!
    @IBOutlet weak var lastItems: NSMenuItem!
    @IBOutlet weak var copyLastLink: NSMenuItem!
    
    let menuView = MenuView()
    var prefs: PreferencesManager!
    var monitor: ScreenshotMonitor!
    var uploadController: UploadController!
    var authController: ConfigurationWindowController!
    
    
    // Delegate methods
    
    func applicationDidFinishLaunching(aNotification: NSNotification) {
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        prefs = PreferencesManager()
        uploadController = UploadController(pref: prefs)
        menuView.setupMenu(menu)
        
        // Add menu to status bar
        updateStatusIcon(false)
        
        deleteAfterUploadOption.state = prefs.shouldDeleteAfterUpload() ? NSOnState : NSOffState
        disableDetectionOption.state = prefs.isDetectionDisabled() ? NSOnState : NSOffState
        launchAtStartup.state = (LaunchServicesHelper.applicationIsInStartUpItems) ? NSOnState : NSOffState
        
        // Start monitoring for screenshots
        monitor = ScreenshotMonitor(delegate: self)
        monitor.startMonitoring()
    }
    
    func applicationWillTerminate(aNotification: NSNotification) {
        NSStatusBar.systemStatusBar().removeStatusItem(menuView.statusItem)
        println("Monitor stop")
        monitor.query.stopQuery()
    }
    
    func screenshotDetected(imagePath: String) {
        if !prefs.isDetectionDisabled() {
            menuView.setUploading(true)
            let upload = Upload(app: self, imagePath: imagePath, isScreenshot: true, delegate: self)
            uploadController.addToQueue(upload)
        }
        
    }
    
    func getMimetype(filePath: NSURL) -> String{
        var UTI = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, filePath.pathExtension as NSString?, nil);
        var str = UTTypeCopyPreferredTagWithClass(UTI.takeUnretainedValue(), kUTTagClassMIMEType);
        if (str == nil) {
            return "application/octet-stream";
        } else {
            return str.takeUnretainedValue() as String
        }
    }
    
    func uploadAttemptCompleted(successful: Bool, isScreenshot: Bool, link: String, imagePath: String) {
        var type = isScreenshot ? "Screenshot" : "Image"
        var url = NSURL(fileURLWithPath: imagePath)!
        let mimeType = getMimetype(url)
        let fileName = url.path?.lastPathComponent
        var nsm = NSMenuItem(title: fileName!, action:"copyLink:", keyEquivalent:"")
        if mimeType.rangeOfString("image/") != nil {
            println("IMAGE")
            nsm.image = NSImage(data: resizeImageForMenu(NSImage(contentsOfFile: imagePath)!)!)
        }else{
            println("NOT IMAGE :(")
        }
        nsm.enabled = true
        nsm.target = self
        nsm.representedObject = link
        let items = lastItems!.submenu!.itemArray
        lastItems!.submenu!.addItem(nsm)
        if items.count > 5{
            for index in 0...(items.count-5) {
                let itemMenu = items[index] as! NSMenuItem
                println("Remove lastItem \(itemMenu.title)")
                lastItems!.submenu!.removeItem(itemMenu)
            }
        }
        if successful {
            copyToClipboard(link)
            copyLastLink.representedObject = link
            displayNotification("\(type) uploaded successfully!", informativeText: link)
            
            let deleteAfterUpload = prefs.shouldDeleteAfterUpload()
            if isScreenshot && deleteAfterUpload {
                println("Deleting screenshot @ \(imagePath)")
                deleteFile(imagePath)
            }
        } else {
            displayNotification("\(type) upload failed...", informativeText: "")
        }
    
    }
    
    @objc @IBAction func copyLink(item: NSMenuItem){
        copyToClipboard(item.representedObject as! String!)
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification) {
        if notification.informativeText != "" {
            openURL(notification.informativeText!)
        }
    }
   
    
    @IBAction func accountAction(sender: NSMenuItem) {
        authController = ConfigurationWindowController(windowNibName: "ConfigurationWindow")
        authController.callback = {
            self.displayNotification("Configuration updated!", informativeText: "")
        }
        authController.prefs = prefs
        NSApplication.sharedApplication().activateIgnoringOtherApps(true)
        authController.showWindow(self)
    }
    
    // Selector methods
    
    @IBAction func selectImages(sender: NSMenuItem) {
        var panel = NSOpenPanel()
        panel.title = "Select Images"
        panel.prompt = "Upload"
        panel.canChooseDirectories = false
        panel.allowsMultipleSelection = true
        if panel.runModal() == NSModalResponseOK {
            for imageURL in panel.URLs {
                if let path = (imageURL as! NSURL).path{
                    let upload = Upload(app: self, imagePath: path, isScreenshot: false, delegate: self)
                    uploadController.addToQueue(upload)
                }
            }
        }
    }
    
    @IBAction func toggleStartup(sender: NSMenuItem) {
        LaunchServicesHelper.toggleLaunchAtStartup()
        launchAtStartup.state = (LaunchServicesHelper.applicationIsInStartUpItems) ? NSOnState : NSOffState
    }
    
    @IBAction func deleteAfterUploadOption(sender: NSMenuItem) {
        let delete = (sender.state != NSOnState)
        prefs.setDeleteAfterUpload(delete)
        if !delete {
            sender.state = NSOffState
        } else {
            sender.state = NSOnState
        }
    }
    
    @IBAction func disableDetectionOption(sender: NSMenuItem) {
        let disabled = (sender.state != NSOnState)
        prefs.setDetectionDisabled(disabled)
        if !disabled {
            sender.state = NSOffState
            monitor.startMonitoring()
        } else {
            sender.state = NSOnState
        }
    }
    
    // Utility methods
    
    func copyToClipboard(string: String) {
        let pasteBoard = NSPasteboard.generalPasteboard()
        pasteBoard.clearContents()
        pasteBoard.setString(string, forType: NSStringPboardType)
    }
    
    func deleteFile(filePath: String) {
        var error: NSError?
        NSFileManager.defaultManager().removeItemAtPath(filePath, error: &error)
        if error != nil {
            NSLog(error!.localizedDescription)
        }
    }
    
    func openURL(url: String) {
        NSWorkspace.sharedWorkspace().openURL(NSURL(string: url)!)
    }
    
    func displayNotification(title: String, informativeText: String) {
        let notification = NSUserNotification()
        notification.title = title
        notification.informativeText = informativeText
        notification.soundName = NSUserNotificationDefaultSoundName
        NSUserNotificationCenter.defaultUserNotificationCenter().scheduleNotification(notification)
    }
    
    func updateStatusIcon(isActive: Bool) {
        menuView.setUploading(isActive)
    }
    
    func resizeImageForMenu(image: NSImage) -> NSData? {
        let scaleFactor = CGFloat(22/max(image.size.width, image.size.height))
        let resizedBounds = NSRect(x: 0, y: 0, width: round(image.size.width * scaleFactor), height: round(image.size.height * scaleFactor))
            
        // Only resize the image if a change in size will occur
        if !NSEqualSizes(resizedBounds.size, image.size) {
            let resizedImage = NSImage(size: resizedBounds.size)
            let imageRep = image.bestRepresentationForRect(resizedBounds, context: nil, hints: nil)!
                
            resizedImage.lockFocus()
            imageRep.drawInRect(resizedBounds)
            resizedImage.unlockFocus()
                
            // Use a PNG representation of the resized image
            return NSBitmapImageRep(data: resizedImage.TIFFRepresentation!)!.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:])!
        }
        return nil;
    }
}