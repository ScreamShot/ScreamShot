//
//  SelectionView.swift
//  Screen Recording Demo
//
//  Created by Miles Dunne on 28/10/2015.
//
//

import Cocoa
import AVFoundation
import ScreamUtils

class SelectionView: NSView, AVCaptureFileOutputRecordingDelegate {
    
    @IBOutlet weak var optionsView: NSVisualEffectView!
    
    let viewPadding: CGFloat = 6
    
    var marchingAntsBackgroundLayer: CAShapeLayer?
    var marchingAntsAnimationLayer: CAShapeLayer?
    var crossLayer1: CAShapeLayer?
    var crossLayer2: CAShapeLayer?
    
    var currentCaptureSession: AVCaptureSession?
    var captureStartedHandler: ((AVCaptureMovieFileOutput) -> Void)?
    var captureOutputHandler: ((NSURL!) -> Void)?
    var lastMouseDownPoint = NSZeroPoint
    var lastMousePoint = NSZeroPoint
    
    override func awakeFromNib() {
        window?.makeFirstResponder(self)
        window?.acceptsMouseMovedEvents = true
        
        // Set up the options bar
        optionsView.layer?.cornerRadius = 6
        optionsView.blendingMode = .WithinWindow
        optionsView.appearance = NSAppearance(named: NSAppearanceNameVibrantDark)
    }
    
    var selectionRect = NSZeroRect {
        didSet {
            // Update selection layer
            let selectionPath = CGPathCreateMutable()
            CGPathAddRect(selectionPath, nil, frame)
            CGPathAddRect(selectionPath, nil, selectionRect)
            
            // Update marching ants
            marchingAntsAnimationLayer?.path = marchingAntsPath
            marchingAntsBackgroundLayer?.path = marchingAntsPath
            
            // Update option bar view location
            optionsView.hidden = selectionRect.width == 0 || selectionRect.height == 0
            optionsView.frame.origin.y = selectionRect.minY - optionsView.frame.height - viewPadding
            optionsView.frame.origin.x = selectionRect.midX - optionsView.frame.width / 2
            optionsView.frame = fit(optionsView.frame, inside: frame, padding: viewPadding)
        }
    }
    
    var marchingAntsPath: CGPath {
        if selectionRect.width != 0 && selectionRect.height != 0 {
            // This makes a 1px rect around the outside of the selectionRect
            let marchingAntsRect =  NSInsetRect(selectionRect.standardized, -0.5, -0.5)
            return CGPathCreateWithRect(marchingAntsRect, nil)
        } else {
            return CGPathCreateMutable() // Empty path
        }
    }
    
