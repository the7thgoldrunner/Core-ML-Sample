//
//  ViewController.swift
//  CoreMLSimple
//
//  Created by 杨萧玉 on 2017/6/9.
//  Copyright © 2017年 杨萧玉. All rights reserved.
//

import UIKit
import CoreMedia
import Vision

class ViewController: UIViewController {
    
    private enum Inceptionv3Constants {
        static let FramesPerSecond: Int32 = 5
        static let SizeMeasurement = 299
        
        static let Size = CGSize(width: Inceptionv3Constants.SizeMeasurement, height: Inceptionv3Constants.SizeMeasurement)
    }
    
    @IBOutlet private weak var predictLabel: UILabel!
    @IBOutlet private weak var previewView: UIView!
    
    let inceptionv3model = Inceptionv3()
    private var videoCapture: VideoCapture!
    
    private lazy var rectanglesRequest: VNDetectRectanglesRequest = {
        let request = VNDetectRectanglesRequest(completionHandler: self.handleRectangles)
        request.minimumSize = 0.3
        return request
    }()
    
    private var carFrameView: UIView?
    private var carObservation: VNDetectedObjectObservation?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        //setupVision()
        let spec = VideoSpec(fps: Inceptionv3Constants.FramesPerSecond, size: Inceptionv3Constants.Size)
        videoCapture = VideoCapture(cameraType: .back,
                                    preferredSpec: spec,
                                    previewContainer: previewView.layer)
        
        
        videoCapture.imageBufferHandler = {[unowned self] (imageBuffer) in
            self.handleImageBufferWithCoreML(imageBuffer: imageBuffer)
        }
        
