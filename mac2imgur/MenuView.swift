import Cocoa

class MenuView: NSView, NSMenuDelegate {
    var highlight = false
    var isActive = false
    var progress = 0.0
    
    // NSVariableStatusItemLength == -1
    // Not using symbol because it doesn't link properly in Swift
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    // MARK: Initializers
    
    override init() {
        super.init(frame: NSMakeRect(0, 0, 24, 24))
        
        registerForDraggedTypes([NSFilenamesPboardType])
        statusItem.view = self
    }
    
    required convenience init(coder: NSCoder) {
        self.init()
    }
    
    // MARK: Menu
    
    func setupMenu(menu: NSMenu) {
        self.menu = menu
        self.menu!.delegate = self
    }
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect)
        frame = dirtyRect
        statusItem.drawStatusBarBackgroundInRect(dirtyRect, withHighlight: highlight)
        if highlight{
            NSColor.selectedMenuItemColor().setFill()
        }else{
            NSColor.clearColor().setFill()
        }
        NSRectFill(dirtyRect)
        (isActive ? "🚀" : "📷").drawInRect(CGRectOffset(dirtyRect, 4, -1), withAttributes: [NSFontAttributeName: NSFont.menuBarFontOfSize(13)])
        var width = dirtyRect.size.width
        var height = dirtyRect.size.height
        var mySimpleRect: NSRect = NSMakeRect(0, 1, width*CGFloat(progress), 3)
        NSColor.grayColor().set()
        NSRectFill(mySimpleRect)
    }
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent)
        setHighlight(true)
        statusItem.popUpStatusItemMenu(menu!)
    }
    
    func menuWillOpen(menu: NSMenu!) {
        setHighlight(true)
    }
    
    func menuDidClose(menu: NSMenu!) {
        setHighlight(false)
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
                let upload = Upload(app: appDelegate, pathToImage: file, isScreenshot: false, delegate: appDelegate)
                appDelegate.uploadController.addToQueue(upload)
            }
        }
        return true
    }
    
    func setUploading(status: Bool){
        isActive = status
        needsDisplay = true
    }
    
    func setHighlight(status: Bool){
        needsDisplay = (highlight != status)
        highlight = status
    }
    
    func setProgress(progress: Double){
        needsDisplay = (self.progress != progress)
        self.progress = progress
    }
}