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

class ScreenshotMonitor {
    
    var query: NSMetadataQuery!
    var delegate: ScreenshotMonitorDelegate
    var blacklist: [String]
    
    init(delegate: ScreenshotMonitorDelegate) {
        self.delegate = delegate
        self.blacklist = []
        
        query = NSMetadataQuery()
        
        // Only accept screenshots
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture = 1")
        query.searchScopes = [NSMetadataQueryLocalComputerScope]
    }
    
    func startMonitoring() {
        // Add observer
        NSNotificationCenter.defaultCenter().addObserverForName(NSMetadataQueryDidUpdateNotification, object: query, queue: NSOperationQueue.mainQueue()) { notification in
            if let itemsAdded = notification.userInfo?["kMDQueryUpdateAddedItems"] as? [NSMetadataItem] {
                for item in itemsAdded {
                    // Get the path to the screenshot
                    if let screenshotPath = item.valueForAttribute(NSMetadataItemPathKey) as? String {
                        let screenshotName = screenshotPath.lastPathComponent.stringByDeletingPathExtension
                        
                        // Ensure that the screenshot detected is from the right folder and isn't blacklisted
                        if screenshotPath.stringByDeletingLastPathComponent.stringByStandardizingPath == self.screenshotLocationPath.stringByStandardizingPath && !contains(self.blacklist, screenshotName) {
                            println("Screenshot file event detected @ \(screenshotPath)")
                            self.delegate.screenshotDetected(screenshotPath)
                            self.blacklist.append(screenshotName)
                        }
                    }
                }
            }
        }
        // Start query
        query.startQuery()
    }
    
    var screenshotLocationPath: String {
        // Check for custom screenshot location chosen by user
        if let customLocation = NSUserDefaults.standardUserDefaults().persistentDomainForName("com.apple.screencapture")?["location"] as? String {
            // Check that the chosen directory exists, otherwise screencapture will not use it
            var isDir = ObjCBool(false)
            if NSFileManager.defaultManager().fileExistsAtPath(customLocation, isDirectory: &isDir) && isDir {
                return customLocation
            }
        }
        // If a custom location is not defined (or invalid) return the default screenshot location (~/Desktop)
        return NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0] as! String
    }
}

protocol ScreenshotMonitorDelegate {
    func screenshotDetected(imagePath: String)
}