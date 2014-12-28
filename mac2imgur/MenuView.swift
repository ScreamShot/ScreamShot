import Cocoa

class MenuView: NSView, NSMenuDelegate {
    var highlight = false
    var isActive = false
    
    let ImageViewWidth: Int = 22
    var imageView: NSImageView
    
    var activeIcon: NSImage!
    var inactiveIcon: NSImage!
    
    // NSVariableStatusItemLength == -1
    // Not using symbol because it doesn't link properly in Swift
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    // MARK: Initializers
    
    override init() {
        var height: CGFloat = NSStatusBar.systemStatusBar().thickness
        imageView = NSImageView(frame: NSMakeRect(0, 0, CGFloat(ImageViewWidth), height))
        super.init(frame: NSMakeRect(0, 0, CGFloat(ImageViewWidth), height))
        
        self.addSubview(imageView)
        registerForDraggedTypes([NSFilenamesPboardType])
        statusItem.view = self
        inactiveIcon = NSImage(named: "StatusInactive")!
        inactiveIcon.setTemplate(true)
        activeIcon = NSImage(named: "StatusActive")!
        activeIcon.setTemplate(true)
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
        imageView.image = status ? activeIcon : inactiveIcon
    }
}