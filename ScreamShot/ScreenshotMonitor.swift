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

import Foundation
import Cocoa

class ScreenshotMonitor {
    var query: NSMetadataQuery!;
    var blacklist: [String];
    var appDelegate: AppDelegate;
    var screenshotLocationPath: String = "";
    
    init() {
        self.blacklist = [];
        appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
        
        query = NSMetadataQuery();
        
        // Only accept screenshots
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture = 1");
        query.searchScopes = [NSMetadataQueryLocalComputerScope];
        
        if let customLocation = NSUserDefaults.standardUserDefaults().persistentDomainForName("com.apple.screencapture")?["location"] as? String {
            // Check that the chosen directory exists, otherwise screencapture will not use it
            var isDir = ObjCBool(false);
            if NSFileManager.defaultManager().fileExistsAtPath(customLocation, isDirectory: &isDir) && isDir {
                self.screenshotLocationPath =  NSURL(fileURLWithPath: customLocation).path!
            }
        }
        if(self.screenshotLocationPath == ""){
            // If a custom location is not defined (or invalid) return the default screenshot location (~/Desktop)
            self.screenshotLocationPath =  NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0]).path!
        }
        print("Path: " + self.screenshotLocationPath, terminator: "");
    }
    
    func startMonitoring() {
        print("Monitoring: starting", terminator: "");
        // Add observer
        NSNotificationCenter.defaultCenter().addObserverForName(NSMetadataQueryDidUpdateNotification, object: query, queue: NSOperationQueue.mainQueue()) { notification in
            if let itemsAdded = notification.userInfo?["kMDQueryUpdateAddedItems"] as? [NSMetadataItem] {
                for item in itemsAdded {
                    // Get the path to the screenshot
                    let screenshotPath = NSURL(fileURLWithPath: (item.valueForAttribute(NSMetadataItemPathKey) as? String)!)
                    let screenshotName = screenshotPath.URLByDeletingPathExtension?.lastPathComponent
                    let screenshotDirectory = screenshotPath.URLByDeletingLastPathComponent!.path
                    // Ensure that the screenshot detected is from the right folder and isn't blacklisted
                    if screenshotDirectory == self.screenshotLocationPath && !self.blacklist.contains(screenshotName!) {
                        print("Screenshot file event detected @ \(screenshotPath)");
                        self.appDelegate.sendScreenshot(screenshotPath);
                        self.blacklist.append(screenshotName!);
                    }
                }
            }
        }
        // Start query
        query.startQuery();
    }
    
    func stopMonitoring(){
        print("Monitoring: stopped", terminator: "");
        query.stopQuery();
    }
    
    var _screenshotLocationPath: NSURL {
        // Check for custom screenshot location chosen by user
        if let customLocation = NSUserDefaults.standardUserDefaults().persistentDomainForName("com.apple.screencapture")?["location"] as? String {
            // Check that the chosen directory exists, otherwise screencapture will not use it
            var isDir = ObjCBool(false);
            if NSFileManager.defaultManager().fileExistsAtPath(customLocation, isDirectory: &isDir) && isDir {
                return NSURL(fileURLWithPath: customLocation)
            }
        }
        // If a custom location is not defined (or invalid) return the default screenshot location (~/Desktop)
        return NSURL(fileURLWithPath: NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0])
    }
}