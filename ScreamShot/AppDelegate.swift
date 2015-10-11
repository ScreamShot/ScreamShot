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
import ScreamUtils

@NSApplicationMain
class AppDelegate: NSObject, NSApplicationDelegate, NSUserNotificationCenterDelegate {
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
        uploadController = UploadController(uploadUrl: prefs.getUploadUrl())
        
        menuView.setupMenu(menu)
        deleteAfterUploadOption.state = prefs.shouldDeleteAfterUpload() ? NSOnState : NSOffState;
        disableDetectionOption.state = prefs.isDetectionDisabled() ? NSOnState : NSOffState;
        launchAtStartup.state = (LaunchServicesHelper.applicationIsInStartUpItems) ? NSOnState : NSOffState;
        
        // Start monitoring for screenshots
        monitor = ScreenshotMonitor()
        monitor.startMonitoring()
    }
    
    
    func applicationWillTerminate(aNotification: NSNotification) {
        NSStatusBar.systemStatusBar().removeStatusItem(menuView.statusItem)
        monitor.stopMonitoring()
    }
    
    @objc @IBAction func copyLink(item: NSMenuItem){
        if item.representedObject == nil {
            return;
        }
        copyToClipboard(item.representedObject as! String!);
    }
    
    @IBAction func accountAction(sender: NSMenuItem) {
        authController = ConfigurationWindowController(windowNibName: "ConfigurationWindow");
        authController.callback = {
            self.uploadController.setUploadUrl(self.prefs.getUploadUrl())
            ScreamUtils.displayNotification("Configuration updated!", informativeText: "");
        }
        authController.prefs = prefs;
        NSApplication.sharedApplication().activateIgnoringOtherApps(true);
        authController.showWindow(self);
    }
    
    // Selector methods
    
    @IBAction func selectImages(sender: NSMenuItem) {
        let panel = NSOpenPanel();
        panel.title = "Select files";
        panel.prompt = "Upload";
        panel.canChooseDirectories = false;
        panel.allowsMultipleSelection = true;
        if panel.runModal() == NSModalResponseOK {
            for imageURL in panel.URLs {
                sendFile(imageURL, isScreenshot: false);
                
            }
        }
    }
    
    @IBAction func toggleStartup(sender: NSMenuItem) {
        LaunchServicesHelper.toggleLaunchAtStartup();
        launchAtStartup.state = (LaunchServicesHelper.applicationIsInStartUpItems) ? NSOnState : NSOffState;
    }
    
    @IBAction func deleteAfterUploadOption(sender: NSMenuItem) {
        let delete = (sender.state != NSOnState);
        prefs.setDeleteAfterUpload(delete);
        if !delete {
            sender.state = NSOffState;
        } else {
            sender.state = NSOnState;
        }
    }
    
    @IBAction func disableDetectionOption(sender: NSMenuItem) {
        let disabled = (sender.state != NSOnState);
        prefs.setDetectionDisabled(disabled);
        if !disabled {
            sender.state = NSOffState;
            monitor.startMonitoring();
        } else {
            sender.state = NSOnState;
            monitor.stopMonitoring();
        }
    }
    
    
    func sendFile(filePath: NSURL, isScreenshot: Bool){
        if isScreenshot && prefs.isDetectionDisabled() {
            return;
        }
        
        let type = isScreenshot ? "Screenshot" : "Image";
        
        menuView.setUploading(true);
        let upload = Upload(filePath: filePath);
        
        upload.addProgressCallback(menuView.setProgress);
        
        upload.addSuccessCallback({(link: String) -> () in
            // Tell the user
            ScreamUtils.copyToClipboard(link);
            ScreamUtils.displayNotification("\(type) uploaded successfully!", informativeText: link);
            
            // Remove the file
            self.menuView.setLastItem(filePath.lastPathComponent!, link: link)
            if isScreenshot && self.prefs.shouldDeleteAfterUpload() {
                print("Deleting screenshot @ \(filePath)", terminator: "");
                deleteFile(filePath.path!);
            }
            
            // Reset the menu icon
            self.uploadController.next();
            self.menuView.setUploading(false);
            self.menuView.setProgress(0);
        });
        
        upload.addErrorCallback({(error: String) -> () in
            NSLog(error);
            ScreamUtils.displayNotification("\(type) upload failed...", informativeText: "");
        });
        
        upload.addStartingCallback({() -> () in
            self.menuView.setUploading(true)
        });
        
        uploadController.addToQueue(upload);
    }
}