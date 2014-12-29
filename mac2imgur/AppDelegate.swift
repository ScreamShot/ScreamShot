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

class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate, ScreenshotMonitorDelegate, UploadControllerDelegate {
    
    @IBOutlet weak var menu: NSMenu!
    let menuView = MenuView()
    @IBOutlet weak var deleteAfterUploadOption: NSMenuItem!
    @IBOutlet weak var launchAtStartup: NSMenuItem!
    @IBOutlet weak var disableDetectionOption: NSMenuItem!
    
    var prefs: PreferencesManager!
    var monitor: ScreenshotMonitor!
    var uploadController: ImgurUploadController!
    var authController: ConfigurationWindowController!
    var lastLink: String = ""

    
    // Delegate methods
    
    func applicationDidFinishLaunching(aNotification: NSNotification?) {
        NSUserNotificationCenter.defaultUserNotificationCenter().delegate = self
        prefs = PreferencesManager()
        uploadController = ImgurUploadController(pref: prefs)
        menuView.setupMenu(menu)
        
        // Add menu to status bar
        updateStatusIcon(false)
        
        deleteAfterUploadOption.state = prefs.shouldDeleteAfterUpload() ? NSOnState : NSOffState
        disableDetectionOption.state = prefs.isDetectionDisabled() ? NSOnState : NSOffState
        launchAtStartup.state = (applicationIsInStartUpItems()) ? NSOnState : NSOffState
        
        // Start monitoring for screenshots
        monitor = ScreenshotMonitor(delegate: self)
    }
    
    func applicationWillTerminate(aNotification: NSNotification?) {
        NSStatusBar.systemStatusBar().removeStatusItem(menuView.statusItem)
        monitor.query.stopQuery()
    }
    
    func screenshotDetected(pathToImage: String) {
        if !prefs.isDetectionDisabled() {
            menuView.setUploading(true)
            let upload = ImgurUpload(app: self, pathToImage: pathToImage, isScreenshot: true, delegate: self)
            uploadController.addToQueue(upload)
            uploadController.processQueue()
        }
    }
    
    func uploadAttemptCompleted(successful: Bool, isScreenshot: Bool, link: String, pathToImage: String) {
        let type = isScreenshot ? "Screenshot" : "Image"
        if successful {
            lastLink = link
            copyToClipboard(link)
            displayNotification("\(type) uploaded successfully!", informativeText: link)
            
            let deleteAfterUpload = prefs.shouldDeleteAfterUpload()
            if isScreenshot && deleteAfterUpload {
                println("Deleting screenshot @ \(pathToImage)")
                deleteFile(pathToImage)
            }
        } else {
            displayNotification("\(type) upload failed...", informativeText: "")
        }
    }
    
    func userNotificationCenter(center: NSUserNotificationCenter, didActivateNotification notification: NSUserNotification!) {
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
        if panel.runModal() == NSOKButton {
            for imageURL in panel.URLs {
                if let path = (imageURL as NSURL).path? {
                    let upload = ImgurUpload(app: self, pathToImage: path, isScreenshot: false, delegate: self)
                    uploadController.addToQueue(upload)
                }
                uploadController.processQueue()
            }
        }
    }
    
    @IBAction func copyLastLink(sender: NSMenuItem) {
        copyToClipboard(lastLink)
    }
    
    @IBAction func toggleStartup(sender: NSMenuItem) {
        toggleLaunchAtStartup()
        launchAtStartup.state = (applicationIsInStartUpItems()) ? NSOnState : NSOffState
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
        } else {
            sender.state = NSOnState
        }
    }
    
    @IBAction func quit(sender: NSMenuItem) {
        NSApplication.sharedApplication().terminate(sender)
    }
    
    // Utility methods
    
    func copyToClipboard(string: String) {
        let pasteBoard = NSPasteboard.generalPasteboard()
        pasteBoard.clearContents()
        pasteBoard.setString(string, forType: NSStringPboardType)
    }
    
    func deleteFile(pathToFile: String) {
        var error: NSError?
        NSFileManager.defaultManager().removeItemAtPath(pathToFile, error: &error)
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

    func applicationIsInStartUpItems() -> Bool {
        return (itemReferencesInLoginItems().existingReference != nil)
    }
    
    func itemReferencesInLoginItems() -> (existingReference: LSSharedFileListItemRef?, lastReference: LSSharedFileListItemRef?) {
        var itemUrl : UnsafeMutablePointer<Unmanaged<CFURL>?> = UnsafeMutablePointer<Unmanaged<CFURL>?>.alloc(1)
        if let appUrl : NSURL = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
            let loginItemsRef = LSSharedFileListCreate(
                nil,
                kLSSharedFileListSessionLoginItems.takeRetainedValue(),
                nil
                ).takeRetainedValue() as LSSharedFileListRef?
            if loginItemsRef != nil {
                let loginItems: NSArray = LSSharedFileListCopySnapshot(loginItemsRef, nil).takeRetainedValue() as NSArray
                let lastItemRef: LSSharedFileListItemRef = loginItems.lastObject as LSSharedFileListItemRef
                for var i = 0; i < loginItems.count; ++i {
                    let currentItemRef: LSSharedFileListItemRef = loginItems.objectAtIndex(i) as LSSharedFileListItemRef
                    if LSSharedFileListItemResolve(currentItemRef, 0, itemUrl, nil) == noErr {
                        if let urlRef: NSURL =  itemUrl.memory?.takeRetainedValue() {
                            if urlRef.isEqual(appUrl) {
                                return (currentItemRef, lastItemRef)
                            }
                        }
                    }
                }
                //The application was not found in the startup list
                return (nil, lastItemRef)
            }
        }
        return (nil, nil)
    }
    
    func toggleLaunchAtStartup() {
        let itemReferences = itemReferencesInLoginItems()
        let shouldBeToggled = (itemReferences.existingReference == nil)
        let loginItemsRef = LSSharedFileListCreate(
            nil,
            kLSSharedFileListSessionLoginItems.takeRetainedValue(),
            nil
            ).takeRetainedValue() as LSSharedFileListRef?
        if loginItemsRef != nil {
            if shouldBeToggled {
                if let appUrl : CFURLRef = NSURL.fileURLWithPath(NSBundle.mainBundle().bundlePath) {
                    LSSharedFileListInsertItemURL(
                        loginItemsRef,
                        itemReferences.lastReference,
                        nil,
                        nil,
                        appUrl,
                        nil,
                        nil
                    )
                    println("Application was added to login items")
                }
            } else {
                if let itemRef = itemReferences.existingReference {
                    LSSharedFileListItemRemove(loginItemsRef,itemRef);
                    println("Application was removed from login items")
                }
            }
        }
    }
}