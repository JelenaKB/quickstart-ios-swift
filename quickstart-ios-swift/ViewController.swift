//
//  ViewController.swift
//  quickstart-ios-swift
//
//  Created by Lara Vertlberg on 09/12/2019.
//  Copyright © 2019 Lara Vertlberg. All rights reserved.
//

import UIKit
import DeepAR
import AVKit
import AVFoundation

enum Mode: String {
    case masks
    case effects
    case filters
}

enum RecordingMode : String {
    case photo
    case video
    case lowQualityVideo
}

enum RecordingState : String {
    case preparing
    case ready
    case recording
}

enum Masks: String, CaseIterable {
    case none
    case aviators
    case bigmouth
    case dalmatian
    case bcgSeg
    case look2
    case fatify
    case flowers
    case grumpycat
    case koala
    case lion
    case mudMask
    case obama
    case pug
    case slash
    case sleepingmask
    case smallface
    case teddycigar
    case tripleface
    case twistedFace
}

enum Effects: String, CaseIterable {
    case none
    case fire
    case heart
    case blizzard
    case rain
}

enum Filters: String, CaseIterable {
    case none
    case tv80
    case drawingmanga
    case sepia
    case bleachbypass
    case realvhs
    case filmcolorperfection
}

class ViewController: UIViewController {
    
    // MARK: - IBOutlets -

    @IBOutlet weak var switchCameraButton: UIButton!
    
    @IBOutlet weak var masksButton: UIButton!
    @IBOutlet weak var effectsButton: UIButton!
    @IBOutlet weak var filtersButton: UIButton!
    
    @IBOutlet weak var previousButton: UIButton!
    @IBOutlet weak var nextButton: UIButton!
    @IBOutlet weak var recordActionButton: UIButton!
    
    @IBOutlet weak var lowQVideoButton: UIButton!
    @IBOutlet weak var videoButton: UIButton!
    @IBOutlet weak var photoButton: UIButton!
    @IBOutlet weak var arView: ARView!
    
    // This class handles camera interaction. Start/stop feed, check permissions etc. You can use it or you
    // can provide your own implementation
    private var cameraController: CameraController!
    
    // MARK: - Private properties -
    
    private var maskIndex: Int = 0
    private var maskPaths: [String?] {
        return Masks.allCases.map { $0.rawValue.path }
    }
    
    private var effectIndex: Int = 0
    private var effectPaths: [String?] {
        return Effects.allCases.map { $0.rawValue.path }
    }
    
    private var filterIndex: Int = 0
    private var filterPaths: [String?] {
        return Filters.allCases.map { $0.rawValue.path }
    }
    
    private var buttonModePairs: [(UIButton, Mode)] = []
    private var currentMode: Mode! {
        didSet {
            updateModeAppearance()
        }
    }
    
    private var buttonRecordingModePairs: [(UIButton, RecordingMode)] = []
    private var currentRecordingMode: RecordingMode! {
        didSet {
            updateRecordingModeAppearance()
        }
    }
    
    private var currentRecordingState: RecordingState! {
        didSet {
            updateRecordingModeAppearance()
        }
    }
    
    //private var isRecordingInProcess: Bool = false
    
    // MARK: - Lifecycle -
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        setupCameraAndArView()
        addTargets()
        
        buttonModePairs = [(masksButton, .masks), (effectsButton, .effects), (filtersButton, .filters)]
        buttonRecordingModePairs = [ (photoButton, RecordingMode.photo), (videoButton, RecordingMode.video), (lowQVideoButton, RecordingMode.lowQualityVideo)]
        currentMode = .masks
        currentRecordingMode = .photo
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        NotificationCenter.default.addObserver(self, selector: #selector(orientationDidChange), name: UIDevice.orientationDidChangeNotification, object: nil)
    }
    
    override func viewWillTransition(to size: CGSize, with coordinator: UIViewControllerTransitionCoordinator) {
        super.viewWillTransition(to: size, with: coordinator)
        // sometimes UIDeviceOrientationDidChangeNotification will be delayed, so we call orientationChanged in 0.5 seconds anyway
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { [weak self] in
            self?.orientationDidChange()
        }
    }
    
    // MARK: - Private methods -
    
