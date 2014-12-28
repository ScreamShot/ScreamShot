import Cocoa

class MenuView: NSView, NSMenuDelegate {
    var highlight = false
    var isActive = false
    
    // NSVariableStatusItemLength == -1
    // Not using symbol because it doesn't link properly in Swift
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    // MARK: Initializers
    
    override init() {
        super.init(frame: NSMakeRect(0, 0, 24, 24))
        
        registerForDraggedTypes([NSFilenamesPboardType])
        statusItem.view = self
        setupMenu()
    }
    
    required convenience init(coder: NSCoder) {
        self.init()
    }
    
    // MARK: Menu
    
    func setupMenu() {
        var menu = NSMenu()
        self.menu = menu
        self.menu!.delegate = self
    }
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        frame = dirtyRect
        statusItem.drawStatusBarBackgroundInRect(dirtyRect, withHighlight: highlight)
        (isActive ? "🚀" : "📷").drawInRect(CGRectOffset(dirtyRect, 4, -1), withAttributes: [NSFontAttributeName: NSFont.menuBarFontOfSize(13)])
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        statusItem.popUpStatusItemMenu(menu!)
    }
    
    func menuWillOpen(menu: NSMenu!) {
        highlight = true
        needsDisplay = true
    }
    
    func menuDidClose(menu: NSMenu!) {
        highlight = false
        needsDisplay = true
    }
    // MARK: Dragging
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.Copy
    }
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard()
        if contains(pboard.types as [NSString], NSFilenamesPboardType) {
            let files = pboard.propertyListForType(NSFilenamesPboardType) as [String]
            let appDelegate = NSApplication.sharedApplication().delegate as AppDelegate
            for file in files{
                let upload = ImgurUpload(app: appDelegate, pathToImage: file, isScreenshot: false, delegate: appDelegate)
                appDelegate.uploadController.addToQueue(upload)
            }
            appDelegate.uploadController.processQueue(true)
        }
        return true
    }
    
    func setUploading(status: Bool){
        isActive = status
        needsDisplay = true
    }
}