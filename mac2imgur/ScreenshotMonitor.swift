import Foundation

class ScreenshotMonitor {
    
    var query: NSMetadataQuery
    var delegate: ScreenshotMonitorDelegate
    var blacklist: [String]
    
    init(delegate: ScreenshotMonitorDelegate) {
        self.delegate = delegate
        self.blacklist = []
        
        query = NSMetadataQuery()
        
        // Only accept screenshots
        query.predicate = NSPredicate(format: "kMDItemIsScreenCapture = 1", argumentArray: nil)
        
        // Add observers
        NSNotificationCenter.defaultCenter().addObserver(self, selector: NSSelectorFromString("initialPhaseComplete"), name: NSMetadataQueryDidFinishGatheringNotification, object: query)
        NSNotificationCenter.defaultCenter().addObserver(self, selector: NSSelectorFromString("liveUpdatePhaseEvent:"), name: NSMetadataQueryDidUpdateNotification, object: query)
        
        // Start query
        query.startQuery()
    }
    
    @objc func initialPhaseComplete() {
        if let itemsAdded = query.results as? [NSMetadataItem] {
            for item in itemsAdded {
                // Get the path to the screenshot
                if let screenshotPath = item.valueForAttribute(NSMetadataItemPathKey) as? String {
                    let screenshotName = screenshotPath.lastPathComponent.stringByDeletingPathExtension
                    
                    // Blacklist the screenshot if it hasn't already been blacklisted
                    if !contains(blacklist, screenshotName) {
                        blacklist.append(screenshotName)
                    }
                }
            }
        }
    }
    
    @objc func liveUpdatePhaseEvent(notification: NSNotification) {
        println("Event 3");
        if let itemsAdded = notification.userInfo?["kMDQueryUpdateAddedItems"] as? [NSMetadataItem] {
            for item in itemsAdded {
                // Get the path to the screenshot
                if let screenshotPath = item.valueForAttribute(NSMetadataItemPathKey) as? String {
                    let screenshotName = screenshotPath.lastPathComponent.stringByDeletingPathExtension
                    
                    // Ensure that the screenshot detected is from the right folder and isn't blacklisted
                    if screenshotPath.stringByDeletingLastPathComponent.stringByStandardizingPath == getScreenshotDirectory().stringByStandardizingPath && !contains(blacklist, screenshotName) {
                        println("Screenshot file event detected @ \(screenshotPath)")
                        delegate.screenshotDetected(screenshotPath)
                        blacklist.append(screenshotName)
                    }
                }
            }
        }
    }
    
    func getScreenshotDirectory() -> String {
        if let dir = NSUserDefaults.standardUserDefaults().persistentDomainForName("com.apple.screencapture")?["location"] as? String {
            var isDir: ObjCBool = false
            if NSFileManager.defaultManager().fileExistsAtPath(dir, isDirectory: &isDir) {
                return dir
            }
        }
        return NSSearchPathForDirectoriesInDomains(.DesktopDirectory, .UserDomainMask, true)[0] as String
    }
}

protocol ScreenshotMonitorDelegate {
    func screenshotDetected(pathToImage: String)
}