    private func setupCameraAndArView() {
        arView.setLicenseKey("your_api_key_here")
        arView.delegate = self
        
        cameraController = CameraController()
        cameraController.arview = arView
        
        arView.initialize()
        
        cameraController.startCamera()
        
        // Set videoRecordingWarmupEnabled after initialization
        arView.deepAR.videoRecordingWarmupEnabled = true;
        
    }
    
    private func addTargets() {
        switchCameraButton.addTarget(self, action: #selector(didTapSwitchCameraButton), for: .touchUpInside)
        recordActionButton.addTarget(self, action: #selector(didTapRecordActionButton), for: .touchUpInside)
        previousButton.addTarget(self, action: #selector(didTapPreviousButton), for: .touchUpInside)
        nextButton.addTarget(self, action: #selector(didTapNextButton), for: .touchUpInside)
        masksButton.addTarget(self, action: #selector(didTapMasksButton), for: .touchUpInside)
        effectsButton.addTarget(self, action: #selector(didTapEffectsButton), for: .touchUpInside)
        filtersButton.addTarget(self, action: #selector(didTapFiltersButton), for: .touchUpInside)
        
        
        photoButton.addTarget(self, action: #selector(didTapPhotoButton), for: .touchUpInside)
        videoButton.addTarget(self, action: #selector(didTapVideoButton), for: .touchUpInside)
        lowQVideoButton.addTarget(self, action: #selector(didTapLowQVideoButton), for: .touchUpInside)
    }
    
    private func updateModeAppearance() {
        buttonModePairs.forEach { (button, mode) in
            button.isSelected = mode == currentMode
        }
    }
    private func updateRecordingButton() {
        if (currentRecordingState == RecordingState.preparing){
            //disable record button while recording is preparing
            recordActionButton.isEnabled = false;
        } else {
            recordActionButton.isEnabled = true;
        }
    }
    
    private func updateRecordingModeAppearance() {
        buttonRecordingModePairs.forEach { (button, recordingMode) in
            button.isSelected = recordingMode == currentRecordingMode
        }
    }
    
    private func switchMode(_ path: String?) {
        arView.switchEffect(withSlot: currentMode.rawValue, path: path)
    }
    
    @objc
    private func orientationDidChange() {
        guard let orientation = UIApplication.shared.windows.first?.windowScene?.interfaceOrientation else { return }
        switch orientation {
        case .landscapeLeft:
            cameraController.videoOrientation = .landscapeLeft
            break
        case .landscapeRight:
            cameraController.videoOrientation = .landscapeRight
            break
        case .portrait:
            cameraController.videoOrientation = .portrait
            break
        case .portraitUpsideDown:
            cameraController.videoOrientation = .portraitUpsideDown
        default:
            break
        }
        
    }
    
    @objc
    private func didTapSwitchCameraButton() {
        cameraController.position = cameraController.position == .back ? .front : .back
    }
    
    @objc
    private func didTapRecordActionButton() {
        //
        
        if (currentRecordingMode == RecordingMode.photo) {
            arView.takeScreenshot()
            return
        }
        
        if (currentRecordingState == RecordingState.recording) {
            arView.finishVideoRecording()
            //finishVideoRecording will start preparing for next recording session if videoRecordingWarmupEnabled is true
            currentRecordingState = RecordingState.preparing
            return
        }
        
        if (currentRecordingMode == RecordingMode.video && currentRecordingState == RecordingState.ready) {
            arView.resumeVideoRecording();
            currentRecordingState = RecordingState.recording;
            return
        }
        // Disabled in prepared recording mode
        /*
        if (currentRecordingMode == RecordingMode.lowQualityVideo) {
            let videoQuality = 0.1
            let bitrate =  1250000
            let videoSettings:[AnyHashable : AnyObject] = [
                AVVideoQualityKey : (videoQuality as AnyObject),
                AVVideoAverageBitRateKey : (bitrate as AnyObject)
            ]
            
            let frame = CGRect(x: 0, y: 0, width: 1, height: 1)
            
            arView.startVideoRecording(withOutputWidth: width, outputHeight: height, subframe: frame, videoCompressionProperties: videoSettings, recordAudio: true)
            isRecordingInProcess = true
        }
         */
        
    }
    
    @objc
    private func didTapPreviousButton() {
        var path: String?
        
        switch currentMode! {
        case .effects:
            effectIndex = (effectIndex - 1 < 0) ? (effectPaths.count - 1) : (effectIndex - 1)
            path = effectPaths[effectIndex]
        case .masks:
            maskIndex = (maskIndex - 1 < 0) ? (maskPaths.count - 1) : (maskIndex - 1)
            path = maskPaths[maskIndex]
        case .filters:
            filterIndex = (filterIndex - 1 < 0) ? (filterPaths.count - 1) : (filterIndex - 1)
            path = filterPaths[filterIndex]
        }
        
        switchMode(path)
    }
    
    @objc
    private func didTapNextButton() {
        var path: String?
        
        switch currentMode! {
        case .effects:
            effectIndex = (effectIndex + 1 > effectPaths.count - 1) ? 0 : (effectIndex + 1)
            path = effectPaths[effectIndex]
        case .masks:
            maskIndex = (maskIndex + 1 > maskPaths.count - 1) ? 0 : (maskIndex + 1)
            path = maskPaths[maskIndex]
        case .filters:
            filterIndex = (filterIndex + 1 > filterPaths.count - 1) ? 0 : (filterIndex + 1)
            path = filterPaths[filterIndex]
        }
        
        switchMode(path)
    }
    
    @objc
    private func didTapMasksButton() {
        currentMode = .masks
    }
    
    @objc
    private func didTapEffectsButton() {
        currentMode = .effects
    }
    
    @objc
    private func didTapFiltersButton() {
        currentMode = .filters
    }
    
    @objc
    private func didTapPhotoButton() {
        currentRecordingMode = .photo
    }
    
    @objc
    private func didTapVideoButton() {
        currentRecordingMode = .video
    }
    
    @objc
    private func didTapLowQVideoButton() {
        currentRecordingMode = .lowQualityVideo
    }
}

// MARK: - ARViewDelegate -

extension ViewController: DeepARDelegate {

    func didStartVideoRecording() { }
    
    func didFinishVideoRecording(_ videoFilePath: String!) {
        let documentsDirectory = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true).first!
        let components = videoFilePath.components(separatedBy: "/")
        guard let last = components.last else { return }
        let destination = URL(fileURLWithPath: String(format: "%@/%@", documentsDirectory, last))
    
        let playerController = AVPlayerViewController()
        let player = AVPlayer(url: destination)
        playerController.player = player
        present(playerController, animated: true) {
            player.play()
        }
    }
    
    func recordingFailedWithError(_ error: Error!) {}
    
    func didTakeScreenshot(_ screenshot: UIImage!) {
        UIImageWriteToSavedPhotosAlbum(screenshot, nil, nil, nil)
        
        let imageView = UIImageView(image: screenshot)
        imageView.frame = view.frame
        view.insertSubview(imageView, aboveSubview: arView)
        
        let flashView = UIView(frame: view.frame)
        flashView.alpha = 0
        flashView.backgroundColor = .black
        view.insertSubview(flashView, aboveSubview: imageView)
        
        UIView.animate(withDuration: 0.1, animations: {
            flashView.alpha = 1
        }) { _ in
            flashView.removeFromSuperview()
            
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.25) {
                imageView.removeFromSuperview()
            }
        }
    }
    
    func didInitialize() {
        // Call startVideoRecording to prepare recording. Only needs to be called once when initialization is finished
        // Must be called on main thread
        DispatchQueue.main.async { [unowned self] in
            let width: Int32 = Int32(arView.renderingResolution.width)
            let height: Int32 =  Int32(arView.renderingResolution.height)
            arView.startVideoRecording(withOutputWidth: width, outputHeight: height);
            currentRecordingState = RecordingState.preparing;
        }
    }
    
    // Video recording is prepared, resumeVideoRecording can now be called
    func didFinishPreparingForVideoRecording() {
        currentRecordingState = RecordingState.ready;
    }
    
    func faceVisiblityDidChange(_ faceVisible: Bool) {}
}

extension String {
    var path: String? {
        return Bundle.main.path(forResource: self, ofType: nil)
    }
}