        self.predictLabel.textAlignment = .center
    }
    
    override var prefersStatusBarHidden: Bool {
        return true
    }
    
    func handleImageBufferWithCoreML(imageBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(imageBuffer) else {
            return
        }
        do {
            let prediction = try self.inceptionv3model.prediction(image: self.resize(pixelBuffer: pixelBuffer)!)
            let isCar = prediction.isCarPrediction()
            DispatchQueue.main.async {
                self.predictLabel.text = isCar ? "-> 🚗 🚙 🏎 <-" : ""
                self.carFrameView?.isHidden = !isCar
            }
            
            if (isCar) {
                handleImageBufferWithVision(imageBuffer: imageBuffer)
            }
        }
        catch let error as NSError {
            fatalError("Unexpected error ocurred: \(error.localizedDescription).")
        }
    }
    
    func handleImageBufferWithVision(imageBuffer: CMSampleBuffer) {
        guard let pixelBuffer = CMSampleBufferGetImageBuffer(imageBuffer) else {
            return
        }
        
        var requestOptions:[VNImageOption : Any] = [:]
        
        if let cameraIntrinsicData = CMGetAttachment(imageBuffer, kCMSampleBufferAttachmentKey_CameraIntrinsicMatrix, nil) {
            requestOptions = [.cameraIntrinsics:cameraIntrinsicData]
        }
        let imageRequestHandler = VNImageRequestHandler( cvPixelBuffer: pixelBuffer, orientation: self.exifOrientationFromDeviceOrientation, options: requestOptions)
        
        /*
        guard let visionModel = try? VNCoreMLModel(for: inceptionv3model.model) else {
            fatalError("can't load Vision ML model")
        }
        let classificationRequest = VNCoreMLRequest(model: visionModel, completionHandler: self.handleRectangles)
         
        
        let trackRequest = VNTrackObjectRequest(detectedObjectObservation: VNDetectedObjectObservation(boundingBox: CGRect(origin: CGPoint(), size: Inceptionv3Constants.Size)), completionHandler: self.handleRectangles)
        */
        do {
            
            if (self.carObservation != nil) {
                let trackCarRequest = VNTrackObjectRequest(detectedObjectObservation: self.carObservation!, completionHandler: self.handleCarTracking)
                try imageRequestHandler.perform([trackCarRequest])
            } else {
                try imageRequestHandler.perform([self.rectanglesRequest])
            }
        } catch {
            print(error)
        }
    }
    
    func handleRectangles(request: VNRequest, error: Error?) {
        guard let findings = request.results as? [VNRectangleObservation] else {
        //guard let findings = request.results as? [VNDetectedObjectObservation] else {
            DispatchQueue.main.async {
                self.carFrameView?.isHidden = true
            }
            return
        }
        print("\(findings.count) found.")
        guard let detectedRectangle = findings.first else {
            DispatchQueue.main.async {
                self.carFrameView?.isHidden = true
            }
            return
        }
        /*
        
        let boundingBox = detectedRectangle.boundingBox.scaled(to: Inceptionv3Constants.Size)
        let topLeft = detectedRectangle.topLeft.scaled(to: Inceptionv3Constants.Size)
        let topRight = detectedRectangle.topRight.scaled(to: Inceptionv3Constants.Size)
        let bottomLeft = detectedRectangle.bottomLeft.scaled(to: Inceptionv3Constants.Size)
        let bottomRight = detectedRectangle.bottomRight.scaled(to: Inceptionv3Constants.Size)
        
        let frame = CGRect(x: bottomLeft.x, y: bottomLeft.y, width: topRight.x - topLeft.x, height: topRight.y - bottomRight.y)
         */
        var transformedRect = detectedRectangle.boundingBox
        //transformedRect.origin.y = 1 - transformedRect.origin.y
        
        
        //let frame = detectedRectangle.boundingBox.scaled(to: Inceptionv3Constants.Size)
        
        DispatchQueue.main.async {
            
            let frame = self.videoCapture.layerRectConverted(fromMetadataOutputRect: transformedRect)
            self.carObservation = VNDetectedObjectObservation(boundingBox: frame)
            
            
            /*
            if (self.carFrameView == nil) {
                self.carFrameView = UIView(frame: frame)
                self.view.addSubview(self.carFrameView!)
                self.carFrameView?.layer.borderColor = UIColor.yellow.cgColor
                self.carFrameView?.layer.borderWidth = 2.0
            } else {
                self.carFrameView?.frame = frame
                self.carFrameView?.isHidden = false
            }
            */
        }
        
    }
    
    func handleCarTracking(request: VNRequest, error: Error?) {
        guard let findings = request.results as? [VNDetectedObjectObservation] else {
            DispatchQueue.main.async {
                self.carFrameView?.isHidden = true
            }
            return
        }
        print("Tracking \(findings.count) findings (cars?).")
        guard let newObservation = findings.first else {
            DispatchQueue.main.async {
                self.carFrameView?.isHidden = true
            }
            return
        }
        self.carObservation = newObservation
        /*
         
         let boundingBox = detectedRectangle.boundingBox.scaled(to: Inceptionv3Constants.Size)
         let topLeft = detectedRectangle.topLeft.scaled(to: Inceptionv3Constants.Size)
         let topRight = detectedRectangle.topRight.scaled(to: Inceptionv3Constants.Size)
         let bottomLeft = detectedRectangle.bottomLeft.scaled(to: Inceptionv3Constants.Size)
         let bottomRight = detectedRectangle.bottomRight.scaled(to: Inceptionv3Constants.Size)
         
         let frame = CGRect(x: bottomLeft.x, y: bottomLeft.y, width: topRight.x - topLeft.x, height: topRight.y - bottomRight.y)
         */
        var transformedRect = newObservation.boundingBox
        //transformedRect.origin.y = 1 - transformedRect.origin.y
        
        
        //let frame = detectedRectangle.boundingBox.scaled(to: Inceptionv3Constants.Size)
        let frame = transformedRect
        print(newObservation.boundingBox)
        
        DispatchQueue.main.async {
            //let frame = self.videoCapture.layerRectConverted(fromMetadataOutputRect: transformedRect)
            if (self.carFrameView == nil) {
                self.carFrameView = UIView(frame: frame)
                self.view.addSubview(self.carFrameView!)
                self.carFrameView?.layer.borderColor = UIColor.yellow.cgColor
                self.carFrameView?.layer.borderWidth = 2.0
            } else {
                self.carFrameView?.frame = frame
                self.carFrameView?.isHidden = false
            }
        }
    }
    
    /*
    func setupVision() {
        guard let visionModel = try? VNCoreMLModel(for: inceptionv3model.model) else {
            fatalError("can't load Vision ML model")
        }
        let classificationRequest = VNCoreMLRequest(model: visionModel) { (request: VNRequest, error: Error?) in
            guard let observations = request.results else {
                print("no results:\(error!)")
                return
            }
            
            let classifications = observations[0...4]
                .flatMap({ $0 as? VNClassificationObservation })
                .filter({ $0.confidence > 0.2 })
                .map({ "\($0.identifier) \($0.confidence)" })
            DispatchQueue.main.async {
                self.predictLabel.text = classifications.joined(separator: "\n")
            }
        }
        classificationRequest.imageCropAndScaleOption = VNImageCropAndScaleOptionCenterCrop
    }
    */
    
    
    /// only support back camera
    var exifOrientationFromDeviceOrientation: Int32 {
        let exifOrientation: DeviceOrientation
        enum DeviceOrientation: Int32 {
            case top0ColLeft = 1
            case top0ColRight = 2
            case bottom0ColRight = 3
            case bottom0ColLeft = 4
            case left0ColTop = 5
            case right0ColTop = 6
            case right0ColBottom = 7
            case left0ColBottom = 8
        }
        switch UIDevice.current.orientation {
        case .portraitUpsideDown:
            exifOrientation = .left0ColBottom
        case .landscapeLeft:
            exifOrientation = .top0ColLeft
        case .landscapeRight:
            exifOrientation = .bottom0ColRight
        default:
            exifOrientation = .right0ColTop
        }
        return exifOrientation.rawValue
    }
    
    
    /// resize CVPixelBuffer
    ///
    /// - Parameter pixelBuffer: CVPixelBuffer by camera output
    /// - Returns: CVPixelBuffer with size (299, 299)
    func resize(pixelBuffer: CVPixelBuffer) -> CVPixelBuffer? {
        let imageSide = 299
        var ciImage = CIImage(cvPixelBuffer: pixelBuffer, options: nil)
        let transform = CGAffineTransform(scaleX: CGFloat(imageSide) / CGFloat(CVPixelBufferGetWidth(pixelBuffer)), y: CGFloat(imageSide) / CGFloat(CVPixelBufferGetHeight(pixelBuffer)))
        ciImage = ciImage.applying(transform).cropping(to: CGRect(x: 0, y: 0, width: imageSide, height: imageSide))
        let ciContext = CIContext()
        var resizeBuffer: CVPixelBuffer?
        CVPixelBufferCreate(kCFAllocatorDefault, imageSide, imageSide, CVPixelBufferGetPixelFormatType(pixelBuffer), nil, &resizeBuffer)
        ciContext.render(ciImage, to: resizeBuffer!)
        return resizeBuffer
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        guard let videoCapture = videoCapture else {return}
        videoCapture.startCapture()
    }
    
    override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        guard let videoCapture = videoCapture else {return}
        videoCapture.resizePreview()
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        guard let videoCapture = videoCapture else {return}
        videoCapture.stopCapture()
        
        super.viewWillDisappear(animated)
    }
}