    var crossPath1: CGPath {
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, lastMousePoint.x, 0)
        CGPathAddLineToPoint(path, nil, lastMousePoint.x, frame.height)
        return path
    }
    
    var crossPath2: CGPath {
        let path = CGPathCreateMutable()
        CGPathMoveToPoint(path, nil, 0, lastMousePoint.y)
        CGPathAddLineToPoint(path, nil, frame.width, lastMousePoint.y)
        return path
    }
    
    func startSelection() {
        window?.ignoresMouseEvents = false
        
        addSubview(optionsView)
        
        lastMouseDownPoint = NSZeroPoint
        lastMousePoint = NSZeroPoint
        
        let backgroundLayer = CAShapeLayer()
        backgroundLayer.path = marchingAntsPath
        backgroundLayer.lineWidth = 1
        backgroundLayer.strokeColor = CGColorGetConstantColor(kCGColorWhite)
        backgroundLayer.fillColor = CGColorGetConstantColor(kCGColorClear)
        
        let lineInterval = 12
        let animationLayer = CAShapeLayer()
        animationLayer.path = marchingAntsPath
        animationLayer.lineWidth = 1
        animationLayer.strokeColor = CGColorGetConstantColor(kCGColorBlack)
        animationLayer.fillColor = CGColorGetConstantColor(kCGColorClear)
        animationLayer.lineDashPattern = [lineInterval, lineInterval]
        
        let animation = CABasicAnimation(keyPath: "lineDashPhase")
        animation.fromValue = 0
        animation.toValue = lineInterval * 2
        animation.duration = 1
        // Keep the animation going forever
        animation.repeatCount = Float.infinity
        
        animationLayer.addAnimation(animation, forKey: "lineDash")
        
        marchingAntsBackgroundLayer = backgroundLayer
        marchingAntsAnimationLayer = animationLayer
        layer?.addSublayer(backgroundLayer)
        layer?.addSublayer(animationLayer)
        
        // Cross around cursor
        let cross1 = CAShapeLayer()
        cross1.path = crossPath1
        cross1.lineWidth = 1
        cross1.strokeColor = CGColorGetConstantColor(kCGColorBlack)
        cross1.fillColor = CGColorGetConstantColor(kCGColorClear)
        cross1.lineDashPattern = [10, 10]
        crossLayer1 = cross1
        
        let cross2 = CAShapeLayer()
        cross2.path = crossPath2
        cross2.lineWidth = 1
        cross2.strokeColor = CGColorGetConstantColor(kCGColorBlack)
        cross2.fillColor = CGColorGetConstantColor(kCGColorClear)
        cross2.lineDashPattern = [10, 10]
        crossLayer2 = cross2
        
        layer?.addSublayer(crossLayer1!) // x
        layer?.addSublayer(crossLayer2!) // y
    }
    
    @IBAction func startRecordingAction(sender: AnyObject?) {
        // Disable mouse events so the windows beneath can be interacted with
        window?.ignoresMouseEvents = true
        //selectionLayer?.fillColor = NSColor.clearColor().CGColor
        
        optionsView.removeFromSuperview()
        
        // https://developer.apple.com/library/mac/qa/qa1740/_index.html
        
        let captureSession = AVCaptureSession()
        captureSession.sessionPreset = AVCaptureSessionPresetPhoto
        currentCaptureSession = captureSession
        
        let screenInput = AVCaptureScreenInput(displayID: CGMainDisplayID())
        screenInput.cropRect = selectionRect
        //Could use (screenInput!.minFrameDuration = CMTimeMake(1, 5)) to set framerate
        
        if captureSession.canAddInput(screenInput) {
            captureSession.addInput(screenInput)
        }
        
        let captureOutput = AVCaptureMovieFileOutput()
        
        if captureSession.canAddOutput(captureOutput) {
            captureSession.addOutput(captureOutput)
        }
        
        captureSession.startRunning()
        let diceRoll = Int(arc4random_uniform(1000))
        let outputURL = NSURL(fileURLWithPath: "\(NSTemporaryDirectory())\(NSDate())-\(diceRoll).mov")
        captureOutput.startRecordingToOutputFileURL(outputURL, recordingDelegate: self)
        
        captureStartedHandler?(captureOutput)
    }
    
    func captureOutput(captureOutput: AVCaptureFileOutput!, didFinishRecordingToOutputFileAtURL outputFileURL: NSURL!, fromConnections connections: [AnyObject]!, error: NSError!) {
        currentCaptureSession?.stopRunning()
        currentCaptureSession = nil
        var preset: AVAssetExportSession?
        if #available(OSX 10.11, *) {
            preset = AVAssetExportSession.init(asset: AVAsset.init(URL: outputFileURL), presetName: AVAssetExportPresetHighestQuality)
        } else {
            preset = AVAssetExportSession.init(asset: AVAsset.init(URL: outputFileURL), presetName: AVAssetExportPresetPassthrough)
        }
        // preset?.shouldOptimizeForNetworkUse = true // true -> won't play on iOS
        preset?.outputFileType = AVFileTypeMPEG4
        preset?.outputURL = NSURL(fileURLWithPath: (outputFileURL.URLByDeletingPathExtension?.path!)! + ".mp4")
        preset?.exportAsynchronouslyWithCompletionHandler({ () -> Void in
            deleteFile(outputFileURL.path!)
            self.captureOutputHandler?(preset?.outputURL)
        })
    }
    
    @IBAction func cancelAction(sender: AnyObject?) {
        cancelOperation(sender)
    }
    
    override func cancelOperation(sender: AnyObject?) {
        layer?.sublayers?.removeAll()
        selectionRect = NSZeroRect
        window?.close()
    }
    
    override func mouseDown(theEvent: NSEvent) {
        lastMouseDownPoint = pointFromEvent(theEvent)
        mouseMoved(theEvent) // To hide the X cursor
    }
    
    override func mouseMoved(theEvent: NSEvent) {
        if lastMouseDownPoint == NSZeroPoint {
            lastMousePoint = pointFromEvent(theEvent)
        }else{
            lastMousePoint = NSZeroPoint
        }
        crossLayer1?.path = crossPath1
        crossLayer2?.path = crossPath2
    }
    
    override func mouseDragged(theEvent: NSEvent) {
        let mousePoint = pointFromEvent(theEvent)
        selectionRect.origin = lastMouseDownPoint
        selectionRect.size.width = mousePoint.x - selectionRect.origin.x
        selectionRect.size.height = mousePoint.y - selectionRect.origin.y
    }
    
    func pointFromEvent(event: NSEvent) -> CGPoint {
        // Convert the event mouse location to this view's coordinate system
        let mousePoint = convertPoint(event.locationInWindow, fromView: nil)
        // Round the point - we need whole pixels
        return CGPoint(x: round(mousePoint.x), y: round(mousePoint.y))
    }
    
    func fit(frame: CGRect, inside: CGRect, padding: CGFloat) -> CGRect {
        var newRect = frame
        
        if newRect.origin.x < padding {
            newRect.origin.x = padding
        }
        
        if newRect.origin.y < padding {
            newRect.origin.y = padding
        }
        
        if newRect.origin.x > inside.width - frame.width - padding {
            newRect.origin.x = inside.width - frame.width - padding
        }
        
        if newRect.origin.y > inside.height - frame.height - padding {
            newRect.origin.y = inside.height - frame.height - padding
        }
        
        return newRect
    }
    
    override func resetCursorRects() {
        if currentCaptureSession == nil {
            addCursorRect(frame, cursor: NSCursor.crosshairCursor())
        }
        addCursorRect(optionsView.frame, cursor: NSCursor.arrowCursor())
    }
    
}