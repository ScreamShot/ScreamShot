import Cocoa
import ScreamUtils

class MenuView: NSView, NSMenuDelegate {
    var _highlight = false;
    var isActive = false;
    var _progress = 0.0;
    
    // NSVariableStatusItemLength == -1
    let statusItem = NSStatusBar.systemStatusBar().statusItemWithLength(-1)
    // MARK: Initializers
    
    init() {
        super.init(frame: NSMakeRect(0, 0, 24, 24));
        
        registerForDraggedTypes([NSFilenamesPboardType]);
        statusItem.view = self;
    }
    
    
    required convenience init(coder: NSCoder) {
        self.init();
    }
    
    // MARK: Menu
    
    func setupMenu(menu: NSMenu) {
        self.menu = menu;
        self.menu!.delegate = self;
        setUploading(false);
    }
    
    
    override func drawRect(dirtyRect: NSRect) {
        super.drawRect(dirtyRect);
        frame = dirtyRect;
        statusItem.drawStatusBarBackgroundInRect(dirtyRect, withHighlight: _highlight);
        if _highlight{
            NSColor.selectedMenuItemColor().setFill();
        }else{
            NSColor.clearColor().setFill();
        }
        NSRectFill(dirtyRect);
        (isActive ? "🚀" : "📷").drawInRect(CGRectOffset(dirtyRect, 4, -1), withAttributes: [NSFontAttributeName: NSFont.menuBarFontOfSize(13)]);
        var width = dirtyRect.size.width;
        var height = dirtyRect.size.height;
        var mySimpleRect: NSRect = NSMakeRect(0, 1, width*CGFloat(_progress), 3);
        NSColor.grayColor().set();
        NSRectFill(mySimpleRect);
    }
    
    
    override func mouseDown(theEvent: NSEvent) {
        super.mouseDown(theEvent);
        setHighlight(true);
        statusItem.popUpStatusItemMenu(menu!);
    }
    
    
    func menuWillOpen(menu: NSMenu) {
        setHighlight(true);
    }
    
    
    func menuDidClose(menu: NSMenu) {
        setHighlight(false);
    }
    // MARK: Dragging
    
    
    override func draggingEntered(sender: NSDraggingInfo) -> NSDragOperation {
        return NSDragOperation.Copy;
    }
    
    
    override func performDragOperation(sender: NSDraggingInfo) -> Bool {
        let pboard = sender.draggingPasteboard();
        println(pboard.types as! [NSString]);
        if contains(pboard.types as! [NSString], NSFilenamesPboardType) {
            let files = pboard.propertyListForType(NSFilenamesPboardType) as! [String];
            let appDelegate = NSApplication.sharedApplication().delegate as! AppDelegate;
            for file in files{
                appDelegate.sendFile(file, isScreenshot: false);
            }
        }
        return true;
    }
    
    // Helpers
    
    
    func setUploading(status: Bool){
        isActive = status;
        needsDisplay = true;
    }
    
    
    func setHighlight(status: Bool){
        needsDisplay = (self._highlight != status);
        self._highlight = status;
    }
    
    
    func setProgress(progress: Double) -> (){
        needsDisplay = (self._progress != progress);
        self._progress = progress;
    }
    
    
    func setLastItem(filePath: String, link: String){
        var url = NSURL(fileURLWithPath: filePath)!;
        let mimeType = ScreamUtils.getMimetype(url);
        let fileName = url.path?.lastPathComponent;
        
        var nsm = NSMenuItem(title: fileName!, action:"copyLink:", keyEquivalent:"");
        var canDisplay = mimeType.rangeOfString("image/") != nil;
        var isSvg = mimeType.rangeOfString("image/svg") != nil;
        // @TODO: Due to a bug, SVG can't be displayed with this method
        if canDisplay && !isSvg {
            if let image = NSImage(contentsOfFile: filePath){
                if let icon = resizeImageForMenu(image) {
                    nsm.image = NSImage(data: icon)
                }
            }
        }else{
            println("NOT AN IMAGE :(");
        }
        nsm.enabled = true;
        nsm.target = self;
        nsm.representedObject = link;
        
        var app = NSApplication.sharedApplication().delegate as! AppDelegate;
        app.copyLastLink.representedObject = link;
        
        
        app.lastItems!.submenu!.addItem(nsm);
        let items = app.lastItems!.submenu!.itemArray;
        if items.count > 5{
            let itemMenu = items[items.count - 6 ] as! NSMenuItem;
            println("Remove lastItem \(itemMenu.title)");
            app.lastItems!.submenu!.removeItem(itemMenu);
            
            for item in items {
                if let itemMenu = item as? NSMenuItem{
                    itemMenu.enabled = true
                }
            }
        }
    }
    
    
    func resizeImageForMenu(image: NSImage) -> NSData? {
        let scaleFactor = CGFloat(22/max(image.size.width, image.size.height))
        let resizedBounds = NSRect(x: 0, y: 0, width: round(image.size.width * scaleFactor), height: round(image.size.height * scaleFactor))
        let resizedBounds2 = NSRect(x: 0, y: 0, width: 22, height: 22)
        
        // Only resize the image if a change in size will occur
        if !NSEqualSizes(resizedBounds.size, image.size) {
            let resizedImage = NSImage(size: resizedBounds.size)
            let imageRep = image.bestRepresentationForRect(resizedBounds, context: nil, hints: nil)!
            
            resizedImage.lockFocus()
            imageRep.drawInRect(resizedBounds2)
            resizedImage.unlockFocus()
            
            // Use a PNG representation of the resized image
            return NSBitmapImageRep(data: resizedImage.TIFFRepresentation!)!.representationUsingType(NSBitmapImageFileType.NSPNGFileType, properties: [:])!
        }
        return nil;
    }
}